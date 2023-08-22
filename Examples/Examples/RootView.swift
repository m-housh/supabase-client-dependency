import ComposableArchitecture
import SupabaseClient
import Supabase
import SwiftUI

struct RootFeature: Reducer {
  enum State: Equatable {
    case loggedIn(TodoListFeature.State)
    case loggedOut(AuthFeature.State)
  }
  
  enum Action: Equatable {
    case loggedIn(TodoListFeature.Action)
    case loggedOut(AuthFeature.Action)
    case receiveAuthEvent(AuthChangeEvent)
    case signOutButtonTapped
    case task
  }
  
  @Dependency(\.supabaseClient.auth) var auth;
  
  var body: some ReducerOf<Self> {
    Scope(state: /State.loggedIn, action: /Action.loggedIn) {
      TodoListFeature()
    }
    Scope(state: /State.loggedOut, action: /Action.loggedOut) {
      AuthFeature()
    }
    Reduce { state, action in
      switch action {
      case .loggedIn:
        return .none
        
      case .loggedOut(.receiveSession(.success(_))):
        state = .loggedIn(.init())
        return .none
        
      case .loggedOut:
        return .none
        
      case let .receiveAuthEvent(authEvent):
        if authEvent == .signedOut {
          state = .loggedOut(.init())
        }
        return .none
        
      case .signOutButtonTapped:
        return .run { _ in
          await auth.logout()
        }
        
      case .task:
        return .run { send in
          await auth.initialize()
          for await event in await auth.events() {
            await send(.receiveAuthEvent(event))
          }
        }
      }
    }
  }
}

struct RootView: View {
  let store: StoreOf<RootFeature>
  
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      SwitchStore(store) { state in
        switch state {
        case .loggedIn:
          CaseLet(
            /RootFeature.State.loggedIn,
             action: RootFeature.Action.loggedIn
          ) { store in
            TodoListView(store: store)
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
            /RootFeature.State.loggedOut,
             action: RootFeature.Action.loggedOut
          ) { store in
            AuthView(store: store)
          }
        }
      }
      .task { await viewStore.send(.task).finish() }
    }
  }
}

#Preview {
  RootView(
    store: .init(initialState: .loggedOut(.init())) {
      RootFeature()
    } withDependencies: {
      $0.uuid = .init { UUID() }
    }
  )
}
