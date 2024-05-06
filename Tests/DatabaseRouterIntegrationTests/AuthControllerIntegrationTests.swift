import Dependencies
import SupabaseDependencies
import XCTest

final class AuthControllerIntegrationTests: XCTestCase {
 
  override func setUp() async throws {
    try await super.setUp()

    try XCTSkipUnless(
      ProcessInfo.processInfo.environment["INTEGRATION_TESTS"] != nil,
      "INTEGRATION_TESTS not defined."
    )
  }

  // This needs moved to integration tests.
  func testCreateUser() async throws {
    let supabaseClient = SupabaseClient(
      supabaseURL: URL(string: Secrets.SUPABASE_URL)!,
      supabaseKey: Secrets.SUPABASE_SERVICE_ROLE_KEY,
      options: .init(auth: .init(storage: LocalAuthStorage()))
    )
    try await withDependencies  {
      $0.supabase = .live(client: supabaseClient)
    } operation: {
      @Dependency(\.supabase) var client;
      
      let credentials = Credentials(
        email: "test@example.com",
        password: "secret-password"
      )
      
      let user = try await client.auth.signUp(with: .credentials(credentials))
      XCTAssertEqual(user.email, credentials.email)
      
      let _ = try await client.auth.login(credentials: credentials)
      
      let currentUser = await client.auth.currentUser
      XCTAssertNotNil(currentUser)
      XCTAssertEqual(currentUser!.email, credentials.email)
      
      try await resetAuth(client.auth)
    }
  }
}

fileprivate func resetAuth(_ auth: AuthController) async throws {
  if let user = await auth.currentUser {
    try await auth.client.signOut()
    try await auth.admin.deleteUser(id: user.id.uuidString)
  }
}
