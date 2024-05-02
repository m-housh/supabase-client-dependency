import Foundation

/// Represents credentials used to create or login a user to the supabase client.
///
///
public struct Credentials: Codable, Equatable, Sendable {

  /// The user's email address.
  public var email: String

  /// The user's password.
  public var password: String

  /// Whether the credentials are valid or not, using the default validation logic.
  ///
  /// - SeeAlso: ``validate(_:validateEmail:validatePassword:)``
  public var isValid: Bool {
    guard let isValid = try? self.validate()
    else { return false }
    return isValid
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
  /// ### Default Logic
  /// The email, must be one or more characters followed by an '@' symbol, then one or more characters
  /// followed by a '.' and finishing with one or more characters.
  ///
  /// The password must be at least 8 characters, at least one capital letter, at least one lowercase letter,
  /// and at least one special character '!$%&?._-'
  ///
  ///  - Parameters:
  ///   - credentials: The credentials to validate.
  ///   - validateEmail: Override the default email validation logic.
  ///   - validatePassword: Override the default password validation logic.
  @discardableResult
  public static func validate(
    _ credentials: Self,
    validateEmail: ((String) throws -> Void)? = nil,
    validatePassword: ((String) throws -> Void)? = nil
  ) throws -> Bool {

    var emailError: CredentialError? = nil
    if let validateEmail {
      emailError = credentials.email.validate(.email, using: validateEmail)
    } else {
      emailError = credentials.email.validate(pattern: .email)
    }

    var passwordError: CredentialError? = nil
    if let validatePassword {
      passwordError = credentials.password.validate(.password, using: validatePassword)
    } else {
      passwordError = credentials.password.validate(pattern: .password)
    }

    switch (emailError, passwordError) {
    // Email and password are valid
    case (.none, .none):
      return true
    // Invalid email.
    case let (.some(emailError), .none):
      throw emailError
    // Invalid password.
    case let (.none, .some(passwordError)):
      throw passwordError
    // Invalid email and password.
    case let (.some(emailError), .some(passwordError)):
      throw CredentialError.invalidEmailAndPassword(
        emailError: emailError.localizedDescription,
        passwordError: passwordError.localizedDescription
      )
    }
  }

  @discardableResult
  public func validate(
    validateEmail: ((String) throws -> Void)? = nil,
    validatePassword: ((String) throws -> Void)? = nil
  ) throws -> Bool {
    try Self.validate(
      self,
      validateEmail: validateEmail,
      validatePassword: validatePassword
    )
  }

}

fileprivate enum CredentialValidationType {
  case email
  case password

  var pattern: String {
    switch self {
    case .email:
      return emailPattern
    case .password:
      return passwordPattern
    }
  }

  var error: CredentialError {
    switch self {
    case .email:
      return .invalidEmail
    case .password:
      return .invalidPassword
    }
  }

  func customError(_ error: Error) -> CredentialError {
    switch self {
    case .email:
      return .customInvalidEmail(error.localizedDescription)
    case .password:
      return .customInvalidPassword(error.localizedDescription)
    }
  }
}

fileprivate extension String {

  func validate(pattern: CredentialValidationType) -> CredentialError? {
    if self.range(
      of: pattern.pattern,
      options: .regularExpression
    ) == nil {
      return pattern.error
    }
    return nil
  }

  func validate(
    _ type: CredentialValidationType,
    using validate: @escaping (String) throws -> Void
  ) -> CredentialError? {
    do {
      try validate(self)
    } catch {
      return type.customError(error)
    }
    return nil
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
fileprivate let emailPattern = #"^\S+@\S+\.\S+$"#

fileprivate let passwordPattern =
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
