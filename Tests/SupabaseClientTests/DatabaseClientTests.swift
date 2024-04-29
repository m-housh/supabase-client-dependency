import XCTest
import Dependencies
@testable import SupabaseClientDependencies

final class DatabaseClientTests: XCTestCase {

  func testDeleteOverride() async throws {
    let mock = withDependencies {
      $0.date.now = Date(timeIntervalSince1970: 1234567890)
    } operation: {
      Todo.finishDocs
    }

    await withDependencies {
      $0.supabaseClient.override(
        .delete(from: .todos)
      )
    } operation: {
      @Dependency(\.supabaseClient) var client;

      do {
        _ = try await client.database().delete(
          id: mock.id,
          from: .todos
        )
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
      $0.supabaseClient.override(
        .fetch(from: .todos),
        with: mocks
      )
    } operation: {
      @Dependency(\.supabaseClient) var client;

      let todos: [Todo] = try await client.database().fetch(
        from: .todos
      )
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
      $0.supabaseClient.override(.fetchOne(from: .todos), with: mock)
    } operation: {
      @Dependency(\.supabaseClient) var client;
      let todo: Todo = try await client.database().fetchOne(
        id: UUID(0),
        from: .todos
      )
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
      $0.supabaseClient.override(
        .insert(into: .todos),
        with: mock
      )
    } operation: {
      @Dependency(\.supabaseClient) var client;
      let todo: Todo = try await client.database().insert(
        TodoInsertRequest(description: "Insert new todo"),
        into: .todos
      )
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
      $0.supabaseClient.override(
        .insertMany(into: .todos),
        with: mocks
      )
    } operation: {
      @Dependency(\.supabaseClient) var client;
      let todos: [Todo] = try await client.database().insert(
        [
          TodoInsertRequest(description: "Insert new todo"),
          TodoInsertRequest(description: "Another new todo"),
        ],
        into: .todos
      )
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
      $0.supabaseClient.override(
        .update(in: .todos),
        with: mock
      )
    } operation: {
      @Dependency(\.supabaseClient) var client;
      let todo: Todo = try await client.database().update(
        id: UUID(0),
        in: .todos,
        with: TodoUpdateRequest(description: "Buy milk & eggs")
      )
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
      $0.supabaseClient.override(
        .upsert(in: .todos),
        with: mock
      )
    } operation: {
      @Dependency(\.supabaseClient) var client;
      let newTodo = Todo(
        id: .init(),
        description: "New todo",
        isComplete: false
      )
      let todo: Todo = try await client.database().upsert(
        in: .todos,
        with: newTodo
      )
      XCTAssertEqual(todo, mock)
    }
  }
}
