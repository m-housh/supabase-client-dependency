# Database Operations

Learn how to use the database operations provided by this library.

## Overview

This article explains how to get started using the database dependency for general `CRUD`
methods on the database.

### The Model

The following model is used to demonstrate the database operations in this document.

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
```

The library ships with a couple protocols that allow for modeling table names and columns
as enum's to help avoid the stringly typed queries supplied with supabase's api's.

```swift
enum Table: String, TableRepresentable { 
  case todos
}

enum TodoColumn: String, ColumnRepresentable {
  case description
  case isComplete = "complete"
}
```

### Access the Database Client

You can access the database client through the dependency mechanism.
This does require the `liveValue` to be setup for your project.

See <doc:GettingStarted> for details on setting up the client.

```swift
@Dependency(\.supabaseClient) var client
let database = client.database()
```

### Fetching Todos

An example of fetching all the todos from the database.

```swift
func fetchTodos() async throws -> [Todo] { 
  try await database.fetch(from: .todos)
}
```

Optionally you can order the todo's returned from the query as well.

```swift
func fetchOrderedTodos() async throws -> [Todo] { 
  try await database.fetch(
    from: .todos,
    orderBy: TableColumn.description.ascending()
  )
}
```

An example of filtering the todo's to only return completed todo's.

```swift
func fetchCompletedTodos() async throws -> [Todo] { 
  try await database.fetch(
    from: .todos, 
    filteredBy: TodoColumn.isComplete.equals(true)
  )
}
```

### Fetching Single Todo's

An example of fetching a single todo by it's id.

```swift
func fetchTodo(id: Todo.ID) async throws -> Todo { 
  try await database.fetchOne(id: id, from: .todos)
}
```

### Inserting a Todo

An example of inserting a todo.

```swift
struct TodoInsertRequest: Encodable { 
  let description: String
  var isComplete: Bool = false

  private enum CodingKeys: String, CodingKey {
    case description
    case isComplete = "complete"
  }
}

func insertTodo(_ todo: TodoInsertRequest) async throws -> Todo { 
  try await database.insert(todo, into: .todos)
}

```

### Inserting Mutliple Todos

An example of inserting multiple todo's.

```swift
func insertTodos(_ todos: [TodoInsertRequest]) async throws -> [Todo] { 
  try await database.insert(todos, into: .todos)
}
```

### Updating A Todo

An example of updating a todo in the database.

```swift
struct TodoUpdateRequest: Encodable { 
  let description: String?
  let isComplete: Bool?

  private enum CodingKeys: String, CodingKey {
    case description
    case isComplete = "complete"
  }
}

func updateTodo(id: Todo.ID, updates: TodoUpdateRequest) async throws -> Todo { 
  try await database.update(id: id, in: .todos, with: updates)
}
```

### Deleting a Todo

An example of deleting a todo by it's id.

```swift
func deleteTodo(id: Todo.ID) async throws { 
  try await database.delete(id: id, from: .todos)
}
```

### Remote Function Calls

The library also exposes a method that mimick's the underlying `PostgREST` client's
`rpc` method, along with a helper type to model the remote function's name as
an enum, similar to table and column names.

```swift
enum RpcName: String, RpcRepresentable { 
  case myFunction
}

func callRemoteFunction() async throws -> [Todo] { 
  try await database.rpc(RpcName.myFunction) { query in 
    // Perform the query and return the results.
    try await query
      .execute()
      .value
  }
}
```
