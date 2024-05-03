import XCTest
import Dependencies
@testable import DatabaseRouter
@testable import SupabaseClientDependencies

final class DatabaseClientTests: XCTestCase {

  override func invokeTest() {
    let supabase = SupabaseClientDependency<DbRoutes>.live(client: .local())
    withDependencies {
      $0.supabaseClient = supabase
      $0.databaseExecutor = .live(database: supabase.client.schema("public"))
    } operation: {
      super.invokeTest()
    }
  }

  func testOverrideMatching() async throws {
    let route = DatabaseRoute.delete(id: "foo", from: .todos)
    let override = AnyOverride.partial(table: .todos, method: .delete)
    let match = try await override.matches(route)
    XCTAssertTrue(match)
  }

  func testDeleteOverride() async throws {
    let mock = withDependencies {
      $0.date.now = Date(timeIntervalSince1970: 1234567890)
    } operation: {
      Todo.finishDocs
    }

    await withDependencies {
      $0.supabaseClient.router.override(.delete, in: .todos)
    } operation: {
      @Dependency(\.supabaseClient.router) var db
      @Dependency(\.supabaseClient.router.todos) var router;

      do {
        try await db(.todos(.delete(
          id: mock.id
        )))
        XCTAssert(true)
      } catch {
        XCTFail("\(error)")
      }

      do {
        try await router(.delete(id: mock.id))
        XCTAssert(true)
      } catch {
        XCTFail("\(error)")
      }
    }
  }

  func testFetchOverride() async throws {
    let mocks = withDependencies {
      $0.date.now = Date(timeIntervalSince1970: 1234567890)
    } operation: {
      Todo.mocks
    }

    try await withDependencies {
      $0.supabaseClient.router.override(
        .todos(.fetch),
        with: mocks
      )
    } operation: {
      @Dependency(\.supabaseClient.router) var db;
      @Dependency(\.supabaseClient.router.todos) var router;

      var todos: [Todo] = try await router(.fetch)
      XCTAssertEqual(todos, Todo.mocks)

      todos = []
      XCTAssertEqual(todos, [])

      todos = try await db(.todos(.fetch))
      XCTAssertEqual(todos, Todo.mocks)
    }
  }
  
  func testFetchOneOverride() async throws {
    let mock = withDependencies {
      $0.date.now = Date(timeIntervalSince1970: 1234567890)
    } operation: {
      Todo.finishDocs
    }

    try await withDependencies {
      $0.supabaseClient.router.override(.fetchOne, in: .todos, with: mock)
    } operation: {
      @Dependency(\.supabaseClient.router) var db;
      @Dependency(\.supabaseClient.router.todos) var router;
      var todo: Todo = try await router(.fetchOne(
        id: UUID(0)
      ))
      XCTAssertEqual(todo, Todo.finishDocs)
      XCTAssertNotEqual(todo.id, UUID(0))

      todo = try await db(.todos(.fetchOne(id: UUID())))
      XCTAssertEqual(todo, mock)
    }
  }
  
  func testInsertOverride() async throws {
    let mock = withDependencies {
      $0.date.now = Date(timeIntervalSince1970: 1234567890)
    } operation: {
      Todo.finishDocs
    }

    try await withDependencies {
      $0.supabaseClient.router.override(
        .insert,
        in: .todos,
        with: mock
      )
    } operation: {
      @Dependency(\.supabaseClient.router) var db;
      @Dependency(\.supabaseClient.router.todos) var router;

      var todo: Todo = try await db(.todos(.insert(
        TodoInsertRequest(description: "Insert new todo")
      )))
      XCTAssertEqual(todo, Todo.finishDocs)
      XCTAssertNotEqual(todo.description, "Insert new todo")

      todo = try await router(.insert(
        TodoInsertRequest(description: "Insert new todo")
      ))
      XCTAssertEqual(todo, Todo.finishDocs)
      XCTAssertNotEqual(todo.description, "Insert new todo")
    }
  }
  
  func testInsertManyOverride() async throws {
    let mocks = withDependencies {
      $0.date.now = Date(timeIntervalSince1970: 1234567890)
    } operation: {
      Todo.mocks
    }

    try await withDependencies {
      $0.supabaseClient.router.override(
        .insert,
        in: .todos,
        with: mocks
      )
    } operation: {
      @Dependency(\.supabaseClient.router) var db;
      @Dependency(\.supabaseClient.router.todos) var router;

      var todos: [Todo] = try await db(.todos(.insert(
        [
          TodoInsertRequest(description: "Insert new todo"),
          TodoInsertRequest(description: "Another new todo"),
        ]
      )))
      XCTAssertEqual(todos, Todo.mocks)

      todos = try await router(.insert(
        [
          TodoInsertRequest(description: "Insert new todo"),
          TodoInsertRequest(description: "Another new todo"),
        ]
      ))
      XCTAssertEqual(todos, Todo.mocks)
    }
  }
  
  func testUpdateOverride() async throws {
    let mock = withDependencies {
      $0.date.now = Date(timeIntervalSince1970: 1234567890)
    } operation: {
      Todo.finishDocs
    }

    try await withDependencies {
      $0.supabaseClient.router.override(
        .update,
        in: .todos,
        with: mock
      )
    } operation: {
      @Dependency(\.supabaseClient.router) var db;
      @Dependency(\.supabaseClient.router.todos) var router;
      var todo: Todo = try await db(.todos(.update(
        id: UUID(0),
        updates: TodoUpdateRequest(description: "Buy milk & eggs")
      )))
      XCTAssertEqual(todo, Todo.finishDocs)

      todo = try await router(.update(
        id: UUID(0),
        updates: TodoUpdateRequest(description: "Buy milk & eggs")
      ))
      XCTAssertEqual(todo, Todo.finishDocs)

    }
  }
  
  func testUpsertOverride() async throws {
    let mock = withDependencies {
      $0.date.now = Date(timeIntervalSince1970: 1234567890)
    } operation: {
      Todo.finishDocs
    }

    try await withDependencies {
      $0.date.now = Date(timeIntervalSince1970: 1234567890)
      $0.supabaseClient.router.override(
        .upsert,
        in: .todos,
        with: mock
      )
    } operation: {
      @Dependency(\.supabaseClient.router) var db;
      @Dependency(\.supabaseClient.router.todos) var router;
      var todo: Todo = try await db(.todos(.upsert(
        Todo(
          id: .init(),
          description: "New todo",
          isComplete: false
        )
      )))
      XCTAssertEqual(todo, mock)

      todo = try await router(.upsert(
        Todo(
          id: .init(),
          description: "New todo",
          isComplete: false
        )
      ))
      XCTAssertEqual(todo, mock)

    }
  }
}
