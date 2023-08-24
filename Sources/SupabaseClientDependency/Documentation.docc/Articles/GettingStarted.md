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
`TestDependencyKey` and has an `unimplemented` version used in tests. It also has a `mock` factory 
method for the `auth` portion of the client dependency, which is helpful for use in previews and test's.

### Define the configuration for the supabase client.

```swift
import Dependencies
import SupabaseClientDependency

extension SupabaseClientDependency.Configuration {
  public static let live = Self.init(url: supabaseURL, anonKey: localAnonKey)
}

// This url in general is used for local supabase installations and should be
// changed to your live url.
fileprivate let supabaseURL = URL(string: "http://localhost:54321")!

// Set this to the anonymous key for your project, for local supabase installations this
// is printed to the screen when you call `supabase start` on your machine.
fileprivate let localAnonKey =
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0"

// Conform the `SupabaseClientDependency` to `DependencyKey` and implement the `liveValue`.
extension SupabaseClientDependency: DependencyKey {
  static var liveValue: Self {
    .live(configuration: .live)
  }
}
```

### The Todo model

A basic todo model as an example for the documentation.

#### The SQL for the database model
```sql
create table if not exists todos (
  id uuid primary key default uuid_generate_v4(),
  description text not null,
  complete boolean not null default false,
  owner_id uuid references auth.users (id) not null,
  created_at timestamptz default (now() at time zone 'utc'::text) not null
);

alter table todos enable row level security;

create policy "Allow access to owner only" on todos as permissive
    for all to authenticated
        using (auth.uid () = owner_id)
        with check (auth.uid () = owner_id);
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
```

### Create your database client dependency.

The database client that is used for interactions with the supabase instance for your project.

```swift
import Dependencies
import SupabaseClientDependency

extension DependencyValues {
  
  // Access the database client as a dependency.
  var database: DatabaseClient {
    get { self[DatabaseClient.self] }
    set { self[DatabaseClient.self] = newValue }
  }

}

// The database client interface.
struct DatabaseClient {
  
  var todos: Todos
  
  // Represents interactions with the todos table in the database.
  struct Todos {

    // Delete a todo by it's id.
    var delete: (TodoModel.ID) async throws -> Void
    
    // Fetch all the todo's for the authenticated user.
    var fetch: () async throws -> IdentifiedArrayOf<TodoModel>
    
    // Insert a new todo in the database.
    var insert: (InsertRequest) async throws -> TodoModel

    // Update an existing todo in the database.
    var update: (TodoModel.ID, UpdateRequest) async throws -> TodoModel
   
    // Represents the columns / fields needed to insert a new todo in the database.
    struct InsertRequest: Encodable {
      var description: String
      var complete: Bool
    }
    
    // Represents the columns / fields to be updated for an existing todo.
    struct UpdateRequest: Encodable {
      var description: String?
      var complete: Bool?
      
      var hasChanges: Bool {
        description != nil || complete != nil
      }
    }
  }
}
```

### The live implementation of the database client.
```swift
extension DatabaseClient: DependencyKey {
  
  static var liveValue: Self {
    // Use the supabase client dependency and it's helper methods for interacting
    // with the supabase postgresql database.
    @Dependency(\.supabaseClient) var client;

    return Self.init(
      todos: DatabaseClient.Todos(
        delete: { try await client.database.delete(id: $0, from: Table.todos) },
        fetch: {
          
          // get the current authenticated user.
          let user = try await client.auth.requireCurrentUser()
         
          // Return the todos.
          return try await .init(
            uniqueElements: client.database.fetch(
              from: Table.todos,
              filteredBy: TodoColumn.ownerId.equals(user.id),
              orderBy: TodoColumn.complete.ascending()
            )
          )
        },
        insert: { request in
          
          // A helper type that includes the authenticated user's
          // id as the owner of the todo in the database, which is
          // required by the row level security.
          //
          // This allows this implementation detail to be hidden away
          // from the user and requires that the user is authenticated
          // when inserting a todo.
          struct InsertValues: Encodable {
            let complete: Bool
            let description: String
            let ownerId: UUID
            
            enum CodingKeys: String, CodingKey {
              case complete
              case description
              case ownerId = "owner_id"
            }
          }
          
          return try await client.database.insert(
            InsertValues(
              complete: request.complete,
              description: request.description,
              ownerId: client.auth.requireCurrentUser().id
            ),
            into: Table.todos
          )
        },
        update: { try await client.database.update(id: $0, in: Table.todos, with: $1) }
      )
    )
  }

  static let previewValue: Self { 
    ...
  }

  static let testValue: Self { 
    ...
  }
}
```

See the [Example](https://github.com/m-housh/supabase-client-dependency/tree/main/Examples/Examples) 
project for a full working example.
