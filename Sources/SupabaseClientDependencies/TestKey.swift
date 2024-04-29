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

}

