import Dependencies
import Foundation
import PostgREST

public typealias DatabaseDeleteRequest = SupabaseClientDependency.DatabaseClient.DeleteRequest
public typealias DatabaseFetchRequest = SupabaseClientDependency.DatabaseClient.FetchRequest
public typealias DatabaseFetchOneRequest = SupabaseClientDependency.DatabaseClient.FetchOneRequest
public typealias DatabaseInsertRequest = SupabaseClientDependency.DatabaseClient.InsertRequest
public typealias DatabaseInsertManyRequest = SupabaseClientDependency.DatabaseClient.InsertManyRequest
public typealias DatabaseUpdateRequest = SupabaseClientDependency.DatabaseClient.UpdateRequest

extension PostgrestClient {
  func delete(
    _ request: DatabaseDeleteRequest
  ) async throws {
    try await self.from(request.table.tableName)
      .delete(returning: .minimal)
      .filter(by: request.filters)
      .execute()
      .value
  }
  
  public func delete(
    from table: AnyTable,
    where filters: [DatabaseFilter]
  ) async throws {
    try await self.delete(.init(table: table, filters: filters))
  }
  
  /// A helper for deleting a database item by the provided filters.
  ///
  /// ### Example
  ///
  /// ```swift
  ///  try await databaseClient.delete(
  ///     from: Table.todos,
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
//  public func delete<Table: TableRepresentable>(
//    from table: Table,
//    where filters: [DatabaseFilter]
//  ) async throws {
//    try await self.delete(from: AnyTable(table), where: filters)
//  }
  

  
  /// A helper for deleting a database item by the provided filters.
  ///
  /// ### Example
  ///
  /// ```swift
  ///  try await databaseClient.delete(
  ///     from: Table.todos,
  ///     filteredBy:
  ///       .equals(column: "complete", value: false),
  ///       .equals(column: "description", value: "Buy milk")
  ///  )
  /// ```
  ///
  /// - Parameters:
  ///   - table: The table name to delete the item from.
  ///   - filters: The filters for the row to be deleted from the database.
//  public func delete<Table: TableRepresentable>(
//    from table: Table,
//    filteredBy filters: DatabaseFilter...
//  ) async throws {
//    try await delete(from: table, where: filters)
//  }
  public func delete(
    from table: AnyTable,
    filteredBy filters: DatabaseFilter...
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
  ///     from: Table.todos,
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
  
  func fetch(
    _ request: DatabaseFetchRequest
  ) async throws -> Data {
    try await self.from(request.table.tableName)
      .select()
      .filter(by: request.filters)
      .order(by: request.order)
      .execute()
      .value
  }

  // MARK: - Fetch

  /// A helper for fetching items from the database, using the table name, Filter's, and Order types.
  ///
  /// ### Example
  ///
  /// ```swift
  /// let todos = try await databaseClient.fetch(
  ///   from: Table.todos,
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
  public func fetch<Response: Decodable>(
    from table: AnyTable,
    where filters: [DatabaseFilter] = [],
    orderBy order: DatabaseOrder? = nil,
    decoding type: Response.Type = Response.self
  ) async throws -> Response {
    @Dependency(\.databaseDecoder) var decoder
    
    return try await self.fetch(
      .init(table: table, filters: filters, order: order)
    )
    .decoding(as: Response.self, with: decoder)
  }

  /// A helper for fetching items from the database, using the table name, a Filter, and Order types.
  ///
  /// ### Example
  ///
  /// ```swift
  /// let todos = try await databaseClient.fetch(
  ///   from: Table.todos,
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
    filteredBy filters: DatabaseFilter...,
    orderBy order: DatabaseOrder? = nil,
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
  
  func fetchOne(
    _ request: DatabaseFetchOneRequest
  ) async throws -> Data {
    try await self.from(request.table.tableName)
      .select()
      .filter(by: request.filters)
      .single()
      .execute()
      .value
  }

  /// A helper for fetching as single item from the database, using the table name and Filter's.
  ///
  /// ### Example
  ///
  /// ```swift
  /// let todo = try await databaseClient.fetch(
  ///   from: Table.todos,
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
    where filters: [DatabaseFilter],
    decoding type: Model.Type = Model.self
  ) async throws -> Model {
    @Dependency(\.databaseDecoder) var decoder
    return try await self.fetchOne(
      .init(
        table: table,
        filters: filters
      )
    )
    .decoding(as: Model.self, with: decoder)
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
    filteredBy filters: DatabaseFilter...,
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
  
  func insert(
    _ request: DatabaseInsertRequest
  ) async throws -> Data {
    try await self.from(request.table.tableName)
      .insert(request.values, returning: request.returningOptions)
      .single()
      .execute()
      .value
  }
  
  func insertMany(
    _ request: DatabaseInsertManyRequest
  ) async throws -> Data {
    try await self.from(request.table.tableName)
      .insert(
        request.values.anyJSON(encoder: .databaseClientEncoder),
        returning: request.returningOptions
      )
      .execute()
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
    @Dependency(\.databaseDecoder) var decoder
    return try await self.insert(
      .init(
        table: table,
        values: values,
        returningOptions: returningOptions
      )
    )
    .decoding(as: Model.self, with: decoder)
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
    @Dependency(\.databaseDecoder) var decoder
    return try await self.insertMany(
      .init(
        table: table,
        values: values,
        returningOptions: returningOptions
      )
    )
    .decoding(as: Response.self, with: decoder)
  }

  // MARK: - Update
  
  func update(_ request: DatabaseUpdateRequest) async throws -> Data {
    try await self.from(request.table.tableName)
      .update(request.values, returning: request.returningOptions)
      .filter(by: request.filters)
      .single()
      .execute()
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
    where filters: [DatabaseFilter],
    values: Values,
    returning returningOptions: PostgrestReturningOptions = .representation,
    decoding type: Model.Type = Model.self
  ) async throws -> Model {
    @Dependency(\.databaseDecoder) var decoder
    return try await self.update(
      .init(
        table: table,
        filters: filters,
        returningOptions: returningOptions,
        values: values
      )
    )
    .decoding(as: Model.self, with: decoder)
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
    filteredBy filters: DatabaseFilter...,
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
}

extension SupabaseClientDependency.DatabaseClient {

  // MARK: - Delete

  /// A helper for deleting a database item by the provided filters.
  ///
  /// ### Example
  ///
  /// ```swift
  ///  try await databaseClient.delete(
  ///     from: Table.todos,
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
  public func delete<Table: TableRepresentable>(
    from table: Table,
    where filters: [Filter]
  ) async throws {
    try await self.delete(.init(table: table, filters: filters))
  }

  /// A helper for deleting a database item by the provided filters.
  ///
  /// ### Example
  ///
  /// ```swift
  ///  try await databaseClient.delete(
  ///     from: Table.todos,
  ///     filteredBy:
  ///       .equals(column: "complete", value: false),
  ///       .equals(column: "description", value: "Buy milk")
  ///  )
  /// ```
  ///
  /// - Parameters:
  ///   - table: The table name to delete the item from.
  ///   - filters: The filters for the row to be deleted from the database.
  public func delete<Table: TableRepresentable>(
    from table: Table,
    filteredBy filters: Filter...
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
  ///     from: Table.todos,
  ///  )
  /// ```
  /// - Parameters:
  ///   - id: The database item's id.
  ///   - table: The table name to delete the item from.
  public func delete<ID: URLQueryRepresentable, Table: TableRepresentable>(
    id: ID,
    from table: Table
  ) async throws {
    try await self.delete(from: table.tableName, filteredBy: .id(id))
  }

  // MARK: - Fetch

  /// A helper for fetching items from the database, using the table name, Filter's, and Order types.
  ///
  /// ### Example
  ///
  /// ```swift
  /// let todos = try await databaseClient.fetch(
  ///   from: Table.todos,
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
  public func fetch<Response: Decodable, Table: TableRepresentable>(
    from table: Table,
    where filters: [Filter] = [],
    orderBy order: Order? = nil,
    decoding type: Response.Type = Response.self
  ) async throws -> Response {
    try await self.fetch(
      .init(table: table, filters: filters, order: order)
    )
    .decoding(as: Response.self, with: self.decoder)
  }

  /// A helper for fetching items from the database, using the table name, a Filter, and Order types.
  ///
  /// ### Example
  ///
  /// ```swift
  /// let todos = try await databaseClient.fetch(
  ///   from: Table.todos,
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
  public func fetch<Response: Decodable, Table: TableRepresentable>(
    from table: Table,
    filteredBy filters: Filter...,
    orderBy order: Order? = nil,
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

  /// A helper for fetching as single item from the database, using the table name and Filter's.
  ///
  /// ### Example
  ///
  /// ```swift
  /// let todo = try await databaseClient.fetch(
  ///   from: Table.todos,
  ///   where: [TodoColumn.id.equals(UUID(0))],
  ///   decoding: TodoModel.self // this is generally inferred and not needed depending on calling context.
  /// )
  /// ```
  ///
  /// - Parameters:
  ///   - table: The table name to fetch the values from.
  ///   - filters: Filters to apply to the query.
  ///   - type: The return value type to decode.
  public func fetchOne<Model: Decodable, Table: TableRepresentable>(
    from table: Table,
    where filters: [Filter],
    decoding type: Model.Type = Model.self
  ) async throws -> Model {
    try await self.fetchOne(
      .init(
        table: table,
        filters: filters
      )
    )
    .decoding(as: Model.self, with: self.decoder)
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
  public func fetchOne<Model: Decodable, Table: TableRepresentable>(
    from table: Table,
    filteredBy filters: Filter...,
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
  public func fetchOne<Model: Decodable, Table: TableRepresentable>(
    id: Model.ID,
    from table: Table,
    decoding type: Model.Type = Model.self
  ) async throws -> Model where Model: Identifiable, Model.ID: URLQueryRepresentable {
    try await self.fetchOne(
      from: table,
      filteredBy: .id(id),
      decoding: Model.self
    )
  }

  // MARK: - Insert

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
  public func insert<Values: Encodable, Model: Decodable, Table: TableRepresentable>(
    _ values: Values,
    into table: Table,
    returning returningOptions: PostgrestReturningOptions = .representation,
    decoding type: Model.Type = Model.self
  ) async throws -> Model {
    try await self.insert(
      .init(
        table: table,
        values: values,
        returningOptions: returningOptions
      )
    )
    .decoding(as: Model.self, with: self.decoder)
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
  public func insert<Values: Encodable, Response: Decodable, Table: TableRepresentable>(
    _ values: [Values],
    into table: Table,
    returning returningOptions: PostgrestReturningOptions = .representation,
    decoding type: Response.Type = Response.self
  ) async throws -> Response {
    try await self.insertMany(
      .init(
        table: table,
        values: values,
        returningOptions: returningOptions
      )
    )
    .decoding(as: Response.self, with: self.decoder)
  }

  // MARK: - Update

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
  public func update<Values: Encodable, Model: Decodable, Table: TableRepresentable>(
    table: Table,
    where filters: [Filter],
    values: Values,
    returning returningOptions: PostgrestReturningOptions = .representation,
    decoding type: Model.Type = Model.self
  ) async throws -> Model {
    try await self.update(
      .init(
        table: table,
        filters: filters,
        returningOptions: returningOptions,
        values: values
      )
    )
    .decoding(as: Model.self, with: self.decoder)
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
  public func update<Values: Encodable, Model: Decodable, Table: TableRepresentable>(
    table: Table,
    filteredBy filters: Filter...,
    values: Values,
    returning returningOptions: PostgrestReturningOptions = .representation,
    decoding type: Model.Type = Model.self
  ) async throws -> Model {
    try await update(
      table: table.tableName,
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
    ID: URLQueryRepresentable, Values: Encodable, Model: Decodable, Table: TableRepresentable
  >(
    id: ID,
    in table: Table,
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
}
