import Dependencies
import Foundation
import PostgREST

extension PostgrestClient {
  private func delete(
    _ request: DatabaseRequest.DeleteRequest
  ) async throws {
    @Dependency(\.supabaseClient.databaseClient) var db
    
    let builder = self.from(request.table.tableName)
      .delete(returning: .minimal)
      .filter(by: request.filters)
    
    return try await db.execute(
      .delete(table: request.table, builder: builder),
      on: self
    )
    .value
  }

  /// A helper for deleting a database item by the provided filters.
  ///
  /// ### Example
  ///
  /// ```swift
  ///  try await databaseClient.delete(
  ///     from: .todos,
  ///     where: [
  ///       .equals(column: "complete", value: false),
  ///       .equals(column: "description", value: "Buy milk")
  ///     ]
  ///  )
  /// ```
  ///
  /// - Parameters:
  ///   - table: The table name to delete the item from.
  ///   - filters: The filters for the row to be deleted from the database.
  public func delete(
    from table: AnyTable,
    where filters: [DatabaseRequest.Filter]
  ) async throws {
    try await self.delete(.init(table: table, filters: filters))
  }

  
  /// A helper for deleting a database item by the provided filters.
  ///
  /// ### Example
  ///
  /// ```swift
  ///  try await databaseClient.delete(
  ///     from: .todos,
  ///     filteredBy:
  ///       .equals(column: "complete", value: false),
  ///       .equals(column: "description", value: "Buy milk")
  ///  )
  /// ```
  ///
  /// - Parameters:
  ///   - table: The table name to delete the item from.
  ///   - filters: The filters for the row to be deleted from the database.
  public func delete(
    from table: AnyTable,
    filteredBy filters: DatabaseRequest.Filter...
  ) async throws {
    try await delete(from: table, where: filters)
  }

  /// A helper for deleting a database item by it's id. This method requires the column name in the database to be "id" for
  /// matching the id value against.
  ///
  /// ### Example
  ///
  /// ```swift
  ///  try await databaseClient.delete(
  ///     id: UUID(0),
  ///     from: .todos,
  ///  )
  /// ```
  /// - Parameters:
  ///   - id: The database item's id.
  ///   - table: The table name to delete the item from.
  public func delete<ID: URLQueryRepresentable>(
    id: ID,
    from table: AnyTable
  ) async throws {
    try await self.delete(from: table, filteredBy: .id(id))
  }


  // MARK: - Fetch
  
  private func fetch<R: Decodable>(
    _ request: DatabaseRequest.FetchRequest
  ) async throws -> R {
    @Dependency(\.supabaseClient.databaseClient) var db
    
    let builder = self.from(request.table.tableName)
      .select()
      .filter(by: request.filters)
      .order(by: request.order)
    
    return try await db.execute(
      .fetch(table: request.table, builder: builder),
      on: self
    )
    .value
  }
  
  /// A helper for fetching items from the database, using the table name, Filter's, and Order types.
  ///
  /// ### Example
  ///
  /// ```swift
  /// let todos = try await databaseClient.fetch(
  ///   from: .todos,
  ///   where: [.equals("complete", "false")],
  ///   orderBy: .init(column: "description").ascending(),
  ///   decoding: [TodoModel].self // this is generally inferred and not needed depending on calling context.
  /// )
  /// ```
  ///
  /// - Parameters:
  ///   - table: The table to fetch the values from.
  ///   - filters: Filters to apply to the query.
  ///   - orderBy: An optional order by clause for the query.
  ///   - type: The return value type to decode.
  func fetch<Response: Decodable>(
    from table: AnyTable,
    where filters: [DatabaseRequest.Filter] = [],
    orderBy order: DatabaseRequest.Order? = nil,
    decoding type: Response.Type = Response.self
  ) async throws -> Response {
    return try await self.fetch(
      .init(table: table, filters: filters, order: order)
    )
  }

