import CasePaths
import ConcurrencyExtras
import Dependencies
import Foundation
import OSLog
import PostgREST

public typealias DatabaseResult = Result<(any Encodable), (any Error)>

@dynamicMemberLookup
public struct DatabaseRouter<Route: RouteCollection>: Sendable {
  
  private var _overrides = LockIsolated<_OverridesContainer>(.init())
  
  private var overrides: _OverridesContainer {
    get { _overrides.value }
    set {
      _overrides.withValue { value in
        value = newValue
      }
    }
  }
  
  private let decoder: JSONDecoder
  private let encoder: JSONEncoder
  private let execute: @Sendable (Route) async throws -> Data
  @UncheckedSendable
  private var logger: Logger?
  
  public init(database: PostgrestClient, logger: Logger? = nil) {
    self.init(
      decoder: database.configuration.decoder,
      encoder: database.configuration.encoder,
      execute: { route in
       try await route.route()
        .build({ database.from($0.name) })
        .execute()
        .data
      },
      logger: logger
    )
  }

  public init(
    decoder: JSONDecoder,
    encoder: JSONEncoder,
    logger: Logger? = nil,
    execute: @escaping @Sendable (Route) async throws -> DatabaseResult
  ) {
    self.init(
      decoder: decoder,
      encoder: encoder,
      execute: { try await execute($0).data(encoder) },
      logger: logger
    )
  }

  internal init(
    decoder: JSONDecoder,
    encoder: JSONEncoder,
    execute: @escaping @Sendable (Route) async throws -> Data,
    logger: Logger? = nil
  ) {
    self.decoder = decoder
    self.encoder = encoder
    self.execute = execute
    self.logger = logger
  }

  /// Call the database route, respecting any overrides and return the decoded result.
  ///
  /// - Parameters:
  ///   - route: The route to call on the database.
  @discardableResult
  public func call<A: Decodable>(
    _ route: Route
  ) async throws -> A {
    try await logIfError("Run Route:") {
      try await decoder.decode(A.self, from: data(for: route))
    }
  }
  /// Call the database route, respecting any overrides ignoring any output.
  ///
  /// - Parameters:
  ///   - route: The route to call on the database.
  public func call(
    _ route: Route
  ) async throws {
    guard await override(for: route) == nil else { return }
    try await logIfError("Run Route:") { try await execute(route) }
  }
  /// Call the database route, respecting any overrides and return the decoded result.
  ///
  /// - Parameters:
  ///   - route: The route to call on the database.
  @discardableResult
  public func callAsFunction<A: Decodable>(
    _ route: Route
  ) async throws -> A {
    try await self.call(route)
  }
  /// Call the database route, respecting any overrides ignoring any output.
  ///
  /// - Parameters:
  ///   - route: The route to call on the database.
  public func callAsFunction(
    _ route: Route
  ) async throws {
    try await self.call(route)
  }

  // Checks if there's an override for the given route, returning the
  // override data otherwise executes the route returning the data from
  // the database.
  private func data(for route: Route) async throws -> Data {
    guard let match = await override(for: route) else {
      return try await logIfError("Execute Route:") {
        try await execute(route)
      }
    }
    return try await logIfError("Decode Override Data:") {
      try match.data(encoder)
    }
  }
  
  // Checks for an override, returing the overrides result if found.
  private func override(for route: Route) async -> DatabaseResult? {
    await overrides.firstMatch(of: route)
  }
  
  @discardableResult
  private func logIfError<T>(
    _ prefix: String? = nil,
    _ call: @escaping () async throws -> T
  ) async throws -> T {
    do {
      return try await call()
    } catch {
      let message = prefix != nil ? "\(prefix!) \(error)" : "\(error)"
      logger?.error("\(message)")
      throw error
    }
  }

}

// MARK: - Overrides

