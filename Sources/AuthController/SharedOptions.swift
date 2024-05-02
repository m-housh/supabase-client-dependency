import Auth
import Foundation

/// Represents options used in several of the signup or login request types.
///
/// > Note: Not all options are required for all signup request types, refer to the underlying `GoTrue` request.
///
public struct SharedOptions: Equatable {

  /// An optional captcha token.
  public let captchaToken: String?

  /// Optional data for the request.
  public let data: [String: AnyJSON]?

  /// An optional redirect-to URL for the request.
  public let redirectURL: URL?

  /// Create a new signup option.
  ///
  /// - Parameters:
  ///   - captchaToken: An optional captcha token.
  ///   - data: Optional data for the request.
  ///   - redirectURL: An optional redirect-to URL for the request.
  public init(
    captchaToken: String? = nil,
    data: [String: AnyJSON]? = nil,
    redirectURL: URL? = nil
  ) {
    self.captchaToken = captchaToken
    self.data = data
    self.redirectURL = redirectURL
  }
}
