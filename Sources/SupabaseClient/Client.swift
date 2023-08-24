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

  /// The supabase authentication client for the application.
  ///
  /// - SeeAlso: ``SupabaseClientDependency/AuthClient``
  public var auth: AuthClient

  /// The supabase database client for the applicaiton.
  ///
  /// - SeeAlso: ``SupabaseClientDependency/DatabaseClient``
  public var database: DatabaseClient

  /// Create a new supabase client dependency.
  ///
  /// - Parameters:
  ///   - auth: The supabase authentication client dependency for the application.
  ///   - database: The supabase database client dependency for the application.
  public init(
    auth: AuthClient,
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
  public struct AuthClient {

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
        throw AuthenticationError()
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
      case email(String, options: Options)

      /// The phone and token used for the request.
      case phone(String, options: Options)

      /// Represents the shared option parameters for the one-time password token request.
      public struct Options: Equatable {

        /// An optional captcha token.
        public let captchaToken: String?

        /// An optional redirect-to URL.
        public let redirectURL: URL?

        /// The one-time password token.
        public let token: String

        /// The token type.
        public let type: OTPType

        /// Create a new one-time password option instance.
        ///
        /// - Parameters:
        ///   - captchaToken: An optional captcha token.
        ///   - redirectURL: An optional redirect-to URL.
        ///   - token: The one-time password token.
        ///   - type: The token type.
        public init(
          captchaToken: String? = nil,
          redirectURL: URL? = nil,
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

  /// Exposes database operations.
  ///
  /// This type mimicks the `PostgrestClient` and also adds some niceties around commonly used
  /// `CRUD` operations.
  ///
  public struct DatabaseClient {

    /// Perform a delete request on the database.
    ///
    /// This is the root item used to perform a delete request, it is generally not used directly, unless you're
    /// overriding the delete operations on the dependency. You generally would use one of the helper methods
    /// on the database client, such as
    /// ``SupabaseClientDependency/DatabaseClient/delete(id:from:)``.
    ///
    public var delete: (DeleteRequest) async throws -> Void

    /// Perform a multi-row fetch request on the database.
    ///
    /// This is the root item used to perform a fetch request, it is generally not used directly, unless you're
    /// overriding the fetch operations on the dependency. You generally would use one of the helper methods
    /// on the database client, such as
    /// ``SupabaseClientDependency/DatabaseClient/fetch(from:filteredBy:orderBy:as:)``.
    ///
    public var fetch: (FetchRequest) async throws -> [[String: AnyJSON]]

    /// Perform a single row fetch request on the database.
    ///
    /// This is the root item used to perform a fetch-one request, it is generally not used directly, unless you're
    /// overriding the fetch-one operations on the dependency. You generally would use one of the helper methods
    /// on the database client, such as
    /// ``SupabaseClientDependency/DatabaseClient/fetchOne(id:from:as:)``.
    ///
    public var fetchOne: (FetchOneRequest) async throws -> [String: AnyJSON]

    /// Build a database query.
    ///
    /// This is the root item used to build a database query, it is generally not used directly, unless you're
    /// overriding the build operations on the dependency. You generally would use the helper method
    /// on the database client, such as
    /// ``SupabaseClientDependency/DatabaseClient/from(_:decoding:perform:)``.
    ///
    public var from: (String) -> PostgrestQueryBuilder

    /// Perform an insert request on the database.
    ///
    /// This is the root item used to perform an insert request, it is generally not used directly, unless you're
    /// overriding the insert operations on the dependency. You generally would use one of the helper methods
    /// on the database client, such as
    /// ``SupabaseClientDependency/DatabaseClient/insert(_:into:returning:as:)``.
    ///
    public var insert: (InsertRequest) async throws -> [String: AnyJSON]

    /// Build a remote function request.
    ///
    /// This is the root item used to build a remote function call, it is generally not used directly, unless you're
    /// overriding the build operations on the dependency. You generally would use the helper method
    /// on the database client, such as
    /// ``SupabaseClientDependency/DatabaseClient/rpc(_:decoding:perform:)``.
    ///
    public var rpc: (RpcRequest) -> PostgrestTransformBuilder

    /// Perform an update request on the database.
    ///
    /// This is the root item used to perform an update request, it is generally not used directly, unless you're
    /// overriding the update operations on the dependency. You generally would use one of the helper methods
    /// on the database client, such as
    /// ``SupabaseClientDependency/DatabaseClient/update(id:in:with:returning:as:)``.
    ///
    public var update: (UpdateRequest) async throws -> [String: AnyJSON]

    /// Create a new database client.
    ///
    /// - Parameters:
    ///   - delete: Perform a delete request on the database.
    ///   - fetch: Perform a multi-row fetch request on the database.
    ///   - fetchOne: Perform a single-row fetch request on the database.
    ///   - from: Build a database query.
    ///   - insert: Perform an insert request on the database.
    ///   - rpc: Build a remote function request.
    ///   - update: Perform an update request on the database.
    public init(
      delete: @escaping (DeleteRequest) async throws -> Void,
      fetch: @escaping (FetchRequest) async throws -> [[String: AnyJSON]],
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

    /// Perform a custom built query on the database.
    ///
    /// This is useful if you need to perform a custom query on the database beyond what this
    /// library provides.  It gives you access to the `PostgrestQueryBuilder`.
    ///
    /// - Parameters:
    ///   - table: The table to perform the query on.
    ///   - decoding: The type to decode from the database (often inferred).
    ///   - perform: Perform the request and decode the response type.
    @discardableResult
    public func from<R: Decodable>(
      _ table: TableRepresentable,
      decoding type: R.Type = R.self,
      perform: (PostgrestQueryBuilder) async throws -> R
    ) async throws -> R {
      try await perform(self.from(table.tableName))
    }

    /// Perform a remote function call on the database.
    ///
    /// - Parameters:
    ///   - function: The rpc function for the request.
    ///   - params: Optional parameters for the function.
    ///   - count: Optional count options for the request.
    ///   - decoding: The type to decode from the response (often inferred).
    ///   - perform: Build and perform the request.
    @discardableResult
    public func rpc<R: Decodable>(
      _ function: RpcRepresentable,
      params: (any Encodable)? = nil,
      count countOptions: CountOption? = nil,
      decoding type: R.Type = R.self,
      perform: (PostgrestTransformBuilder) async throws -> R
    ) async throws -> R {
      try await perform(
        self.rpc(.init(function: function, params: params, count: countOptions))
      )
    }

    /// Represents the parameters for a delete request on the database.
    ///
    /// You generally do not instantiate this type directly, instead use one of the helper methods on the database client, such as
    /// ``SupabaseClientDependency/DatabaseClient/delete(id:from:)``.
    ///
    public struct DeleteRequest {

      /// The table to perform the delete on.
      public let table: TableRepresentable

      /// The row filters for the delete request.
      public let filters: [Filter]

      /// Create a new delete request.
      ///
      /// You generally do not instantiate this type directly, instead use one of the helper methods on the database client, such as
      /// ``SupabaseClientDependency/DatabaseClient/delete(id:from:)``.
      ///
      ///  - Parameters:
      ///   - table: The table to perform the delete request on.
      ///   - filters: The row filters for the delete request.
      public init(table: TableRepresentable, filters: [Filter]) {
        self.table = table
        self.filters = filters
      }
    }

    /// Represents the requst parameters for a database fetch request.
    ///
    /// You generally do not instantiate this type directly, instead use one of the helper methods on the database client, such as
    /// ``SupabaseClientDependency/DatabaseClient/fetch(from:filteredBy:orderBy:as:)``.
    ///
    public struct FetchRequest {

      /// The table to perform the fetch on.
      public let table: TableRepresentable

      /// The row filters for the request.
      public let filters: [Filter]

      /// The order by clause for the request.
      public let order: Order?

      /// Create a new fetch request.
      ///
      /// You generally do not instantiate this type directly, instead use one of the helper methods on the database client, such as
      /// ``SupabaseClientDependency/DatabaseClient/fetch(from:filteredBy:orderBy:as:)``.
      ///
      /// - Parameters:
      ///   - table: The table to perform the fetch requst on.
      ///   - filters: The row filters for the request.
      ///   - order: The order by clause for the request.
      public init(
        table: TableRepresentable,
        filters: [Filter] = [],
        order: Order? = nil
      ) {
        self.table = table
        self.filters = filters
        self.order = order
      }
    }

    /// Represents a single row fetch request on the database.
    ///
    /// You generally do not instantiate this type directly, instead use one of the helper methods on the database client, such as
    /// ``SupabaseClientDependency/DatabaseClient/fetchOne(id:from:as:)``.
    ///
    public struct FetchOneRequest {

      /// The table to perform the request on.
      public let table: TableRepresentable

      /// Filters for the request.
      public let filters: [Filter]

      /// Create a new single row fetch request.
      ///
      /// You generally do not instantiate this type directly, instead use one of the helper methods on the database client, such as
      /// ``SupabaseClientDependency/DatabaseClient/fetchOne(id:from:as:)``.
      ///
      /// - Parameters:
      ///   - table: The table to perform the request on.
      ///   - filters: The filters for the request.
      public init(
        table: TableRepresentable,
        filters: [Filter] = []
      ) {
        self.table = table
        self.filters = filters
      }
    }

    /// Represents an insert request on the database.
    ///
    /// You generally do not instantiate this type directly, instead use one of the helper methods on the database client, such as
    /// ``SupabaseClientDependency/DatabaseClient/insert(_:into:returning:as:)``.
    ///
    public struct InsertRequest {

      /// The table to insert the values into.
      public let table: TableRepresentable

      /// The returning options for the request.
      public let returningOptions: PostgrestReturningOptions?

      /// The values to insert into the database.
      public let values: any Encodable

      /// Create a new insert request.
      ///
      /// You generally do not instantiate this type directly, instead use one of the helper methods on the database client, such as
      /// ``SupabaseClientDependency/DatabaseClient/insert(_:into:returning:as:)``.
      ///
      /// - Parameters:
      ///   - table: The table to insert the values into.
      ///   - values: The values to insert into the database.
      ///   - returningOptions: The returning options for the response values.
      public init(
        table: TableRepresentable,
        values: any Encodable,
        returningOptions: PostgrestReturningOptions? = nil
      ) {
        self.table = table
        self.returningOptions = returningOptions
        self.values = values
      }
    }

    /// Represents the parameters need for a remote function call on the database.
    ///
    /// You generally do not instantiate this type directly, instead use one of the helper methods on the database client, such as
    /// ``SupabaseClientDependency/DatabaseClient/rpc(_:params:count:decoding:perform:)``.
    ///
    public struct RpcRequest {

      /// The remote function name.
      public let functionName: String

      /// The parameters for the function.
      public let params: any Encodable

      /// The count options for the function, if applicable.
      public let count: CountOption?

      /// Create a new rpc request.
      ///
      /// You generally do not instantiate this type directly, instead use one of the helper methods on the database client, such as
      /// ``SupabaseClientDependency/DatabaseClient/rpc(_:params:count:decoding:perform:)``.
      ///
      /// - Parameters:
      ///   - function: The remote function name.
      ///   - params: The parameters for the function, if applicable.
      ///   - count: The count options for the function, if applicable.
      public init(
        function: RpcRepresentable,
        params: (any Encodable)? = nil,
        count: CountOption? = nil
      ) {
        self.functionName = function.functionName
        self.params = params ?? NoParams()
        self.count = count
      }

      struct NoParams: Encodable {}
    }

    /// Represents an update request on the database.
    ///
    /// You generally do not instantiate this type directly, instead use one of the helper methods on the database client, such as
    /// ``SupabaseClientDependency/DatabaseClient/update(id:in:with:returning:as:)``.
    ///
    public struct UpdateRequest {

      /// The table to perform the update request on.
      public let table: TableRepresentable

      /// The filters for the request.
      public let filters: [Filter]

      /// The returning options for the response type.
      public let returningOptions: PostgrestReturningOptions

      /// The values to update in the database.
      public let values: any Encodable

      /// Create a new update request.
      ///
      /// You generally do not instantiate this type directly, instead use one of the helper methods on the database client, such as
      /// ``SupabaseClientDependency/DatabaseClient/update(id:in:with:returning:as:)``.
      ///
      /// - Parameters:
      ///   - table: The table to perform the request on.
      ///   - filters: The row filters for the request.
      ///   - returningOptions: The returning options for the response type.
      ///   - values: The values to update in the database.
      public init(
        table: TableRepresentable,
        filters: [Filter],
        returningOptions: PostgrestReturningOptions = .representation,
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

extension SupabaseClientDependency.AuthClient {
  static let unimplemented = Self.init(
    events: XCTestDynamicOverlay.unimplemented(
      "\(Self.self).events", placeholder: AsyncStream { nil }),
    getOAuthURL: XCTestDynamicOverlay.unimplemented(
      "\(Self.self).getOAuthURL", placeholder: URL(string: "/")!),
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
