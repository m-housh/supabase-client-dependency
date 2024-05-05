# Database Router

This article explains the database router module that is used for modeling database / table
routes.

## Overview

The database router module is used to model your database and table routes as enumurations.
It also offers the ability to override routes for preview and testing purposes in your application.

The ``SupabaseClientDependency`` contains a router for your database routes, however this module can
be used as a standalone package as well.  This article is focused on explaining the module as a 
standalone package.

### Database Route

A database route is an operation / route on the database.  It holds onto the table that query
is built for and other information such as database filters, values to be inserted / updates,
etc.

The database route can be thought of as the description of the route, and can be used to match
an override to a route in previews and tests.

The library ships with the following routes:
- ``DatabaseRoute/delete(from:filteredBy:routeId:)``
- ``DatabaseRoute/fetch(from:filteredBy:order:routeId:)``
- ``DatabaseRoute/fetchOne(from:filteredBy:routeId:)``
- ``DatabaseRoute/insert(_:into:returning:routeId:)``
- ``DatabaseRoute/update(id:in:with:returning:routeId:)``
- ``DatabaseRoute/upsert(_:in:returning:routeId:)``
- ``DatabaseRoute/custom(_:routeId:build:)``

All database routes have the option of providing a string id which can be used to match a route
against when overriding the route for previews or test purposes.  This is most useful when / if
you use the `custom` route type or perhaps provide multiple routes for the same ``DatabaseRoute/Method``.

### Route Controllers

A route controller is a collection of related ``DatabaseRoute``s, generally for a table or perhaps all the routes
required for a view.  Generally they are modeled as enumuration.  You model a route controller by conforming
your type to the ``RouteController`` and returning a ``DatabaseRoute`` from
the `route` method.

Below is an example for a `Todos` table.

```swift
@CasePathable
enum TodoRoute: RouteController {
  static let table: DatabaseTable = "todos"

  // The delete route, which uses the filters to know which row(s) to delete.
  case delete(filteredBy: [DatabaseRoute.Filter])

  // The fetch route, which can optionally take filters and an order.
  case fetch(filteredBy: [DatabaseRoute.Filter] = [], orderedBy: DatabaseRoute.Order?)
  
  // The fetch by id route.
  case fetchOne(id: Todo.ID)

  // Insert new todos.
  case insert(InsertRequest)

  // Update a todo by id.
  case update(id: Todo.ID, updates: TodoUpdateRequest)

  // Upsert a todo.
  case upsert(Todo)

  public func route() async throws -> DatabaseRoute {
    switch self {
    case let .delete(filters):
      return .delete(from: Self.table, filters: filters)
    case let .fetch(filters, order):
      return .fetch(from: Self.table, filters: filters, order: order)
    case .fetchOne(id: let id):
      return .fetchOne(from: Self.table, filteredBy: .id(id))
    case let .insert(request):
      switch request {
      case let .single(todo):
        return try .insert(todo, into: Self.table)
      case let .many(todos):
        return try .insert(todos, into: Self.table)
      }
    case .update(id: let id, updates: let updates):
      return try .update(id: id, in: Self.table, with: updates)
    case let .upsert(todo):
      return try .upsert(todo, in: Self.table)
    }
  }

  // MARK: - Helpers
  
  enum InsertRequest {
    case single(TodoInsertRequest)
    case many([TodoInsertRequest])
  }

  static func delete(id: Todo.ID) -> Self {
    self.delete(.id(id))
  }

  static func insert(_ request: TodoInsertRequest) -> Self {
    .insert(.single(request))
  }

  static func insert(_ request: [TodoInsertRequest]) -> Self {
    .insert(.many(request))
  }

  static var fetch: Self { .fetch(filteredBy: [], orderedBy: nil) }

}

```

A route controller can also be used to manage multiple other route controllers for the database.

```swift
@CasePathable
enum DbRoutes: RouteController {
  case todos(TodoRoute)
  ...

  func route() async throws -> DatabaseRoute {
    switch self {
    case let .todos(todos):
      return try todos.route()
    ...
    }
  }
}
```

### Database Router

A database router is used to manage a ``RouteController`` and provides ways to override
the routes for previews or testing purposes.

#### Example override.

```swift
var router = DatabaseRouter<DbRoutes>()

// Override fetch route in for the todos table.
// This uses an exact match on the route, so it would not override
// if you called the fetch route providing any filters or order.
router.override(.todos(.fetch))

// Override all calls to the delete route in the todos table.
router.override(.delete, in: "todos")

```

### Database Executor

The database executor is used to execute queries on the database and handles decoding
responses.  The database executor needs to be extended to conform to `DependencyKey` and
provide the `liveValue` by calling it's ``DatabaseExecutor/live(database:)`` method.  It
is provided to give a hook into any of the calls to the database from a ``DatabaseRouter``
or ``RouteController``.

#### Example override.

```swift
let todos: [Todo] = try await withDependencies {
  $0.databaseExecutor.execute = { _  in 
    // Ignore the postgrest route / query and always return
    // mock todos.
    return try JSONEncoder().encode(Todos.mocks)
  }
} operation: {
  return try await router(.todos(.fetch))
}
```