  /// A helper for fetching items from the database, using the table name, a Filter, and Order types.
  ///
  /// ### Example
  ///
  /// ```swift
  /// let todos = try await databaseClient.fetch(
  ///   from: .todos,
  ///   filteredBy: TodoColumn.complete.equals(false),
  ///   orderBy: TodoColumn.description.ascending(),
  ///   decoding: [TodoModel].self // this is generally inferred and not needed depending on calling context.
  /// )
  /// ```
  ///
  /// - Parameters:
  ///   - table: The table to fetch the values from.
  ///   - filters: Filter(s) to apply to the query.
  ///   - orderBy: An optional order by clause for the query.
  ///   - type: The return value type to decode.
  public func fetch<Response: Decodable>(
    from table: AnyTable,
    filteredBy filters: DatabaseRequest.Filter...,
    orderBy order: DatabaseRequest.Order? = nil,
    decoding type: Response.Type = Response.self
  ) async throws -> Response {
    try await self.fetch(
      from: table,
      where: filters,
      orderBy: order,
      decoding: Response.self
    )
  }

  // MARK: - Fetch One
  
  private func fetchOne<R: Decodable>(
    _ request: DatabaseRequest.FetchOneRequest
  ) async throws -> R {
    
    @Dependency(\.supabaseClient.databaseClient) var db
    
    let builder = self.from(request.table.tableName)
      .select()
      .filter(by: request.filters)
      .single()
    
    return try await db.execute(
      .fetchOne(table: request.table, builder: builder),
      on: self
    )
    .value
  }

  /// A helper for fetching as single item from the database, using the table name and Filter's.
  ///
  /// ### Example
  ///
  /// ```swift
  /// let todo = try await databaseClient.fetch(
  ///   from: .todos,
  ///   where: [TodoColumn.id.equals(UUID(0))],
  ///   decoding: TodoModel.self // this is generally inferred and not needed depending on calling context.
  /// )
  /// ```
  ///
  /// - Parameters:
  ///   - table: The table name to fetch the values from.
  ///   - filters: Filters to apply to the query.
  ///   - type: The return value type to decode.
  public func fetchOne<Model: Decodable>(
    from table: AnyTable,
    where filters: [DatabaseRequest.Filter],
    decoding type: Model.Type = Model.self
  ) async throws -> Model {
    return try await self.fetchOne(
      .init(
        table: table,
        filters: filters
      )
    )
  }

  /// A helper for fetching as single item from the database, using the table name and Filter's.
  ///
  /// ### Example
  ///
  /// ```swift
  /// let todo = try await databaseClient.fetch(
  ///   from: Table.todos,
  ///   filteredBy: TodoColumn.id.equals(UUID(0)),
  ///   decoding: TodoModel.self // this is generally inferred and not needed depending on calling context.
  /// )
  /// ```
  ///
  /// - Parameters:
  ///   - table: The table name to fetch the values from.
  ///   - filters: Filters to apply to the query.
  ///   - type: The return value type to decode.
  public func fetchOne<Model: Decodable>(
    from table: AnyTable,
    filteredBy filters: DatabaseRequest.Filter...,
    decoding type: Model.Type = Model.self
  ) async throws -> Model {
    try await self.fetchOne(
      from: table,
      where: filters,
      decoding: Model.self
    )
  }

  /// A helper for fetching items from the database, using the table name and an id of an element. This method requires the column name
  /// in the database to be "id" for matching the id value against.
  ///
  /// ### Example
  ///
  /// ```swift
  /// let todo = try await databaseClient.fetch(
  ///   id: UUID(0),
  ///   from: Table.todos,
  ///   decoding: TodoModel.self // this is generally inferred and not needed depending on calling context.
  /// )
  /// ```
  ///
  /// - Parameters:
  ///   - id: The id of the item to fetch from the database.
  ///   - table: The table to fetch the values from.
  ///   - type: The return value type to decode.
  public func fetchOne<Model: Decodable>(
    id: Model.ID,
    from table: AnyTable,
    decoding type: Model.Type = Model.self
  ) async throws -> Model where Model: Identifiable, Model.ID: URLQueryRepresentable {
    try await self.fetchOne(
      from: table,
      filteredBy: .id(id),
      decoding: Model.self
    )
  }

