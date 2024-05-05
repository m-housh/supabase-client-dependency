import Auth
import Foundation

/// Represents request parameters for loggiing users in.
public enum LoginRequest: Equatable, Sendable {

  /// Login with an email and password.
  case email(String, password: String)

  /// Login with a phone number and a password.
  case phone(String, password: String)
  //    case idToken(OpenIDConnectCredentials)

  /// Login with a one-time-password.
  case otp(
    OTPRequest,
    shouldCreateUser: Bool? = nil,
    options: SharedOptions = .init()
  )

  /// Login with a credentials instance.
  public static func credentials(_ credentials: Credentials) -> Self {
    .email(credentials.email, password: credentials.password)
  }

  /// Represents a one-time-password login request.
  public enum OTPRequest: Equatable, Sendable {

    /// The email address for the request.
    case email(String)

    /// The phone number for the request.
    case phone(String)

    /// The underlying string value for either the email or the phone number.
    public var value: String {
      switch self {
      case let .email(email):
        return email
      case let .phone(phone):
        return phone
      }
    }
  }
}
