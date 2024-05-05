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

  var todos: DatabaseRouter<TodoRoute>

  enum TodoRoute: RouteCollection {
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
          into: DatabaseRoute.Table.todos
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
          // Overrides for preview mode.
          switch route {
          case let .delete(id: id):
              return await .init { try await todos.delete(id: id) }
          case .fetch:
            return await .init { try await todos.fetch() }
          case let .insert(todo):
            return await .init { try await todos.insert(request: todo) }
          case let .update(id: id, updates: updates):
            return await .init { try await todos.update(id: id, request: updates) }
          }
        }
      )
    )
  }
}

extension DatabaseRoute.Table {
  static let todos = Self.init("todos")
}

fileprivate enum TodoColumn: String, ColumnRepresentable {
  case complete
  case ownerId = "owner_id"
}

extension DatabaseRoute.Filter {
  static func ownerId(equals value: User.ID) -> Self {
    .equals(column: TodoColumn.ownerId, value: value)
  }
}

extension DatabaseRoute.Order {
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
