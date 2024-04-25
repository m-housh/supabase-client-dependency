import ComposableArchitecture
import SwiftUI

@Reducer
struct TodoFormFeature {

  @ObservableState
  struct State: Equatable {
    var id: TodoModel.ID?
    var description: String
    var isComplete: Bool

    var isValid: Bool { !description.isEmpty }

    init(
      id: TodoModel.ID? = nil,
      description: String = "",
      isComplete: Bool = false
    ) {
      self.id = id
      self.description = description
      self.isComplete = isComplete
    }

    init(todo: TodoModel) {
      self.id = todo.id
      self.description = todo.description
      self.isComplete = todo.isComplete
    }
  }

  enum Action: BindableAction, Equatable {
    case binding(BindingAction<State>)
  }

  var body: some ReducerOf<Self> {
    BindingReducer()
  }
}

struct TodoForm: View {
  @Perception.Bindable var store: StoreOf<TodoFormFeature>

  var body: some View {
    WithPerceptionTracking {
      Form {
        TextField("Description", text: $store.description)
        Toggle("Complete", isOn: $store.isComplete)
      }
    }
  }
}

#Preview {
  TodoForm(
    store: .init(initialState: .init()) {
      TodoFormFeature()
    }
  )
}