  // MARK: - Insert
  
  private func insert<R: Decodable, V: Encodable>(
    _ request: DatabaseRequest.InsertRequest<V>
  ) async throws -> R {
    
    @Dependency(\.supabaseClient.databaseClient) var db
    
    let builder = try self.from(request.table.tableName)
      .insert(request.values, returning: request.returningOptions)
      .single()
    
    return try await db.execute(
      .insert(table: request.table, builder: builder),
      on: self
    )
    .value
  }
  
  private func insertMany<R: Decodable, V: Encodable>(
    _ request: DatabaseRequest.InsertManyRequest<V>
  ) async throws -> R {
    @Dependency(\.supabaseClient.databaseClient) var db
    
    let builder = try self.from(request.table.tableName)
      .insert(
        request.values.anyJSON(encoder: self.configuration.encoder),
        returning: request.returningOptions
      )
    
    return try await db.execute(
      .insertMany(table: request.table, builder: builder),
      on: self
    )
    .value
  }

  /// Helper for inserting a new value into the database.
  ///
  /// ### Example
  ///
  /// ```swift
  /// let todo = try await databaseClient.insert(
  ///   TodoInsertRequest(description: "New Todo", complete: false),
  ///   into: Table.todos,
  ///   returning: .representation,
  ///   decoding: TodoModel.self // this is generally inferred and not needed depending on the calling context.
  /// )
  /// ```
  ///
  /// - Parameters:
  ///   - table: The table to insert the values into.
  ///   - values: The row values.
  ///   - returningOptions: The postgres returning options (defaults to `.representation`)
  ///   - type: The return value type to decode from the response.
  public func insert<Values: Encodable, Model: Decodable>(
    _ values: Values,
    into table: AnyTable,
    returning returningOptions: PostgrestReturningOptions = .representation,
    decoding type: Model.Type = Model.self
  ) async throws -> Model {
    return try await self.insert(
      .init(
        table: table,
        values: values,
        returningOptions: returningOptions
      )
    )
  }

  /// Helper for inserting multiple new values into the database.
  ///
  /// ### Example
  ///
  /// ```swift
  /// let todo = try await databaseClient.insert(
  ///   into: Table.todos,
  ///   values: [
  ///     TodoInsertRequest(description: "New Todo", complete: false),
  ///     TodoInsertRequest(description: "Another new todo", complete: true)
  ///   ],
  ///   returning: .representation,
  ///   decoding: TodoModel.self // this is generally inferred and not needed depending on the calling context.
  /// )
  /// ```
  ///
  /// - Parameters:
  ///   - table: The table to insert the values into.
  ///   - values: The row values.
  ///   - returningOptions: The postgres returning options (defaults to `.representation`)
  ///   - type: The return value type to decode from the response.
  public func insert<Values: Encodable, Response: Decodable>(
    _ values: [Values],
    into table: AnyTable,
    returning returningOptions: PostgrestReturningOptions = .representation,
    decoding type: Response.Type = Response.self
  ) async throws -> Response {
    return try await self.insertMany(
      .init(
        table: table,
        values: values,
        returningOptions: returningOptions
      )
    )
  }

  // MARK: - Update
  
  private func update<R: Decodable, V: Encodable>(
    _ request: DatabaseRequest.UpdateRequest<V>
  ) async throws -> R {
    
    @Dependency(\.supabaseClient.databaseClient) var db
    
    let builder = try self.from(request.table.tableName)
      .update(request.values, returning: request.returningOptions)
      .filter(by: request.filters)
      .single()
    
    return try await db.execute(.update(table: request.table, builder: builder), on: self)
      .value
  }


