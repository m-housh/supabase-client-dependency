import Dependencies
import Foundation
import GoTrue
import IdentifiedStorage
import Supabase

extension SupabaseClientDependency.Auth {

  /// Create a mock authentication client for the supabase client dependency.
  ///
  /// This is useful for previews or tests.
  ///
  ///  > Note: The auth event stream for the mock auth client only sends `AuthChangeEvent.signIn` and `AuthChangeEventsignOut` events.
  ///
  ///  - Parameters:
  ///   - allowedCredentials: Restrict the credentials allowed to login if needed (defaults to `any`).
  ///   - session: Supply a custom session object, when supplied this will automatically login when credentials are not supplied to the `login` method.
  ///
  public static func mock(
    allowedCredentials: AllowedCredentials = .any,
    session: Session? = .mock
  ) -> Self {
    @Dependency(\.date.now) var now
    @Dependency(\.uuid) var uuid

    let userStorage = IdentifiedStorageOf<User>(
      initialValues: [],
      timeDelays: nil
    )

    let sessionStorage = IdentifiedStorage<User.ID, Session>(
      id: \.user.id,
      initialValues: session != nil ? [session!] : [],
      timeDelays: nil
    )
    
    let (authEventStream, authEventStreamContinuation) = AsyncStream.makeStream(of: AuthChangeEvent.self)

    return .init(
      createUser: {
        credentials in
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
      events: { authEventStream },
      initialize: { 
        _ = try? await AuthHelpers.login(
          authEventStreamContinuation: authEventStreamContinuation,
          credentials: nil,
          sessionStorage: sessionStorage,
          userStorage: userStorage
        )
      },
      login: { optionalCredentials in
        
        guard allowedCredentials.isAllowedToAuthenticate(credentials: optionalCredentials) else {
          throw AuthenticationError()
        }
        
        return try await AuthHelpers.login(
          authEventStreamContinuation: authEventStreamContinuation,
          credentials: optionalCredentials,
          sessionStorage: sessionStorage,
          userStorage: userStorage
        )
      },
      logout: {
        await sessionStorage.set(elements: .init(id: \.user.id))
        authEventStreamContinuation.yield(.signedOut)
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

    // A helper that validates whether credentials can either be added to
    // the user storage or to authenticate a session for the mock client.
    func isAllowedToAuthenticate(credentials: Credentials?) -> Bool {
      guard let credentials else { return true }
      switch self {
      case .any:
        return true
      case let .only(allowedCredentials):
        return allowedCredentials.contains(credentials)
      }
    }
  }
}

private enum AuthHelpers {
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
      expiresIn: 123_456_789,
      refreshToken: "mock-refresh-token",
      user: user
    )
    _ = try? await storage.insert(
      request: SessionInsertRequest(session: session)
    )
    return session
  }
  
  @discardableResult
  fileprivate static func login(
    authEventStreamContinuation: AsyncStream<AuthChangeEvent>.Continuation,
    credentials: Credentials?,
    sessionStorage: IdentifiedStorage<User.ID, Session>,
    userStorage: IdentifiedStorageOf<User>
  ) async throws -> Session {
    guard let credentials else {
      // Check if there's a session.
      guard let session = await sessionStorage.first else {
        throw AuthenticationError()
      }
      authEventStreamContinuation.yield(.signedIn)
      return session
    }
    
    // Check if there's a user stored with the credentials.
    let optionalUser = await userStorage.withValues(
      perform: { $0.first(where: { $0.email == credentials.email }) }
    )
    guard let user = optionalUser else {
      throw AuthenticationError()
    }
    
    authEventStreamContinuation.yield(.signedIn)
    return await AuthHelpers.createSession(
      for: user,
      in: sessionStorage
    )
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

extension IdentifiedStorage {
  var first: Element? {
    get async { await withValues { $0.first } }
  }
}
