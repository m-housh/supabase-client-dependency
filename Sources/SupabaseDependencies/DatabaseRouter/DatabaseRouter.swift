import CasePaths
import ConcurrencyExtras
import Dependencies
import Foundation
import OSLog
import PostgREST

public typealias DatabaseResult = Result<(any Codable), (any Error)>

/// A database router that gives override hooks for routes for previews and tests.
///
/// Routes are generally modeled as enumurations.  The database router is responsible for holding onto any route
/// overrides.  If an override is not found for the given route it will call the database with the route and decode the
/// results.
///
/// ### Example
///
/// ```swift
///
/// extension DatabaseRoute.Table {
///   static var todos: Self = "todos"
/// }
///
/// @CasePathable
/// enum TodoRoute: RouteCollection {
///   case delete(id: Todo.ID)
///   case fetch(filteredBy: [DatabaseRoute.Filter] = [], orderedBy: DatabaseRoute.Order? = nil)
///   case fetchOne(id: Todo.ID)
///   case save(Todo)
///
///   func route() async throws -> DatabaseRoute {
///     switch self {
///     case let .delete(id):
///       return .delete(id: id, from: .todos)
///     case let .fetch(filters, order):
///       return .fetch(from: .todos, filters: filters, order: order)
///     case .fetchOne(id: let id):
///       return .fetchOne(from: .todos, filteredBy: .id(id))
///     case let .save(todo):
///       return try .upsert(todo, into: .todos)
///     }
///   }
/// }
///
/// @CasePathable
/// enum DatabaseRoutes: RouteCollection {
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
/// supabase.router.override(\.todos.fetch, with: Todo.mocks)
/// let mockTodos: [Todo] = try await todos(.fetch())
///
/// ```
///
@dynamicMemberLookup
public struct DatabaseRouter<Route: RouteCollection>: Sendable {
  
  // TODO: Explore removing RouteCollection conformance for struct based routes??
  
  private var _overrides = LockIsolated([Override]())
  var overrides: [Override] {
    get { _overrides.value }
    set {
      _overrides.withValue { value in
        value = newValue
      }
    }
  }
  private let decoder: JSONDecoder
  private let encoder: JSONEncoder
  // TODO: Make this take a DatabaseRoute??
  private let execute: @Sendable (DatabaseRoute) async throws -> Data
  @UncheckedSendable private var logger: Logger?
  
  /// Create a new database router.  This is generally the initializer to use when creating your live router.
  ///
  /// - Parameters:
  ///   - database: The postgres client to use.
  ///   - decoder: A custom decoder used to decode database response, will use the one registered with the database if not supplied.
  ///   - encoder: A custom encoder used to encode override data, will use the one registered with the database if not supplied.
  ///   - logger: An optional logger to used to log any errors when performing database calls.
  public init(
    database: PostgrestClient,
    decoder: JSONDecoder? = nil,
    encoder: JSONEncoder? = nil,
    logger: Logger? = nil
  ) {
    self.init(
      decoder: decoder ?? database.configuration.decoder,
      encoder: encoder ?? database.configuration.encoder,
      execute: { route in
        try await route
          .build({ database.from($0.name) })
          .execute()
          .data
      },
      logger: logger
    )
  }
  
  /// Create a new database router.
  ///
  /// - Parameters:
  ///   - decoder: A custom decoder used to decode database response, will use the one registered with the database if not supplied.
  ///   - encoder: A custom encoder used to encode override data, will use the one registered with the database if not supplied.
  ///   - logger: An optional logger to used to log any errors when performing database calls.
  ///   - execute: The function used to return a response for the given route.
  public init(
    decoder: JSONDecoder,
    encoder: JSONEncoder,
    logger: Logger? = nil,
    execute: @escaping @Sendable (DatabaseRoute) async throws -> DatabaseResult
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
    execute: @escaping @Sendable (DatabaseRoute) async throws -> Data,
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
  public func callAsFunction<A: Decodable>(
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
  public func callAsFunction(
    _ route: Route
  ) async throws {
    try await logIfError("Run Route:") {
      try await data(for: route)
    }
  }
  
  /// Removes all overrides currently set on the router.
  public mutating func resetOverrides() {
    overrides = []
  }

  // Checks if there's an override for the given route, returning the
  // override data otherwise executes the route returning the data from
  // the database.
  @discardableResult
  private func data(for route: Route) async throws -> Data {
    guard let match = try await overrides.firstMatch(of: route) else {
      logger?.debug("No match found for route.")
      return try await logIfError("Execute Route:") {
        try await execute(route.route())
      }
    }
    return try await logIfError("Decode Override Data:") {
      logger?.debug("Match found for route.")
      return try match.data(encoder)
    }
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
    public func callAsFunction(_ route: Value) async throws {
      try await router(casePath.embed(route))
    }
    /// Call the database route, respecting any overrides and return the decoded result.
    ///
    /// - Parameters:
    ///   - route: The route to call on the database.
    @discardableResult
    public func callAsFunction<A: Decodable>(_ route: Value) async throws -> A {
      try await router(casePath.embed(route))
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
      decoder: JSONDecoder(),
      encoder: JSONEncoder(),
      execute: XCTestDynamicOverlay.unimplemented("\(Self.self).execute", placeholder: Data())
    )
  }
}

extension DatabaseResult {
  
  /// Create a success result with a void value.
  public static func success() -> Self {
    .success(EmptyEncodable())
  }
 
  /// Create a success result with a void value if the result closure succeeds.
  ///
  /// - Parameters:
  ///   - result: The result closure used to evaluate if successful or not.
  public init(catching result: () async throws -> Void) async {
    do {
      try await result()
      self = .success()
    } catch {
      self = .failure(error)
    }
  }
}

extension DatabaseResult {
  fileprivate func data(_ encoder: JSONEncoder) throws -> Data {
    return try encoder.encode(self.get())
  }
}

extension Array {
  
  func firstMatch<Route>(
    of route: Route
  ) async throws -> DatabaseResult? where Element == DatabaseRouter<Route>.Override {
    for override in self {
      if try await override.match(route) {
        return try await override.result(route)
      }
    }
    return nil
  }
  
  mutating func insert<Route>(
    _ override: DatabaseRouter<Route>.Override
  ) where Element == DatabaseRouter<Route>.Override {
    self.insert(override, at: 0)
  }
}

fileprivate struct EmptyEncodable: Codable { }
