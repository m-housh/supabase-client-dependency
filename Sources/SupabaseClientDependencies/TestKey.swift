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

extension SupabaseClientDependency.DatabaseClient {
  static let unimplemented = Self.init(
    decoder: JSONDecoder(),
    delete: XCTestDynamicOverlay.unimplemented("\(Self.self).delete"),
    encoder: JSONEncoder(),
    fetch: XCTestDynamicOverlay.unimplemented("\(Self.self).fetch", placeholder: Data()),
    fetchOne: XCTestDynamicOverlay.unimplemented("\(Self.self).fetchOne", placeholder: Data()),
    from: XCTestDynamicOverlay.unimplemented("\(Self.self).from"),
    insert: XCTestDynamicOverlay.unimplemented("\(Self.self).insert", placeholder: Data()),
    insertMany: XCTestDynamicOverlay.unimplemented("\(Self.self).insertMany", placeholder: Data()),
    rpc: XCTestDynamicOverlay.unimplemented("\(Self.self).rpc"),
    update: XCTestDynamicOverlay.unimplemented("\(Self.self).update", placeholder: Data())
  )
}

extension SupabaseClientDependency: TestDependencyKey {

  /// The unimplemented supabase client dependency for usage in tests.
  public static var testValue: Self {
    Self.init(
      auth: .unimplemented,
      client: .init(configuration: .local)
//      database: .unimplemented
    )
  }
}
