import Auth
import ConcurrencyExtras
import Foundation

#if DEBUG
extension AuthController {
  /// Create a mock ``AuthController`` with override hooks based on the passed in values.
  ///
  /// Uses the ``AllowedCredentials`` type to determine successful calls to the `login` and `signUp` methods.
  ///
  /// > Note: Any calls to the underlying `AuthClient` will fail because this generates a client with an invalid url.
  ///
  ///
  /// - Parameters:
  ///   - allowedCredentials: The credentials that are allowed to login or sign-up.
  ///   - user: The inital user, this does get replaced if login or sign-up methods are called.
  ///   - session: An optional initial session, this does get replaced if login or sign-up methods are called.
  ///   - uuid: The uuid generator for creating mock users.
  ///   - date: The date generator for creating mock users.
  public static func mock(
    allowedCredentials: AllowedCredentials = .any,
    user: User = .mock,
    session: Session? = nil,
    uuid: @escaping () -> UUID = UUID.init,
    date: @escaping () -> Date = Date.init
  ) -> Self {
    

    final class Storage {
      var currentUser: User
      var currentSession: Session? = nil
      
      init(currentUser: User, currentSession: Session? = nil) {
        self.currentUser = currentUser
        self.currentSession = currentSession
      }
    }
    
    let storage = LockIsolated<Storage>(.init(currentUser: user))
    
    return self.init(
      client: .init(configuration: .init(
        url: URL(string: "/")!,
        localStorage: LocalAuthStorage(),
        logger: nil
      )),
      currentUser: { storage.value.currentUser },
      loginHandler: { loginRequest in
        guard allowedCredentials.isAllowedToAuthenticate(.login(loginRequest)) else {
          throw AuthenticationError.notAuthenticated
        }
        if storage.currentSession == nil {
          storage.withValue {
            $0.currentSession = .mock(user: storage.currentUser)
          }
        }
        return storage.value.currentSession!
      },
      signupHandler: { signUp in
        guard allowedCredentials.isAllowedToAuthenticate(.signUp(signUp)) else {
          throw AuthenticationError.notAuthenticated
        }
        storage.withValue {
          $0.currentUser = signUp.mockUser(date: date(), uuid: uuid)
          $0.currentSession = .mock(user: storage.currentUser)
        }
        return storage.value.currentUser
      }
    )
  }
}

#if DEBUG
public struct LocalAuthStorage: AuthLocalStorage, Sendable {
  private let storage = LockIsolated([String:Data]())
  
  public init() { }
 
  public func store(key: String, value: Data) throws {
    storage.withValue { storage in
      storage[key] = value
    }
  }
  
  public func retrieve(key: String) throws -> Data? {
    storage.value[key]
  }
  
  public func remove(key: String) throws {
    _ = storage.withValue { storage in
      storage.removeValue(forKey: key)
    }
  }
}
#endif

/// Represents credentials that are allowed to be used in the mock  implementation.
///
///
public enum AllowedCredentials: Sendable {

  /// Allow's any credentials to authenticate.
  case any
  
  /// Dont' allow any credentials to authenticate.
  case none

  /// Allow's only the supplied credentials to authenticate.
  ///
  /// ### Example
  /// ```swift
  /// .only([.credentials(email: "blob@example.com", password: "secret-password!"])
  /// ```
  ///
  case only([AuthController.LoginRequest])

  /// Allow's only the supplied credentials to authenticate.
  ///
  /// ### Example
  /// ```swift
  /// .only(.credentials(email: "blob@example.com", password: "secret-password!")
  /// ```
  ///
  public static func only(_ values: AuthController.LoginRequest...) -> Self {
    .only(values)
  }

  // A helper that validates whether credentials can either be added to
  // the user storage or to authenticate a session for the mock client.
  func isAllowedToAuthenticate(_ request: Request) -> Bool {
    switch self {
    case .any:
      return true
    case .none:
      return false
    case let .only(allowedCredentials):
      switch request {
      case let .login(optionalLogin):
        guard let loginRequest = optionalLogin else { return true }
        return allowedCredentials.contains(loginRequest)
      case let .signUp(signUpRequest):
        return self.isAllowedToAuthenticate(.login(signUpRequest.loginRequest))
      }
    }
  }

  enum Request {
    case login(AuthController.LoginRequest?)
    case signUp(AuthController.SignUpRequest)
  }
}

extension AuthController.SignUpRequest {

  fileprivate var loginRequest: AuthController.LoginRequest {
    switch self {
    case let .email(email, password: password, options: _):
      return .email(email, password: password)
    case let .phone(phone, password: password, options: _):
      return .phone(phone, password: password)
    }
  }

  func mockUser(date: Date, uuid: @escaping () -> UUID) -> User {
    switch self {
    case let .email(email, password: _, options: _):
      return .init(
        id: uuid(),
        appMetadata: [:],
        userMetadata: [:],
        aud: "mock-auth",
        confirmationSentAt: nil,
        recoverySentAt: nil,
        emailChangeSentAt: nil,
        newEmail: nil,
        invitedAt: nil,
        actionLink: nil,
        email: email,
        phone: nil,
        createdAt: date,
        confirmedAt: date,
        emailConfirmedAt: date,
        phoneConfirmedAt: nil,
        lastSignInAt: nil,
        role: nil,
        updatedAt: date,
        identities: nil
      )
    case let .phone(phone, password: _, options: _):
      return .init(
        id: uuid(),
        appMetadata: [:],
        userMetadata: [:],
        aud: "mock-auth",
        confirmationSentAt: nil,
        recoverySentAt: nil,
        emailChangeSentAt: nil,
        newEmail: nil,
        invitedAt: nil,
        actionLink: nil,
        email: nil,
        phone: phone,
        createdAt: date,
        confirmedAt: date,
        emailConfirmedAt: nil,
        phoneConfirmedAt: date,
        lastSignInAt: nil,
        role: nil,
        updatedAt: date,
        identities: nil
      )
    }
  }
}

extension User {

  /// A mock user instance.
  ///
  /// This is only used as a placeholder item for unimplemented dependencies.
  public static let mock = Self.init(
    id: UUID(),
    appMetadata: [:],
    userMetadata: [:],
    aud: "",
    createdAt: Date(),
    updatedAt: Date()
  )
}

extension Session {
  /// A mock session instance.
  ///
  /// This is only used as a placeholder item for unimplemented dependencies.
  public static let mock = Self.init(
    accessToken: "",
    tokenType: "",
    expiresIn: 1,
    expiresAt: nil,
    refreshToken: "",
    user: .mock
  )

  public static func mock(user: User = .mock) -> Self {
    Self.init(
      accessToken: "",
      tokenType: "",
      expiresIn: 1,
      expiresAt: nil,
      refreshToken: "",
      user: user
    )
  }
}
#endif
