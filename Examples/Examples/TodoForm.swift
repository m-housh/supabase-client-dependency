import ComposableArchitecture
import SwiftUI

struct TodoFormFeature: Reducer {
  
  struct State: Equatable {
    var id: TodoModel.ID?
    @BindingState var description: String
    @BindingState var isComplete: Bool
    
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
  let store: StoreOf<TodoFormFeature>
  
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      Form {
        TextField("Description", text: viewStore.$description)
        Toggle("Complete", isOn: viewStore.$isComplete)
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
