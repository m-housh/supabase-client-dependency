import CasePaths
import Dependencies
import Foundation
import SupabaseDependencies
import Supabase

extension DatabaseRoute.Table {
  static var todos: Self { .init("todos") }
}

extension DatabaseRoute.Column {
  static let description: Self = "description"
  static let isComplete: Self = "complete"
}

struct Todo: Codable, Hashable, Identifiable {
  let id: UUID
  var description: String
  var isComplete: Bool
  let createdAt: Date

  init(
    id: UUID,
    description: String,
    isComplete: Bool,
    createdAt: Date? = nil
  ) {
    @Dependency(\.date.now) var now;
    self.id = id
    self.description = description
    self.isComplete = isComplete
    self.createdAt = createdAt ?? now
  }

  enum CodingKeys: String, CodingKey {
    case id
    case description
    case isComplete = "complete"
    case createdAt = "created_at"
  }
}


extension Todo {
  static let buyMilk = Todo(
    id: UUID(0),
    description: "Buy milk",
    isComplete: Bool.random()
  )

  static let finishDocs = Todo(
    id: UUID(1),
    description: "Finish documentation",
    isComplete: Bool.random()
  )

  static let drinkCoffee = Todo(
    id: UUID(2),
    description: "Drink coffee",
    isComplete: Bool.random()
  )
  
  static func mocks(date: Date) -> [Todo] {
    withDependencies {
      $0.date = .constant(date)
    } operation: {
      [
        .buyMilk,
        .finishDocs,
        .drinkCoffee
      ]
    }
  }
}

struct TodoInsertRequest: Codable, Hashable {
  let description: String
  let isComplete: Bool = false

  enum CodingKeys: String, CodingKey {
    case description
    case isComplete = "complete"
  }
}

struct TodoUpdateRequest: Codable, Hashable {
  var description: String? = nil
  var isComplete: Bool? = nil

  enum CodingKeys: String, CodingKey {
    case description
    case isComplete = "complete"
  }
}

@CasePathable
enum TodoRoute: RouteCollection {
  static var table: DatabaseRoute.Table { DatabaseRoute.Table.todos }

  case delete(filteredBy: [DatabaseRoute.Filter])
  case fetch(filteredBy: [DatabaseRoute.Filter] = [], orderedBy: DatabaseRoute.Order?)
  case fetchOne(id: Todo.ID)
  case insert(InsertRequest)
  case update(id: Todo.ID, updates: TodoUpdateRequest)
  case upsert(Todo)

  public func route() throws -> DatabaseRoute {
    switch self {
    case let .delete(filters):
      return .delete(from: Self.table, filters: filters)
    case let .fetch(filters, order):
      return .fetch(from: Self.table, filters: filters, order: order)
    case .fetchOne(id: let id):
      return .fetchOne(from: Self.table, filteredBy: .id(id))
    case let .insert(request):
      switch request {
      case let .single(todo):
        return try .insert(todo, into: Self.table)
      case let .many(todos):
        return try .insert(todos, into: Self.table)
      }
    case .update(id: let id, updates: let updates):
      return try .update(id: id, in: Self.table, with: updates)
    case let .upsert(todo):
      return try .upsert(todo, in: Self.table)
    }
  }

  enum InsertRequest {
    case single(TodoInsertRequest)
    case many([TodoInsertRequest])
  }

  static func delete(_ filters: DatabaseRoute.Filter...) -> Self {
    .delete(filteredBy: filters)
  }

  static func delete(id: Todo.ID) -> Self {
    self.delete(.id(id))
  }

  static func insert(_ request: TodoInsertRequest) -> Self {
    .insert(.single(request))
  }

  static func insert(_ request: [TodoInsertRequest]) -> Self {
    .insert(.many(request))
  }

  static var fetch: Self { .fetch(filteredBy: [], orderedBy: nil) }

  static func fetch(
    filteredBy filters: DatabaseRoute.Filter...,
    orderedBy order: DatabaseRoute.Order? = nil
  ) -> Self {
    .fetch(filteredBy: filters, orderedBy: order)
  }
}

struct DbRoutes {

  var todos: DatabaseRouter<TodoRoute>
  
  init(database: PostgrestClient) {
    self.todos = .init(database: database)
  }

}

private let supabaseClient = SupabaseClient.local()
let localServiceRoleKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9." +
  "eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0." +
  "EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU"

extension DbRoutes: DependencyKey {
  
  static var testValue: DbRoutes { .init(database: supabaseClient.schema("public")) }
  static var liveValue: DbRoutes { .testValue }
}

extension DependencyValues {
  var router: DbRoutes {
    get { self[DbRoutes.self] }
    set { self[DbRoutes.self] = newValue }
  }
}

extension DependencyValues {
  var supabase: SupabaseDependency<TodoRoute> {
    get { self[SupabaseDependency<TodoRoute>.self] }
    set { self[SupabaseDependency<TodoRoute>.self] = newValue }
  }
}
