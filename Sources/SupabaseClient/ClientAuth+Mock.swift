import Dependencies
import Foundation
import GoTrue
import IdentifiedStorage
import Supabase

extension SupabaseClientDependency.Auth {
  
  public static func mock(
    allowedCredentials: AllowedCredentials = .any,
    session: Session? = .mock
  ) -> Self {
    @Dependency(\.date.now) var now;
    @Dependency(\.uuid) var uuid;
    
    let userStorage = IdentifiedStorageOf<User>(
      initialValues: [],
      timeDelays: nil
    )
    
    let sessionStorage = IdentifiedStorage<User.ID, Session>(
      id: \.user.id,
      initialValues: session != nil ? [session!] : [],
      timeDelays: nil
    )
    
    return .init(
      createUser: { credentials in
        guard allowedCredentials.isAllowedToAuthenticate(credentials: credentials) else {
          throw AuthenticationError()
        }
        return await AuthHelpers.createUser(
          in: userStorage,
          using: credentials,
          date: now,
          uuid: uuid
        )
      },
      currentUser: {
        await sessionStorage.withValues {
          $0.first?.user
        }
      },
      events: {
        AsyncStream { nil }
      },
      login: { optionalCredentials in
        if let credentials = optionalCredentials {
          guard allowedCredentials.isAllowedToAuthenticate(credentials: credentials) else {
            throw AuthenticationError()
          }
          
          guard let user = await userStorage.withValues(
            perform: { $0.first(where: { $0.email == credentials.email }) }
          )
          else {
            throw AuthenticationError()
          }
          return await AuthHelpers.createSession(
            for: user,
            in: sessionStorage
          )
        }
        guard let session = await sessionStorage.withValues(
          perform: { $0.first }
        ) else {
          throw AuthenticationError()
        }
        return session
      },
      logout: {
        await sessionStorage.set(elements: .init(id: \.user.id))
      },
      session: {
        await sessionStorage.withValues {
          $0.first
        }
      }
    )
  }
  
  public enum AllowedCredentials {
    case any
    case only([Credentials])
    
    func isAllowedToAuthenticate(credentials: Credentials) -> Bool {
      switch self {
      case .any:
        return true
      case let .only(allowedCredentials):
        return allowedCredentials.contains(credentials)
      }
    }
  }
}


fileprivate enum AuthHelpers {
  fileprivate static func createUser(
    in storage: IdentifiedStorageOf<User>,
    using credentials: Credentials,
    date now: Date,
    uuid: UUIDGenerator
  ) async -> User {
    let user = User(
      id: uuid(),
      appMetadata: [:],
      userMetadata: [:],
      aud: "mock-auth",
      email: credentials.email,
      createdAt: now,
      confirmedAt: now,
      emailConfirmedAt: now,
      updatedAt: now
    )
    _ = try? await storage.insert(user)
    return user
  }
  
  fileprivate static func createSession(
    for user: User,
    in storage: IdentifiedStorage<User.ID, Session>
  ) async -> Session {
    let session = Session(
      accessToken: "mock-access-token",
      tokenType: "fake",
      expiresIn: 123456789,
      refreshToken: "mock-refresh-token",
      user: user
    )
    _ = try? await storage.insert(
      request: SessionInsertRequest(session: session)
    )
    return session
  }
  
  fileprivate struct SessionInsertRequest: InsertRequestConvertible {
    
    typealias ID = User.ID
    typealias Value = Session
    let session: Session
    
    func transform() -> Session {
      session
    }
  }
}
