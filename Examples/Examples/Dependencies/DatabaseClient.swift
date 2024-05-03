import CasePaths
import Dependencies
import Foundation
import IdentifiedStorage
import SupabaseClientDependencies
import XCTestDynamicOverlay

extension DependencyValues {
  var database: DatabaseRoutes {
    get { self[DatabaseRoutes.self] }
    set { self[DatabaseRoutes.self] = newValue }
  }
}

struct DatabaseRoutes {

  var todos: DBRouter<TodoRoute>

  enum TodoRoute: RouteController {
    case delete(id: TodoModel.ID)
    case fetch
    case insert(InsertRequest)
    case update(id: TodoModel.ID, updates: UpdateRequest)


    func route() async throws -> DatabaseRoute {
      @Dependency(\.auth) var auth

      switch self {
      case let .delete(id: id):
        return .delete(id: id, from: .todos)
      case .fetch:
        return .fetch(from: .todos)
      case let .insert(request):

        // A helper type that includes the authenticated user's
        // id as the owner of the todo in the database, which is
        // required by the row level security.
        //
        // This allows this implementation detail to be hidden away
        // from the user and requires that the user is authenticated
        // when inserting a todo.
        struct InsertValues: Codable {
          let complete: Bool
          let description: String
          let ownerId: UUID

          enum CodingKeys: String, CodingKey {
            case complete
            case description
            case ownerId = "owner_id"
          }
        }

        return try await .insert(
          InsertValues(
            complete: request.complete,
            description: request.description,
            ownerId: auth.requireCurrentUser().id
          ),
          into: AnyTable.todos
        )

      case let .update(id: id, updates: updates):
        return try .update(id: id, in: .todos, with: updates)
      }
    }

    struct InsertRequest {
      var description: String
      var complete: Bool
    }
    
    struct UpdateRequest: Codable {
      var description: String?
      var complete: Bool?
      
      var hasChanges: Bool {
        description != nil || complete != nil
      }
    }
  }
}

extension DatabaseRoutes: TestDependencyKey {
  static var testValue: DatabaseRoutes { .init(todos: .testValue) }
  static var previewValue: DatabaseRoutes {
    let todos = IdentifiedStorageOf<TodoModel>(initialValues: TodoModel.mocks)

    return .init(
      todos: .init(
        decoder: JSONDecoder(),
        encoder: JSONEncoder(),
        execute: { route in
          switch route {
          case let .delete(id: id):
              return .void { try await todos.delete(id: id) }
          case .fetch:
            return .data { try await todos.fetch() }
          case let .insert(todo):
            return .data { try await todos.insert(request: todo) }
          case let .update(id: id, updates: updates):
            return .data { try await todos.update(id: id, request: updates) }
          }
        }
      )
    )
  }
}



//extension DatabaseClient: DependencyKey {
//  
//  static var liveValue: Self {
//    @Dependency(\.supabaseClient) var client;
//    let database = client.database
//    return Self.init(
//      todos: DatabaseClient.Todos(
//        delete: { try await database.delete(id: $0, from: .todos) },
//        fetch: {
//          
//          // get the current authenticated user.
//          let user = try await client.auth.requireCurrentUser()
//          
//          // Return the todos.
//          return try await database.fetch(
//            from: AnyTable.todos,
////            filteredBy: TodoColumn.ownerId.equals(user.id),
//            filteredBy: .ownerId(equals: user.id),
//            orderBy: .complete
//          )
//        },
//        insert: { request in
//
//          // A helper type that includes the authenticated user's
//          // id as the owner of the todo in the database, which is
//          // required by the row level security.
//          //
//          // This allows this implementation detail to be hidden away
//          // from the user and requires that the user is authenticated
//          // when inserting a todo.
//          struct InsertValues: Encodable {
//            let complete: Bool
//            let description: String
//            let ownerId: UUID
//            
//            enum CodingKeys: String, CodingKey {
//              case complete
//              case description
//              case ownerId = "owner_id"
//            }
//          }
//          
//          return try await database.insert(
//            InsertValues(
//              complete: request.complete,
//              description: request.description,
//              ownerId: client.auth.requireCurrentUser().id
//            ),
//            into: AnyTable.todos
//          )
//        },
//        update: { try await database.update(id: $0, in: AnyTable.todos, with: $1) }
//      )
//    )
//  }
//  
//  
//  static var previewValue: DatabaseClient {
//    let storage = IdentifiedStorageOf<TodoModel>(initialValues: TodoModel.mocks)
//    
//    return Self.init(
//      todos: DatabaseClient.Todos(
//        delete: { try await storage.delete(id: $0) },
//        fetch: { try await storage.fetch() },
//        insert: { try await storage.insert(request: $0) },
//        update: { try await storage.update(id: $0, request: $1) }
//      )
//    )
//  }
//  
//  static var testValue: DatabaseClient {
//    Self.init(
//      todos: DatabaseClient.Todos(
//        delete: unimplemented(),
//        fetch: unimplemented(placeholder: []),
//        insert: unimplemented(placeholder: TodoModel.mocks[0]),
//        update: unimplemented(placeholder: TodoModel.mocks[0])
//      )
//    )
//  }
//  
// 
//}

extension AnyTable {
  static let todos = Self.init("todos")
}

fileprivate enum TodoColumn: String, ColumnRepresentable {
  case complete
  case ownerId = "owner_id"
}

extension DatabaseFilter {
  static func ownerId(equals value: User.ID) -> Self {
    .equals(column: TodoColumn.ownerId, value: value)
  }
}

extension DatabaseOrder {
  static var complete: Self { .init(column: TodoColumn.complete, ascending: true) }
}

extension DatabaseRoutes.TodoRoute.InsertRequest: InsertRequestConvertible {
  typealias ID = TodoModel.ID
  
  func transform() -> TodoModel {
    @Dependency(\.uuid) var uuid;
    return .init(id: uuid(), description: description, isComplete: complete)
  }
}

extension DatabaseRoutes.TodoRoute.UpdateRequest: UpdateRequestConvertible {
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
