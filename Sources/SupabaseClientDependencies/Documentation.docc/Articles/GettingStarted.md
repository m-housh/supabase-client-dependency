# GettingStarted

This article explains how to integrate the supabase client dependency into your project.

## Installation

Install this as a swift package in your project.

```swift
import PackageDescription

let package = Package(
  ...
  dependencies: [
    .package(
      url: "https://github.com/m-housh/supabase-client-dependency.git",
      from: "0.1.0"
    )
  ],
  targets: [
    .target(
      name: "<My Target>",
      dependencies: [
        .product(name: "SupabaseClient", package: "supabase-client-dependency")
      ]
    )
  ]
)
```

## Basic Usage

This package does not have an official `liveValue` declared on the dependency because it is intended 
that the live value is setup in the project that depends on it. It does conform to the 
`TestDependencyKey` and has an `unimplemented` version used in tests.

### The Todo model

A basic todo model as an example for the documentation.

#### The SQL for the database model
```sql
create table if not exists todos (
  id uuid primary key default uuid_generate_v4(),
  description text not null,
  complete boolean not null default false,
  created_at timestamptz default (now() at time zone 'utc'::text) not null
);
```

#### The swift model implementation.
```swift
import Dependencies
import Foundation

struct TodoModel: Codable, Equatable, Identifiable, Sendable {
  var id: UUID
  var createdAt: Date
  var description: String
  var isComplete: Bool = false
  
  init(
    id: UUID,
    createdAt: Date? = nil,
    description: String,
    isComplete: Bool
  ) {
    @Dependency(\.date.now) var now;
    self.id = id
    self.createdAt = createdAt ?? now
    self.description = description
    self.isComplete = isComplete
  }
  
  private enum CodingKeys: String, CodingKey {
    case id
    case createdAt = "created_at"
    case description
    case isComplete = "complete"
  }
}

// MARK: - Helper types.

struct TodoInsertRequest: Codable, Hashable {
  let description: String
  let isComplete: Bool = false

  enum CodingKeys: String, CodingKey {
    case description
    case isComplete = "complete"
  }
}

struct TodoUpdateRequest: Codable, Hashable {
  var description: String? = nil
  var isComplete: Bool? = nil

  enum CodingKeys: String, CodingKey {
    case description
    case isComplete = "complete"
  }
}

```

### The `Todo` route controller

A route controller is used to declare a group of routes, generally for a specific table in
the database.

```swift
@CasePathable
enum TodoRoute: RouteController {
  static var table: AnyTable { "todos" }

  // The fetch route, which can optionally take filters and an order.
  case fetch(filteredBy: [DatabaseFilter] = [], orderedBy: DatabaseOrder?)
  
  // The insert route.
  case insert(TodoInsertRequest)

  // Provide the database route.
  public func route() throws -> DatabaseRoute {
    switch self {
    case let .fetch(filters, order):
      // Returns a fetch query with the given filters and order.
      return .fetch(from: Self.table, filters: filters, order: order)
    case let .insert(request):
      // Returns an insert query with the new todo request.
      return try .insert(todo, into: Self.table)
    }
  }

  static var fetch: Self { .fetch(filteredBy: [], orderedBy: nil) }

}

```

### Create your database router.

A database router holds on to all your route controllers.

```swift
@CasePathable
enum DbRoutes: DatabaseController {

  case todos(TodoRoute)
  ...

  func route() throws -> DatabaseRoute {
    switch self {
    case let .todos(todos):
      return try todos.route()
    ...
    }
  }
}
```

### Setup the supabase dependency.

The supabase client dependency needs to be extended to provide the live value.

```swift
extension DependencyValues {
  var supabase: SupabaseClientDependency<DbRoutes> {
    get { self[SupabaseClientDependency<DbRoutes>.self] }
    set { self[SupabaseClientDependency<DbRoutes>.self] = newValue }
  }
}

extension SupabaseClientDependency<DbRoutes>: DependencyKey {
  // Use the `.live(client:)` method with your supabase client configuration.
  static let liveValue: Self = .live(client: SupabaseClient(...))
}
```

### Use the supabase dependency.

The supabase dependency contains an authentication controller that has some convenience
methods for interacting with the supabase authentication client. Providing hooks that can allow
you to override the current user, session, and convenience methods for logging in users.

See <doc:AuthControllerUsage> for more authentication methods.

```swift

func login(credentials: Credentials) async throws -> Session {
  @Dependency(\.supabase.auth) var auth
  return try await auth.login(credentials: credentials)
}
```

Use the database router to perform operations on the database.

```swift
func fetchTodos() async throws -> [Todo] {
  @Dependency(\.supabase.router.todos)
  return try await todos(.fetch)
}

func insertTodo(description: String, isComplete: Bool = false) -> Todo {
  @Dependency(\.supabase.router.todos)
  return try await todos(.insert(
    TodoInsertRequest(description: description, isComplete: isComplete)
  ))
}
```

See <doc:DatabaseRouterUsage> for more details about modeling your database routes.
See <doc:DatabaseOperations> for database operations / convenience methods.

See the [Example](https://github.com/m-housh/supabase-client-dependency/tree/main/Examples/Examples) 
project for a full working example.