  /// A helper for updating an item in the database, using the table name and a filter for the item.
  ///
  /// ### Example
  ///
  /// ```swift
  /// let todo = try await databaseClient.update(
  ///   table: "todos",
  ///   where: [.equals("id", UUID(0))],
  ///   values: TodoUpdateRequest(complete: true),
  ///   returning: .representation,
  ///   decoding: TodoModel.self // this is generally inferred and not needed depending on the calling context.
  /// )
  /// ```
  ///
  /// - Parameters:
  ///   - table: The table name to update the row.
  ///   - filters: The filter(s) for the row query.
  ///   - values: The values to updated in the row.
  ///   - returningOptions: The postgres returning options (defaults to `.representation`)
  ///   - type: The type to decode from the response.
  @discardableResult
  public func update<Values: Encodable, Model: Decodable>(
    table: AnyTable,
    where filters: [DatabaseRequest.Filter],
    values: Values,
    returning returningOptions: PostgrestReturningOptions = .representation,
    decoding type: Model.Type = Model.self
  ) async throws -> Model {
    return try await self.update(
      .init(
        table: table,
        filters: filters,
        returningOptions: returningOptions,
        values: values
      )
    )
  }

  /// A helper for updating an item in the database, using the table name and a filter for the item.
  ///
  /// ### Example
  ///
  /// ```swift
  /// let todo = try await databaseClient.update(
  ///   table: Table.todos,
  ///   filteredBy: .equals("id", UUID(0)),
  ///   values: TodoUpdateRequest(complete: true),
  ///   returning: .representation,
  ///   decoding: TodoModel.self // this is generally inferred and not needed depending on the calling context.
  /// )
  /// ```
  ///
  /// - Parameters:
  ///   - table: The table name to update the row.
  ///   - filters: The filter(s) for the row query.
  ///   - values: The values to updated in the row.
  ///   - returningOptions: The postgres returning options (defaults to `.representation`)
  ///   - type: The type to decode from the response.
  @discardableResult
  public func update<Values: Encodable, Model: Decodable>(
    table: AnyTable,
    filteredBy filters: DatabaseRequest.Filter...,
    values: Values,
    returning returningOptions: PostgrestReturningOptions = .representation,
    decoding type: Model.Type = Model.self
  ) async throws -> Model {
    try await update(
      table: table,
      where: filters,
      values: values,
      returning: returningOptions,
      decoding: Model.self
    )
  }

  /// A helper for updating an item in the database, using the table name and the item's id. This method requires the column name
  /// in the database to be "id" for matching the id value against.
  ///
  /// ### Example
  ///
  /// ```swift
  /// let todo = try await databaseClient.update(
  ///   id: UUID(0)
  ///   in: Table.todo,
  ///   with: TodoUpdateRequest(complete: true),
  ///   returning: .representation,
  ///   decoding: TodoModel.self // this is generally inferred and not needed depending on the calling context.
  /// )
  /// ```
  ///
  /// - Parameters:
  ///   - id: The item's id.
  ///   - table: The table to update the row.
  ///   - values: The values to updated in the row.
  ///   - returningOptions: The postgres returning options (defaults to `.representation`)
  ///   - type: The type to decode from the response.
  @discardableResult
  public func update<
    ID: URLQueryRepresentable, Values: Encodable, Model: Decodable
  >(
    id: ID,
    in table: AnyTable,
    with values: Values,
    returning returningOptions: PostgrestReturningOptions = .representation,
    decoding type: Model.Type = Model.self
  ) async throws -> Model {
    try await update(
      table: table,
      filteredBy: .id(id),
      values: values,
      returning: returningOptions,
      decoding: Model.self
    )
  }


  // MARK: - Upsert
  private func upsert<R: Decodable, V: Encodable>(
    _ request: DatabaseRequest.UpsertRequest<V>
  ) async throws -> R {
    
    @Dependency(\.supabaseClient.databaseClient) var db
   
    let builder = try self.from(request.table.tableName)
      .upsert(request.values, returning: request.returningOptions, ignoreDuplicates: request.ignoreDuplicates)
      .filter(by: request.filters)
      .single()
    
    return try await db.execute(.upsert(table: request.table, builder: builder), on: self)
      .value
  }

