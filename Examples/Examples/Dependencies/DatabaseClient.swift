import Dependencies
import Foundation
import IdentifiedStorage
import SupabaseClient
import XCTestDynamicOverlay

extension DependencyValues {
  var database: DatabaseClient {
    get { self[DatabaseClient.self] }
    set { self[DatabaseClient.self] = newValue }
  }
}

struct DatabaseClient {
  
  var todos: Todos
  
  struct Todos {
    var delete: (TodoModel.ID) async throws -> Void
    var fetch: (FetchRequest) async throws -> IdentifiedArrayOf<TodoModel>
    var fetchOne: (TodoModel.ID) async throws -> TodoModel?
    var insert: (InsertRequest) async throws -> TodoModel
    var update: (TodoModel.ID, UpdateRequest) async throws -> TodoModel
    
    func fetch() async throws -> IdentifiedArrayOf<TodoModel> {
      try await self.fetch(.all)
    }
    
    enum FetchRequest {
      case all
      case filtered(by: Filter)
      
      enum Filter {
        case complete
        case incomplete
      }
    }
    
    struct InsertRequest: Encodable {
      var description: String
      var complete: Bool
    }
    
    struct UpdateRequest: Encodable {
      var description: String?
      var complete: Bool?
    }
  }
}

extension DatabaseClient: DependencyKey {
  
  static var liveValue: Self {
    @Dependency(\.supabaseClient) var client;
    return Self.init(
      todos: DatabaseClient.Todos(
        delete: { try await client.delete(id: $0, from: Table.todos) },
        fetch: { request in
          switch request {
          case .all:
            return .init(
              uniqueElements: try await client.fetch(from: Table.todos)
            )
          case let .filtered(by: filter):
            return .init(
              uniqueElements: try await client.fetch(
                from: Table.todos,
                filteredBy:  TodoColumn.complete.equals(filter == .complete ? true : false)
              )
            )
          }
        },
        fetchOne: { try await client.fetchOne(id: $0, from: Table.todos) },
        insert: { try await client.insert($0, into: Table.todos) },
        update: { try await client.update(id: $0, in: Table.todos, with: $1) }
      )
    )
  }
  
  
  static var previewValue: DatabaseClient {
    let storage = IdentifiedStorageOf<TodoModel>(initialValues: TodoModel.mocks)
    
    return Self.init(
      todos: DatabaseClient.Todos(
        delete: { try await storage.delete(id: $0) },
        fetch: { try await storage.fetch(request: $0) },
        fetchOne: { try await storage.fetchOne(id: $0) },
        insert: { try await storage.insert(request: $0) },
        update: { try await storage.update(id: $0, request: $1) }
      )
    )
  }
  
  static var testValue: DatabaseClient {
    Self.init(
      todos: DatabaseClient.Todos(
        delete: unimplemented(),
        fetch: unimplemented(placeholder: []),
        fetchOne: unimplemented(placeholder: nil),
        insert: unimplemented(placeholder: TodoModel.mocks[0]),
        update: unimplemented(placeholder: TodoModel.mocks[0])
      )
    )
  }
  
 
}

fileprivate enum Table: String, TableRepresentable {
  case todos
}

fileprivate enum TodoColumn: String, ColumnRepresentable {
  case complete
}

// MARK: - Mock Helpers
extension DatabaseClient.Todos.FetchRequest: FetchRequestConvertible {
  typealias ID = TodoModel.ID
  
  func fetch(
    from values: IdentifiedArray<TodoModel.ID, TodoModel>
  ) -> IdentifiedArray<TodoModel.ID, TodoModel> {
    switch self {
    case .all:
      return values
    case let .filtered(by: filter):
      return values.filter { $0.isComplete == (filter == .complete ? true : false) }
    }
  }
}

extension DatabaseClient.Todos.InsertRequest: InsertRequestConvertible {
  typealias ID = TodoModel.ID
  
  func transform() -> TodoModel {
    @Dependency(\.uuid) var uuid;
    return .init(id: uuid(), description: description, isComplete: complete)
  }
}

extension DatabaseClient.Todos.UpdateRequest: UpdateRequestConvertible {
  typealias ID = TodoModel.ID
  
  func apply(to state: inout TodoModel) {
    if let description {
      state.description = description
    }
    if let complete {
      state.isComplete = complete
    }
  }
}
