import XCTest
import CasePaths
import Dependencies
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
    
//    var todosRouter = router[dynamicMember: \.todos]
//    
//    let cp = \MultiRouter.Cases.todos
//    
//    var fetchedThroughCasePathProxy: [Todo] = try await todosRouter(.fetch)
//    XCTAssertEqual(fetchedThroughCasePathProxy, [])
//    
//    todosRouter.router.override(.case(\.todos.fetch), with: todoMocks)
//    fetchedThroughCasePathProxy = try await todosRouter(.fetch)
//    XCTAssertEqual(fetchedThroughCasePathProxy, todoMocks)
// 
  }
  
  func testMultiRouter() async throws {
    let todoMocks = withDependencies {
      $0.date.now = Date(timeIntervalSince1970: 1234567890)
    } operation: {
      Todo.mocks
    }
    
    try await withDependencies {
      $0.multiRouter.override(
        .case(\.todos.fetch), 
        with: todoMocks
      )
      $0.multiRouter.override(
        .case(\.alsoTodos.fetch),
        with: [Todo]()
      )
      $0.multiRouter.override(
        .case(\.nested.todos.fetch),
        with: todoMocks
      )
    } operation: {
      @Dependency(\.multiRouter[case: \.todos]) var router
      let todos: [Todo] = try await router(.fetch)
      XCTAssertEqual(todos, todoMocks)
      
      @Dependency(\.multiRouter.todos) var todosRouter
      let todos2: [Todo] = try await todosRouter.call(.fetch)
      XCTAssertEqual(todos2, todoMocks)
      
      @Dependency(\.multiRouter.alsoTodos) var alsoTodos
      let todos3: [Todo] = try await alsoTodos(.fetch)
      XCTAssertEqual(todos3, [])
      
      @Dependency(\.multiRouter.nested.todos) var nestedTodos
      let todos4: [Todo] = try await nestedTodos(.fetch)
      XCTAssertEqual(todos4, todoMocks)

    }


  }
}

@CasePathable
enum Nested {
  case todos(TodoRoute)
}

@CasePathable
enum MultiRouter: RouteCollection {
  case todos(TodoRoute)
  case alsoTodos(TodoRoute)
  case nested(Nested)
  
  func route() async throws -> DatabaseRoute {
    switch self {
    case let .todos(todos):
      return try todos.route()
    case let .alsoTodos(todos):
      return try todos.route()
    case let .nested(.todos(todos)):
      return try todos.route()
    }
  }
}

struct MultiRouterKey: TestDependencyKey {
  
  var router: DatabaseRouter<MultiRouter>
  
  static var testValue: MultiRouterKey = .init(router: .init(
    decoder: .init(),
    encoder: .init(),
    execute: { _ in .success([Todo]()) }
  ))
}

extension DependencyValues {
  var multiRouter: DatabaseRouter<MultiRouter> {
    get { self[MultiRouterKey.self].router }
    set { self[MultiRouterKey.self].router = newValue }
  }
}
