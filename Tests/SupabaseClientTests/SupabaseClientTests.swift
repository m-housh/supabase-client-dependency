import Dependencies
import XCTest
import SupabaseClientDependencies

@MainActor
final class SupabaseClientTests: XCTestCase {

  func testSanity() {
    XCTAssert(true)
  }

  func testCreateUser() async throws {
    await withDependencies {
      $0.supabaseClient = .live(configuration: .local)
    } operation: {
      @Dependency(\.supabaseClient) var client;

      let currentUser = await client.auth.currentUser()
      XCTAssertNil(currentUser)

      let credentials = Credentials(
        email: "test@example.com",
        password: "secret-password"
      )

      let user = try? await client.auth.signUp(.credentials(credentials))

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
  
  func testCredentialValidationStrings() {
    var credentials = Credentials.empty
    XCTAssertFalse(credentials.isValid)
    
    do {
      _ = try Credentials.validate(credentials)
      XCTFail("Should have failed credential validation.")
    } catch let credentialError as CredentialError {
      XCTAssertEqual(
        credentialError.localizedDescription,
        CredentialError.invalidEmailAndPassword().localizedDescription
      )
    } catch {
      XCTFail("Invalid error recieved: \(error)")
    }
    
    credentials.email = "test@example.com"
    do {
      _ = try Credentials.validate(credentials)
      XCTFail("Should have failed credential validation.")
    } catch let credentialError as CredentialError {
      XCTAssertEqual(
        credentialError.localizedDescription,
        CredentialError.invalidPassword.localizedDescription
      )
    } catch {
      XCTFail("Invalid error recieved: \(error)")
    }
    
    credentials.email = ""
    credentials.password = "$tr0ngPa$$w0rd"
    do {
      _ = try Credentials.validate(credentials)
      XCTFail("Should have failed credential validation.")
    } catch let credentialError as CredentialError {
      XCTAssertEqual(
        credentialError.localizedDescription,
        CredentialError.invalidEmail.localizedDescription
      )
    } catch {
      XCTFail("Invalid error recieved: \(error)")
    }
  }

  func testCustomCredentialValidation() throws {
    enum CustomError: Error, Equatable {
      case invalidEmail
      case invalidPassword

      var localizedDescription: String {
        switch self {
        case .invalidEmail:
          return "Invalid email"
        case .invalidPassword:
          return "Invalid password"
        }
      }
    }

    let credentials = Credentials(email: "blob@example.com", password: "super-secret-password")

    do {
      _ = try Credentials.validate(credentials, validateEmail: { _ in throw CustomError.invalidEmail } )
      XCTFail("Should have failed email validation.")
    } catch _ as CredentialError {
      XCTAssert(true)
    } catch {
      XCTFail()
    }

    do {
      _ = try Credentials.validate(credentials, validatePassword: { _ in throw CustomError.invalidPassword } )
      XCTFail("Should have failed password validation.")
    } catch _ as CredentialError {
      XCTAssert(true)
    } catch {
      XCTFail()
    }
  }
}
