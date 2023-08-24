import Foundation
import PostgREST

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
  ///   decoding: TodoModel.self // this is generally inferred and not needed depending on calling context.
  /// )
  /// ```
  ///
  /// - Parameters:
  ///   - table: The table to fetch the values from.
  ///   - filters: Filters to apply to the query.
  ///   - orderBy: An optional order by clause for the query.
  ///   - type: The return value type to decode.
  public func fetch<Model: Decodable, Table: TableRepresentable>(
    from table: Table,
    where filters: [Filter] = [],
    orderBy order: Order? = nil,
    decoding type: Model.Type = Model.self
  ) async throws -> [Model] {
    try await self.fetch(
      .init(table: table, filters: filters, order: order)
    )
    .decoding(as: Model.self)
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
  ///   decoding: TodoModel.self // this is generally inferred and not needed depending on calling context.
  /// )
  /// ```
  ///
  /// - Parameters:
  ///   - table: The table to fetch the values from.
  ///   - filters: Filter(s) to apply to the query.
  ///   - orderBy: An optional order by clause for the query.
  ///   - type: The return value type to decode.
  public func fetch<Model: Decodable, Table: TableRepresentable>(
    from table: Table,
    filteredBy filters: Filter...,
    orderBy order: Order? = nil,
    decoding type: Model.Type = Model.self
  ) async throws -> [Model] {
    try await self.fetch(
      from: table,
      where: filters,
      orderBy: order,
      decoding: Model.self
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
    .decoding(as: Model.self)
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
    .decoding(as: Model.self)
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
  public func insert<Values: Encodable, Model: Decodable, Table: TableRepresentable>(
    _ values: [Values],
    into table: Table,
    returning returningOptions: PostgrestReturningOptions = .representation,
    decoding type: Model.Type = Model.self
  ) async throws -> [Model] {
    try await self.insertMany(
      .init(
        table: table,
        values: values,
        returningOptions: returningOptions
      )
    )
    .decoding(as: Model.self)
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
    .decoding(as: Model.self)
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
