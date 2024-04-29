import Dependencies
import Foundation
//@_exported import GoTrue
@_exported import PostgREST
@_exported import Supabase
import XCTestDynamicOverlay

extension DependencyValues {

  /// Access the supbase client as a dependency in the application.
  public var supabaseClient: SupabaseClientDependency {
    get { self[SupabaseClientDependency.self] }
    set { self[SupabaseClientDependency.self] = newValue }
  }
  
  /// The decoder used for decoding database values.
  public var databaseCoder: DatabaseCoder {
    get { self[DatabaseCoder.self] }
    set { self[DatabaseCoder.self] = newValue }
  }
}

public struct DatabaseCoder: DependencyKey {
  var encoder: JSONEncoder
  var decoder: JSONDecoder

  public static var testValue: DatabaseCoder {
    .init(
      encoder: .databaseClientEncoder,
      decoder: .databaseClientDecoder
    )
  }
  public static var liveValue: DatabaseCoder { .testValue }
}

/// A wrapper around the `SupabaseClient` that can be used as a dependency in your projects that integrate
/// with supabase.
///
/// This adds some niceties around database operations and also includes an `auth` client.
///
@dynamicMemberLookup
public struct SupabaseClientDependency {

  /// The supabase authentication client for the application.
  ///
  /// - SeeAlso: ``AuthClient``
  public var auth: AuthClient
  
  public var client: SupabaseClient

  /// Create a new supabase client dependency.
  ///
  /// - Parameters:
  ///   - auth: The supabase authentication client dependency for the application.
  ///   - database: The supabase database client dependency for the application.
  public init(
    auth: AuthClient,
    client: SupabaseClient
  ) {
    self.auth = auth
    self.client = client
  }
  
  public subscript<T>(dynamicMember keyPath: WritableKeyPath<SupabaseClient, T>) -> T {
    get { self.client[keyPath: keyPath] }
    set { self.client[keyPath: keyPath] = newValue }
  }
  
  public func database(schema: String = "public") -> PostgrestClient {
    client.schema(schema)
  }

  /// An authentication client to create and manage user sessions for access to data that is secured by
  /// access policies.
  ///
  /// This exposes all of the api's of the `GoTrue` client with some niceities around some of them, but can
  /// mocked or overriden for usage in your `TCA` based applications.
  ///
  ///
  public struct AuthClient {

    /// Asynchronous sequence of authentication change events emitted during life of `GoTrueClient`.
    public var events: @Sendable () -> AsyncStream<(event: AuthChangeEvent, session: Session?)>

    /// Log in an existing user via a third-party provider.
    public var getOAuthURL: @Sendable (OAuthRequest) throws -> URL

    /// Initialize the client session from storage.
    ///
    /// This method is called automatically when instantiating the client, but it's recommended to
    /// call this method on the app startup, for making sure that the client is fully initialized
    /// before proceeding.
    public var initialize: @Sendable () async -> Void

    /// Perform session operations on the auth client.
    public var session: @Sendable (SessionRequest?) async throws -> Session

    /// Login users.
    public var login: @Sendable (LoginRequest?) async throws -> Session?

    /// Logout users.
    public var logout: @Sendable () async throws -> Void

    /// Sends a reset request to an email address.
    public var resetPassword: @Sendable (ResetPasswordRequest) async throws -> Void

    /// Signup users.
    public var signUp: @Sendable (SignUpRequest) async throws -> User

    /// Update users.
    public var update: @Sendable (UserAttributes) async throws -> User

    /// Login a user given a User supplied OTP
    public var verifyOTP: @Sendable (VerifyOTPRequest) async throws -> User

    public init(
      events: @escaping @Sendable () -> AsyncStream<(event: AuthChangeEvent, session: Session?)>,
      getOAuthURL: @escaping @Sendable (OAuthRequest) throws -> URL,
      initialize: @escaping @Sendable () async -> Void,
      login: @escaping @Sendable (LoginRequest?) async throws -> Session?,
      logout: @escaping @Sendable () async throws -> Void,
      resetPassword: @escaping @Sendable (ResetPasswordRequest) async throws -> Void,
      session: @escaping @Sendable (SessionRequest?) async throws -> Session,
      signUp: @escaping @Sendable (SignUpRequest) async throws -> User,
      update: @escaping @Sendable (UserAttributes) async throws -> User,
      verifyOTP: @escaping @Sendable (VerifyOTPRequest) async throws -> User
    ) {
      self.events = events
      self.getOAuthURL = getOAuthURL
      self.initialize = initialize
      self.session = session
      self.login = login
      self.logout = logout
      self.resetPassword = resetPassword
      self.signUp = signUp
      self.update = update
      self.verifyOTP = verifyOTP
    }

