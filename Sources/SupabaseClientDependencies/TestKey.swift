import Dependencies
import Foundation
import XCTestDynamicOverlay

extension SupabaseClientDependency.AuthClient {
  static let unimplemented = Self.init(
    events: XCTestDynamicOverlay.unimplemented(
      "\(Self.self).events", placeholder: AsyncStream { nil }),
    getOAuthURL: XCTestDynamicOverlay.unimplemented(
      "\(Self.self).getOAuthURL", placeholder: URL(string: "/")!),
    initialize: XCTestDynamicOverlay.unimplemented("\(Self.self).initialize"),
    login: XCTestDynamicOverlay.unimplemented("\(Self.self).login", placeholder: nil),
    logout: XCTestDynamicOverlay.unimplemented("\(Self.self).logout"),
    resetPassword: XCTestDynamicOverlay.unimplemented("\(Self.self).resetPassword"),
    session: XCTestDynamicOverlay.unimplemented("\(Self.self).session", placeholder: .mock),
    signUp: XCTestDynamicOverlay.unimplemented("\(Self.self).signUp", placeholder: .mock),
    update: XCTestDynamicOverlay.unimplemented("\(Self.self).update", placeholder: .mock),
    verifyOTP: XCTestDynamicOverlay.unimplemented("\(Self.self).verifyOTP", placeholder: .mock)
  )
}

extension SupabaseClientDependency: TestDependencyKey {

  /// The unimplemented supabase client dependency for usage in tests.
  public static var testValue: Self {
    Self.init(
      auth: .unimplemented,
      client: .init(configuration: .local)
    )
  }

  mutating public func override(
    _ data: @escaping () throws -> Data
  ) {

    let currentDb = self.database()
    self.database = {
        .init(
          configuration: .init(
            url: currentDb.configuration.url,
            schema: currentDb.configuration.schema,
            headers: currentDb.configuration.headers,
            logger: nil,
            fetch: { _ in
                try await OK(data())
            },
            encoder: currentDb.configuration.encoder,
            decoder: currentDb.configuration.decoder
          )
        )
    }
  }

  struct OverrideMatch {

    var isEqual: (URLRequest) -> Bool

    init(
      isEqual: @escaping (URLRequest) -> Bool
    ) {
      self.isEqual = isEqual
    }
  }

  public enum Override {
    case all
    case delete(from: AnyTable)
    case fetch(from: AnyTable)

    var match: OverrideMatch {
      switch self {
      case .all:
        return .init { _ in true }

      case let .delete(from: table):
          return .init {
            $0.httpMethod == "DELETE" &&
            $0.url?.lastPathComponent == table.tableName
          }

      case let .fetch(from: table):
        return .init {
          $0.httpMethod == "GET" &&
          $0.url?.lastPathComponent == table.tableName
        }
      }
    }
  }

  mutating public func override<A: Encodable>(
    with value: A
  ) {

    let currentDb = self.database()
    self.database = {
      .init(
        configuration: .init(
          url: currentDb.configuration.url,
          schema: currentDb.configuration.schema,
          headers: currentDb.configuration.headers,
          logger: nil,
          fetch: { request in
            return try await OK(value, encoder: currentDb.configuration.encoder)
          },
          encoder: currentDb.configuration.encoder,
          decoder: currentDb.configuration.decoder
        )
      )
    }
  }

  mutating public func override<A: Encodable>(
    _ matching: Override,
    with value: A
  ) {

    let currentDb = self.database()
    self.database = {
      .init(
        configuration: .init(
          url: currentDb.configuration.url,
          schema: currentDb.configuration.schema,
          headers: currentDb.configuration.headers,
          logger: nil,
          fetch: { request in
            guard matching.match.isEqual(request) else {
              return try await currentDb.configuration.fetch(request)
            }
            return try await OK(value, encoder: currentDb.configuration.encoder)
          },
          encoder: currentDb.configuration.encoder,
          decoder: currentDb.configuration.decoder
        )
      )
    }
  }
}
#if DEBUG

public func OK<A: Encodable>(
  _ value: A, encoder: JSONEncoder = .init()
) async throws -> (Data, URLResponse) {
  (
    try encoder.encode(value),
    HTTPURLResponse(
      url: URL(string: "/")!, statusCode: 200, httpVersion: nil, headerFields: nil)!
  )
}

public func OK(_ jsonObject: Any) async throws -> (Data, URLResponse) {
  (
    try JSONSerialization.data(withJSONObject: jsonObject, options: []),
    HTTPURLResponse(
      url: URL(string: "/")!, statusCode: 200, httpVersion: nil, headerFields: nil)!
  )
}
#endif
