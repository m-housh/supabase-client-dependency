import ComposableArchitecture
import SupabaseClient
import Supabase
import SwiftUI

struct RootFeature: Reducer {
  struct State: Equatable {
    var destination: Destination.State = .loggedOut(.init())
  }
  
  enum Action: Equatable {
    case destination(Destination.Action)
    case receiveAuthEvent(AuthChangeEvent)
    case signOutButtonTapped
    case task
  }

  struct Destination: Reducer  {
    enum State: Equatable {
      case loggedIn(TodoListFeature.State)
      case loggedOut(AuthFeature.State)
    }

    enum Action: Equatable {
      case loggedIn(TodoListFeature.Action)
      case loggedOut(AuthFeature.Action)
    }

    var body: some ReducerOf<Self> {
      Scope(state: /State.loggedIn, action: /Action.loggedIn) {
        TodoListFeature()
      }
      Scope(state: /State.loggedOut, action: /Action.loggedOut) {
        AuthFeature()
      }
    }
  }

  @Dependency(\.supabaseClient.auth) var auth;
  
  var body: some ReducerOf<Self> {
    Scope(state: \.destination, action: /Action.destination) {
      Destination()
    }
    Reduce { state, action in
      switch action {

      case .destination(.loggedOut(.receiveSession(.success(_)))):
        state.destination = .loggedIn(.init())
        return .none

      case .destination:
        return .none

      case let .receiveAuthEvent(authEvent):
        if authEvent == .signedOut {
          state.destination = .loggedOut(.init())
        }
        return .none

      case .signOutButtonTapped:
        return .run { _ in
          await auth.logout()
        }

      case .task:
        return .run { send in
          for await event in await auth.events() {
            await send(.receiveAuthEvent(event))
          }
          await auth.initialize()
        }
      }
    }
  }
}

struct RootView: View {
  let store: StoreOf<RootFeature>
  
  var body: some View {
    WithViewStore(store, observe: { _ in true }) { viewStore in
      NavigationStack {
        SwitchStore(
          store.scope(state: \.destination, action: { .destination($0) })
        ) { state in
          switch state {
          case .loggedIn:
            CaseLet(
              /RootFeature.Destination.State.loggedIn,
               action: RootFeature.Destination.Action.loggedIn
            ) { store in
              TodoListView.init(store: store)
                .toolbar {
                  ToolbarItem(placement: .cancellationAction) {
                    Button("Sign Out") {
                      viewStore.send(.signOutButtonTapped)
                    }
                  }
                }
            }
          case .loggedOut:
            CaseLet(
              /RootFeature.Destination.State.loggedOut,
               action: RootFeature.Destination.Action.loggedOut,
               then: AuthView.init(store:)
            )
          }
        }
      }
      .task { await viewStore.send(.task).finish() }
    }
  }

}

#Preview {
  RootView(
    store: .init(initialState: .init()) {
      RootFeature()._printChanges()
    } withDependencies: {
      $0.uuid = .init { UUID() }
    }
  )
}