    /// Access the currently logged in user.
    public func currentUser() async -> User? {
      try? await self.session().user
    }

    /// Attempt to login with credentials stored in the user's key-chain, if they've logged in
    /// in the past.
    ///
    @discardableResult
    public func login() async throws -> Session? {
      try await self.login(nil)
    }

    /// Login a user with the supplied credentials.
    ///
    @discardableResult
    public func login(credentials: Credentials) async throws -> Session? {
      try await self.login(.email(credentials.email, password: credentials.password))
    }

    /// A helper that will throw an error if there is not a current user logged in.
    ///
    /// This is useful for requiring authentication to certain views / routes in your application.
    ///
    public func requireCurrentUser() async throws -> User {
      guard let user = await currentUser() else {
        throw AuthenticationError.notAuthenticated
      }
      return user
    }

    /// Attempt to login with a previously stored session in the session storage, if they've logged in
    /// in the past.
    ///
    public func session() async throws -> Session {
      try await session(nil)
    }

    /// Represents parameters needed to perform a OAuth request.
    ///
    ///
    public struct OAuthRequest: Equatable {

      /// The OAuth provider.
      public let provider: Provider

      /// The query parameters.
      public let queryParams: [QueryParam]

      /// The redirect to URL.
      public let redirectURL: URL?

      /// The scopes.
      public let scopes: String?

      /// Create a new OAuth request.
      ///
      /// - Parameters:
      ///   - provider: The OAuth provider.
      ///   - queryParams: The query parameters.
      ///   - redirectURL: The optional redirect-to url.
      ///   - scopes: The optional scopes.
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

      /// Represent an OAuth query parameters.
      ///
      public struct QueryParam: Equatable {
        /// The parameter name.
        public let name: String

        /// The optional value
        public let value: String?

        /// Create a new OAuth query parameter.
        ///
        /// - Parameters:
        ///   - name: The parameter name.
        ///   - value: The optional value.
        public init(name: String, value: String? = nil) {
          self.name = name
          self.value = value
        }
      }
    }

    /// Represents the parameters required for a reset password request.
    ///
    public struct ResetPasswordRequest: Equatable {

      /// The email to use for the request.
      public let email: String

      /// An optional redirect-to URL.
      public let redirectURL: URL?

      /// An optional captcha token.
      public let captchaToken: String?

      /// Create a new reset password request.
      ///
      /// - Parameters:
      ///   - email: The email to use for the request.
      ///   - redirectURL: An optional redirect-to URL.
      ///   - captchaToken: An optional captcha token.
      public init(
        email: String,
        redirectURL: URL? = nil,
        captchaToken: String? = nil
      ) {
        self.email = email
        self.redirectURL = redirectURL
        self.captchaToken = captchaToken
      }
    }

    /// Represents request parameters for managing authentication session.
    public enum SessionRequest: Equatable {
      case oAuth(URL, storeSession: Bool = true)
      case refresh(String)
      case set(accessToken: String, refreshToken: String)
    }

    /// Represents request parameters for loggiing users in.
    public enum LoginRequest: Equatable {

      /// Login with an email and password.
      case email(String, password: String)

      /// Login with a phone number and a password.
      case phone(String, password: String)
      //    case idToken(OpenIDConnectCredentials)

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
      public enum OTPRequest: Equatable {

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

    /// Represents parameters for signing users up.
    ///
    public enum SignUpRequest: Equatable {

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

    /// Login a user with a one-time password token request.
    public enum VerifyOTPRequest: Equatable {

      /// The email and token used for the request.
      case email(String, options: Options, type: EmailOTPType)

      /// The phone and token used for the request.
      case phone(String, options: Options, type: MobileOTPType)

      /// Represents the shared option parameters for the one-time password token request.
      public struct Options: Equatable {

        /// An optional captcha token.
        public let captchaToken: String?

        /// An optional redirect-to URL.
        public let redirectURL: URL?

        /// The one-time password token.
        public let token: String

        /// Create a new one-time password option instance.
        ///
        /// - Parameters:
        ///   - captchaToken: An optional captcha token.
        ///   - redirectURL: An optional redirect-to URL.
        ///   - token: The one-time password token.
        public init(
          captchaToken: String? = nil,
          redirectURL: URL? = nil,
          token: String
        ) {
          self.captchaToken = captchaToken
          self.redirectURL = redirectURL
          self.token = token
        }
      }
    }
  }

}
