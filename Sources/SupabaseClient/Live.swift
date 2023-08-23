import Dependencies
import Foundation
import GoTrue
import Supabase

extension SupabaseClientDependency {

  /// A helper to generate a live ``SupabaseClientDependency``.
  ///
  /// This is generally used to conform the supabase client dependency to `DependencyKey` and
  /// provide it's `liveValue` in your project.
  ///
  /// - Parameters:
  ///   - configuration: The configuration for the supabase client.
  ///
  public static func live(configuration: Configuration) -> Self {
    let client = SupabaseClient(configuration: configuration)

    let session = AuthDependency(client: client)

    return Self.init(
      client: client,
      auth: .init(
        createUser: { try await session.createUser(credentials: $0) },
        currentUser: { await session.currentUser },
        events: { await session.authEvents },
        initialize: { await client.auth.initialize() },
        login: { try await session.login(credentials: $0) },
        logout: { await session.logout() },
        session: { await session.session }
      )
    )
  }

}

extension Auth2 {
  static func live(client: GoTrueClient) -> Self {
    Self.init(
      events: {
        client.authEventChange
      },
      getOAuthURL: { request in
        try client.getOAuthSignInURL(
          provider: request.provider,
          scopes: request.scopes,
          redirectTo: request.redirectURL,
          queryParams: request.queryParams.map { ($0.name, $0.value) }
        )
      },
      initialize: { await client.initialize() },
      refreshSession: { token in
        try await client.refreshSession(refreshToken: token)
      },
      session: { sessionRequest in
        guard let sessionRequest else {
          return try await client.session
        }
        switch sessionRequest {
          
        case let .oAuth(oAuthURL, storeSession: storeSession):
          return try await client.session(
            from: oAuthURL,
            storeSession: storeSession
          )
          
        case let .refresh(token):
          return try await client.refreshSession(
            refreshToken: token
          )
          
        case let .set(accessToken: accessToken, refreshToken: refreshToken):
          return try await client.setSession(
            accessToken: accessToken,
            refreshToken: refreshToken
          )
        }
        
      },
      login: { loginRequest in
        switch loginRequest {
          
        case let .email(email, password: password):
          return try await client.signIn(email: email, password: password)
        
        case let .phone(phone, password: password):
          return try await client.signIn(phone: phone, password: password)
          
        // SPI guarded.
//        case let .idToken(token):
//          fatalError()
          
        case let .otp(otpRequest, shouldCreateUser: shouldCreateUser, options: options):
          switch otpRequest {
           
          case let .email(email):
            try await client.signInWithOTP(
              email: email,
              redirectTo: options.redirectURL,
              shouldCreateUser: shouldCreateUser,
              data: options.data,
              captchaToken: options.captchaToken
            )
            return nil
          case let .phone(phone):
            try await client.signInWithOTP(
              phone: phone,
              shouldCreateUser: shouldCreateUser,
              data: options.data,
              captchaToken: options.captchaToken
            )
            return nil
          }
        }
        
      },
      logout: { try await client.signOut() },
      signUp: { signUpRequest in
        switch signUpRequest {
          
        case let .email(email, password: password, options: options):
          return try await client.signUp(
            email: email,
            password: password,
            data: options.data,
            redirectTo: options.redirectURL,
            captchaToken: options.captchaToken
          )
          .user
          
        case let .phone(phone, password: password, options: options):
          return try await client.signUp(
            phone: phone,
            password: password,
            data: options.data,
            captchaToken: options.captchaToken
          )
          .user
          
        }
      },
      update: { userAttributes in
        try await client.update(user: userAttributes)
      },
      verifyOTP: { otpRequest in
        switch otpRequest {
        case let .email(email, options: options):
          return try await client.verifyOTP(
            email: email,
            token: options.token,
            type: options.type,
            redirectTo: options.redirectURL,
            captchaToken: options.captchaToken
          )
          .user
          
        case let .phone(phone, options: options):
          return try await client.verifyOTP(
            phone: phone,
            token: options.token,
            type: options.type,
            captchaToken: options.captchaToken
          )
          .user
        }
      }
    )
  }
}

fileprivate extension AuthResponse {
  var user: User {
    switch self {
    case let .session(session):
      return session.user
    case let .user(user):
      return user
    }
  }
}

fileprivate actor AuthDependency {
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

struct AuthenticationError: Error {}
