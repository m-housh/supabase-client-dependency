@_exported import Auth
import Dependencies
import Foundation

/// Wraps an `Supabase.Auth.AuthClient` to provide override capabilities for login and signup flows.
///
/// You will generally want to expose this as a `Dependency` in your application and create it with the ``live(auth:)`` method.
///
@dynamicMemberLookup
public struct AuthController {
  
  /// The supabase auth client used on the controller.
  public let client: AuthClient

  /// Exposes an override hook for methods that return a `User` on the current controller instance.
  ///
  /// > Note: This does only provides overrides for methods declared on the controller, not the auth client as a whole.
  ///
  public var getCurrentUser: (() async -> User?)?

  /// Exposes an override hook for the login methods on the current controller instance.
  ///
  /// > Note: This does only provides overrides for methods declared on the controller, not the auth client as a whole.
  /// > For Example, calling down to the `client.signIn` method is not overriden you need to call one of the `login` methods.
  ///
  public var loginHandler: ((LoginRequest?) async throws -> Session?)?

  /// Exposes an override hook for the login methods on the current controller instance.
  ///
  /// > Note: This does only provides overrides for methods declared on the controller, not the auth client as a whole.
  /// > For Example, calling down to the `client.signUp` method is not overriden you need to call the ``signUp(with:)`` method.
  ///
  public var signupHandler: ((SignUpRequest) async throws -> User)?
  
  /// Create a new ``AuthController`` instance, optionally providing override hooks.
  ///
  /// If not override hooks are provided, then it uses the wrapped `AuthClient` instance.
  ///
  /// - Parameters:
  ///   - client: The `AuthClient` instance.
  ///   - currentUser: Optional override hook for methods that return the currently logged in user.
  ///   - loginHandler: Optional override hook for methods that login a user.
  ///   - signupHandler: Optional override hook for methods that sign-up a new user.
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
  
  /// Exposes all the properties on the wrapped `AuthClient`.
  public subscript<T>(dynamicMember keyPath: KeyPath<AuthClient, T>) -> T {
    client[keyPath: keyPath]
  }
  
  /// Attempt to login with previously stored credentials, returning `nil` if it was un-successful.
  public func login() async -> Session? {
    guard let loginHandler else {
      return await client.login()
    }
    return try? await loginHandler(nil)
  }
  
  /// Attempt to login with provided credentials, throwing an error if it was un-successful.
  ///
  /// This method will return the session provided by the ``loginHandler`` if it is set on the controller, if it
  /// is not set, then it will use the live `AuthClient` to login a user.
  ///
  /// - Parameters:
  ///   - request: The login request type.
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

  /// Attempt to login with provided credentials, throwing an error if it was un-successful.
  ///
  /// This method will return the session provided by the ``loginHandler`` if it is set on the controller, if it
  /// is not set, then it will use the live `AuthClient` to login a user.
  ///
  /// - Parameters:
  ///   - credentials: The login credentials.
  @discardableResult
  public func login(credentials: Credentials) async throws -> Session {
    return try await self.login(.credentials(credentials))
  }

  /// Access the currently logged in user, returning `nil` if no login session is found.
  ///
  /// This method will return the user provided by the ``getCurrentUser`` if it is set on the controller, if it
  /// is not set, then it will use the live `AuthClient` session to retrieve the current user.
  ///
  public var currentUser: User? {
    get async {
      guard let getCurrentUser else {
        return await client.currentUser
      }
      return await getCurrentUser()
    }
  }

  /// Access the currently logged in user, throwing an error  if no login session is found.
  ///
  /// This method will return the user provided by the ``getCurrentUser`` if it is set on the controller, if it
  /// is not set, then it will use the live `AuthClient` session to retrieve the current user.
  ///
  @discardableResult
  public func requireCurrentUser() async throws -> User {
    guard let user = await currentUser else {
      throw AuthenticationError.notAuthenticated
    }
    return user
  }

  /// Sign-up a new user.
  ///
  /// This method will return the user provided by the ``signupHandler`` if it is set on the controller, if it
  /// is not set, then it will use the live `AuthClient` session to sign-up the user.
  ///
  @discardableResult
  public func signUp(with request: SignUpRequest) async throws -> User {
    guard let signupHandler else {
      return try await client.signUp(request)
    }
    return try await signupHandler(request)
  }
}

extension AuthController {

  /// Create the live ``AuthController`` with no override hooks.
  ///
  /// - Parameters:
  ///   - auth: The `AuthClient` to use for the controller.
  public static func live(auth: AuthClient) -> Self {
    self.init(client: auth)
  }

  #if DEBUG
  /// Create a mock ``AuthController`` with override hooks based on the passed in values.
  ///
  /// Uses the ``AllowedCredentials`` type to determine successful calls to the `login` and `signUp` methods.
  ///
  /// > Note: Any calls to the underlying `AuthClient` will fail because this generates a client with an invalid url.
  ///
  ///
  /// - Parameters:
  ///   - allowedCredentials: The credentials that are allowed to login or sign-up.
  ///   - user: The inital user, this does get replaced if login or sign-up methods are called.
  ///   - session: An optional initial session, this does get replaced if login or sign-up methods are called.
  ///   - uuid: The uuid generator for creating mock users.
  ///   - date: The date generator for creating mock users.
  public static func mock(
    allowedCredentials: AllowedCredentials = .any,
    user: User = .mock,
    session: Session? = nil,
    uuid: @escaping () -> UUID = UUID.init,
    date: @escaping () -> Date = Date.init
  ) -> Self {

    struct AuthStorage: AuthLocalStorage, Sendable {
      private let storage = LockIsolated<Storage>(Storage())

      final class Storage {
        var storage: [String: Data] = [:]

        init() {
          self.storage = [:]
        }
      }

      func store(key: String, value: Data) throws {
        storage.withValue { storage in
          storage.storage[key] = value
        }
      }

      func retrieve(key: String) throws -> Data? {
        storage.value.storage[key]
      }

      func remove(key: String) throws {
        _ = storage.withValue { storage in
          storage.storage.removeValue(forKey: key)
        }
      }
    }

    final class Storage {
      var currentUser: User
      var currentSession: Session? = nil

      init(currentUser: User, currentSession: Session? = nil) {
        self.currentUser = currentUser
        self.currentSession = currentSession
      }
    }

    let storage = Storage(currentUser: user)

    return self.init(
      client: .init(configuration: .init(
        url: URL(string: "/")!,
        localStorage: AuthStorage(),
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
