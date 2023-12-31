# Advanced Database Operations

Learn about advanced database operations.

## Overview

This article describes advanced operations for the ``SupabaseClientDependency/DatabaseClient``.

### Overriding Methods

The following properties are available to override for when you need to mock the database
for use in previews or tests.  Overriding these methods will override the values returned
for all the associated helper methods for the common `CRUD` operations for the database.

It is important to understand how dependencies get propogated in your application. Refer
to the [swift-dependencies](https://pointfreeco.github.io/swift-dependencies/main/documentation/dependencies)
documentation for more information.

For the purposes of the documentation, we will show overriding properties using the `withDependencies`
method, but the same things will apply for overriding the properties in a `Store` or `Reducer`
context.

#### Mock's Used

The following mock values are used in this article.

```swift
extension TodoModel {
  static let buyMilk = TodoModel(
    id: UUID(0),
    description: "Buy milk",
    isComplete: Bool.random()
  )

  static let finishDocs = TodoModel(
    id: UUID(1),
    description: "Finish documentation",
    isComplete: Bool.random()
  )

  static let drinkCoffee = TodoModel(
    id: UUID(2),
    description: "Drink coffee",
    isComplete: Bool.random()
  )

  static let mocks: [TodoModel] = [
    .buyMilk,
    .finishDocs,
    .drinkCoffee
  ]
}
```

#### Fetch Many

To override / mock the values returned from any of the `fetch` methods on the database
client.

Set a custom value for the ``SupabaseClientDependency/DatabaseClient/fetch`` property.

```swift
try await withDependencies { 
  $0.supabaseClient.database.fetch = { _ in
    // Ignore the incoming request and return mock todo's.
    return try JSONEncoder().encode(TodoModel.mocks)
  }
} operation: { 
  @Dependency(\.supabaseClient.database) var database;
  let todos: [TodoModel] = try await database.fetch(
    from: Table.todos
  )
  XCTAssertEqual(todos, TodoModel.mocks)
}
```

#### Fetch One

To override / mock the values returned from any of the `fetchOne` methods on the database
client.

Set a custom value for the ``SupabaseClientDependency/DatabaseClient/fetchOne`` property.

```swift
try await withDependencies { 
  $0.supabaseClient.database.fetchOne = { _ in
    // Ignore the incoming request and return a mock todo.
    return try JSONEncoder().encode(TodoModel.finishDocs)
  }
} operation: { 
  @Dependency(\.supabaseClient.database) var database;
  let todo: TodoModel = try await database.fetchOne(
    id: UUID(0),
    from: Table.todos
  )
  XCTAssertEqual(todo, TodoModel.finishDocs)
  XCTAssertNotEqual(todo.id, UUID(0))
}
```

#### Insert

To override / mock the values returned from the `insert` methods on the database
client for single value insert requests.

Set a custom value for the ``SupabaseClientDependency/DatabaseClient/insert`` property.

```swift
try await withDependencies { 
  $0.supabaseClient.database.insert = { _ in
    // Ignore the incoming request and return a mock todo.
    return try JSONEncoder().encode(TodoModel.finishDocs)
  }
} operation: { 
  @Dependency(\.supabaseClient.database) var database;
  let todo: TodoModel = try await database.insert(
    TodoInsertRequest(description: "Insert new todo"),
    into: Table.todos
  )
  XCTAssertEqual(todo, TodoModel.finishDocs)
  XCTAssertNotEqual(todo.description, "Insert new todo")
}
```

#### Insert Many

To override / mock the values returned from any of the `insert` methods on the database
client that insert multiple items.

Set a custom value for the ``SupabaseClientDependency/DatabaseClient/insertMany`` property.

```swift
try await withDependencies { 
  $0.supabaseClient.database.insertMany = { _ in
    // Ignore the incoming request and return a mock todo.
    return try JSONEncoder().encode(TodoModel.mocks)
  }
} operation: { 
  @Dependency(\.supabaseClient.database) var database;
  let todos: [TodoModel] = try await database.insert(
    [
      TodoInsertRequest(description: "Insert new todo"),
      TodoInsertRequest(description: "Another new todo"),
    ],
    into: Table.todos
  )
  XCTAssertEqual(todos, TodoModel.mocks)
}
```

#### Update

To override / mock the values returned from any of the `update` methods on the database
client.

Set a custom value for the ``SupabaseClientDependency/DatabaseClient/update`` property.

```swift
try await withDependencies { 
  $0.supabaseClient.database.update = { _ in
    // Ignore the incoming request and return a mock todo.
    return try JSONEncoder().encode(TodoModel.finishDocs)
  }
} operation: { 
  @Dependency(\.supabaseClient.database) var database;
  let todo: TodoModel = try await database.update(
    id: UUID(0),
    in: Table.todos,
    with: TodoUpdateRequest(description: "Buy milk & eggs")
  )
  XCTAssertEqual(todo, TodoModel.finishDocs)
}
```

#### Delete

To override any of the `delete` methods on the database
client.

Set a custom value for the ``SupabaseClientDependency/DatabaseClient/delete`` property.

```swift
try await withDependencies { 
  $0.supabaseClient.database.update = { _ in
    // Ignore the incoming request and do nothing.
  }
} operation: { 
  @Dependency(\.supabaseClient.database) var database;
  try await database.delete(
    id: UUID(0),
    from: Table.todos
  )
}
```


