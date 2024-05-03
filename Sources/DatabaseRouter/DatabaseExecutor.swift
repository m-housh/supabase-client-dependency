import DatabaseExtensions
import Dependencies
import Foundation
import PostgREST

extension DependencyValues {

  /// Access the database executor that can execute queries on the database.
  public var databaseExecutor: DatabaseExecutor {
    get { self[DatabaseExecutor.self] }
    set { self[DatabaseExecutor.self] = newValue }
  }
}

/// Execute queries on the database and decode the results.
///
/// This is provided to allow an override hook into all queries ran by a ``DatabaseRouter`` or a ``RouteController``
/// by overriding the ``DatabaseExecutor/execute`` variable, however it is more common to override individual routes using
/// one of the `override` methods on your ``DatabaseRouter``.
///
/// This type  needs to be extended to provide the live implementation in your application,
/// by  passing in a `PostgrestClient` and using the ``live(database:)`` helper.
///
public struct DatabaseExecutor {
  #if DEBUG
  private static var _Overrides = LockIsolated<OverridesContainer>(.init())

  // NB: Holds overrides as a global, so they act correctly / can be overridden when accessing
  // a sub-route controller on a database router.
  internal static var currentOverrides: OverridesContainer {
    get {
      return _Overrides.value
    }
    set {
      _Overrides.withValue { value in
        value = newValue
      }
    }
  }
  #endif

  /// The json decoder used to decode responses.
  public var decoder: JSONDecoder = .init()
  
  /// Execute commands on the database and return the data.
  public var execute: (PostgrestBuilder) async throws -> Data
  
  /// Create a query builder for the given table.
  public var query: (AnyTable) throws -> PostgrestQueryBuilder

  /// Run the route on the database.
  public func run(_ route: DatabaseRoute) async throws {
    if await Self.currentOverrides.firstMatch(of: route, decoder: decoder) != nil {
      return
    }
    _ = try await self.execute(
      route.build(self.query)
    )
  }

  /// Run the route on the database and decode the output.
  @discardableResult
  public func run<A: Decodable>(
    _ route: DatabaseRoute
  ) async throws -> A {
    if let match = await Self.currentOverrides.firstMatch(of: route, decoder: decoder) {
      guard let value = match as? A else {
        throw UnmatchedOverrideError()
      }
      return value
    }
    let data = try await self.execute(
      route.build(self.query)
    )
    return try decoder.decode(A.self, from: data)
  }

  /// Run the route on the database, ignoring any output.
  public func run<R: RouteCollection>(_ router: R) async throws {
    try await self.run(router.route())
  }

  /// Run the route on the database, decoding the output.
  @discardableResult
  public func run<A: Decodable, R: RouteCollection>(
    _ router: R
  ) async throws -> A {
    try await self.run(router.route())
  }

}

extension DatabaseExecutor: TestDependencyKey {
  public static let testValue = Self.init(
    execute: XCTestDynamicOverlay.unimplemented("\(Self.self).execute", placeholder: Data()),
    query: XCTestDynamicOverlay.unimplemented("\(Self.self).query")
  )
}

extension DatabaseExecutor {

  /// A helper to create the live dependency from the given `PostgrestClient`.
  ///
  /// - Parameters:
  ///   - database: The postgrest client used to execute and build queries.
  public static func live(database: PostgrestClient) -> Self {
    // Just a precaution... Reset any overrides, since they're global.
    DatabaseExecutor.currentOverrides.reset()
    return .init(
      decoder: database.configuration.decoder,
      execute: { try await $0.execute().data },
      query: { database.from($0.tableName) }
    )
  }
}

#if DEBUG
struct OverridesContainer {
  typealias FetchValue = (DatabaseRoute, JSONDecoder) async throws -> Any

  var overrides: [(route: AnyOverride, value: FetchValue)] = []

  func firstMatch(of route: DatabaseRoute, decoder: JSONDecoder) async -> Any? {
    for override in overrides {
      if let match = try? await override.route.matches(route), 
          match == true
      {
        return try? await override.value(route, decoder)
      }
    }
    return nil
  }

  mutating func insert<V>(_ override: AnyOverride, value: @escaping () async throws -> V) {
    overrides.insert((route: override, value: { _, _ in try await value() as Any } ), at: 0)
  }

  mutating func insert<V>(
    _ override: AnyOverride,
    value: @escaping (DatabaseRoute, JSONDecoder) async throws -> V
  ) {
    overrides.insert(
      (
        route: override,
        value: { route, decoder in
          try await value(route, decoder) as Any
        }
      ),
      at: 0
    )
  }

  mutating func reset() {
    self.overrides = []
  }
}

// Used internally to match route overrides.
enum AnyOverride {

  // Match a full route.
  case route(() async throws -> DatabaseRoute)

  // Match a partial route.
  case partial(table: AnyTable, method: DatabaseRoute.Method)

  // Match a route by id and table.
  case id(String, table: AnyTable)

  func matches(_ route: DatabaseRoute) async throws -> Bool {
    switch self {
    case let .route(build):
      return try await build() == route
    case let .partial(table: table, method: method):
      return table == route.table && method == route.method
    case let .id(id, table: table):
      return route.table == table && route.id == id
    }
  }
}
#endif
