import Foundation

/// Represents errors thrown during authentication.
///
public enum AuthenticationError: Error, Equatable {
  case authenticationNotAllowed
  case invalidOAuthOption
  case notAuthenticated
  case sessionNotFound
  case signupNotAllowed
  case userNotFound
}
