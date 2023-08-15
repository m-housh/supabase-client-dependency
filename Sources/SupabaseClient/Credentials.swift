import Foundation

/// Represents credentials used to create or login a user to the supabase client.
public struct Credentials: Codable, Equatable, Sendable {

  /// The user's email address.
  public var email: String

  /// The user's password.
  public var password: String

  /// Whether the credentials are valid or not.
  ///
  /// - SeeAlso: ``Credentials.validate``
  public var isValid: Bool { Credentials.validate(self) }

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
  public static func validate(_ credentials: Self) -> Bool {
    guard credentials.email.range(
      of: emailPattern,
      options: .regularExpression
    ) != nil
    else { return false }
    guard credentials.password.range(
      of: passwordPattern,
      options: .regularExpression
    ) != nil
    else { return false }
    return true
  }

}

// One or more characters followed by an "@",
// then one or more characters followed by a ".",
// and finishing with one or more characters
fileprivate let emailPattern = #"^\S+@\S+\.\S+$"#

fileprivate let passwordPattern =
// At least 8 characters
#"(?=.{8,})"# +

// At least one capital letter
#"(?=.*[A-Z])"# +

// At least one lowercase letter
#"(?=.*[a-z])"# +

// At least one digit
#"(?=.*\d)"# +

// At least one special character
#"(?=.*[ !$%&?._-])"#
