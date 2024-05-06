import CasePaths
import CustomDump
import Dependencies
import IdentifiedCollections
import Supabase
import SupabaseDependencies
import XCTest

final class DatabaseClientIntegrationTests: XCTestCase {

  let postgrestClient = supabaseClient.schema("public")

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
      .from("todos")
      .delete(returning: .minimal)
      .eq("complete", value: true)
      .execute()

    try await postgrestClient
      .from("todos")
      .delete(returning: .minimal)
      .eq("complete", value: false)
      .execute()
  }

  public func testIntegration() async throws {
    @Dependency(\.router.todos) var router;

    var todos: IdentifiedArrayOf<Todo> = try await router(.fetch())
    XCTAssertEqual(todos, [])

    let insertedTodo: Todo = try await router(.insert(
      TodoInsertRequest(description: "Implement integration tests for supabase-client-dependency.")
    ))

    todos = try await router(.fetch)
    XCTAssertEqual(todos, [insertedTodo])

    let insertedTodos: [Todo] = try await router(.insert(
      [
        TodoInsertRequest(description: "Make supabase-client-dependency production ready."),
        TodoInsertRequest(description: "Drink some coffee.", isComplete: true)
      ]
    ))

    todos = try await router(.fetch())
    XCTAssertEqual(todos, [insertedTodo] + insertedTodos)

    let orderedTodos: [Todo] = try await router(.fetch(
      orderedBy: .ascending(.description)
    ))
    XCTAssertEqual(
      orderedTodos,
      [
        insertedTodos[1],
        insertedTodo,
        insertedTodos[0]
      ]
    )

    let drinkCoffeeTodo = insertedTodos[1]
    let fetchOneTodo: Todo = try await router(.fetchOne(
      id: drinkCoffeeTodo.id
    ))
    XCTAssertEqual(drinkCoffeeTodo, fetchOneTodo)

    let updatedTodo: Todo = try await router(.update(
      id: drinkCoffeeTodo.id,
      updates: TodoUpdateRequest(isComplete: true)
    ))
    XCTAssertEqual(updatedTodo.isComplete, true)

    let completedTodos: [Todo] = try await router(.fetch(
      filteredBy: .equals(column: .isComplete, value: true)
    ))
    XCTAssertEqual(completedTodos, [updatedTodo])

    try await router(.delete(
      filteredBy: [
        .equals(column: .isComplete, value: true)
      ]
    ))
    todos = try await router(.fetch())
    XCTAssertTrue(completedTodos.allSatisfy { todo in !todos.contains(todo) })

    let firstTodo = todos.first!
    try await router(.delete(id: firstTodo.id))
  }

}
