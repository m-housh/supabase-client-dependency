import Dependencies
import XCTest
@testable import SupabaseClient

@MainActor
final class SupabaseClientTests: XCTestCase {

  func testSanity() {
    XCTAssert(true)
  }

  func testCreateUser() async throws {
    await withDependencies {
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

      // Testing session does not work because the `keychain` is not setup properly
      // in a swift package.

//      let session = try await client.auth.login(credentials: credentials)
//
//      currentUser = await client.auth.currentUser()
//      XCTAssertNotNil(currentUser)
//
//      await client.auth.logout()

    }
  }

  func testCredentialValidation() {
    var credentials = Credentials.empty

    XCTAssertFalse(credentials.isValid)

    credentials.email = "test@example.com"
    credentials.password = "$tr0ngPa$$w0rd"

    XCTAssert(credentials.isValid)
  }
}
