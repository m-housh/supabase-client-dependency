import Dependencies
import Foundation
@_exported import GoTrue
@_exported import Supabase
@_exported import PostgREST
import XCTestDynamicOverlay

extension DependencyValues {

  /// Access the supbase client as a dependency in the application.
  public var supabaseClient: SupabaseClientDependency {
    get { self[SupabaseClientDependency.self] }
    set { self[SupabaseClientDependency.self] = newValue }
  }
}

public struct SupabaseClientDependency {

  /// The supabase client for the application.
  private let client: LockIsolated<Supabase.SupabaseClient>

  /// The supabase authentication client for the application.
  public var auth: Auth

  /// Create a new supabase client.
  ///
  /// - Parameters:
  ///   - client: The supabase client for the application.
  ///   - auth: The supabase authentication client dependency for the application.
  public init(
    client: Supabase.SupabaseClient,
    auth: Auth
  ) {
    self.client = .init(client)
    self.auth = auth
  }

  /// Performs a database request.
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

    /// Access authentication events.
    public var events: () async -> AsyncStream<AuthChangeEvent>

    /// Log in the user with the given credentials, if the credentials are `nil` then
    /// login with previously saved credentials.
    public var _login: (Credentials?) async throws -> Session

    /// Logout the current user.
    public var logout: () async -> Void

    /// Access the current authentication session if the user has logged in.
    public var session: () async throws -> Session?

    public init(
      createUser: @escaping (Credentials) async throws -> User,
      currentUser: @escaping () async -> User?,
      events: @escaping () async -> AsyncStream<AuthChangeEvent>,
      login: @escaping (Credentials?) async throws -> Session,
      logout: @escaping () async -> Void,
      session: @escaping () async throws -> Session?
    ) {
      self.createUser = createUser
      self.currentUser = currentUser
      self.events = events
      self._login = login
      self.logout = logout
      self.session = session
    }

    @discardableResult
    public func login() async throws -> Session {
      try await self._login(nil)
    }

    @discardableResult
    public func login(credentials: Credentials) async throws -> Session {
      try await self._login(credentials)
    }
  }
}

extension SupabaseClientDependency.Auth {
  static let unimplemented = Self.init(
    createUser: XCTestDynamicOverlay.unimplemented("\(Self.self).createUser", placeholder: .mock),
    currentUser: XCTestDynamicOverlay.unimplemented("\(Self.self).currentUser", placeholder: nil),
    events: XCTestDynamicOverlay.unimplemented("\(Self.self).events"),
    login: XCTestDynamicOverlay.unimplemented("\(Self.self).login", placeholder: .mock),
    logout: XCTestDynamicOverlay.unimplemented("\(Self.self).logout"),
    session: XCTestDynamicOverlay.unimplemented("\(Self.self).session", placeholder: nil)
  )
}

extension SupabaseClientDependency: TestDependencyKey {

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
