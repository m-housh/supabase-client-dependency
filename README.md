# supabase-client-dependency

[![CI](https://github.com/m-housh/supabase-client-dependency/actions/workflows/ci.yml/badge.svg)](https://github.com/m-housh/supabase-client-dependency/actions/workflows/ci.yml)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fm-housh%2Fsupabase-client-dependency%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/m-housh/supabase-client-dependency)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fm-housh%2Fsupabase-client-dependency%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/m-housh/supabase-client-dependency)

A [swift-dependencies](https://github.com/pointfreeco/swift-dependencies) client for supabase integrations.

This dependency wraps the [supabase-swift](https://github.com/supabase/supabase-swift) client,
database, and auth for convenience methods for use in `TCA` based apps.

This package adds some niceties around database queries as well as holds onto an `authentication` client.
In general you use this package / dependency to build your database clients for usage in a
[swift-composable-architecture](https://github.com/pointfreeco/swift-composable-architecture) based application.

## Installation

Install this as a swift package in your project.

```swift
import PackageDescription

let package = Package(
  ...
  dependencies: [
    .package(
      url: "https://github.com/m-housh/supabase-client-dependency.git",
      from: "0.4.0"
    )
  ],
  targets: [
    .target(
      name: "<My Target>",
      dependencies: [
        .product(name: "SupabaseDependencies", package: "supabase-client-dependency")
      ]
    )
  ]
)
```

## Basic Usage

This package does not have an official `liveValue` declared on the dependency because it is intended 
that the live value is setup in the project that depends on it. It does conform to the 
`TestDependencyKey` and has an `unimplemented` version that can be used in tests.

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
import SupabaseDependencies

struct TodoModel: Codable, Equatable, Identifiable, Sendable {
  var id: UUID
  var createdAt: Date
  var description: String
  var isComplete: Bool = false
  
  enum CodingKeys: String, CodingKey {
    case id
    case createdAt = "created_at"
    case description
    case isComplete = "complete"
  }
}
```

### The `Todo` route collection

A route collection is used to declare a group of routes, generally for a specific table in
the database.

```swift
@CasePathable
enum TodoRoute: RouteCollection {
  static var table: DatabaseRoute.Table { "todos" }

  case delete(id: TodoModel.ID)
  case fetch(filteredBy: [DatabaseRoute.Filter] = [], orderedBy: DatabaseRoute.Order? = nil)
  case fetchOne(id: TodoModel.ID)
  case save(TodoModel)

  // Provide the database route.
  public func route() async throws -> DatabaseRoute {
    switch self {
    case let .delete(id: id):
      return .delete(id: id, from: Self.table)

    case let .fetch(filters, order):
      return .fetch(from: Self.table, filters: filters, order: order)

    case let .fetchOne(id: id):
      return .fetchOne(id: id, from: Self.table)

    case let .save(todo):
      return try .upsert(todo, in: Self.table)
    }
  }

  static var fetch: Self { .fetch(filteredBy: [], orderedBy: nil) }

}

```

### Create your root database route controller.

A route collection that holds on to all your individual route collections, which also
conforms the ``RouteCollection`` protocol.  The route collection conformance is required
by to create the router later on when setting up the live dependency.

```swift
@CasePathable
enum Routes: RouteCollection {

  case todos(TodoRoute)
  ...

  func route() async throws -> DatabaseRoute {
    switch self {
    case let .todos(todos):
      return try await todos.route()
    ...
    }
  }
}
```

### Setup the supabase dependency.

The supabase client dependency needs to be extended to provide the live value.

```swift
extension DependencyValues {
  var supabase: SupabaseDependency<Routes> {
    get { self[SupabaseDependency<Routes>.self] }
    set { self[SupabaseDependency<Routes>.self] = newValue }
  }
}

extension SupabaseDependency<Routes>: DependencyKey {
  // Use the `.live(client:)` method with your supabase client configuration.
  static let liveValue: Self = .live(client: SupabaseClient(...))
}
```

### Use the supabase dependency.

The supabase dependency contains an authentication controller that has some convenience
methods for interacting with the supabase authentication client. Providing hooks that can allow
you to override the current user, session, and convenience methods for logging in users.

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
  return try await todos(.fetch(orderBy: .descending("complete")))
}

func insertTodo(description: String, isComplete: Bool = false) -> Todo {
  @Dependency(\.supabase.router.todos)
  return try await todos(
    .save(
      TodoModel(
        createdAt: Date(),
        description: description,
        isComplete: isComplete
      )
    )
  )
}
```

See the [Example](https://github.com/m-housh/supabase-client-dependency/tree/main/Examples/Examples)
project for a full working example.

## Documentation

The full documentation can be viewed [here](https://m-housh.github.io/supabase-client-dependency/documentation/supabasedependencies/)

## License

All modules are released under the MIT license. See [LICENSE](https://github.com/m-housh/supabase-client-dependency/blob/main/LICENSE) for details.