  private func upsertMany<R: Decodable, V: Encodable>(
    _ request: DatabaseRequest.UpsertManyRequest<V>
  ) async throws -> [R] {
    @Dependency(\.supabaseClient.databaseClient) var db
    
    let builder = try self.from(request.table.tableName)
      .upsert(
        request.values,
        returning: request.returningOptions,
        ignoreDuplicates: request.ignoreDuplicates
      )
      .filter(by: request.filters)
    
    return try await db.execute(.upsertMany(table: request.table, builder: builder), on: self)
      .value
  }

  /// A helper for upserting an item in the database, using the table name and the item. This method requires the id to be
  /// supplied.
  ///
  /// ### Example
  ///
  /// ```swift
  ///  let newTodo: Todo = try await databaseClient.upsert(
  ///    Todo(id: .init(), description: "A new todo"),
  ///    in: .todos
  ///  )
  /// ```
  ///
  /// - Parameters:
  ///   - values: The values to updated in the row.
  ///   - table: The table to update the row.
  ///   - returningOptions: The postgres returning options (defaults to `.representation`)
  ///   - ignoringDuplicates: If `true` then duplicates are ignored, if `false` then duplicates are merged.
  ///   - type: The type to decode from the response.
  @discardableResult
  public func upsert<
    Values: Encodable, Model: Decodable
  >(
    _ values: Values,
    in table: AnyTable,
    returning returningOptions: PostgrestReturningOptions = .representation,
    ignoreDuplicates: Bool = false,
    decoding type: Model.Type = Model.self
  ) async throws -> Model where Values: Identifiable {
    try await self.upsert(
      .init(
        table: table,
        filters: [],
        returningOptions: returningOptions,
        ignoreDuplicates: ignoreDuplicates,
        values: values
      )
    )
  }

  /// A helper for upserting an item in the database, using the table name and the item. This method requires the id to be
  /// supplied.
  ///
  /// ### Example
  ///
  /// ```swift
  ///  let newTodo: Todo = try await databaseClient.upsert(
  ///    Todo(id: .init(), description: "A new todo"),
  ///    in: .todos
  ///  )
  /// ```
  ///
  /// - Parameters:
  ///   - values: The values to updated in the row.
  ///   - table: The table to update the row.
  ///   - returningOptions: The postgres returning options (defaults to `.representation`)
  ///   - ignoringDuplicates: If `true` then duplicates are ignored, if `false` then duplicates are merged.
  ///   - type: The type to decode from the response.
  @discardableResult
  public func upsert<
    Values: Encodable
  >(
    _ values: Values,
    in table: AnyTable,
    returning returningOptions: PostgrestReturningOptions = .representation,
    ignoreDuplicates: Bool = false,
    decoding type: Values.Type = Values.self
  ) async throws -> Values where Values: Identifiable, Values: Decodable {
    try await self.upsert(
      .init(
        table: table,
        filters: [],
        returningOptions: returningOptions,
        ignoreDuplicates: ignoreDuplicates,
        values: values
      )
    )
  }

  /// A helper for upserting multiple items in the database, using the table name and the item. This method requires the id to be
  /// supplied.
  ///
  /// ### Example
  ///
  /// ```swift
  ///  let newTodos: [Todo] = try await databaseClient.upsert(
  ///    [
  ///     Todo(id: .init(), description: "A new todo"),
  ///     Todo(id: .init(), description: "Another new todo"),
  ///    ],
  ///    in: .todos
  ///  )
  /// ```
  ///
  /// - Parameters:
  ///   - values: The values to updated in the row.
  ///   - table: The table to update the row.
  ///   - returningOptions: The postgres returning options (defaults to `.representation`)
  ///   - ignoringDuplicates: If `true` then duplicates are ignored, if `false` then duplicates are merged.
  ///   - type: The type to decode from the response.
  @discardableResult
  public func upsert<
    Value: Encodable, Model: Decodable
  >(
    _ values: [Value],
    in table: AnyTable,
    returning returningOptions: PostgrestReturningOptions = .representation,
    ignoreDuplicates: Bool = false,
    decoding type: [Model].Type = [Model].self
  ) async throws -> [Model] where Value: Identifiable {
    try await self.upsertMany(
      .init(
        table: table,
        filters: [],
        returningOptions: returningOptions,
        ignoreDuplicates: ignoreDuplicates,
        values: values
      )
    )
  }
  
