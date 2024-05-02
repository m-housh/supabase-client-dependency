import AuthController
import Dependencies
import XCTest

final class AuthControllerTests: XCTestCase {

  func testMockAuth() async throws {
    let user = User.mock
    let date = Date(timeIntervalSince1970: 1234567890)
    let auth = AuthController.mock(
      user: user,
      uuid: { UUID(0) },
      date: { date }
    )

    let currentUser = await auth.currentUser
    XCTAssertNotNil(currentUser)
    XCTAssertEqual(currentUser, user)

    let requiredUser = try await auth.requireCurrentUser()
    XCTAssertEqual(requiredUser, user)

    var session = await auth.login()
    XCTAssertNotNil(session)
    XCTAssertEqual(session?.user, user)

    session = try await auth.login(.email("foo@bar.com", password: "super-secret-password"))
    XCTAssertNotNil(session)
    XCTAssertEqual(session?.user, user)

    let newUser = try await auth.signUp(with: .email("foo@bar.com", password: "12345", options: .init()))

    XCTAssertEqual(
      newUser,
      .init(
        id: UUID(0),
        appMetadata: [:],
        userMetadata: [:],
        aud: "mock-auth",
        confirmationSentAt: nil,
        recoverySentAt: nil,
        emailChangeSentAt: nil,
        newEmail: nil,
        invitedAt: nil,
        actionLink: nil,
        email: "foo@bar.com",
        phone: nil,
        createdAt: date,
        confirmedAt: date,
        emailConfirmedAt: date,
        phoneConfirmedAt: nil,
        lastSignInAt: nil,
        role: nil,
        updatedAt: date,
        identities: nil,
        factors: nil
      )
    )

    let checkCurrentUser = try await auth.requireCurrentUser()
    XCTAssertEqual(newUser, checkCurrentUser)
  }

  func testOnlyAllowedCredentials() async throws {
    let credentials = Credentials(email: "test@example.com", password: "test-password")
    let auth = AuthController.mock(allowedCredentials: .only(.credentials(credentials)))

    let user = try await auth.signUp(with: .credentials(credentials))
    let session = try await auth.login(credentials: credentials)
    XCTAssertEqual(session.user, user)

    do {
      _ = try await auth.signUp(with: .email("bad@example.com", password: "bad-password"))
      XCTFail()
    } catch {
      XCTAssert(true)
    }

    do {
      _ = try await auth.login(credentials: .init(email: "bad@example.com", password: "bad-password"))
      XCTFail()
    } catch {
      XCTAssert(true)
    }
  }

  func testCredentialValidation() throws {
    let validCredentials = Credentials(
      email: "test@example.com",
      password: "Test-pa$$word1"
    )
    try validCredentials.validate()

    var invalidCredentials = validCredentials
    invalidCredentials.email = "invalid.email"
    do {
      try invalidCredentials.validate()
    } catch CredentialError.invalidEmail {
      XCTAssert(true)
    } catch {
      XCTFail("Unexpected error: \(error)")
    }

    invalidCredentials.email = validCredentials.email
    invalidCredentials.password = "invalid-bc-does-not-contain-proper-characters"
    do {
      try invalidCredentials.validate()
    } catch CredentialError.invalidPassword {
      XCTAssert(true)
    } catch {
      XCTFail("Unexpected error: \(error)")
    }

    invalidCredentials.email = "invalid.email"
    do {
      try invalidCredentials.validate()
    } catch {
      guard let credentialError = error as? CredentialError else {
        XCTFail("Unexpected error: \(error)")
        throw error
      }
      XCTAssertEqual(credentialError, .invalidEmailAndPassword())
    }
  }
}
