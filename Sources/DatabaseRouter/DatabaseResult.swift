import Foundation

/// A result like type for database results, these are used when providing overrides for a database route(r).
public struct DatabaseResult: @unchecked Sendable {
  let data: (JSONEncoder) async throws -> Data

  public static func success() -> Self {
    self.init(data: { _ in Data() })
  }

  public static func success<A: Encodable>(_ value: @autoclosure @escaping () -> A) -> Self {
    .ok(value)
  }

  public static func success(_ run: @escaping () async throws -> Void) -> Self {
    self.init(data: { _ in
      try await run()
      return Data()
    })
  }

  public static func ok<A: Encodable>(_ run: @escaping () async throws -> A) -> Self {
    self.init(data: { encoder in
      try await encoder.encode(run())
    })
  }

  public static func failure(_ error: Error) -> Self {
    self.init(data: { _ in throw error })
  }
}