  /// A helper for upserting multiple items in the database, using the table name and the item. This method requires the id to be
  /// supplied.
  ///
  /// ### Example
  ///
  /// ```swift
  ///  let newTodos: [Todo] = try await databaseClient.upsert(
  ///     Todo(id: .init(), description: "A new todo"),
  ///     Todo(id: .init(), description: "Another new todo"),
  ///    in: .todos
  ///  )
  /// ```
  ///
  /// - Parameters:
  ///   - values: The values to be upserted.
  ///   - table: The table to upsert the values in.
  ///   - returningOptions: The postgres returning options (defaults to `.representation`)
  ///   - ignoringDuplicates: If `true` then duplicates are ignored, if `false` then duplicates are merged.
  ///   - type: The type to decode from the response.
  @discardableResult
  public func upsert<
    Value: Encodable, Model: Decodable
  >(
    _ values: Value...,
    in table: AnyTable,
    returning returningOptions: PostgrestReturningOptions = .representation,
    ignoreDuplicates: Bool = false,
    decoding type: [Model].Type = [Model].self
  ) async throws -> [Model] where Value: Identifiable {
    try await self.upsertMany(
      .init(
        table: table,
        filters: [],
        returningOptions: returningOptions,
        ignoreDuplicates: ignoreDuplicates,
        values: values
      )
    )
  }
  
  /// A helper for upserting multiple items in the database, using the table name and the item. This method requires the id to be
  /// supplied.
  ///
  /// ### Example
  ///
  /// ```swift
  ///  let newTodos: [Todo] = try await databaseClient.upsert(
  ///    [
  ///     Todo(id: .init(), description: "A new todo"),
  ///     Todo(id: .init(), description: "Another new todo"),
  ///    ],
  ///    in: .todos
  ///  )
  /// ```
  ///
  /// - Parameters:
  ///   - values: The values to be upserted.
  ///   - table: The table to upsert the values in.
  ///   - returningOptions: The postgres returning options (defaults to `.representation`)
  ///   - ignoringDuplicates: If `true` then duplicates are ignored, if `false` then duplicates are merged.
  ///   - type: The type to decode from the response.
  @discardableResult
  public func upsert<
    Value: Encodable
  >(
    _ values: [Value],
    in table: AnyTable,
    returning returningOptions: PostgrestReturningOptions = .representation,
    ignoreDuplicates: Bool = false,
    decoding type: [Value].Type = [Value].self
  ) async throws -> [Value] where Value: Identifiable, Value: Decodable {
    try await self.upsertMany(
      .init(
        table: table,
        filters: [],
        returningOptions: returningOptions,
        ignoreDuplicates: ignoreDuplicates,
        values: values
      )
    )
  }
  
  /// A helper for upserting multiple items in the database, using the table name and the item. This method requires the id to be
  /// supplied.
  ///
  /// ### Example
  ///
  /// ```swift
  ///  let newTodos: [Todo] = try await databaseClient.upsert(
  ///     Todo(id: .init(), description: "A new todo"),
  ///     Todo(id: .init(), description: "Another new todo"),
  ///    in: .todos
  ///  )
  /// ```
  ///
  /// - Parameters:
  ///   - values: The values to be upserted.
  ///   - table: The table to upsert the values in.
  ///   - returningOptions: The postgres returning options (defaults to `.representation`)
  ///   - ignoringDuplicates: If `true` then duplicates are ignored, if `false` then duplicates are merged.
  ///   - type: The type to decode from the response.
  @discardableResult
  public func upsert<
    Value: Encodable
  >(
    _ values: Value...,
    in table: AnyTable,
    returning returningOptions: PostgrestReturningOptions = .representation,
    ignoreDuplicates: Bool = false,
    decoding type: [Value].Type = [Value].self
  ) async throws -> [Value] where Value: Identifiable, Value: Decodable {
    try await self.upsertMany(
      .init(
        table: table,
        filters: [],
        returningOptions: returningOptions,
        ignoreDuplicates: ignoreDuplicates,
        values: values
      )
    )
  }
}

