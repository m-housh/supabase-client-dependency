import ComposableArchitecture
import SupabaseClientDependencies
import Supabase
import SwiftUI

@Reducer
struct RootFeature: Reducer {
  
//  @Reducer(state: .equatable, action: .equatable)
//  enum Destination {
//    case loggedIn(TodoListFeature)
//    case loggedOut(AuthFeature)
//  }
  
  @ObservableState
  struct State: Equatable {
    @Presents var destination: Destination.State? = .loggedOut(.init())
  }
  
  enum Action: Equatable {
    case destination(PresentationAction<Destination.Action>)
    case receiveAuthEvent(AuthChangeEvent)
    case signOutButtonTapped
    case task
  }

  @Reducer(state: .equatable, action: .equatable)
  enum Destination {
    case loggedIn(TodoListFeature)
    case loggedOut(AuthFeature)
  }

  @Dependency(\.supabaseClient.auth) var auth;
  
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {

      case .destination(.presented(.loggedOut(.receiveSession(.success(_))))):
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
          try await auth.logout()
        }

      case .task:
        return .run { send in
          for await (event, _) in auth.events() {
            await send(.receiveAuthEvent(event))
          }
          await auth.initialize()
        }
      }
    }
    .ifLet(\.$destination, action: \.destination)
  }
}

struct RootView: View {
  @Perception.Bindable var store: StoreOf<RootFeature>
  
  var body: some View {
    WithPerceptionTracking {
      NavigationStack {
        Text("Loading...")
          .navigationDestination(
            item: $store.scope(state: \.destination?.loggedIn, action: \.destination.loggedIn)
          ) { store in
            TodoListView(store: store)
              .navigationBarBackButtonHidden()
              .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                  Button("Sign Out") {
                    self.store.send(.signOutButtonTapped)
                  }
                }
              }
          }
          .navigationDestination(
            item: $store.scope(state: \.destination?.loggedOut, action: \.destination.loggedOut),
            destination: AuthView.init(store:)
          )
      }
      .task { await store.send(.task).finish() }
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
