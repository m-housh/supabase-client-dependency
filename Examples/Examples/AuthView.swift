import ComposableArchitecture
import SupabaseClient
import SwiftUI

struct AuthFeature: Reducer {
  struct State: Equatable {

    @BindingState var credentials = Credentials.empty
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
  }

  @Dependency(\.supabaseClient) var supabaseClient;

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
        return.none

      case .submitButtonTapped:
        guard state.credentials.isValid else { return .none }
        state.error = nil
        return .run { [credentials = state.credentials, mode = state.mode] send in
          await send(.receiveSession(
            TaskResult {
              switch mode {
              case .signIn:
                return try await supabaseClient.auth.login(credentials: credentials)
              case .signUp:
                let user = try await supabaseClient.auth.createUser(credentials)
                return try await supabaseClient.auth.login(credentials: credentials)
              }
            }
          ))
        }
      }
    }
  }
}

struct AuthView: View {
  let store: StoreOf<AuthFeature>

  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      Form {
        Section {
          TextField("Email", text: viewStore.$credentials.email)
            .keyboardType(.emailAddress)
            .textContentType(.emailAddress)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)

          SecureField("Password", text: viewStore.$credentials.password)
            .textContentType(.password)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)

          Button(viewStore.mode.title) {
            viewStore.send(.submitButtonTapped)
          }

          if let error = viewStore.error {
            ErrorText(error)
          }
        }

        Section {
          Button(
            viewStore.mode == .signIn ? "Don't have an account? Sign up." :
              "Already have an account? Sign in."
          ) {
            viewStore.send(.changeModeButtonTapped)
          }
        }
      }
    }
  }
}

#Preview {
  AuthView(
    store: .init(initialState: .init()) {
      AuthFeature()
    } withDependencies: {
      $0.supabaseClient.auth = .mock()
    }
  )
}
