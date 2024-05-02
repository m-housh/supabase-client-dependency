import CasePaths
import XCTest
import DatabaseExtensions
import DatabaseRouter
import Dependencies
import IdentifiedCollections
import SupabaseClientDependencies

final class DatabaseClientIntegrationTests: XCTestCase {

  let postgrestClient = SupabaseClient.local().schema("public")

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
    let client = SupabaseClientDependency<DbRoutes>.live(client: .local())
    let database = client.client.schema("public")
    withDependencies {
      $0.supabaseClient = client
      $0.databaseExecutor = .live(database: database)
    } operation: {
      super.invokeTest()
    }
  }

  public func testIntegration() async throws {
    @Dependency(\.supabaseClient) var database;

    var todos: IdentifiedArrayOf<Todo> = try await database.from(.todos).fetch().execute().value
    XCTAssertEqual(todos, [])

    let insertedTodo: Todo = try await database.from(.todos).insert(
      TodoInsertRequest(description: "Implement integration tests for supabase-client-dependency.")
    )
    .execute()
    .value

    todos = try await database.from(.todos).fetch().execute().value
    XCTAssertEqual(todos, [insertedTodo])

    let insertedTodos: [Todo] = try await database.from(.todos).insert(
      [
        TodoInsertRequest(description: "Make supabase-client-dependency production ready."),
        TodoInsertRequest(description: "Drink some coffee.")
      ]
    ).execute().value

    todos = try await database.from(.todos).fetch().execute().value
    XCTAssertEqual(todos, [insertedTodo] + insertedTodos)

    let orderedTodos: [Todo] = try await database.from(.todos).fetch(
      orderBy: TodoColumn.description.ascending()
    ).execute().value
    XCTAssertEqual(
      orderedTodos,
      [
        insertedTodos[1],
        insertedTodo,
        insertedTodos[0]
      ]
    )

    let drinkCoffeeTodo = insertedTodos[1]
    let fetchOneTodo: Todo = try await database.from(.todos).fetchOne(
      id: drinkCoffeeTodo.id
    ).execute().value
    XCTAssertEqual(drinkCoffeeTodo, fetchOneTodo)

    let updatedTodo: Todo = try await database.from(.todos).update(
      id: drinkCoffeeTodo.id,
      with: TodoUpdateRequest(isComplete: true)
    ).execute().value
    XCTAssertEqual(updatedTodo.isComplete, true)

    let completedTodos: [Todo] = try await database.from(.todos).fetch(
      filteredBy: TodoColumn.isComplete.equals(true)
    ).execute().value
    XCTAssertEqual(completedTodos, [updatedTodo])

    try await database.from(.todos).delete(
      filteredBy: TodoColumn.isComplete.equals(true)
    ).execute().value
    todos = try await database.from(.todos).fetch().execute().value
    XCTAssertTrue(completedTodos.allSatisfy { todo in !todos.contains(todo) })

    let firstTodo = todos.first!
    try await database.from(.todos).delete(id: firstTodo.id).execute().value
  }

  public func testDatabaseRouter() async throws {
    @Dependency(\.supabaseClient.router) var router;
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
    todos = try await router(.todos(.fetch))
    XCTAssertTrue(completedTodos.allSatisfy { todo in !todos.contains(todo) })

    let firstTodo = todos.first!
    try await todosRouter(.delete(id: firstTodo.id))
//    try await database.delete(id: firstTodo.id, from: AnyTable.todos)
  }

  func testOverrides() async throws {
    let mocks = withDependencies {
      $0.date.now = .init(timeIntervalSince1970: 1234567890)
    } operation: {
      Todo.mocks
    }

    try await withDependencies {
      $0.router.override(.todos(.fetch), with: mocks)
    } operation: {
      @Dependency(\.router) var router
      let sut: [Todo] = try await router(.todos(.fetch))
      XCTAssertEqual(sut, mocks)
    }
  }

}
