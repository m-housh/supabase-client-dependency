import Dependencies
import Foundation
@_exported import GoTrue
@_exported import PostgREST
@_exported import Supabase
import XCTestDynamicOverlay

extension DependencyValues {

  /// Access the supbase client as a dependency in the application.
  public var supabaseClient: SupabaseClientDependency {
    get { self[SupabaseClientDependency.self] }
    set { self[SupabaseClientDependency.self] = newValue }
  }
}

/// A wrapper around the `SupabaseClient` that can be used as a dependency in your projects that integrate
/// with supabase.
///
/// This adds some niceties around database operations and also includes an `auth` client.
///
public struct SupabaseClientDependency {

  /// The supabase client for the application.
  private let client: Supabase.SupabaseClient

  /// The supabase authentication client for the application.
  ///
  /// - SeeAlso: ``SupabaseClientDependency/Auth-swift.struct``
  public var auth: Auth

  /// Create a new supabase client dependency.
  ///
  /// - Parameters:
  ///   - client: The supabase client for the application.
  ///   - auth: The supabase authentication client dependency for the application.
  public init(
    client: Supabase.SupabaseClient,
    auth: Auth
  ) {
    self.client = client
    self.auth = auth
  }
  
  /// Create a new supabase client dependency.
  ///
  /// - Parameters:
  ///   - configuration: The supabase client configuration for the application.
  ///   - auth: The supabase authentication client dependency for the application.
  public init(
    configuration: Configuration,
    auth: Auth
  ) {
    self.init(client: configuration.client, auth: auth)
  }

  /// Perform a database request on the postgres client.
  ///
  ///  This is useful when you need to perform a custom query beyond what is provided by this library.
  ///
  /// ### Example
  ///
  /// ```swift
  ///  try await client.withDatabase { database in
  ///     database.from("todos")
  ///       .select()
  ///       .execute()
  ///       .value
  ///  }
  /// ```
  ///
  /// - Parameters:
  ///   - perform: The action to perform on the supabase database.
  @discardableResult
  public func withDatabase<R: Sendable>(
    perform: @escaping @Sendable (PostgrestClient) async throws -> R
  ) async rethrows -> R {
    try await perform(self.client.database)
  }
}

// MARK: - Auth
extension SupabaseClientDependency {
  /// The supabase authentication client.
  ///
  /// Use this to manage authentication tasks for the application.  It can create user's, login, logout, and gives access to
  /// the currently logged in user.
  ///
  public struct Auth {

    /// Create a new user in the database with the given credentials.
    public var createUser: (Credentials) async throws -> User

    /// Access the currently logged in user.
    public var currentUser: () async -> User?

    /// Access the authentication event stream.
    public var events: () async -> AsyncStream<AuthChangeEvent>
    
    /// Initialize the client session from storage.
    ///
    /// This method is called automatically when instantiating the client, but it's recommended to
    /// call this method on the app startup, for making sure that the client is fully initialized
    /// before proceeding.
    public var initialize: () async -> Void

    /// Log in the user with the given credentials, if the credentials are `nil` then
    /// login with previously saved credentials.
    public var _login: (Credentials?) async throws -> Session

    /// Logout the current user.
    public var logout: () async -> Void

    /// Access the current authentication session if the user has logged in.
    public var session: () async throws -> Session?

    /// Create a new auth client.
    ///
    /// - Parameters:
    ///   - createUser: Create a new user.
    ///   - currentUser: Get the current authenticated user.
    ///   - events: Access authentication event stream.
    ///   - initialize: Ensure the auth client is initialized for the application.
    ///   - login: Login a user.
    ///   - logout: Logout a user.
    ///   - session: Access the current authentication session if the user has logged in.
    public init(
      createUser: @escaping (Credentials) async throws -> User,
      currentUser: @escaping () async -> User?,
      events: @escaping () async -> AsyncStream<AuthChangeEvent>,
      initialize: @escaping () async -> Void,
      login: @escaping (Credentials?) async throws -> Session,
      logout: @escaping () async -> Void,
      session: @escaping () async throws -> Session?
    ) {
      self.createUser = createUser
      self.currentUser = currentUser
      self.events = events
      self.initialize = initialize
      self._login = login
      self.logout = logout
      self.session = session
    }

    /// Attempt to login with credentials stored in the user's key-chain, if they've logged in
    /// in the past.
    ///
    @discardableResult
    public func login() async throws -> Session {
      try await self._login(nil)
    }

    /// Login with the supplied credentials for the user. This is generally only needed once and after
    /// that the credentials will be stored in the user's key-chain for future login's.
    ///
    /// - Parameters:
    ///   - credentials: The credentials used to login.
    ///
    @discardableResult
    public func login(credentials: Credentials) async throws -> Session {
      try await self._login(credentials)
    }

    /// A helper that will throw an error if there is not a current user logged in.
    ///
    /// This is useful for requiring authentication to certain views / routes in your application.
    ///
    @discardableResult
    public func requireCurrentUser() async throws -> User {
      guard let user = await currentUser() else {
        throw AuthenticationError()
      }
      return user
    }

  }
}

extension SupabaseClientDependency.Auth {
  
