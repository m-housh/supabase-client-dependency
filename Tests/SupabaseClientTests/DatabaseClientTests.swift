import XCTest
import Dependencies
@testable import SupabaseClientDependencies

final class DatabaseClientTests: XCTestCase {
  
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
      $0.supabaseClient.override(with: mock)
    } operation: {
      @Dependency(\.supabaseClient.database) var database;
      let todo: Todo = try await database().fetchOne(
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
      $0.supabaseClient.override(with: mock)
    } operation: {
      @Dependency(\.supabaseClient.database) var database;
      let todo: Todo = try await database().insert(
        TodoInsertRequest(description: "Insert new todo"),
        into: .todos
      )
      XCTAssertEqual(todo, Todo.finishDocs)
      XCTAssertNotEqual(todo.description, "Insert new todo")
    }
  }
//  
//  func testInsertManyOverride() async throws {
//    try await withDependencies {
//      $0.supabaseClient.client.database.insertMany = { _ in
//        // Ignore the incoming request and return a mock todo.
//        return try JSONEncoder().encode(Todo.mocks)
//      }
//    } operation: {
//      @Dependency(\.supabaseClient.client.database) var database;
//      let todos: [Todo] = try await database.insert(
//        [
//          TodoInsertRequest(description: "Insert new todo"),
//          TodoInsertRequest(description: "Another new todo"),
//        ],
//        into: Table.todos
//      )
//      XCTAssertEqual(todos, Todo.mocks)
//    }
//  }
//  
////  func testUpdateOverride() async throws {
////    try await withDependencies {
////      $0.supabaseClient.client.database.update = { _ in
////        // Ignore the incoming request and return a mock todo.
////        return try JSONEncoder().encode(Todo.finishDocs)
////      }
////    } operation: {
////      @Dependency(\.supabaseClient.client.database) var database;
////      let todo: Todo = try await database.update(
////        id: UUID(0),
////        in: Table.todos,
////        with: TodoUpdateRequest(description: "Buy milk & eggs")
////      )
////      XCTAssertEqual(todo, Todo.finishDocs)
////    }
////  }
//  
}
