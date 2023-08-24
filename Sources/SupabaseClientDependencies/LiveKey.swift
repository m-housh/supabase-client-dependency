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

    return Self.init(
      auth: .live(client: client.auth),
      database: .live(client: client.database)
    )
  }

}

extension SupabaseClientDependency.AuthClient {

  /// Create a new ``SupabaseClientDependencies/SupabaseClientDependency/AuthClient`` instance.
  ///
  /// - Parameters:
  ///   - client: The go-true client used to build the live dependency.
  ///
  public static func live(client: GoTrueClient) -> Self {
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
      login: { loginRequest in
        guard let loginRequest else {
          // Attempt to login with previously saved credentials.
          return try await client.session
        }

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
      resetPassword: { request in
        try await client.resetPasswordForEmail(
          request.email,
          redirectTo: request.redirectURL,
          captchaToken: request.captchaToken
        )
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

extension SupabaseClientDependency.DatabaseClient {
  /// Create a live ``SupabaseClientDependencies/SupabaseClientDependency/DatabaseClient`` instance.
  ///
  /// - Parameters:
  ///   - client: The postgres client used to build the live client.
  ///
  public static func live(client: PostgrestClient) -> Self {
    .init(
      delete: { request in
        try await client.from(request.table.tableName)
          .delete(returning: .minimal)
          .filter(by: request.filters)
          .execute()
          .value
      },
      fetch: { request in
        try await client.from(request.table.tableName)
          .select()
          .filter(by: request.filters)
          .order(by: request.order)
          .execute()
          .value
      },
      fetchOne: { request in
        try await client.from(request.table.tableName)
          .select()
          .filter(by: request.filters)
          .single()
          .execute()
          .value
      },
      from: { table in
        client.from(table)
      },
      insert: { request in
        try await client.from(request.table.tableName)
          .insert(values: request.values, returning: request.returningOptions)
          .single()
          .execute()
          .value
      },
      insertMany: { request in
        try await client.from(request.table.tableName)
          .insert(values: request.values.anyJSON(), returning: request.returningOptions)
          .execute()
          .value
      },
      rpc: { client.rpc(fn: $0.functionName, params: $0.params, count: $0.count) },
      update: { request in
        try await client.from(request.table.tableName)
          .update(values: request.values, returning: request.returningOptions)
          .filter(by: request.filters)
          .single()
          .execute()
          .value
      }

    )
  }
}

extension AuthResponse {
  fileprivate var user: User {
    switch self {
    case let .session(session):
      return session.user
    case let .user(user):
      return user
    }
  }
}
