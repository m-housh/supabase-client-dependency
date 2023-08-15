import Dependencies
import Foundation
import GoTrue
import Supabase

extension SupabaseClientDependency {

  public static func live(configuration: Configuration = .local) -> Self {
    let client = SupabaseClient(
      supabaseURL: configuration.url,
      supabaseKey: configuration.anonKey,
      options: configuration.options
    )

    let session = _ClientDependency(client: client)

    return Self.init(
      client: client,
      auth: .init(
        createUser: { try await session.createUser(credentials: $0) },
        currentUser: { await session.currentUser },
        events: { await session.authEvents },
        login: { try await session.login(credentials: $0) },
        logout: { await session.logout() },
        session: { await session.session }
      )
    )
  }

}

fileprivate actor _ClientDependency {
  private let client: SupabaseClient

  init(client: SupabaseClient) {
    self.client = client
  }

  var session: Session? {
    get async {
      try? await client.auth.session
    }
  }

  var authEvents: AsyncStream<AuthChangeEvent> { client.auth.authEventChange }

  func createUser(credentials: Credentials) async throws -> User {
    let response = try await client.auth.signUp(
      email: credentials.email,
      password: credentials.password
    )

    switch response {
    case let .session(session):
      return session.user
    case let .user(user):
      return user
    }
  }

  var currentUser: User? {
    get async { await self.session?.user }
  }

  func login(credentials: Credentials?) async throws -> Session {
    if let credentials {
      return try await client.auth.signIn(
        email: credentials.email,
        password: credentials.password
      )
    }

    guard let session = await self.session
    else { throw AuthenticationError() }

    return session
  }

  func logout() async {
    try? await client.auth.signOut()
  }
}

struct AuthenticationError: Error { }
