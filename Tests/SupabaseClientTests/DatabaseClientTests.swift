import XCTest
import CasePaths
import Dependencies
@testable import DatabaseRouter
@testable import SupabaseClientDependencies

final class DatabaseClientTests: XCTestCase {

//  override func invokeTest() {
//    let supabase = SupabaseClientDependency<DbRoutes>.live(client: .local())
//    withDependencies {
//      $0.supabaseClient = supabase
////      $0.databaseExecutor = .live(database: supabase.client.schema("public"))
//    } operation: {
//      super.invokeTest()
//    }
//  }

//  func testOverrideMatching() async throws {
//    let route = DatabaseRoute.delete(id: "foo", from: .todos)
//    let override = AnyOverride.partial(table: .todos, method: .delete)
//    let match = try await override.matches(route)
//    XCTAssertTrue(match)
//  }

  func testDeleteOverride() async throws {
    let mock = withDependencies {
      $0.date.now = Date(timeIntervalSince1970: 1234567890)
    } operation: {
      Todo.finishDocs
    }

    await withDependencies {
      $0.router.todos.override(.method(.delete))
    } operation: {
      @Dependency(\.router.todos) var router;
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
      $0.router.todos.override(
        .method(.fetch),
        with: mocks
      )
    } operation: {
      @Dependency(\.router.todos) var router;

      var todos: [Todo] = try await router(.fetch)
      XCTAssertEqual(todos, Todo.mocks)

      todos = []
      XCTAssertEqual(todos, [])
    }
  }
  
  func testFetchOneOverride() async throws {
    let mock = withDependencies {
      $0.date.now = Date(timeIntervalSince1970: 1234567890)
    } operation: {
      Todo.finishDocs
    }

    try await withDependencies {
      $0.router.todos.override(.method(.fetchOne), with: mock)
    } operation: {
      @Dependency(\.router.todos) var router;
      let todo: Todo = try await router(.fetchOne(
        id: UUID(0)
      ))
      XCTAssertEqual(todo, Todo.finishDocs)
      XCTAssertNotEqual(todo.id, UUID(0))
    }
  }
  
  func testInsertOverride() async throws {
    let mock = withDependencies {
      $0.date.now = Date(timeIntervalSince1970: 1234567890)
    } operation: {
      Todo.finishDocs
    }

    try await withDependencies {
      $0.router.todos.override(.method(.insert), with: mock)
    } operation: {
      @Dependency(\.router.todos) var router;

      let todo: Todo = try await router(.insert(
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
      $0.router.todos.override(
        .method(.insert),
        with: mocks
      )
    } operation: {
      @Dependency(\.router.todos) var router;

      let todos: [Todo] = try await router(.insert(
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
      $0.router.todos.override(
        .method(.update),
        with: mock
      )
    } operation: {
      @Dependency(\.router.todos) var router;

      let todo: Todo = try await router(.update(
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
      $0.router.todos.override(
        .method(.upsert),
        with: mock
      )
    } operation: {
      @Dependency(\.router.todos) var router;

      let todo: Todo = try await router(.upsert(
        Todo(
          id: .init(),
          description: "New todo",
          isComplete: false
        )
      ))
      XCTAssertEqual(todo, mock)

    }
  }
//  
//  func testTableOverride() async throws {
//    var overrideNoTable = DatabaseRouter<TodoRoute>.Override.id("foo")
//    var match = try await overrideNoTable.match(.update(id: 1, in: "bar", with: Data(), routeId: "foo"))
//    XCTAssertTrue(match)
//    
//    overrideNoTable = .method(.update, nil)
//    match = try await overrideNoTable.match(.update(id: 1, in: "bar", with: Data(), routeId: "foo"))
//    XCTAssertTrue(match)
//    
//    var overrideWithTable = DatabaseRouter<TodoRoute>.Override.id("foo", "baz")
//    match = try await overrideWithTable.match(.update(id: 1, in: "bar", with: Data(), routeId: "foo"))
//    XCTAssertFalse(match)
//    
//    overrideWithTable = .method(.update, "baz")
//    match = try await overrideWithTable.match(.update(id: 1, in: "bar", with: Data(), routeId: "foo"))
//    XCTAssertFalse(match)
//  }
  
  func testCaseOverride() async throws {
    
    let todoMocks = withDependencies {
      $0.date.now = Date(timeIntervalSince1970: 1234567890)
    } operation: {
      Todo.mocks
    }
    
    var router = DatabaseRouter<MultiRouter>.init(
      decoder: .init(),
      encoder: .init(),
      execute: { _ in try JSONEncoder().encode(todoMocks) }
    )
    router.override(.case(\.todos.fetch), with: .success([Todo]()))
    
    var todos: [Todo] = try await router(.todos(.fetch))
    XCTAssertEqual(todos, [])
    
    todos = try await router(.alsoTodos(.fetch))
    XCTAssertEqual(todos, todoMocks)
    
    let override = DatabaseRouter<MultiRouter>.Override.case(\.todos.delete)
    var match = try await override.match(.todos(.delete(id: .init())))
    XCTAssertTrue(match)
    
    match = try await override.match(.alsoTodos(.delete(id: .init())))
    XCTAssertFalse(match)

  }
}

@CasePathable
enum MultiRouter: RouteCollection {
  case todos(TodoRoute)
  case alsoTodos(TodoRoute)
  
  func route() throws -> DatabaseRoute {
    switch self {
    case let .todos(todos):
      return try todos.route()
    case let .alsoTodos(todos):
      return try todos.route()
    }
  }
  }
