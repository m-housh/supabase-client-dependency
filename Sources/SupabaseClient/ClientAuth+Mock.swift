import Dependencies
import Foundation
import GoTrue
import IdentifiedStorage
import Supabase

extension SupabaseClientDependency.Auth {

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
  @_spi(Mock)
  public static func mock(
    allowedCredentials: AllowedCredentials = .any,
    oAuthURL: URL = URL(string: "/")!,
    session: Session? = .mock,
    verifyOTP: @escaping (SupabaseClientDependency.Auth.VerifyOTPRequest) async throws -> User = { _ in .mock }
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
          throw AuthenticationError()
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
            throw AuthenticationError()
          }
          return session
        }
        switch request {

        case .oAuth(_, storeSession: let storeSession):
          guard storeSession else {
            throw AuthenticationError()
          }
          return await AuthHelpers.createSession(
            for: .mock,
            in: sessionStorage
          )
        case let .refresh(token):
          guard var session = await sessionStorage.first else {
            throw AuthenticationError()
          }
          session.refreshToken = token
          await sessionStorage.set(elements: .init(uniqueElements: [session], id: \.user.id))
          authEventStreamContinuation.yield(.tokenRefreshed)
          return session

        case .set(accessToken: let accessToken, refreshToken: let refreshToken):
          let session = Session(
            accessToken: accessToken,
            tokenType: "mock-auth",
            expiresIn: 123456789,
            refreshToken: refreshToken,
            user: .mock // ?? what to do here.
          )
          await sessionStorage.set(elements: .init(uniqueElements: [session], id: \.user.id))
          authEventStreamContinuation.yield(.signedIn)
          return session

        }
      },

      signUp: { request in
        guard allowedCredentials.isAllowedToAuthenticate(.signUp(request)) else {
          throw AuthenticationError()
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
          throw AuthenticationError()
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

  @_spi(Mock)
  public enum AllowedCredentials {
    case any
    case only([LoginRequest])

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
      case login(SupabaseClientDependency.Auth.LoginRequest?)
      case signUp(SupabaseClientDependency.Auth.SignUpRequest)
    }
  }
}

private enum AuthHelpers {
  fileprivate static func createUser(
    in storage: IdentifiedStorageOf<User>,
    using request: SupabaseClientDependency.Auth.SignUpRequest,
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
    request: SupabaseClientDependency.Auth.LoginRequest?,
    sessionStorage: IdentifiedStorage<User.ID, Session>,
    userStorage: IdentifiedStorageOf<User>
  ) async throws -> Session {
    guard let request else {
      // Check if there's a session.
      guard let session = await sessionStorage.first else {
        throw AuthenticationError()
      }
      authEventStreamContinuation.yield(.signedIn)
      return session
    }

    // Check if there's a user stored with the credentials.
    let optionalUser = await userStorage.first(matching: request)
    guard let user = optionalUser else {
      throw AuthenticationError()
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

fileprivate extension IdentifiedStorage {
  var first: Element? {
    get async { await withValues { $0.first } }
  }
}

fileprivate extension IdentifiedStorage where Element == User {
  func first(matching request: SupabaseClientDependency.Auth.LoginRequest) async -> User? {
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

fileprivate extension SupabaseClientDependency.Auth.SignUpRequest {

  var loginRequest: SupabaseClientDependency.Auth.LoginRequest {
    switch self {
    case let .email(email, password: password, options: _):
      return .email(email, password: password)
    case let .phone(phone, password: password, options: _):
      return .phone(phone, password: password)
    }
  }

  func mockUser(date: Date, uuid: UUIDGenerator) -> User {
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
