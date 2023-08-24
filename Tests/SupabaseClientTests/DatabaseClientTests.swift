import XCTest
import Dependencies
@testable import SupabaseClientDependencies

@MainActor
final class DatabaseClientTests: XCTestCase {

  let postgrestClient = PostgrestClient(
    url: URL(string: "http://localhost:54321/rest/v1")!,
    headers: [
      "apiKey": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0"
    ],
    schema: "public"
  )

  override func setUp() async throws {
    try await super.setUp()

    try XCTSkipUnless(
      ProcessInfo.processInfo.environment["INTEGRATION_TESTS"] != nil,
      "INTEGRATION_TESTS not defined."
    )

    // Delete all the todos before running tests.

    // Kind of hacky, as the delete items need a where clause, so we just
    // delete all the todos that are complete, then delete all the ones that
    // are not complete.
    try await postgrestClient
      .from(Table.todos.tableName)
      .delete(returning: .minimal)
      .eq(column: "complete", value: true)
      .execute()

    try await postgrestClient
      .from(Table.todos.tableName)
      .delete(returning: .minimal)
      .eq(column: "complete", value: false)
      .execute()
  }

  override func invokeTest() {
    withDependencies {
      $0.supabaseClient.database = .live(
        client: postgrestClient
      )
    } operation: {
      super.invokeTest()
    }
  }

  public func testIntegration() async throws {
    @Dependency(\.supabaseClient.database) var database;

    var todos: [Todo] = try await database.fetch(from: Table.todos)
    XCTAssertEqual(todos, [])

    let insertedTodo: Todo = try await database.insert(
      NewTodo(description: "Implement integration tests for supabase-client-dependency."),
      into: Table.todos
    )

    todos = try await database.fetch(from: Table.todos)
    XCTAssertEqual(todos, [insertedTodo])

    let insertedTodos: [Todo] = try await database.insert(
      [
        NewTodo(description: "Make supabase-client-dependency production ready."),
        NewTodo(description: "Drink some coffee.")
      ],
      into: Table.todos
    )

    todos = try await database.fetch(from: Table.todos)
    XCTAssertEqual(todos, [insertedTodo] + insertedTodos)

    let orderedTodos: [Todo] = try await database.fetch(
      from: Table.todos,
      orderBy: TodoColumn.description.ascending()
    )
    XCTAssertEqual(
      orderedTodos,
      [
        insertedTodos[1],
        insertedTodo,
        insertedTodos[0]
      ]
    )

    let drinkCoffeeTodo = insertedTodos[1]
    let fetchOneTodo: Todo = try await database.fetchOne(
      id: drinkCoffeeTodo.id,
      from: Table.todos
    )
    XCTAssertEqual(drinkCoffeeTodo, fetchOneTodo)

    let updatedTodo: Todo = try await database.update(
      id: drinkCoffeeTodo.id,
      in: Table.todos,
      with: ["complete": true]
    )
    XCTAssertEqual(updatedTodo.isComplete, true)

    let completedTodos: [Todo] = try await database.fetch(
      from: Table.todos,
      filteredBy: TodoColumn.isComplete.equals(true)
    )
    XCTAssertEqual(completedTodos, [updatedTodo])

    try await database.delete(
      from: Table.todos,
      filteredBy: TodoColumn.isComplete.equals(true)
    )
    todos = try await database.fetch(from: Table.todos)
    XCTAssertTrue(completedTodos.allSatisfy { todo in !todos.contains(todo) })

    let firstTodo = todos.first!
    try await database.delete(id: firstTodo.id, from: Table.todos)
  }
}

enum Table: String, TableRepresentable {
  case todos
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

  enum CodingKeys: String, CodingKey {
    case id
    case description
    case isComplete = "complete"
    case createdAt = "created_at"
  }
}

struct NewTodo: Codable, Hashable {
  let description: String
  let isComplete: Bool = false

  enum CodingKeys: String, CodingKey {
    case description
    case isComplete = "complete"
  }
}
