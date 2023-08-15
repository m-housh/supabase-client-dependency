import Foundation

public struct Credentials: Codable, Equatable, Sendable {
  public var email: String
  public var password: String

  public init(email: String, password: String) {
    self.email = email
    self.password = password
  }

  public static let empty = Self.init(email: "", password: "")
}
