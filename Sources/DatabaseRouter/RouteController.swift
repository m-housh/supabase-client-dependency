import DatabaseExtensions
import Dependencies
import Foundation
import PostgREST

public struct RouteController<Route: RouteCollection>: @unchecked Sendable {

  private let decoder: JSONDecoder
  private let encoder: JSONEncoder
  private let execute: (Route) async throws -> Data

  public init(database: PostgrestClient) {
    self.decoder = database.configuration.decoder
    self.encoder = database.configuration.encoder
    self.execute = { route in
      try await route.route()
        .build({ database.from($0.tableName) })
        .execute()
        .data
    }
  }

  public init(
    decoder: JSONDecoder,
    encoder: JSONEncoder,
    execute: @escaping (Route) async throws -> DatabaseResult
  ) {
    self.decoder = decoder
    self.encoder = encoder
    self.execute = { try await execute($0).data(encoder) }
  }

  internal init(
    decoder: JSONDecoder,
    encoder: JSONEncoder,
    execute: @escaping (Route) async throws -> Data
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
    if try await overrides.firstMatch(of: route.route()) != nil {
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

  private func data(for route: Route) async throws -> Data {
    guard let match = try await overrides.firstMatch(of: route.route()) else {
      return try await execute(route)
    }
    return try await match.data(encoder)
  }

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
}

extension RouteController: TestDependencyKey {

  public static var testValue: RouteController<Route> {
    .init(
      decoder: XCTestDynamicOverlay.unimplemented("\(Self.self).decoder", placeholder: JSONDecoder()),
      encoder: XCTestDynamicOverlay.unimplemented("\(Self.self).encoder", placeholder: JSONEncoder()),
      execute: XCTestDynamicOverlay.unimplemented("\(Self.self).execute", placeholder: Data())
    )
  }
}


#if DEBUG
extension RouteController {
  // MARK: - Overrides
  private mutating func insertOverride(
    route: _AnyOverride
  ) {
    overrides.insert(route, value: { _ in .success() })
  }
  private mutating func insertOverride(
    route: _AnyOverride,
    value: DatabaseResult
  ) {
    overrides.insert(route, value: { _ in value })
  }
  /// Override the given route with the value.
  ///
  /// - Parameters:
  ///   - route: The route to override.
  ///   - value: The value to return when the route is called.
  public mutating func override(
    route: Route,
    with response: DatabaseResult
  ) {
    insertOverride(route: .route(route.route), value: response)
  }
  /// Override the given route with a void value.
  ///
  /// - Parameters:
  ///   - route: The route to override.
  public mutating func override(
    route: Route
  ) {
    insertOverride(route: .route(route.route))
  }
  /// Override the given route method with the value.
  ///
  /// - Parameters:
  ///   - method: The route method to override.
  ///   - value: The value to return when the route is called.
  public mutating func override(
    _ method: DatabaseRoute.Method,
    with response: DatabaseResult
  ) {
    insertOverride(route: .method(method), value: response)
  }
  /// Override the given route with a void value.
  ///
  /// - Parameters:
  ///   - method: The route method to override.
  public mutating func override(
    _ method: DatabaseRoute.Method
  ) {
    insertOverride(route: .method(method))
  }
  /// Override the given route method with the value.
  ///
  /// - Parameters:
  ///   - id: The route identifier to override.
  ///   - response: The response when the route is called.
  public mutating func override(
    id: String,
    with response: DatabaseResult
  ) {
    insertOverride(route: .id(id), value: response)
  }
  /// Override the given route with a void value.
  ///
  /// - Parameters:
  ///   - id: The route identifier to override.
  public mutating func override(id: String) {
    insertOverride(route: .id(id))
  }
}

fileprivate struct _OverridesContainer {
  typealias FetchValue = (DatabaseRoute) async throws -> DatabaseResult

  private var overrides: [(route: _AnyOverride, value: FetchValue)] = []

  func firstMatch(of route: DatabaseRoute) async -> DatabaseResult? {
    for override in overrides {
      if let match = try? await override.route.matches(route),
          match == true
      {
        return try? await override.value(route)
      }
    }
    return nil
  }

  mutating func insert(
    _ override: _AnyOverride,
    value: @escaping FetchValue
  ) {
    overrides.insert(
      (route: override, value: value),
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
