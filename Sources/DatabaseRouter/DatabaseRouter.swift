import CasePaths
import ConcurrencyExtras
import Dependencies
import Foundation
import PostgREST
import Foundation

public typealias DatabaseResult = Result<(any Encodable), (any Error)>

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
  
  public init(database: PostgrestClient) {
    self.init(
      decoder: database.configuration.decoder,
      encoder: database.configuration.encoder,
      execute: { route in
       try await route.route()
        .build({ database.from($0.name) })
        .execute()
        .data
      }
    )
  }

  public init(
    decoder: JSONDecoder,
    encoder: JSONEncoder,
    execute: @escaping @Sendable (Route) async throws -> DatabaseResult
  ) {
    self.init(
      decoder: decoder,
      encoder: encoder,
      execute: { try await execute($0).data(encoder) }
    )
  }

  internal init(
    decoder: JSONDecoder,
    encoder: JSONEncoder,
    execute: @escaping @Sendable (Route) async throws -> Data
  ) {
    self.decoder = decoder
    self.encoder = encoder
    self.execute = execute
  }

  @discardableResult
  public func run<A: Decodable>(
    _ route: Route
  ) async throws -> A {
    return try await decoder.decode(A.self, from: data(for: route))
  }

  public func run(
    _ route: Route
  ) async throws {
    guard await override(for: route) == nil else { return }
    _ = try await execute(route)
  }

  @discardableResult
  public func callAsFunction<A: Decodable>(
    _ route: Route
  ) async throws -> A {
    try await self.run(route)
  }

  public func callAsFunction(
    _ route: Route
  ) async throws {
    try await self.run(route)
  }

  private func data(for route: Route) async throws -> Data {
    guard let match = await override(for: route) else {
      return try await execute(route)
    }
    return try match.data(encoder)
  }
  
  private func override(for route: Route) async -> DatabaseResult? {
    await overrides.firstMatch(of: route)
  }

}

extension DatabaseRouter: CasePathable where Route: CasePathable {
  public typealias AllCasePaths = Route.AllCasePaths
  public static var allCasePaths: Route.AllCasePaths { Route.allCasePaths }
}

// MARK: - Overrides

#if DEBUG
extension DatabaseRouter {
  /// Override the given route with the value.
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
  /// - Parameters:
  ///   - override: The override used to match a route.
  ///   - value: The value to return when the route is called.
  public mutating func override<A: Encodable>(
    _ override: Override,
    with value: A
  ) {
    overrides.insert(override, result: { _ in .success(value) })
  }
  /// Override the given route with a void value
  ///
  /// - Parameters:
  ///   - override: The override used to match a route.
  public mutating func override(
    _ override: Override
  ) {
    overrides.insert(override, result: { _ in .success() })
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
    ) -> Self {
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