#if DEBUG
extension DatabaseRouter {
  /// Override a route with the database result.
  ///
  /// ### Example
  /// ```swift
  /// router.override(.method(.delete, in: "todos"), with: .failure(MyError()))
  /// ```
  ///
  /// - Parameters:
  ///   - override: The override used to match a route.
  ///   - result: The result to return when the route is called.
  public mutating func override(
    _ override: Override,
    with result: DatabaseResult
  ) {
    overrides.insert(override, result: { _ in result })
  }
  /// Override the given route with the value.
  ///
  /// ### Example
  ///
  /// ```swift
  /// router.override(.case(\.todos.fetch), with: Todo.mocks)
  /// ```
  ///
  /// - Parameters:
  ///   - override: The override used to match a route.
  ///   - value: The value to return when the route is called.
  public mutating func override<A: Encodable>(
    _ override: Override,
    with value: A
  ) {
    overrides.insert(override, result: { _ in .success(value) })
  }
  /// Override the given route that returns void values.
  ///
  /// ### Example
  ///
  /// ```swift
  /// router.override(.method(.delete, in "todos"))
  /// ```
  ///
  /// - Parameters:
  ///   - override: The override used to match a route.
  public mutating func override(
    _ override: Override
  ) {
    overrides.insert(override, result: { _ in .success() })
  }
  
  /// Removes all overrides currently set on the router.
  public mutating func resetOverrides() {
    overrides.reset()
  }

  // Represents a collection of overrides managed by the router.
  struct _OverridesContainer {
    typealias FetchValue = (Route) async -> DatabaseResult
    
    private var overrides: [(route: Override, result: FetchValue)] = []
    
    func firstMatch(of route: Route) async -> DatabaseResult? {
      for override in overrides {
        if let match = try? await override.route.match(route),
           match == true
        {
          return await override.result(route)
        }
      }
      return nil
    }
    
    // Insert new overrides at the begining of the list, the
    // first override found for a given route will be used.
    mutating func insert(
      _ override: Override,
      result: @escaping FetchValue
    ) {
      overrides.insert(
        (route: override, result: result),
        at: 0
      )
    }
    
    mutating func reset() {
      self.overrides = []
    }
  }
  
  public struct Override {
    let match: (Route) async throws -> Bool
    
    public init(matching match: @escaping (Route) async throws -> Bool) {
      self.match = match
    }
    
    public static func `case`<T>(
      _ caseKeyPath: CaseKeyPath<Route, T>
    ) -> Self where Route: CasePathable {
      .init { route in
        AnyCasePath(caseKeyPath).extract(from: route) != nil
      }
    }
    
    public static func id(
      _ id: String,
      in table: DatabaseTable? = nil
    ) -> Self {
      .init { route in
        let route = try await route.route()
        return route.id == id && checkTable(route: route, table: table)
      }
    }
    
    public static func method(
      _ method: DatabaseRoute.Method,
      in table: DatabaseTable? = nil
    ) -> Self {
      .init { route in
        let route = try await route.route()
        return route.method == method && checkTable(route: route, table: table)
      }
    }
    
    public static func route(
      _ route: @escaping () async throws -> DatabaseRoute
    ) -> Self {
      .init { inputRoute in
        try await inputRoute.route() == route()
      }
    }
    
    public static func route(
      _ route: @escaping @autoclosure () -> DatabaseRoute
    ) -> Self {
      .route(route)
    }
    
    public static func route(
      _ route: Route
    ) -> Self where Route: Equatable {
      .init { route == $0 }
    }
    
    private static func checkTable(route: DatabaseRoute, table: DatabaseTable?) -> Bool {
      guard let table else { return true }
      return route.table == table
    }
  }
}
#endif

extension DatabaseRouter: CasePathable where Route: CasePathable {
  public typealias AllCasePaths = Route.AllCasePaths
  public static var allCasePaths: Route.AllCasePaths { Route.allCasePaths }
  
  /// Used with case key path's and dynamic member lookups when the `Route` is modeled as
  /// a `CasePathable` enum.  This type respects the overrides in the router and allows access
  /// to a router-like object that is able to call a route, returning it's value if applicable.
  ///
  /// > Note: Any overrides need to be made to the database router. You will not be able to add overrides
  /// > to the database router proxy.
  ///
  /// ### Example
  ///
  /// ```swift
  /// @CasePathable
  /// enum DatabaseRoutes: RouteController {
  ///   case todos(TodoRoute)
  ///   ... // Other routes.
  ///
  ///   func route() async throws -> DatabaseRoute {
  ///     switch self {
  ///       case let .todos(todos):
  ///         return try await todos.route()
  ///        ... // Handle other routes.
  ///     }
  ///   }
  /// }
  ///
  /// // Redacted registering the routes with the supabase client / dependencies mechanism.
  /// // The router is an instance of DatabaseRouter<DatabaseRoutes> in this example.
  ///
  /// @Dependency(\.supabase.router.todos) var todos
  /// let todos: [Todo] = try await todos(.fetch())
  ///
  /// // Override needs done on the router.
  /// supabase.router.override(.case(\.todos.fetch), with: Todo.mocks)
  /// let mockTodos: [Todo] = try await todos(.fetch())
  ///
  /// ```
  ///
  @dynamicMemberLookup
  public struct DatabaseRouterProxy<Value>: Sendable {
    private let casePath: AnyCasePath<Route, Value>
    private let router: DatabaseRouter<Route>
    
