import Auth
import Foundation

#if DEBUG
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
