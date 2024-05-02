import Auth

extension AuthClient {
  
  // Access the currently logged in user, returns nil if not logged in.
  var currentUser: User? {
    get async {
      try? await self.session.user
    }
  }
  
  // Access the currently logged in user.
  func requireCurrentUser() async throws -> User {
    guard let user = await currentUser else {
      throw AuthenticationError.notAuthenticated
    }
    return user
  }
  
  func login() async -> Session? {
    try? await session
  }
  
  func login(_ request: LoginRequest) async throws -> Session {
    switch request {
    case let .email(email, password):
      return try await self.signIn(email: email, password: password)
    case let .phone(phone, password):
      return try await self.signIn(phone: phone, password: password)
    case let .otp(oTPRequest, shouldCreateUser, options):
      switch oTPRequest {
      case let .email(email):
        try await self.signInWithOTP(
          email: email,
          redirectTo: options.redirectURL,
          shouldCreateUser: shouldCreateUser ?? false,
          data: options.data,
          captchaToken: options.captchaToken
        )
        
      case let .phone(phone):
        try await self.signInWithOTP(
          phone: phone,
          shouldCreateUser: shouldCreateUser ?? false,
          data: options.data,
          captchaToken: options.captchaToken
        )
      }
      return try await self.session
    }
  }
  
  func signUp(_ request: SignUpRequest) async throws -> User {
    switch request {

    case let .email(email, password: password, options: options):
      return try await self.signUp(
        email: email,
        password: password,
        data: options.data,
        redirectTo: options.redirectURL,
        captchaToken: options.captchaToken
      )
      .user

    case let .phone(phone, password: password, options: options):
      return try await self.signUp(
        phone: phone,
        password: password,
        data: options.data,
        captchaToken: options.captchaToken
      )
      .user

    }
  }
}