  /// The unimplemented version of the auth client for usage in tests.
  static let unimplemented = Self.init(
    createUser: XCTestDynamicOverlay.unimplemented("\(Self.self).createUser", placeholder: .mock),
    currentUser: XCTestDynamicOverlay.unimplemented("\(Self.self).currentUser", placeholder: nil),
    events: XCTestDynamicOverlay.unimplemented("\(Self.self).events"),
    initialize: XCTestDynamicOverlay.unimplemented("\(Self.self).initialize"),
    login: XCTestDynamicOverlay.unimplemented("\(Self.self).login", placeholder: .mock),
    logout: XCTestDynamicOverlay.unimplemented("\(Self.self).logout"),
    session: XCTestDynamicOverlay.unimplemented("\(Self.self).session", placeholder: nil)
  )
}

extension SupabaseClientDependency: TestDependencyKey {

  /// The unimplemented supabase client dependency for usage in tests.
  public static var testValue: Self {
    Self.init(
      client: unimplemented(
        "\(Self.self).client",
        placeholder: SupabaseClient(supabaseURL: URL(string: "/")!, supabaseKey: "")
      ),
      auth: .unimplemented
    )
  }
}

public struct Auth2 {
  
  public var events: @Sendable () -> AsyncStream<AuthChangeEvent>
  public var getOAuthURL: @Sendable (OAuthRequest) throws -> URL
  public var initialize: @Sendable () async -> Void
  public var refreshSession: @Sendable (String) async throws -> Session
  public var session: @Sendable (SessionRequest?) async throws -> Session
  public var login: @Sendable (SignInRequest) async throws -> Session?
  public var logout: @Sendable () async throws -> Void
  public var signUp: @Sendable (SignUpRequest) async throws -> User
  public var update: @Sendable (UserAttributes) async throws -> User
  public var verifyOTP: @Sendable (VerifyOTPRequest) async throws -> User
  
  public init(
    events: @escaping @Sendable () -> AsyncStream<AuthChangeEvent>,
    getOAuthURL: @escaping @Sendable (OAuthRequest) throws -> URL,
    initialize: @escaping @Sendable () async  -> Void,
    refreshSession: @escaping @Sendable (String) async throws -> Session,
    session: @escaping @Sendable (SessionRequest?) async throws -> Session,
    login: @escaping @Sendable (SignInRequest) async throws -> Session?,
    logout: @escaping @Sendable () async throws -> Void,
    signUp: @escaping @Sendable (SignUpRequest) async throws -> User, 
    update: @escaping @Sendable (UserAttributes) async throws -> User,
    verifyOTP: @escaping @Sendable (VerifyOTPRequest) async throws -> User
  ) {
    self.events = events
    self.getOAuthURL = getOAuthURL
    self.initialize = initialize
    self.refreshSession = refreshSession
    self.session = session
    self.login = login
    self.logout = logout
    self.signUp = signUp
    self.update = update
    self.verifyOTP = verifyOTP
  }
  
  public func session() async throws -> Session {
    try await session(nil)
  }
  
  public struct OAuthRequest: Equatable {
    let provider: Provider
    let queryParams: [QueryParam]
    let redirectURL: URL?
    let scopes: String?
    
    public init(
      provider: Provider,
      queryParams: [QueryParam] = [],
      redirectURL: URL? = nil,
      scopes: String? = nil
    ) {
      self.provider = provider
      self.queryParams = queryParams
      self.redirectURL = redirectURL
      self.scopes = scopes
    }
        
    public struct QueryParam: Equatable {
      let name: String
      let value: String?
      
      public init(name: String, value: String?) {
        self.name = name
        self.value = value
      }
    }
  }
  
  public enum SessionRequest: Equatable {
    case oAuth(URL, storeSession: Bool = true)
    case refresh(String)
    case set(accessToken: String, refreshToken: String)
  }

  
  public enum SignInRequest: Equatable {
    
    case email(String, password: String)
    case phone(String, password: String)
//    case idToken(OpenIDConnectCredentials)
    case otp(
      OTPRequest,
      shouldCreateUser: Bool? = nil,
      options: SignUpOptions = .init()
    )
    
    public func email(credentials: Credentials) -> Self {
      .email(credentials.email, password: credentials.password)
    }

    
    public enum OTPRequest: Equatable {
      case email(String)
      case phone(String)
      
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
   
  public struct SignUpOptions: Equatable {
    let captchaToken: String?
    let data: [String: AnyJSON]?
    let redirectURL: URL?
    
    public init(
      captchaToken: String? = nil,
      data: [String : AnyJSON]? = nil,
      redirectURL: URL? = nil
    ) {
      self.captchaToken = captchaToken
      self.data = data
      self.redirectURL = redirectURL
    }
  } 
  
  public enum SignUpRequest: Equatable {
    case email(
      String,
      password: String,
      options: SignUpOptions = .init()
    )
    
    public static func email(
      credentials: Credentials,
      options: SignUpOptions = .init()
    ) -> Self {
      .email(
        credentials.email,
        password: credentials.password,
        options: options
      )
    }
    
    case phone(
      String,
      password: String,
      options: SignUpOptions = .init()
    )
  }
  
  public enum VerifyOTPRequest: Equatable {
    case email(String, options: Options)
    case phone(String, options: Options)
    
    public struct Options: Equatable {
      let captchaToken: String?
      let redirectURL: URL?
      let token: String
      let type: OTPType
      
      public init(
        captchaToken: String?,
        redirectURL: URL?,
        token: String,
        type: OTPType
      ) {
        self.captchaToken = captchaToken
        self.redirectURL = redirectURL
        self.token = token
        self.type = type
      }
    }
  }
}

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
