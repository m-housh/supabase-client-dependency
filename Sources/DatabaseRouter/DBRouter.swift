import DatabaseExtensions
import Dependencies
import Foundation
import PostgREST

public struct DBRouter<Route: RouteController>: @unchecked Sendable {

  #if DEBUG
  private var _overrides = LockIsolated<_OverridesContainer>(.init())
  private var overrides: _OverridesContainer {
    get { _overrides.value }
    set {
      _overrides.withValue { value in
        value = newValue
      }
    }
  }
  #endif

  let decoder: JSONDecoder
  let encoder: JSONEncoder
  let execute: (Route) async throws -> Data

  init(
    decoder: JSONDecoder,
    encoder: JSONEncoder,
    execute: @escaping (Route) async throws -> Data
  ) {
    self.decoder = decoder
    self.encoder = encoder
    self.execute = execute
  }

  public init(
    decoder: JSONDecoder,
    encoder: JSONEncoder,
    execute: @escaping (Route) async throws -> Response
  ) {
    self.decoder = decoder
    self.encoder = encoder
    self.execute = { try await execute($0).run(encoder) }
  }

  public struct Response: @unchecked Sendable {
    let run: (JSONEncoder) async throws -> Data

    public static func void(_ run: @escaping () async throws -> Void) -> Self {
      .init { _ in
        try await run()
        return Data()
      }
    }

    public static func data(
      _ run: @escaping () async throws -> (any Encodable)
    ) -> Self {
      .init { encoder in
        let encodable = try await run()
        return try encoder.encode(encodable)
      }
    }
  }

  @discardableResult
  public func run<A: Decodable>(
    _ route: Route
  ) async throws -> A {
    if let match = try await overrides.firstMatch(of: route.route(), decoder: decoder) {
      guard let value = match as? A else {
        throw UnmatchedOverrideError()
      }
      return value
    }
    let data = try await execute(route)
    return try decoder.decode(A.self, from: data)
  }

  public func run(
    _ route: Route
  ) async throws {
    if try await overrides.firstMatch(of: route.route(), decoder: decoder) != nil {
      return
    }
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
}

extension DBRouter: TestDependencyKey {
  public static func live(database: PostgrestClient) -> Self {
    .init(
      decoder: database.configuration.decoder,
      encoder: database.configuration.encoder,
      execute: { route in
        try await route.route()
          .build({ database.from($0.tableName) })
          .execute()
          .data
      }
    )
  }

  public static var testValue: DBRouter<Route> {
    .init(
      decoder: XCTestDynamicOverlay.unimplemented("\(Self.self).decoder", placeholder: JSONDecoder()),
      encoder: XCTestDynamicOverlay.unimplemented("\(Self.self).encoder", placeholder: JSONEncoder()),
      execute: XCTestDynamicOverlay.unimplemented("\(Self.self).execute", placeholder: Data())
    )
  }
}

#if DEBUG
extension DBRouter {
  // MARK: - Overrides
  private mutating func insertOverride<V>(
    route: _AnyOverride,
    value: @escaping () async throws -> V
  ) {
    overrides.insert(route, value: value)
  }
  private mutating func insertOverride<V>(
    route: _AnyOverride,
    value: @autoclosure @escaping () -> V
  ) {
    overrides.insert(route, value: value)
  }
  /// Override the given route with the value.
  ///
  /// - Parameters:
  ///   - route: The route to override.
  ///   - value: The value to return when the route is called.
  public mutating func override<A>(
    route: Route,
    with value: A
  ) {
    insertOverride(route: .route(route.route), value: value)
  }
  /// Override the given route with the value.
  ///
  /// - Parameters:
  ///   - route: The route to override.
  ///   - value: The value to return when the route is called.
  public mutating func override<A>(
    route: Route,
    with value: @escaping () async throws -> A
  ) {
    insertOverride(route: .route(route.route), value: value)
  }
  /// Override the given route with a void value.
  ///
  /// - Parameters:
  ///   - route: The route to override.
  public mutating func override(
    route: Route
  ) {
    insertOverride(route: .route(route.route), value: ())
  }
  /// Override the given route method with the value.
  ///
  /// - Parameters:
  ///   - method: The route method to override.
  ///   - value: The value to return when the route is called.
  public mutating func override<A>(
    _ method: DatabaseRoute.Method,
    with value: A
  ) {
    insertOverride(route: .method(method), value: value)
  }
  /// Override the given route method with the value.
  ///
  /// - Parameters:
  ///   - method: The route method to override.
  ///   - value: The value to return when the route is called.
  public mutating func override<A>(
    _ method: DatabaseRoute.Method,
    with value: @escaping () async throws -> A
  ) {
    insertOverride(route: .method(method), value: value)
  }
  /// Override the given route with a void value.
  ///
  /// - Parameters:
  ///   - method: The route method to override.
  public mutating func override(
    _ method: DatabaseRoute.Method
  ) {
    insertOverride(route: .method(method), value: ())
  }
  /// Override the given route method with the value.
  ///
  /// - Parameters:
  ///   - id: The route identifier to override.
  ///   - value: The value to return when the route is called.
  public mutating func override<A>(
    id: String,
    with value: A
  ) {
    insertOverride(route: .id(id), value: value)
  }
  /// Override the given route method with the value.
  ///
  /// - Parameters:
  ///   - id: The route identifier to override.
  ///   - value: The value to return when the route is called.
  public mutating func override<A>(
    id: String,
    with value: @escaping () async throws -> A
  ) {
    insertOverride(route: .id(id), value: value)
  }
  /// Override the given route with a void value.
  ///
  /// - Parameters:
  ///   - id: The route identifier to override.
  public mutating func override(
    id: String
  ) {
    insertOverride(route: .id(id), value: ())
  }
}

// TODO: Try fetch to hold onto `DBRouter.Response`??
fileprivate struct _OverridesContainer {
  typealias FetchValue = (DatabaseRoute, JSONDecoder) async throws -> Any

  var overrides: [(route: _AnyOverride, value: FetchValue)] = []

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

  mutating func insert<V>(
    _ override: _AnyOverride,
    value: @escaping () async throws -> V
  ) {
    overrides.insert(
      (route: override, value: { _, _ in try await value() as Any } ),
      at: 0
    )
  }

  mutating func insert<V>(
    _ override: _AnyOverride,
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
fileprivate enum _AnyOverride {

  // Match a full route.
  case route(() async throws -> DatabaseRoute)

  // Match a partial route.
  case method(DatabaseRoute.Method)

  // Match a route by id and table.
  case id(String)

  func matches(_ route: DatabaseRoute) async throws -> Bool {
    switch self {
    case let .route(build):
      return try await build() == route
    case let .method(method):
      return method == route.method
    case let .id(id):
      return route.id == id
    }
  }
}
#endif
