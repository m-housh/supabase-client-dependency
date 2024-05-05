import Foundation

#if DEBUG
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
  case only([LoginRequest])

  /// Allow's only the supplied credentials to authenticate.
  ///
  /// ### Example
  /// ```swift
  /// .only(.credentials(email: "blob@example.com", password: "secret-password!")
  /// ```
  ///
  public static func only(_ values: LoginRequest...) -> Self {
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
    case login(LoginRequest?)
    case signUp(SignUpRequest)
  }
}

extension SignUpRequest {

  fileprivate var loginRequest: LoginRequest {
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
#endif
