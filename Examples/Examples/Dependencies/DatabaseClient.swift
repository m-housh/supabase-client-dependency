import Dependencies
import Foundation
import IdentifiedStorage
import SupabaseClientDependencies
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
    var fetch: () async throws -> IdentifiedArrayOf<TodoModel>
    var insert: (InsertRequest) async throws -> TodoModel
    var update: (TodoModel.ID, UpdateRequest) async throws -> TodoModel
   
    struct InsertRequest: Encodable {
      var description: String
      var complete: Bool
    }
    
    struct UpdateRequest: Encodable {
      var description: String?
      var complete: Bool?
      
      var hasChanges: Bool {
        description != nil || complete != nil
      }
    }
  }
}

extension DatabaseClient: DependencyKey {
  
  static var liveValue: Self {
    @Dependency(\.supabaseClient) var client;
    let database = client.database()
    return Self.init(
      todos: DatabaseClient.Todos(
        delete: { try await database.delete(id: $0, from: .todos) },
        fetch: {
          
          // get the current authenticated user.
          let user = try await client.auth.requireCurrentUser()
          
          // Return the todos.
          return try await database.fetch(
            from: AnyTable.todos,
            filteredBy: TodoColumn.ownerId.equals(user.id),
            orderBy: TodoColumn.complete.ascending()
          )
        },
        insert: { request in
          
          // A helper type that includes the authenticated user's
          // id as the owner of the todo in the database, which is
          // required by the row level security.
          //
          // This allows this implementation detail to be hidden away
          // from the user and requires that the user is authenticated
          // when inserting a todo.
          struct InsertValues: Encodable {
            let complete: Bool
            let description: String
            let ownerId: UUID
            
            enum CodingKeys: String, CodingKey {
              case complete
              case description
              case ownerId = "owner_id"
            }
          }
          
          return try await database.insert(
            InsertValues(
              complete: request.complete,
              description: request.description,
              ownerId: client.auth.requireCurrentUser().id
            ),
            into: AnyTable.todos
          )
        },
        update: { try await database.update(id: $0, in: AnyTable.todos, with: $1) }
      )
    )
  }
  
  
  static var previewValue: DatabaseClient {
    let storage = IdentifiedStorageOf<TodoModel>(initialValues: TodoModel.mocks)
    
    return Self.init(
      todos: DatabaseClient.Todos(
        delete: { try await storage.delete(id: $0) },
        fetch: { try await storage.fetch() },
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
        insert: unimplemented(placeholder: TodoModel.mocks[0]),
        update: unimplemented(placeholder: TodoModel.mocks[0])
      )
    )
  }
  
 
}

//fileprivate enum Table: String, TableRepresentable {
//  case todos
//}
extension AnyTable {
  static let todos = Self.init("todos")
}

fileprivate enum TodoColumn: String, ColumnRepresentable {
  case complete
  case ownerId = "owner_id"
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
