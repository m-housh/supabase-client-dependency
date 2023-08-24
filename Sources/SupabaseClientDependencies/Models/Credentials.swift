import Foundation

/// Represents credentials used to create or login a user to the supabase client.
///
///
public struct Credentials: Codable, Equatable, Sendable {

  /// The user's email address.
  public var email: String

  /// The user's password.
  public var password: String

  /// Whether the credentials are valid or not.
  ///
  /// - SeeAlso: ``validate(_:emailPattern:passwordPattern:)``
  public var isValid: Bool {
    guard (try? Credentials.validate(self)) != nil
    else { return false }
    return true
  }

  /// Create a new credential.
  ///
  /// - Parameters:
  ///   - email: The user's email address.
  ///   - password: The user's plain text password.
  public init(email: String, password: String) {
    self.email = email
    self.password = password
  }

  /// An empty credentials object, which is useful for signup / signin forms.
  public static let empty = Self.init(email: "", password: "")

  /// Validates a credentials object.
  ///
  /// The email, must be one or more characters followed by an '@' symbol, then one or more characters
  /// followed by a '.' and finishing with one or more characters.
  ///
  /// The password must be at least 8 characters, at least one capital letter, at least one lowercase letter,
  /// and at least one special character '!$%&?._-'
  ///
  ///  - Parameters:
  ///   - credentials: The credentials to validate.
  ///   - emailPattern: Override the default email pattern with a custom pattern.
  ///   - passwordPattern: Override the default password pattern with a custom pattern.
  public static func validate(
    _ credentials: Self,
    emailPattern: (pattern: String, errorDescription: String)? = nil,
    passwordPattern: (pattern: String, errorDescription: String)? = nil
  ) throws -> Bool {
    var error: CredentialError? = nil
    if credentials.email.range(
      of: emailPattern?.pattern ?? SupabaseClientDependencies.emailPattern,
      options: .regularExpression
    ) == nil {
      if let customMessage = emailPattern?.errorDescription {
        error = .customInvalidEmail(customMessage)
      } else {
        error = .invalidEmail
      }
    }
    if credentials.password.range(
      of: passwordPattern?.pattern ?? SupabaseClientDependencies.passwordPattern,
      options: .regularExpression
    ) == nil {
      if error != nil {
        error = .invalidEmailAndPassword(
          emailError: error!.localizedDescription,
          passwordError: passwordPattern?.errorDescription
            ?? CredentialError.invalidPassword.localizedDescription
        )
      } else {
        if let passwordPattern {
          error = .customInvalidPassword(passwordPattern.errorDescription)
        } else {
          error = .invalidPassword
        }
      }
    }
    guard let error else { return true }
    throw error
  }

}

/// Represents errors thrown while validating a ``Credentials`` instance.
///
///
public enum CredentialError: Error, Equatable {

  /// The credentials have an invalid email address.
  case invalidEmail

  case customInvalidEmail(String)

  /// The credentials have an invalid password.
  case invalidPassword

  case customInvalidPassword(String)

  /// The credentials have an invalid email and an invalid password.
  case invalidEmailAndPassword(emailError: String, passwordError: String)

  public static func invalidEmailAndPassword() -> Self {
    .invalidEmailAndPassword(
      emailError: Self.invalidEmail.localizedDescription,
      passwordError: Self.invalidPassword.localizedDescription
    )
  }

  var invalidEmailString: String {
    """
    Invalid email: The email address should contain one or more characters followed
    by an '@' symbol, then one or more characters followed by a '.' and finish with
    one or more characters.
    """
  }

  var invalidPasswordString: String {
    """
    Invalid password: The password should be at least 8 characters long,
    should contain at least one capital letter, at least one lowercase
    letter, at least one digit, and at least one special character.
    """
  }

  public var localizedDescription: String {
    switch self {
    case .invalidEmail:
      return invalidEmailString
    case let .customInvalidEmail(emailString):
      return emailString
    case .invalidPassword:
      return invalidPasswordString
    case let .customInvalidPassword(passwordString):
      return passwordString
    case let .invalidEmailAndPassword(emailString, passwordString):
      return """
        \(emailString)

        \(passwordString)
        """
    }
  }

}

// One or more characters followed by an "@",
// then one or more characters followed by a ".",
// and finishing with one or more characters
private let emailPattern = #"^\S+@\S+\.\S+$"#

private let passwordPattern =
  // At least 8 characters
  #"(?=.{8,})"#

  // At least one capital letter
  + #"(?=.*[A-Z])"#

  // At least one lowercase letter
  + #"(?=.*[a-z])"#

  // At least one digit
  + #"(?=.*\d)"#

  // At least one special character
  + #"(?=.*[ !$%&?._-])"#
