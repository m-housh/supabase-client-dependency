import CasePaths
import CasePathsMacros
import Dependencies
import Foundation
import SupabaseClientDependencies

//enum Table: String, TableRepresentable {
//  case todos
//}
extension AnyTable {
  static var todos: Self { .init("todos") }
}

enum TodoColumn: String, ColumnRepresentable {
  case description
  case isComplete = "complete"
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

  static let mocks: [Todo] = [
    .buyMilk,
    .finishDocs,
    .drinkCoffee
  ]
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

protocol DatabaseRouter {
  func execute(on client: PostgrestClient) async throws

  @discardableResult
  func execute<A: Decodable>(on client: PostgrestClient) async throws -> A
}

struct QueryBuilder<Table> {
  let build: (PostgrestQueryBuilder, Table) throws -> PostgrestBuilder
}

protocol TableRouter {
  var table: AnyTable { get }
  var builder: QueryBuilder<Self> { get }
}

extension TableRouter {
  func execute(on client: PostgrestClient) async throws {
    try await builder.build(client.from(table.tableName), self).execute().value
  }

  @discardableResult
  func execute<A: Decodable>(on client: PostgrestClient) async throws -> A {
    try await builder.build(client.from(table.tableName), self).execute().value
  }
}

@CasePathable
enum TodoRoute: TableRouter {
  var table: AnyTable { AnyTable.todos }

  case delete(filteredBy: [DatabaseFilter])
  case fetch(filteredBy: [DatabaseFilter] = [], orderedBy: DatabaseOrder?)
  case fetchOne(id: Todo.ID)
  case insert(InsertRequest)
  case update(id: Todo.ID, updates: TodoUpdateRequest)
  case upsert(Todo)

  var builder: QueryBuilder<TodoRoute> {
    QueryBuilder { query, route in
      switch route {
      case let .delete(filters):
        return query.delete(filteredBy: filters)
      case let .fetch(filters, order):
        return query.fetch(filteredBy: filters, orderBy: order)
      case .fetchOne(id: let id):
        return query.fetchOne(filteredBy: .id(id))
      case let .insert(request):
        switch request {
        case let .single(todo):
          return try query.insert(todo, returning: .representation).single()
        case let .many(todos):
          return try query.insert(todos, returning: .representation)
        }
      case .update(id: let id, updates: let updates):
        return try query.update(id: id, with: updates)

      case let .upsert(todo):
        return try query.upsert(todo)
      }
    }
  }

  enum InsertRequest {
    case single(TodoInsertRequest)
    case many([TodoInsertRequest])
  }

  static func delete(_ filters: DatabaseFilter...) -> Self {
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
    filteredBy filters: DatabaseFilter...,
    orderedBy order: DatabaseOrder? = nil
  ) -> Self {
    .fetch(filteredBy: filters, orderedBy: order)
  }
}

@CasePathable
enum MyRouter: DatabaseRouter {
  case todos(TodoRoute)

  func execute(on client: PostgrestClient) async throws {
    switch self {
    case let .todos(route):
      return try await route.execute(on: client)
    }
  }

  @discardableResult
  func execute<A: Decodable>(on client: PostgrestClient) async throws -> A {
    switch self {
    case let .todos(route):
      return try await route.execute(on: client)
    }
  }
}

extension PostgrestClient {

  func execute<D: DatabaseRouter>(_ route: D) async throws {
    try await route.execute(on: self)
  }

  @discardableResult
  func execute<A: Decodable, D: DatabaseRouter>(
    _ route: D
  ) async throws -> A {
    return try await route.execute(on: self)
  }

  func execute(_ route: MyRouter) async throws {
    try await self.execute<MyRouter>(route)
  }

  @discardableResult
  func execute<A: Decodable>(
    _ route: MyRouter
  ) async throws -> A {
    try await self.execute<MyRouter>(route)
  }
}
