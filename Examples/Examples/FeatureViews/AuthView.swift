import ComposableArchitecture
import SupabaseClientDependencies
import SwiftUI

@Reducer
struct AuthFeature {

  @ObservableState
  struct State: Equatable {
    var credentials = Credentials.empty
    var error: Error?
    var mode: Mode = .signIn

    var submitButtonEnabled: Bool { credentials.isValid }

    enum Mode: Equatable {
      case signIn
      case signUp

      var title: String {
        switch self {
        case .signIn:
          return "Sign In"
        case .signUp:
          return "Sign Up"
        }
      }

      mutating func toggle() {
        switch self {
        case .signIn:
          self = .signUp
        case .signUp:
          self = .signIn
        }
      }

      static func == (lhs: Mode, rhs: Mode) -> Bool {
        switch lhs {
        case .signIn:
          switch rhs {
          case .signIn:
            return true
          case .signUp:
            return false
          }
        case .signUp:
          switch rhs {
          case .signIn:
            return false
          case .signUp:
            return true
          }
        }
      }
    }

    static func == (lhs: AuthFeature.State, rhs: AuthFeature.State) -> Bool {
      lhs.credentials == rhs.credentials
        && lhs.error?.localizedDescription == rhs.error?.localizedDescription
        && lhs.mode == rhs.mode
    }
  }

  enum Action: BindableAction, Equatable {
    case binding(BindingAction<State>)
    case changeModeButtonTapped
    case receiveSession(TaskResult<Session>)
    case submitButtonTapped
    case task
  }

  @Dependency(\.supabaseClient) var supabaseClient

  var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .binding:
        return .none

      case .changeModeButtonTapped:
        state.mode.toggle()
        return .none

      case let .receiveSession(.failure(error)):
        state.error = error
        return .none

      case .receiveSession(.success(_)):
        print("Logged in user: \(state.credentials.email)")
        return .none

      case .submitButtonTapped:
        state.error = nil
        return .run { [credentials = state.credentials, mode = state.mode] send in
          struct AuthenticationError: Error {}
          await send(
            .receiveSession(
              TaskResult {
                switch mode {
                case .signIn:
                  guard let session = try await supabaseClient.auth.login(credentials: credentials)
                  else {
                    throw AuthenticationError()
                  }
                  return session
                case .signUp:
                  _ = try await supabaseClient.auth.signUp(.credentials(credentials))
                  guard let session = try await supabaseClient.auth.login(credentials: credentials)
                  else {
                    throw AuthenticationError()
                  }
                  return session
                }
              }
            ))
        }

      case .task:
        return .run { send in
          // Attempts to login with already saved credentials.
          if let session = try? await supabaseClient.auth.login() {
            await send(.receiveSession(.success(session)))
          }
        }
      }
    }
  }
}

struct AuthView: View {
  @Perception.Bindable var store: StoreOf<AuthFeature>

  var body: some View {
    WithPerceptionTracking {
      Form {
        Section {
          TextField("Email", text: $store.credentials.email)
            .autocorrectionDisabled()
            #if os(iOS)
            .textContentType(.emailAddress)
            .keyboardType(.emailAddress)
            .textInputAutocapitalization(.never)
            #endif
          
          SecureField("Password", text: $store.credentials.password)
            .autocorrectionDisabled()
            #if os(iOS)
            .textContentType(.password)
            .textInputAutocapitalization(.never)
            #endif
          
          Button(store.mode.title) {
            store.send(.submitButtonTapped)
          }
          
          if let error = store.error {
            ErrorText(error)
          }
        }
        
        Section {
          Button(
            store.mode == .signIn
            ? "Don't have an account? Sign up." 
            : "Already have an account? Sign in."
          ) {
            store.send(.changeModeButtonTapped)
          }
        }
      }
      .navigationBarBackButtonHidden()
      .navigationTitle(store.mode.title)
      .task { await store.send(.task).finish() }
    }
  }
}

#if DEBUG
  #Preview {
    NavigationStack {
      AuthView(
        store: .init(initialState: .init()) {
          AuthFeature()
        } withDependencies: {
          $0.supabaseClient.auth = .mock()
        }
      )
    }
  }
#endif
