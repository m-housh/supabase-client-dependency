import ComposableArchitecture
import SwiftUI

struct TodoFeature: Reducer {
  
  struct State: Equatable {
    @PresentationState var destination: Destination.State?
    var todos: IdentifiedArrayOf<TodoModel>?
    var isLoadingTodos: Bool = false
  }
  
  struct Destination: Reducer {
    enum State: Equatable {
      case addTodo(TodoFormFeature.State)
      case editTodo(TodoFormFeature.State)
    }
    
    enum Action: Equatable {
      case addTodo(TodoFormFeature.Action)
      case editTodo(TodoFormFeature.Action)
    }
    
    var body: some ReducerOf<Self> {
      Scope(state: /State.addTodo, action: /Action.addTodo) {
        TodoFormFeature()
      }
      Scope(state: /State.editTodo, action: /Action.editTodo) {
        TodoFormFeature()
      }
    }
  }
  
  enum Action: Equatable {
    case addTodoButtonTapped
    case destination(PresentationAction<Destination.Action>)
    case receiveTodos(TaskResult<IdentifiedArrayOf<TodoModel>>)
    case receiveSavedTodo(TaskResult<TodoModel>)
    case rowTapped(id: TodoModel.ID)
    case saveTodoFormButtonTapped
    case task
  }
  
  @Dependency(\.database) var database;
  
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
        
      case .addTodoButtonTapped:
        state.destination = .addTodo(.init())
        return .none
        
      case .destination:
        return .none
        
      case let .receiveTodos(.failure(error)):
        state.isLoadingTodos = false
        XCTFail("Failed to fetch todos: \(error)")
        return .none
        
      case let .receiveTodos(.success(todos)):
        state.isLoadingTodos = false
        state.todos = todos
        return .none
        
      case let .receiveSavedTodo(.failure(error)):
        state.destination = nil
        XCTFail("Failed to save todo: \(error)")
        return .none
        
      case let .receiveSavedTodo(.success(todo)):
        state.destination = nil
        if state.todos?[id: todo.id] != nil {
          // We are updating the todo, so replace it in the list.
          state.todos?[id: todo.id] = todo
        } else {
          // We are inserting a new todo, so put it at the head of the list.
          state.todos?.insert(todo, at: 0)
        }
        return .none
        
      case let .rowTapped(id: id):
        guard let todo = state.todos?[id: id]
        else {
          XCTFail("Recieved a row tapped action for an invalid id: \(id)")
          return .none
        }
        state.destination = .editTodo(.init(todo: todo))
        return .none
        
      case .saveTodoFormButtonTapped:
        guard let destination = state.destination
        else { return .none }
        
        switch destination {
        case let .addTodo(form):
          // Confirm form is valid.
          guard form.isValid else { return .none }
          // Save a new todo.
          return .run { send in
            await send(.receiveSavedTodo(self.saveNewTodo(form: form)))
          }
        case let .editTodo(form):
          // Confirm the form has an id, we can find the original todo in our state,
          // and that the form is valid.
          guard let todoId = form.id,
                let originalTodo = state.todos?[id: todoId],
                form.isValid
          else { return .none }
          // Update the todo.
          return .run { send in
            guard let todoResult = await self.updateTodo(form: form, original: originalTodo)
            else { return }
            await send(.receiveSavedTodo(todoResult))
          }
          
        }
       
      case .task:
        // Check if the todos have been populated or not.
        guard state.todos == nil else { return .none }
        state.isLoadingTodos = true
        return .run { send in
          await send(.receiveTodos(
            TaskResult { try await database.todos.fetch() }
          ))
        }
        
      }
    }
    .ifLet(\.$destination, action: /Action.destination) {
      Destination()
    }
  }
  
  private func saveNewTodo(form: TodoFormFeature.State) async -> TaskResult<TodoModel> {
    await TaskResult {
      try await database.todos.insert(
        .init(description: form.description, complete: form.isComplete)
      )
    }
  }
  
  private func updateTodo(
    form: TodoFormFeature.State,
    original: TodoModel
  ) async -> TaskResult<TodoModel>? {
    let updateRequest = DatabaseClient.Todos.UpdateRequest(
      description: form.description == original.description ? nil : form.description,
      complete: form.isComplete == original.isComplete ? nil : form.isComplete
    )
    
    guard updateRequest.description != nil || updateRequest.complete != nil else {
      return nil
    }
    
    return await TaskResult {
      try await database.todos.update(original.id, updateRequest)
    }
  }
}

struct TodoView: View {
  let store: StoreOf<TodoFeature>
  
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      NavigationStack {
        if let todos = viewStore.todos {
          List {
            ForEach(todos) { todo in
              Button {
                viewStore.send(.rowTapped(id: todo.id))
              } label: {
                HStack {
                  Text(todo.description)
                  Spacer()
                  Image(systemName: todo.isComplete ? "checkmark.square" : "square")
                  Image(systemName: "chevron.right")
                    .foregroundStyle(Color.secondary)
                }

              }
              .buttonStyle(.plain)
            }
          }
          .navigationTitle("Todos")
          .navigationDestination(
            store: store.scope(state: \.$destination, action: { .destination($0) })
          ) { store in
            DestinationView(store: store)
              .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                  Button("Save") {
                    viewStore.send(.saveTodoFormButtonTapped)
                  }
                }
              }
          }
          .toolbar {
            ToolbarItem(placement: .confirmationAction) {
              Button {
                viewStore.send(.addTodoButtonTapped)
              } label: {
                Label("Add Todo", systemImage: "plus")
              }
            }
          }
        } else {
          ProgressView()
            .navigationTitle("Todos")
            .task { await viewStore.send(.task).finish() }
        }
      }
    }
  }
  
  struct DestinationView: View {
    let store: StoreOf<TodoFeature.Destination>
    
    var body: some View {
      SwitchStore(store) { state in
        switch state {
        case .addTodo:
          CaseLet(
            /TodoFeature.Destination.State.addTodo,
             action: TodoFeature.Destination.Action.addTodo
          ) { store in
            TodoForm(store: store)
              .navigationTitle("Add Todo")
          }
        case .editTodo:
          CaseLet(
            /TodoFeature.Destination.State.editTodo,
             action: TodoFeature.Destination.Action.editTodo
          ) { store in
            TodoForm(store: store)
              .navigationTitle("Edit Todo")
          }
        }
      }
    }
  }
}

#Preview {
  TodoView(
    store: .init(initialState: .init()) {
      TodoFeature()._printChanges()
    } withDependencies: {
      $0.uuid = .init { UUID() }
    }
  )
}
