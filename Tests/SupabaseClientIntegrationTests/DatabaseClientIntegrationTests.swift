import CasePaths
import XCTest
import DatabaseRouter
import Dependencies
import IdentifiedCollections
import SupabaseClientDependencies

final class DatabaseClientIntegrationTests: XCTestCase {

  let postgrestClient = SupabaseClient(configuration: .local).schema("public")

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
    let client = SupabaseClientDependency.live(configuration: .local)
    withDependencies {
      $0.supabaseClient = client
      $0.databaseExecutor = .live(database: client.database)
    } operation: {
      super.invokeTest()
    }
  }

  public func testIntegration() async throws {
    @Dependency(\.supabaseClient.database) var database;

    var todos: IdentifiedArrayOf<Todo> = try await database.fetch(
      from: .todos,
      decoding: IdentifiedArrayOf<Todo>.self
    )
    XCTAssertEqual(todos, [])

    let insertedTodo: Todo = try await database.insert(
      TodoInsertRequest(description: "Implement integration tests for supabase-client-dependency."),
      into: .todos
    )

    todos = try await database.fetch(from: .todos)
    XCTAssertEqual(todos, [insertedTodo])

    let insertedTodos: [Todo] = try await database.insert(
      [
        TodoInsertRequest(description: "Make supabase-client-dependency production ready."),
        TodoInsertRequest(description: "Drink some coffee.")
      ],
      into: .todos
    )

    todos = try await database.fetch(from: .todos)
    XCTAssertEqual(todos, [insertedTodo] + insertedTodos)

    let orderedTodos: [Todo] = try await database.fetch(
      from: .todos,
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
      from: .todos
    )
    XCTAssertEqual(drinkCoffeeTodo, fetchOneTodo)

    let updatedTodo: Todo = try await database.update(
      id: drinkCoffeeTodo.id,
      in: .todos,
      with: TodoUpdateRequest(isComplete: true)
    )
    XCTAssertEqual(updatedTodo.isComplete, true)

    let completedTodos: [Todo] = try await database.fetch(
      from: .todos,
      filteredBy: TodoColumn.isComplete.equals(true)
    )
    XCTAssertEqual(completedTodos, [updatedTodo])

    try await database.delete(
      from: .todos,
      filteredBy: TodoColumn.isComplete.equals(true)
    )
    todos = try await database.fetch(from: .todos)
    XCTAssertTrue(completedTodos.allSatisfy { todo in !todos.contains(todo) })

    let firstTodo = todos.first!
    try await database.delete(id: firstTodo.id, from: AnyTable.todos)
  }

  public func testDatabaseRouter() async throws {
    @Dependency(\.supabaseClient.database) var database;
    @Dependency(\.router) var router
    @Dependency(\.router.todos) var todosRouter

    var todos: IdentifiedArrayOf<Todo> = try await router(.todos(.fetch))
    XCTAssertEqual(todos, [])
    
    todos = try await todosRouter(.fetch)
    XCTAssertEqual(todos, [])

    todos = try await router(.todos(.fetch()))
    XCTAssertEqual(todos, [])

    let insertedTodo: Todo = try await router(.todos(.insert(
        TodoInsertRequest(
          description: "Implement integration test for supabase-client-dependencies"
        )
    )))
    todos = try await todosRouter(.fetch)
    XCTAssertEqual(todos, [insertedTodo])
    let insertedTodos: [Todo] = try await router(.todos(.insert(
      [
        TodoInsertRequest(description: "Make supabase-client-dependency production ready."),
        TodoInsertRequest(description: "Drink some coffee.")
      ]
    )))

    todos = try await todosRouter(.fetch)
    XCTAssertEqual(todos, [insertedTodo] + insertedTodos)

    let orderedTodos: [Todo] = try await router(.todos(.fetch(
      orderedBy: TodoColumn.description.ascending()
    )))
    XCTAssertEqual(
      orderedTodos,
      [
        insertedTodos[1],
        insertedTodo,
        insertedTodos[0]
      ]
    )

    let drinkCoffeeTodo = insertedTodos[1]
    let fetchOneTodo: Todo = try await router(.todos(.fetchOne(
      id: drinkCoffeeTodo.id
    )))
    XCTAssertEqual(drinkCoffeeTodo, fetchOneTodo)
    
//    let fetchOneKp = \DbRoutes.Cases.todos.fetchOne
//    let q = fetchOneKp(drinkCoffeeTodo.id)
    
    let updatedTodo: Todo = try await todosRouter(.update(
      id: drinkCoffeeTodo.id,
      updates: TodoUpdateRequest(isComplete: true)
    ))
    XCTAssertEqual(updatedTodo.isComplete, true)

    let completedTodos: [Todo] = try await todosRouter(.fetch(
      filteredBy: TodoColumn.isComplete.equals(true)
    ))
    XCTAssertEqual(completedTodos, [updatedTodo])

    try await router(.todos(.delete(TodoColumn.isComplete.equals(true))))
    todos = try await database.fetch(from: .todos)
    XCTAssertTrue(completedTodos.allSatisfy { todo in !todos.contains(todo) })

    let firstTodo = todos.first!
    try await database.delete(id: firstTodo.id, from: AnyTable.todos)
  }

}
