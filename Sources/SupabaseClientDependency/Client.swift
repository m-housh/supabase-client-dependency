import Dependencies
import Foundation
@_exported import GoTrue
@_exported import Supabase
@_exported import PostgREST
import XCTestDynamicOverlay

extension DependencyValues {
  public var supabaseClient: SupabaseClientDependency {
    get { self[SupabaseClientDependency.self] }
    set { self[SupabaseClientDependency.self] = newValue }
  }
}

public struct SupabaseClientDependency {
  private let client: LockIsolated<Supabase.SupabaseClient>
  public var auth: Auth

  public init(
    client: Supabase.SupabaseClient,
    auth: Auth
  ) {
    self.client = .init(client)
    self.auth = auth
  }

  @discardableResult
  public func withDatabase<R: Sendable>(
    perform: @escaping @Sendable (PostgrestClient) async throws -> R
  ) async rethrows -> R {
    try await perform(self.client.database)
  }
}

// MARK: - Auth
extension SupabaseClientDependency {
  public struct Auth {
    public var createUser: (Credentials) async throws -> User
    public var currentUser: () async -> User?
    public var events: () async -> AsyncStream<AuthChangeEvent>
    public var _login: (Credentials?) async throws -> Session
    public var logout: () async -> Void
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
