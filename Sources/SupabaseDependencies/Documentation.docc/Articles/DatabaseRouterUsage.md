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

#### Delete:

  - ``DatabaseRoute/delete(from:filteredBy:routeId:)-guk8``
  - ``DatabaseRoute/delete(from:filteredBy:routeId:)-568k``
  - ``DatabaseRoute/delete(id:from:routeId:)``

#### Fetch:

- ``DatabaseRoute/fetch(from:filteredBy:order:routeId:)-2my88``
- ``DatabaseRoute/fetchOne(from:filteredBy:routeId:)-1b974``

#### Fetch One:

- ``DatabaseRoute/fetchOne(from:filteredBy:routeId:)-3m1iy``
- ``DatabaseRoute/fetchOne(from:filteredBy:routeId:)-1b974``
- ``DatabaseRoute/fetchOne(id:from:routeId:)``

#### Insert:

- ``DatabaseRoute/insert(_:into:returning:routeId:)``

#### Update:

- ``DatabaseRoute/update(id:in:with:returning:routeId:)``
- ``DatabaseRoute/update(_:in:filteredBy:returning:routeId:)``

#### Upsert:

- ``DatabaseRoute/upsert(_:in:returning:routeId:)``

#### Custom:

- ``DatabaseRoute/custom(on:routeId:build:)``

All database routes have the option of providing a string id which can be used to match a route
against when overriding the route for previews or test purposes.  This is most useful when / if
you use the `custom` route type or perhaps provide multiple routes for the same ``DatabaseRoute/Method``.

### Route Collections

A route collection is a collection of related ``DatabaseRoute``s, generally for a table or perhaps all the routes
required for a view.  Generally they are modeled as an enumuration.  You model a route collection by conforming
your type to the ``RouteCollection`` and returning a ``DatabaseRoute`` from
the `route` method.

Below is an example for a `Todos` table.

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

A route collection can also be used to manage multiple other route collections for the database.

```swift
@CasePathable
enum Routes: RouteCollection {
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

A database router is used generally to manage a ``RouteCollection`` and provides ways to override
the routes for previews or testing purposes.

#### Example override.

```swift
var router = DatabaseRouter<Routes>(...)

// Override fetch route in for the todos table.
// This uses an exact match on the route, so it would not override
// if you called the fetch route providing any filters or order.
router.override(.route(.todos(.fetch), with: Todo.mocks))

// Override all fetch one routes with it's `CaseKeyPath`
router.override(\.todos.fetchOne, with: Todo.mocks[0])

// Override all calls to the delete route in the todos table, using it's `CaseKeyPath`,
// using a failure as a result.
router.override(\.todos.delete, with: .failure(MyError()))

```

See ``DatabaseRouter/Override`` for more ways to override routes.

### Using the database router.

You use the database router by calling it with a database route, generally resolved from a route collection.
Which will respect any overrides or call the database if an override is not found for the given route.  It
also handles decoding the result.

```swift
let todos: [Todo] = router(.todos(.fetch))

let newTodo: Todo = router(.todos(.save(
  Todo(...)
)))
```

### General Purpose Router

You can also create a general purpose router if you do not model your routes as a ``RouteCollection``, but
instead want to model them as `struct`'s or just use it to manage overrides for your tables.  A general
purpose router uses `Never` as the routes that it is generic over, there is a typealias for this style
router which is ``GeneralRouter``.

> Note: You can also use `Never` as the generic for a ``SupabaseDependency`` to use a genral purpose router.

General purpose routers still can manage overrides by either matching an entire route, a route id, or 
matching a method and table.

#### Example

```swift
var router = GeneralRouter(...)

router.override(.method(.fetch, in: "todos", with: Todo.mocks))

let todos: [Todo] = router(.fetch(from: "todos"))

```

