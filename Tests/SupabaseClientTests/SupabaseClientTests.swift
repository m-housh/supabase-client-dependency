import Dependencies
import XCTest
@testable import SupabaseClientDependency

@MainActor
final class SupabaseClientTests: XCTestCase {

  func testSanity() {
    XCTAssert(true)
  }

  func testCreateUser() async throws {
    try await withDependencies {
      $0.supabaseClient = .live()
    } operation: {
      @Dependency(\.supabaseClient) var client;

      var currentUser = await client.auth.currentUser()
      XCTAssertNil(currentUser)

      let credentials = Credentials(
        email: "test@example.com",
        password: "secret-password"
      )

      let user = try? await client.auth.createUser(credentials)

//      let session = try await client.auth.login(credentials: credentials)
//
//      currentUser = await client.auth.currentUser()
//      XCTAssertNotNil(currentUser)
//
//      await client.auth.logout()

    }
  }
}