fileprivate extension SupabaseClientDependency.DatabaseClient {
  
  // An internal helper that is used as a proxy for overrides.
  enum DatabaseExecutor {
    case delete(table: AnyTable, builder: PostgrestBuilder)
    case fetch(table: AnyTable, builder: PostgrestBuilder)
    case fetchOne(table: AnyTable, builder: PostgrestBuilder)
    case insert(table: AnyTable, builder: PostgrestBuilder)
    case insertMany(table: AnyTable, builder: PostgrestBuilder)
    case update(table: AnyTable, builder: PostgrestBuilder)
    case upsert(table: AnyTable, builder: PostgrestBuilder)
    case upsertMany(table: AnyTable, builder: PostgrestBuilder)

    var builder: PostgrestBuilder {
      switch self {
      case let .delete(table: _, builder: builder):
        return builder
      case let .fetch(table: _, builder: builder):
        return builder
      case let .fetchOne(table: _, builder: builder):
        return builder
      case let .insert(table: _, builder: builder):
        return builder
      case let .insertMany(table: _, builder: builder):
        return builder
      case let .update(table: _, builder: builder):
        return builder
      case let .upsert(table: _, builder: builder):
        return builder
      case let .upsertMany(table: _, builder: builder):
        return builder
      }
    }
    
    var override: SupabaseClientDependency.DatabaseOverride {
      switch self {
      case let .delete(table: table, builder: _):
        return .delete(from: table)
      case let .fetch(table: table, builder: _):
        return .fetch(from: table)
      case let .fetchOne(table: table, builder: _):
        return .fetchOne(from: table)
      case let .insert(table: table, builder: _):
        return .insert(into: table)
      case let .insertMany(table: table, builder: _):
        return .insertMany(into: table)
      case let .update(table: table, builder: _):
        return .update(in: table)
      case let .upsert(table: table, builder: _):
        return .upsert(in: table)
      case let .upsertMany(table: table, builder: _):
        return .upsertMany(in: table)
      }
    }
  }
  
  func execute(
    _ executor: DatabaseExecutor,
    on client: PostgrestClient
  ) async throws -> PostgrestResponse<Void> {
    
    // Short circuit if there is an `all` override.
    if let allMatch = overrides.first(where: { $0.override == .all }) {
      let allResponse = try await allMatch.response(client.configuration.encoder)
      return .init(data: allResponse.0, response: allResponse.1 as! HTTPURLResponse, value: ())
    }
    
    // Check if there are any specific overrides for this route.
    guard let firstMatch = overrides.first(where: {
      $0.override == executor.override
    }) else {
      return try await executor.builder.execute()
    }
    let response = try await firstMatch.response(client.configuration.encoder)
    return PostgrestResponse(
      data: response.0,
      response: response.1 as! HTTPURLResponse,
      value: ()
    )
  }
  
  func execute<T: Decodable>(
    _ executor: DatabaseExecutor,
    on client: PostgrestClient
  ) async throws -> PostgrestResponse<T> {
    
    // Short circuit if there is an `all` override.
    if let allMatch = overrides.first(where: { $0.override == .all }) {
      let allResponse = try await allMatch.response(client.configuration.encoder)
      let decoded = try client.configuration.decoder.decode(T.self, from: allResponse.0)
      return .init(data: allResponse.0, response: allResponse.1 as! HTTPURLResponse, value: decoded)
    }
    
    // Check if there are any specific overrides for this route.
    guard let firstMatch = overrides.first(where: {
      $0.override == executor.override
    }) else {
      return try await executor.builder.execute()
    }
    let response = try await firstMatch.response(client.configuration.encoder)
    let decoded = try client.configuration.decoder.decode(T.self, from: response.0)
    return PostgrestResponse(
      data: response.0,
      response: response.1 as! HTTPURLResponse,
      value: decoded
    )
  }
}
