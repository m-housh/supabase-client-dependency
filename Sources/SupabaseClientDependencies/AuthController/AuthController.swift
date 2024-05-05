@_exported import Auth
import Dependencies
import Foundation

/// Wraps an `Supabase.Auth.AuthClient` to provide override capabilities for login and signup flows.
///
/// You will generally want to expose this as a `Dependency` in your application and create it with the 
/// ``AuthController/live(auth:)`` method.
///
@dynamicMemberLookup
public struct AuthController: Sendable {
  
  /// The supabase auth client used on the controller.
  public let client: AuthClient

  /// Exposes an override hook for methods that return a `User` on the current controller instance.
  ///
  /// > Note: This only provides overrides for methods declared on the controller, not the auth client as a whole.
  ///
  public var getCurrentUser: (@Sendable () async -> User?)?

  /// Exposes an override hook for the login methods on the current controller instance.
  ///
  /// > Note: This only provides overrides for methods declared on the controller, not the auth client as a whole.
  /// > For Example, calling down to the `client.signIn` method is not overriden you need to call one of the `login` methods.
  ///
  public var loginHandler: (@Sendable (LoginRequest?) async throws -> Session?)?

  /// Exposes an override hook for the login methods on the current controller instance.
  ///
  /// > Note: This only provides overrides for methods declared on the controller, not the auth client as a whole.
  /// > For Example, calling down to the `client.signUp` method is not overriden you need to call the ``signUp(with:)`` method.
  ///
  public var signupHandler: (@Sendable (SignUpRequest) async throws -> User)?
  
  /// Create a new ``AuthController`` instance, optionally providing override hooks.
  ///
  /// If no override hooks are provided, then it uses the wrapped `AuthClient` instance.
  ///
  /// - Parameters:
  ///   - client: The `AuthClient` instance.
  ///   - currentUser: Optional override hook for methods that return the currently logged in user.
  ///   - loginHandler: Optional override hook for methods that login a user.
  ///   - signupHandler: Optional override hook for methods that sign-up a new user.
  public init(
    client: AuthClient,
    currentUser getCurrentUser: (@Sendable () async -> User?)? = nil,
    loginHandler: (@Sendable (LoginRequest?) async throws -> Session?)? = nil,
    signupHandler: (@Sendable (SignUpRequest) async throws -> User)? = nil
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
  
  
  /// Represents request parameters for loggiing users in.
  public enum LoginRequest: Equatable, Sendable {
    
    /// Login with an email and password.
    case email(String, password: String)

    /// Login with a phone number and a password.
    case phone(String, password: String)
    
    /// Login with a one-time-password.
    case otp(
      OTPRequest,
      shouldCreateUser: Bool? = nil,
      options: SharedOptions = .init()
    )
    /// Login with a credentials instance.
    public static func credentials(_ credentials: Credentials) -> Self {
      .email(credentials.email, password: credentials.password)
    }

    /// Represents a one-time-password login request.
    public enum OTPRequest: Equatable, Sendable {
      
      /// The email address for the request.
      case email(String)
      
      /// The phone number for the request.
      case phone(String)
      
      /// The underlying string value for either the email or the phone number.
      public var value: String {
        switch self {
        case let .email(email):
          return email
        case let .phone(phone):
          return phone
        }
      }
    }
  }
  
  /// Represents options used in several of the signup or login request types.
  ///
  /// > Note: Not all options are required for all signup request types, refer to the underlying `GoTrue` request.
  ///
  public struct SharedOptions: Equatable, Sendable {

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

  /// Represents parameters for signing users up.
  ///
  public enum SignUpRequest: Equatable, Sendable {

    /// Signup with an email and a password.
    case email(
      String,
      password: String,
      options: SharedOptions = .init()
    )

    /// Signup with a credentials instance.
    public static func credentials(
      _ credentials: Credentials,
      options: SharedOptions = .init()
    ) -> Self {
      .email(
        credentials.email,
        password: credentials.password,
        options: options
      )
    }

    /// Signup with a phone number and a password.
    case phone(
      String,
      password: String,
      options: SharedOptions = .init()
    )
  }

}

extension AuthController: TestDependencyKey {

  /// Create the live ``AuthController`` with no override hooks.
  ///
  /// - Parameters:
  ///   - auth: The `AuthClient` to use for the controller.
  public static func live(auth: AuthClient) -> Self {
    self.init(client: auth)
  }
  
  public static var testValue: AuthController {
    .init(client: .init(
      configuration: .init(
        url: XCTestDynamicOverlay.unimplemented(
          "\(Self.self).url",
          placeholder: URL(string: "/")!
        ),
        localStorage: XCTestDynamicOverlay.unimplemented(
          "\(Self.self).localStorage",
          placeholder: AuthClient.Configuration.defaultLocalStorage
        ),
        logger: nil
      )
    ))
  }
}

public enum AuthenticationError: Error {
  case notAuthenticated
  case failedToAuthenticate
}
