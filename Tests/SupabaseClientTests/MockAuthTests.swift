//import Dependencies
//import SupabaseClientDependencies
//import XCTest
//
//final class MockAuthTests: XCTestCase {
//  
//  func makeAuthMock(
//    allowedCredentials: SupabaseClientDependency.AuthClient.AllowedCredentials = .any,
//    session: Session? = .mock
//  ) -> SupabaseClientDependency.AuthClient {
//    withDependencies {
//      $0.uuid = .incrementing
//      $0.date.now = .init(timeIntervalSince1970: 123456789)
//    } operation: {
//      .mock(allowedCredentials: allowedCredentials, session: session)
//    }
//  }
//  
//  func testSessionGetsReturnedWhenSuppliedOnCreatingMock() async throws {
//    let auth = makeAuthMock()
//    let session = try await auth.session()
//    XCTAssertNotNil(session)
//    XCTAssertEqual(session, .mock)
//  }
//  
//  func testLoginDoesNotRequireCredentialsWhenSessionIsSupplied() async throws {
//    let auth = makeAuthMock()
//    let session = try await auth.login()
//    XCTAssertEqual(session, .mock)
//  }
//  
//  func testLogoutDeletesSession() async throws {
//    let auth = makeAuthMock()
//    try await auth.logout()
//    do {
//      try await auth.login()
//      XCTFail()
//    } catch {
//      XCTAssert(true)
//    }
//  }
//  
//  func testOnlyAllowedCredentials() async throws {
//    let credentials = Credentials(email: "test@example.com", password: "test-password")
//    let auth = makeAuthMock(
//      allowedCredentials: .only([.credentials(credentials)]),
//      session: nil
//    )
//    
//    let user = try await auth.signUp(.credentials(credentials))
//    let session = try await auth.login(credentials: credentials)
//    XCTAssertNotNil(session)
//    XCTAssertEqual(session!.user, user)
//
//    do {
//      _ = try await auth.signUp(.email("bad@example.com", password: "bad-password"))
//      XCTFail()
//    } catch {
//      XCTAssert(true)
//    }
//    
//    do {
//      _ = try await auth.login(credentials: .init(email: "bad@example.com", password: "bad-password"))
//      XCTFail()
//    } catch {
//      XCTAssert(true)
//    }
//  }
//  
//  func testCurrentUser() async throws {
//    let auth = makeAuthMock()
//    let user = await auth.currentUser()
//    XCTAssertNotNil(user)
//    XCTAssertEqual(user, .mock)
//  }
//}
