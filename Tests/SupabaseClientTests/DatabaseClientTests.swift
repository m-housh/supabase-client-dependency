import XCTest
import Dependencies
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

  func testDeleteOverride() async throws {
    let mock = withDependencies {
      $0.date.now = Date(timeIntervalSince1970: 1234567890)
    } operation: {
      Todo.finishDocs
    }

    await withDependencies {
      $0.supabaseClient.router.override(.delete, in: .todos)
    } operation: {
      @Dependency(\.supabaseClient.router.todos) var router;

      do {
        try await router(.delete(
          id: mock.id
        ))
        XCTAssert(true)
      } catch {
        XCTFail("\(error)")
      }
    }
  }

//  func testFetchOverride() async throws {
//    let mocks = withDependencies {
//      $0.date.now = Date(timeIntervalSince1970: 1234567890)
//    } operation: {
//      Todo.mocks
//    }
//
//    try await withDependencies {
//      $0.supabaseClient.override(
//        .fetch(from: .todos),
//        with: mocks
//      )
//    } operation: {
//      @Dependency(\.supabaseClient.database) var database;
//
//      let todos: [Todo] = try await database.fetch(
//        from: .todos
//      )
//      XCTAssertEqual(todos, Todo.mocks)
//    }
//  }
//  
//  func testFetchOneOverride() async throws {
//    let mock = withDependencies {
//      $0.date.now = Date(timeIntervalSince1970: 1234567890)
//    } operation: {
//      Todo.finishDocs
//    }
//
//    try await withDependencies {
//      $0.supabaseClient.override(.fetchOne(from: .todos), with: mock)
//    } operation: {
//      @Dependency(\.supabaseClient.database) var database;
//      let todo: Todo = try await database.fetchOne(
//        id: UUID(0),
//        from: .todos
//      )
//      XCTAssertEqual(todo, Todo.finishDocs)
//      XCTAssertNotEqual(todo.id, UUID(0))
//    }
//  }
//  
//  func testInsertOverride() async throws {
//    let mock = withDependencies {
//      $0.date.now = Date(timeIntervalSince1970: 1234567890)
//    } operation: {
//      Todo.finishDocs
//    }
//
//    try await withDependencies {
//      $0.supabaseClient.override(
//        .insert(into: .todos),
//        with: mock
//      )
//    } operation: {
//      @Dependency(\.supabaseClient.database) var database;
//      let todo: Todo = try await database.insert(
//        TodoInsertRequest(description: "Insert new todo"),
//        into: .todos
//      )
//      XCTAssertEqual(todo, Todo.finishDocs)
//      XCTAssertNotEqual(todo.description, "Insert new todo")
//    }
//  }
//  
//  func testInsertManyOverride() async throws {
//    let mocks = withDependencies {
//      $0.date.now = Date(timeIntervalSince1970: 1234567890)
//    } operation: {
//      Todo.mocks
//    }
//
//    try await withDependencies {
//      $0.supabaseClient.override(
//        .insertMany(into: .todos),
//        with: mocks
//      )
//    } operation: {
//      @Dependency(\.supabaseClient.database) var database;
//      let todos: [Todo] = try await database.insert(
//        [
//          TodoInsertRequest(description: "Insert new todo"),
//          TodoInsertRequest(description: "Another new todo"),
//        ],
//        into: .todos
//      )
//      XCTAssertEqual(todos, Todo.mocks)
//    }
//  }
//  
//  func testUpdateOverride() async throws {
//    let mock = withDependencies {
//      $0.date.now = Date(timeIntervalSince1970: 1234567890)
//    } operation: {
//      Todo.finishDocs
//    }
//
//    try await withDependencies {
//      $0.supabaseClient.override(
//        .update(in: .todos),
//        with: mock
//      )
//    } operation: {
//      @Dependency(\.supabaseClient.database) var database;
//      let todo: Todo = try await database.update(
//        id: UUID(0),
//        in: .todos,
//        with: TodoUpdateRequest(description: "Buy milk & eggs")
//      )
//      XCTAssertEqual(todo, Todo.finishDocs)
//    }
//  }
//  
//  func testUpsertOverride() async throws {
//    let mock = withDependencies {
//      $0.date.now = Date(timeIntervalSince1970: 1234567890)
//    } operation: {
//      Todo.finishDocs
//    }
//
//    try await withDependencies {
//      $0.date.now = Date(timeIntervalSince1970: 1234567890)
//      $0.supabaseClient.override(
//        .upsert(in: .todos),
//        with: mock
//      )
//    } operation: {
//      @Dependency(\.supabaseClient.database) var database;
//      let todo: Todo = try await database.upsert(
//        Todo(
//          id: .init(),
//          description: "New todo",
//          isComplete: false
//        ),
//        in: .todos
//      )
//      XCTAssertEqual(todo, mock)
//    }
//  }
}
