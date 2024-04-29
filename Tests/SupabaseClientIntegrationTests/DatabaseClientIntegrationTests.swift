import XCTest
import Dependencies
import IdentifiedCollections
import SupabaseClientDependencies

final class DatabaseClientIntegrationTests: XCTestCase {

  let postgrestClient = PostgrestClient(configuration: .local, schema: "public")

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
      .from(AnyTable.todos.tableName)
      .delete(returning: .minimal)
      .eq("complete", value: true)
      .execute()

    try await postgrestClient
      .from(AnyTable.todos.tableName)
      .delete(returning: .minimal)
      .eq("complete", value: false)
      .execute()
  }

  override func invokeTest() {
    withDependencies {
      $0.supabaseClient = .live(configuration: .local)
    } operation: {
      super.invokeTest()
    }
  }

  public func testIntegration() async throws {
    @Dependency(\.supabaseClient) var client;
    let database = client.database(schema: "public")

    var todos: IdentifiedArrayOf<Todo> = try await database.fetch(from: AnyTable.todos)
    XCTAssertEqual(todos, [])

    let insertedTodo: Todo = try await database.insert(
      TodoInsertRequest(description: "Implement integration tests for supabase-client-dependency."),
      into: AnyTable.todos
    )

    todos = try await database.fetch(from: AnyTable.todos)
    XCTAssertEqual(todos, [insertedTodo])

    let insertedTodos: [Todo] = try await database.insert(
      [
        TodoInsertRequest(description: "Make supabase-client-dependency production ready."),
        TodoInsertRequest(description: "Drink some coffee.")
      ],
      into: AnyTable.todos
    )

    todos = try await database.fetch(from: AnyTable.todos)
    XCTAssertEqual(todos, [insertedTodo] + insertedTodos)

    let orderedTodos: [Todo] = try await database.fetch(
      from: AnyTable.todos,
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
      from: AnyTable.todos
    )
    XCTAssertEqual(drinkCoffeeTodo, fetchOneTodo)

    let updatedTodo: Todo = try await database.update(
      id: drinkCoffeeTodo.id,
      in: AnyTable.todos,
      with: TodoUpdateRequest(isComplete: true)
    )
    XCTAssertEqual(updatedTodo.isComplete, true)

    let completedTodos: [Todo] = try await database.fetch(
      from: AnyTable.todos,
      filteredBy: TodoColumn.isComplete.equals(true)
    )
    XCTAssertEqual(completedTodos, [updatedTodo])

    try await database.delete(
      from: .todos,
      filteredBy: TodoColumn.isComplete.equals(true)
    )
    todos = try await database.fetch(from: AnyTable.todos)
    XCTAssertTrue(completedTodos.allSatisfy { todo in !todos.contains(todo) })

    let firstTodo = todos.first!
    try await database.delete(id: firstTodo.id, from: AnyTable.todos)
  }
}
