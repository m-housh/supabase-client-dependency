import Dependencies
import Foundation
@_exported import GoTrue
@_exported import PostgREST
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
//  private let client: Supabase.SupabaseClient

  /// The supabase authentication client for the application.
  ///
  /// - SeeAlso: ``SupabaseClientDependency/Auth-swift.struct``
  public var auth: Auth
  
  public var database: DatabaseClient
  
  /// Create a new supabase client dependency.
  ///
  /// - Parameters:
  ///   - auth: The supabase authentication client dependency for the application.
  ///   - database: The supabase database client dependency for the application.
  public init(
    auth: Auth,
    database: DatabaseClient
  ) {
    self.auth = auth
    self.database = database
  }


  /// An authentication client to create and manage user sessions for access to data that is secured by
  /// access policies.
  ///
  /// This exposes all of the api's of the `GoTrue` client with some niceities around some of them, but can
  /// mocked or overriden for usage in your `TCA` based applications.
  /// 
  ///
  public struct Auth {

    /// Asynchronous sequence of authentication change events emitted during life of `GoTrueClient`.
    public var events: @Sendable () -> AsyncStream<AuthChangeEvent>

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
      events: @escaping @Sendable () -> AsyncStream<AuthChangeEvent>,
      getOAuthURL: @escaping @Sendable (OAuthRequest) throws -> URL,
      initialize: @escaping @Sendable () async  -> Void,
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
        throw AuthenticationError()
      }
      return user
    }
    /// Attempt to login with a previously stored in the session in the storage, if they've logged in
    /// in the past.
    ///
    public func session() async throws -> Session {
      try await session(nil)
    }

    public struct OAuthRequest: Equatable {
      public let provider: Provider
      public let queryParams: [QueryParam]
      public let redirectURL: URL?
      public let scopes: String?

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
        public let name: String
        public let value: String?

        public init(name: String, value: String?) {
          self.name = name
          self.value = value
        }
      }
    }

    public struct ResetPasswordRequest: Equatable {
      public let email: String
      public let redirectURL: URL?
      public let captchaToken: String?

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

    public enum SessionRequest: Equatable {
      case oAuth(URL, storeSession: Bool = true)
      case refresh(String)
      case set(accessToken: String, refreshToken: String)
    }


    public enum LoginRequest: Equatable {

      case email(String, password: String)
      case phone(String, password: String)
      //    case idToken(OpenIDConnectCredentials)
      case otp(
        OTPRequest,
        shouldCreateUser: Bool? = nil,
        options: SignUpOptions = .init()
      )

      public static func credentials(_ credentials: Credentials) -> Self {
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
      public let captchaToken: String?
      public let data: [String: AnyJSON]?
      public let redirectURL: URL?

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

      public static func credentials(
        _ credentials: Credentials,
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
        public let captchaToken: String?
        public let redirectURL: URL?
        public let token: String
        public let type: OTPType

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
  
  public struct DatabaseClient {

    public var delete: (DeleteRequest) async throws -> Void
    public var fetch: (FetchRequest) async throws -> [[String: AnyJSON]]
    public var fetchOne: (FetchOneRequest) async throws -> [String: AnyJSON]
    public var from: (String) -> PostgrestQueryBuilder
    public var insert: (InsertRequest) async throws -> [String: AnyJSON]
    public var rpc: (RpcRequest) -> PostgrestTransformBuilder
    public var update: (UpdateRequest) async throws -> [String: AnyJSON]
    
    public init(
      delete: @escaping (DeleteRequest) async throws -> Void,
      fetch: @escaping (FetchRequest) async throws -> [[String : AnyJSON]],
      fetchOne: @escaping (FetchOneRequest) async throws -> [String: AnyJSON],
      from: @escaping (String) -> PostgrestQueryBuilder,
      insert: @escaping (InsertRequest) async throws -> [String: AnyJSON],
      rpc: @escaping (RpcRequest) -> PostgrestTransformBuilder,
      update: @escaping (UpdateRequest) async throws -> [String: AnyJSON]
    ) {
      self.delete = delete
      self.fetch = fetch
      self.fetchOne = fetchOne
      self.from = from
      self.insert = insert
      self.rpc = rpc
      self.update = update
    }
    
    @discardableResult
    public func from<R: Decodable>(
      _ table: TableRepresentable,
      decoding type: R.Type = R.self,
      perform: (PostgrestQueryBuilder) async throws -> R
    ) async throws -> R {
      try await perform(self.from(table.tableName))
    }
    
    @discardableResult
    public func rpc<R: Decodable>(
      _ rpcRequest: RpcRequest,
      decoding type: R.Type = R.self,
      perform: (PostgrestTransformBuilder) async throws -> R
    ) async throws -> R {
      try await perform(self.rpc(rpcRequest))
    }
    
    public struct DeleteRequest {
      public let table: TableRepresentable
      public let filters: [Filter]

      public init(table: TableRepresentable, filters: [Filter]) {
        self.table = table
        self.filters = filters
      }
    }

    public struct FetchRequest {
      
      public let table: TableRepresentable
      public let filters: [Filter]
      public let order: Order?

      public init(
        table: TableRepresentable,
        filters: [Filter],
        order: Order?
      ) {
        self.table = table
        self.filters = filters
        self.order = order
      }
    }
    
    public struct FetchOneRequest {
      
      public let table: TableRepresentable
      public let filters: [Filter]
      
      public init(
        table: TableRepresentable,
        filters: [Filter]
      ) {
        self.table = table
        self.filters = filters
      }
    }
    
    public struct InsertRequest {
      public let table: TableRepresentable
      public let returningOptions: PostgrestReturningOptions?
      public let values: any Encodable
      
      public init(
        table: TableRepresentable,
        returningOptions: PostgrestReturningOptions?,
        values: any Encodable
      ) {
        self.table = table
        self.returningOptions = returningOptions
        self.values = values
      }
    }
    
    public struct RpcRequest {
      public let functionName: String
      public let params: any Encodable
      public let count: CountOption?
      
      public init(
        functionName: String,
        params: (any Encodable)? = nil,
        count: CountOption? = nil
      ) {
        self.functionName = functionName
        self.params = params ?? NoParams()
        self.count = count
      }
      
      struct NoParams: Encodable { }
    }
    
    public struct UpdateRequest {
      public let table: TableRepresentable
      public let filters: [Filter]
      public let returningOptions: PostgrestReturningOptions
      public let values: any Encodable
      
      public init(
        table: TableRepresentable,
        filters: [Filter],
        returningOptions: PostgrestReturningOptions,
        values: any Encodable
      ) {
        self.table = table
        self.filters = filters
        self.returningOptions = returningOptions
        self.values = values
      }
    }
  }

}

extension SupabaseClientDependency.Auth {
  static let unimplemented = Self.init(
    events: XCTestDynamicOverlay.unimplemented("\(Self.self).events", placeholder: AsyncStream { nil }),
    getOAuthURL: XCTestDynamicOverlay.unimplemented("\(Self.self).getOAuthURL", placeholder: URL(string: "/")!),
    initialize: XCTestDynamicOverlay.unimplemented("\(Self.self).initialize"),
    login: XCTestDynamicOverlay.unimplemented("\(Self.self).login", placeholder: nil),
    logout: XCTestDynamicOverlay.unimplemented("\(Self.self).logout"),
    resetPassword: XCTestDynamicOverlay.unimplemented("\(Self.self).resetPassword"),
    session: XCTestDynamicOverlay.unimplemented("\(Self.self).session", placeholder: .mock),
    signUp: XCTestDynamicOverlay.unimplemented("\(Self.self).signUp", placeholder: .mock),
    update: XCTestDynamicOverlay.unimplemented("\(Self.self).update", placeholder: .mock),
    verifyOTP: XCTestDynamicOverlay.unimplemented("\(Self.self).verifyOTP", placeholder: .mock)
  )
}

extension SupabaseClientDependency.DatabaseClient {
  static let unimplemented = Self.init(
    delete: XCTestDynamicOverlay.unimplemented("\(Self.self).delete"),
    fetch: XCTestDynamicOverlay.unimplemented("\(Self.self).fetch", placeholder: []),
    fetchOne: XCTestDynamicOverlay.unimplemented("\(Self.self).fetchOne", placeholder: [:]),
    from: XCTestDynamicOverlay.unimplemented("\(Self.self).from"),
    insert: XCTestDynamicOverlay.unimplemented("\(Self.self).insert", placeholder: [:]),
    rpc: XCTestDynamicOverlay.unimplemented("\(Self.self).rpc"),
    update: XCTestDynamicOverlay.unimplemented("\(Self.self).update", placeholder: [:])
  )
}

extension SupabaseClientDependency: TestDependencyKey {

  /// The unimplemented supabase client dependency for usage in tests.
  public static var testValue: Self {
    Self.init(
      auth: .unimplemented,
      database: .unimplemented
    )
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
