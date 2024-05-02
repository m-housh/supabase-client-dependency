@_exported import Auth
import Foundation

@dynamicMemberLookup
public struct AuthController {
  
  private var client: AuthClient
  public var getCurrentUser: (() async -> User?)?
  public var loginHandler: ((LoginRequest?) async throws -> Session?)?
  public var signupHandler: ((SignUpRequest) async throws -> User)?
  
  public init(
    client: AuthClient,
    currentUser getCurrentUser: (() async -> User?)? = nil,
    loginHandler: ((LoginRequest?) async throws -> Session?)? = nil,
    signupHandler: ((SignUpRequest) async throws -> User)? = nil
  ) {
    self.client = client
    self.getCurrentUser = getCurrentUser
    self.loginHandler = loginHandler
    self.signupHandler = signupHandler
  }
  
  public subscript<T>(dynamicMember keyPath: KeyPath<AuthClient, T>) -> T {
    client[keyPath: keyPath]
  }
  
  public func login() async -> Session? {
    guard let loginHandler else {
      return await client.login()
    }
    return try? await loginHandler(nil)
  }
  
  @discardableResult
  public func login(_ request: LoginRequest) async throws -> Session {
    guard let loginHandler else {
      return try await client.login(request)
    }
    guard let session = try await loginHandler(request) else {
      throw AuthenticationError.failedToAuthenticate
    }
    return session
  }

  @discardableResult
  public func login(credentials: Credentials) async throws -> Session {
    return try await self.login(.credentials(credentials))
  }

  public var currentUser: User? {
    get async {
      guard let getCurrentUser else {
        return await client.currentUser
      }
      return await getCurrentUser()
    }
  }
  
  @discardableResult
  public func requireCurrentUser() async throws -> User {
    guard let user = await currentUser else {
      throw AuthenticationError.notAuthenticated
    }
    return user
  }
  
  @discardableResult
  public func signUp(with request: SignUpRequest) async throws -> User {
    guard let signupHandler else {
      return try await client.signUp(request)
    }
    return try await signupHandler(request)
  }
}

extension AuthController {
  public static func live(auth: AuthClient) -> Self {
    self.init(client: auth)
  }

  #if DEBUG
  public static func mock(
    allowedCredentials: AllowedCredentials = .any,
    user: User = .mock,
    session: Session? = nil,
    uuid: @escaping () -> UUID = UUID.init,
    date: @escaping () -> Date = Date.init
  ) -> Self {

    final class Storage {
      var currentUser: User
      var currentSession: Session? = nil

      init(currentUser: User, currentSession: Session? = nil) {
        self.currentUser = currentUser
        self.currentSession = currentSession
      }
    }

    let storage = Storage(currentUser: user, currentSession: session)

    return self.init(
      client: .init(configuration: .init(
        url: URL(string: "/")!,
        localStorage: AuthClient.Configuration.defaultLocalStorage,
        logger: nil
      )),
      currentUser: { storage.currentUser },
      loginHandler: { loginRequest in
        guard allowedCredentials.isAllowedToAuthenticate(.login(loginRequest)) else {
          throw AuthenticationError.notAuthenticated
        }
        if storage.currentSession == nil {
          storage.currentSession = .mock(user: storage.currentUser)
        }
        return storage.currentSession!
      },
      signupHandler: { signUp in
        guard allowedCredentials.isAllowedToAuthenticate(.signUp(signUp)) else {
          throw AuthenticationError.notAuthenticated
        }
        storage.currentUser = signUp.mockUser(date: date(), uuid: uuid)
        storage.currentSession = .mock(user: storage.currentUser)
        return storage.currentUser
      }
    )
  }
  #endif
}
