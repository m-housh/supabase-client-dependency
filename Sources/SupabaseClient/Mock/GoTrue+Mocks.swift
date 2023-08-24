import Foundation
import GoTrue

#if DEBUG
  extension User {
    public static let mock = Self.init(
      id: UUID(0),
      appMetadata: [:],
      userMetadata: [:],
      aud: "",
      createdAt: Date(),
      updatedAt: Date()
    )
  }

  extension Session {
    public static let mock = Self.init(
      accessToken: "",
      tokenType: "",
      expiresIn: 1,
      refreshToken: "",
      user: .mock
    )
  }
#endif