    init(
      casePath: AnyCasePath<Route, Value>,
      router: DatabaseRouter<Route>
    ) {
      self.casePath = casePath
      self.router = router
    }
    /// Call the database route, respecting any overrides ignoring any output.
    ///
    /// - Parameters:
    ///   - route: The route to call on the database.
    public func call(_ route: Value) async throws {
      try await router.call(casePath.embed(route))
    }
    /// Call the database route, respecting any overrides and return the decoded result.
    ///
    /// - Parameters:
    ///   - route: The route to call on the database.
    @discardableResult
    public func call<A: Decodable>(_ route: Value) async throws -> A {
      try await router.call(casePath.embed(route))
    }
    /// Call the database route, respecting any overrides ignoring any output.
    ///
    /// - Parameters:
    ///   - route: The route to call on the database.
    public func callAsFunction(_ route: Value) async throws {
      try await self.call(route)
    }
    /// Call the database route, respecting any overrides and return the decoded result.
    ///
    /// - Parameters:
    ///   - route: The route to call on the database.
    @discardableResult
    public func callAsFunction<A: Decodable>(_ route: Value) async throws -> A {
      try await self.call(route)
    }
  }
  
  public subscript<T>(case caseKeyPath: CaseKeyPath<Route, T>) -> DatabaseRouterProxy<T> {
    .init(casePath: AnyCasePath(caseKeyPath), router: self)
  }
  
  public subscript<T>(
    dynamicMember keyPath: KeyPath<Self.AllCasePaths, AnyCasePath<Route, T>>
  ) -> DatabaseRouterProxy<T> {
    .init(
      casePath: Self.allCasePaths[keyPath: keyPath],
      router: self
    )
  }
  
}

extension DatabaseRouter.DatabaseRouterProxy: CasePathable where Value: CasePathable {
  public typealias AllCasePaths = Value.AllCasePaths
  public static var allCasePaths: Value.AllCasePaths { Value.allCasePaths }
  
  public subscript<T>(case caseKeyPath: CaseKeyPath<Value, T>) -> DatabaseRouter.DatabaseRouterProxy<T> {
    self.appending(path: AnyCasePath(caseKeyPath))
  }
  
  public subscript<T>(
    dynamicMember keyPath: KeyPath<Self.AllCasePaths, AnyCasePath<Value, T>>
  ) -> DatabaseRouter.DatabaseRouterProxy<T> {
    self.appending(path: Self.allCasePaths[keyPath: keyPath])
  }
  
  private func appending<T>(
    path: AnyCasePath<Value, T>
  ) -> DatabaseRouter.DatabaseRouterProxy<T> {
    .init(
      casePath: self.casePath.appending(path: path),
      router: self.router
    )
  }
}

extension DatabaseRouter: TestDependencyKey {

  public static var testValue: DatabaseRouter<Route> {
    .init(
      decoder: XCTestDynamicOverlay.unimplemented("\(Self.self).decoder", placeholder: JSONDecoder()),
      encoder: XCTestDynamicOverlay.unimplemented("\(Self.self).encoder", placeholder: JSONEncoder()),
      execute: XCTestDynamicOverlay.unimplemented("\(Self.self).execute", placeholder: Data())
    )
  }
}

fileprivate struct EmptyEncodable: Encodable { }

extension DatabaseResult {
  
  public static func success() -> Self {
    .success(EmptyEncodable())
  }
  
  public init(catching result: () async throws -> Void) async {
    await self.init {
      try await result()
      return EmptyEncodable()
    }
  }
}

extension DatabaseResult {
  func data(_ encoder: JSONEncoder) throws -> Data {
    try encoder.encode(self.get())
  }
}

