import Dependencies
import Foundation
import GoTrue
import IdentifiedStorage
import PostgREST

extension SupabaseClientDependency.AuthClient {

  /// Create a mock authentication client for the supabase client dependency.
  ///
  /// This is useful for previews or tests.
  ///
  ///  > Note: The auth event stream may not mimick exactly what is done by the live gotrue client.
  ///
  ///  - Parameters:
  ///    - allowedCredentials: Restrict the credentials allowed to login / signUp if needed (defaults to `any`).
  ///    - oAuthURL: A url returned from the `getOAuthURL` method.
  ///    - session: Supply a custom session object, when supplied this will automatically login when credentials are not supplied to the `login` method.
  ///    - verifyOTP: A custom verify otp method.
  public static func mock(
    allowedCredentials: AllowedCredentials = .any,
    oAuthURL: URL = URL(string: "/")!,
    session: Session? = .mock,
    verifyOTP: @escaping (SupabaseClientDependency.AuthClient.VerifyOTPRequest) async throws ->
      User = { _ in .mock }
  ) -> Self {
    @Dependency(\.date.now) var now
    @Dependency(\.uuid) var uuid

    let userStorage = IdentifiedStorageOf<User>(
      initialValues: [],
      timeDelays: nil
    )

    let sessionStorage = IdentifiedStorage<User.ID, Session>(
      id: \.user.id,
      initialValues: session != nil ? [session!] : [],
      timeDelays: nil
    )

    let (authEventStream, authEventStreamContinuation) = AsyncStream.makeStream(
      of: AuthChangeEvent.self
    )

    return .init(
      events: { authEventStream },
      getOAuthURL: { _ in oAuthURL },
      initialize: {
        // attempt to login / create a session.
        _ = try? await AuthHelpers.login(
          authEventStreamContinuation: authEventStreamContinuation,
          request: nil,
          sessionStorage: sessionStorage,
          userStorage: userStorage
        )
      },
      login: { optionalRequest in
        guard allowedCredentials.isAllowedToAuthenticate(.login(optionalRequest)) else {
          throw AuthenticationError.authenticationNotAllowed
        }
        return try await AuthHelpers.login(
          authEventStreamContinuation: authEventStreamContinuation,
          request: optionalRequest,
          sessionStorage: sessionStorage,
          userStorage: userStorage
        )
      },
      logout: {
        await sessionStorage.set(elements: .init(id: \.user.id))
        authEventStreamContinuation.yield(.signedOut)
      },
      resetPassword: { _ in },
      session: { optionalRequest in
        guard let request = optionalRequest else {
          guard let session = await sessionStorage.first else {
            throw AuthenticationError.sessionNotFound
          }
          return session
        }
        switch request {

        case .oAuth(_, let storeSession):
          guard storeSession else {
            throw AuthenticationError.invalidOAuthOption
          }
          return await AuthHelpers.createSession(
            for: .mock,
            in: sessionStorage
          )
        case let .refresh(token):
          guard var session = await sessionStorage.first else {
            throw AuthenticationError.sessionNotFound
          }
          session.refreshToken = token
          await sessionStorage.set(elements: .init(uniqueElements: [session], id: \.user.id))
          authEventStreamContinuation.yield(.tokenRefreshed)
          return session

        case .set(let accessToken, let refreshToken):
          let session = Session(
            accessToken: accessToken,
            tokenType: "mock-auth",
            expiresIn: 123_456_789,
            refreshToken: refreshToken,
            user: .mock  // ?? what to do here.
          )
          await sessionStorage.set(elements: .init(uniqueElements: [session], id: \.user.id))
          authEventStreamContinuation.yield(.signedIn)
          return session

        }
      },

      signUp: { request in
        guard allowedCredentials.isAllowedToAuthenticate(.signUp(request)) else {
          throw AuthenticationError.signupNotAllowed
        }
        return await AuthHelpers.createUser(
          in: userStorage,
          using: request,
          date: now,
          uuid: uuid
        )
      },
      update: { attributes in
        guard var user = await userStorage.first else {
          throw AuthenticationError.userNotFound
        }
        user.email = attributes.email ?? user.email
        user.phone = attributes.phone ?? user.phone
        user.userMetadata = attributes.data ?? user.userMetadata
        try await userStorage.update(user)
        authEventStreamContinuation.yield(.userUpdated)
        return user
      },
      verifyOTP: { request in
        try await verifyOTP(request)
      }
    )
  }

  /// Represents credentials that are allowed to be used in the mock ``SupabaseClientDependencies/SupabaseClientDependency/AuthClient/mock(allowedCredentials:oAuthURL:session:verifyOTP:)`` implementation.
  ///
  ///
  public enum AllowedCredentials {

    /// Allow's any credentials to authenticate.
    case any

    /// Allow's only the supplied credentials to authenticate.
    ///
    /// ### Example
    /// ```swift
    /// .only([.credentials(email: "blob@example.com", password: "secret-password!"])
    /// ```
    ///
    case only([LoginRequest])

    /// Allow's only the supplied credentials to authenticate.
    ///
    /// ### Example
    /// ```swift
    /// .only(.credentials(email: "blob@example.com", password: "secret-password!")
    /// ```
    ///
    public static func only(_ values: LoginRequest...) -> Self {
      .only(values)
    }

