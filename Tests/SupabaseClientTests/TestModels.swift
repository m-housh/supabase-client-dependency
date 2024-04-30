import Dependencies
import Foundation
import SupabaseClientDependencies

extension AnyTable {
  static let todos = Self("todos")
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

enum TodoRoute {
  static let table = AnyTable.todos
  
  case delete(id: Todo.ID)
  case fetch
  case fetchOne(id: Todo.ID)
  case insert(TodoInsertRequest)
  case update(id: Todo.ID, updates: TodoUpdateRequest)
  case upsert(Todo)

  var builder: (PostgrestQueryBuilder) throws -> PostgrestBuilder {
    return { query in
      switch self {
      case .delete(id: let id):
        return query.delete().filter(by: .id(id))
      case .fetch:
        return query.select()
      case .fetchOne(id: let id):
        return query.select().filter(by: .id(id)).single()
      case let .insert(todo):
        return try query.insert(todo)
      case .update(id: let id, updates: let updates):
        return try query.update(updates).filter(by: .id(id))
      case let .upsert(todo):
        return try query.upsert(todo)
      }
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
