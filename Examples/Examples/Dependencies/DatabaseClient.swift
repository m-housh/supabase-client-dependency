import Dependencies
import SupabaseClient
import Foundation
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
    var fetch: (FetchRequest) async throws -> [TodoModel]
    var fetchOne: (TodoModel.ID) async throws -> TodoModel?
    var insert: (InsertRequest) async throws -> TodoModel
    var update: (TodoModel.ID, UpdateRequest) async throws -> TodoModel
    
    func fetch() async throws -> [TodoModel] {
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

extension DatabaseClient: TestDependencyKey {
  
  static var testValue: DatabaseClient {
    .init(
      todos: .init(
        delete: unimplemented(),
        fetch: unimplemented(placeholder: [TodoModel]()),
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

extension DatabaseClient: DependencyKey {
  
  static var liveValue: DatabaseClient {
    @Dependency(\.supabaseClient) var client;
    
    return .init(
      todos: .init(
        delete: { try await client.delete(id: $0, from: Table.todos) },
        fetch: { request in
          switch request {
          case .all:
            return try await client.fetch(from: Table.todos)
          case let .filtered(by: filter):
            return try await client.fetch(
              from: Table.todos,
              filteredBy:  TodoColumn.complete.equals(filter == .complete ? true : false)
            )
          }
        },
        fetchOne: { try await client.fetchOne(id: $0, from: Table.todos) },
        insert: { try await client.insert(into: Table.todos, values: $0) },
        update: { try await client.update(id: $0, table: Table.todos, values: $1) }
      )
    )
  }
}