    // A helper that validates whether credentials can either be added to
    // the user storage or to authenticate a session for the mock client.
    func isAllowedToAuthenticate(_ request: Request) -> Bool {
      switch self {
      case .any:
        return true
      case let .only(allowedCredentials):
        switch request {
        case let .login(optionalLogin):
          guard let loginRequest = optionalLogin else { return true }
          return allowedCredentials.contains(loginRequest)
        case let .signUp(signUpRequest):
          return self.isAllowedToAuthenticate(.login(signUpRequest.loginRequest))
        }
      }
    }

    enum Request {
      case login(SupabaseClientDependency.AuthClient.LoginRequest?)
      case signUp(SupabaseClientDependency.AuthClient.SignUpRequest)
    }
  }
}

private enum AuthHelpers {
  fileprivate static func createUser(
    in storage: IdentifiedStorageOf<User>,
    using request: SupabaseClientDependency.AuthClient.SignUpRequest,
    date now: Date,
    uuid: UUIDGenerator
  ) async -> User {
    let user = request.mockUser(date: now, uuid: uuid)
    _ = try? await storage.insert(user)
    return user
  }

  fileprivate static func createSession(
    for user: User,
    in storage: IdentifiedStorage<User.ID, Session>
  ) async -> Session {
    let session = Session(
      accessToken: "mock-access-token",
      tokenType: "fake",
      expiresIn: 123_456_789,
      refreshToken: "mock-refresh-token",
      user: user
    )
    _ = try? await storage.insert(
      request: SessionInsertRequest(session: session)
    )
    return session
  }

  @discardableResult
  fileprivate static func login(
    authEventStreamContinuation: AsyncStream<AuthChangeEvent>.Continuation,
    request: SupabaseClientDependency.AuthClient.LoginRequest?,
    sessionStorage: IdentifiedStorage<User.ID, Session>,
    userStorage: IdentifiedStorageOf<User>
  ) async throws -> Session {
    guard let request else {
      // Check if there's a session.
      guard let session = await sessionStorage.first else {
        throw AuthenticationError.sessionNotFound
      }
      authEventStreamContinuation.yield(.signedIn)
      return session
    }

    // Check if there's a user stored with the credentials.
    let optionalUser = await userStorage.first(matching: request)
    guard let user = optionalUser else {
      throw AuthenticationError.userNotFound
    }

    authEventStreamContinuation.yield(.signedIn)
    return await AuthHelpers.createSession(
      for: user,
      in: sessionStorage
    )
  }

  fileprivate struct SessionInsertRequest: InsertRequestConvertible {

    typealias ID = User.ID
    typealias Value = Session
    let session: Session

    func transform() -> Session {
      session
    }
  }
}

extension IdentifiedStorage {
  fileprivate var first: Element? {
    get async { await withValues { $0.first } }
  }
}

extension IdentifiedStorage where Element == User {
  fileprivate func first(matching request: SupabaseClientDependency.AuthClient.LoginRequest) async
    -> User?
  {
    switch request {
    case let .email(email, password: _):
      return await withValues {
        $0.first(where: { $0.email == email })
      }
    case let .phone(phone, password: _):
      return await withValues {
        $0.first(where: { $0.phone == phone })
      }
    case let .otp(otpRequest, shouldCreateUser: _, options: _):
      switch otpRequest {
      case let .email(email):
        return await withValues {
          $0.first(where: { $0.email == email })
        }
      case let .phone(phone):
        return await withValues {
          $0.first(where: { $0.phone == phone })
        }
      }

    }
  }
}

extension SupabaseClientDependency.AuthClient.SignUpRequest {

  fileprivate var loginRequest: SupabaseClientDependency.AuthClient.LoginRequest {
    switch self {
    case let .email(email, password: password, options: _):
      return .email(email, password: password)
    case let .phone(phone, password: password, options: _):
      return .phone(phone, password: password)
    }
  }

  fileprivate func mockUser(date: Date, uuid: UUIDGenerator) -> User {
    switch self {
    case let .email(email, password: _, options: _):
      return .init(
        id: uuid(),
        appMetadata: [:],
        userMetadata: [:],
        aud: "mock-auth",
        confirmationSentAt: nil,
        recoverySentAt: nil,
        emailChangeSentAt: nil,
        newEmail: nil,
        invitedAt: nil,
        actionLink: nil,
        email: email,
        phone: nil,
        createdAt: date,
        confirmedAt: date,
        emailConfirmedAt: date,
        phoneConfirmedAt: nil,
        lastSignInAt: nil,
        role: nil,
        updatedAt: date,
        identities: nil
      )
    case let .phone(phone, password: _, options: _):
      return .init(
        id: uuid(),
        appMetadata: [:],
        userMetadata: [:],
        aud: "mock-auth",
        confirmationSentAt: nil,
        recoverySentAt: nil,
        emailChangeSentAt: nil,
        newEmail: nil,
        invitedAt: nil,
        actionLink: nil,
        email: nil,
        phone: phone,
        createdAt: date,
        confirmedAt: date,
        emailConfirmedAt: nil,
        phoneConfirmedAt: date,
        lastSignInAt: nil,
        role: nil,
        updatedAt: date,
        identities: nil
      )
    }
  }
}
