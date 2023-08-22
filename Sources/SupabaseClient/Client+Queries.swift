import Foundation
import PostgREST

extension SupabaseClientDependency {

  // MARK: - Delete

  /// A helper for deleting a database item by the provided filters.
  ///
  /// ### Example
  ///
  /// ```swift
  ///  try await databaseClient.delete(
  ///     from: "todos",
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
    from table: String,
    where filters: [Filter]
  ) async throws {
    try await self.withDatabase { database in
      try await database.from(table)
        .delete(returning: .minimal)
        .filter(by: filters)
        .execute()
        .value
    }
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
  public func delete<Table: TableRepresentable>(
    from table: Table,
    where filters: [Filter]
  ) async throws {
    try await delete(from: table.tableName, where: filters)
  }

  /// A helper for deleting a database item by the provided filters.
  ///
  /// ### Example
  ///
  /// ```swift
  ///  try await databaseClient.delete(
  ///     from: "todos",
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
    from table: String,
    filteredBy filters: Filter...
  ) async throws {
    try await delete(from: table, where: filters)
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

  /// A helper for deleting a database item by it's id.
  ///
  /// ### Example
  ///
  /// ```swift
  ///  try await databaseClient.delete(
  ///     id: UUID(0),
  ///     from: "todos",
  ///  )
  /// ```
  /// - Parameters:
  ///   - id: The database item's id.
  ///   - table: The table name to delete the item from.
  public func delete<ID: URLQueryRepresentable>(
    id: ID,
    from table: String
  ) async throws {
    try await self.withDatabase { database in
      try await database.from(table)
        .delete()
        .filter(by: .id(id))
        .execute()
        .value
    }
  }

  /// A helper for deleting a database item by it's id.
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
    try await self.delete(id: id, from: table.tableName)
  }

  // MARK: - Fetch

  /// A helper for fetching items from the database, using the table name, Filter's, and Order types.
  ///
  /// ### Example
  ///
  /// ```swift
  /// let todos = try await databaseClient.fetch(
  ///   from: "todos",
  ///   where: [.equals("complete", "false")],
  ///   orderBy: .init(column: "description"),
  ///   as: TodoModel.self // this is generally inferred and not needed depending on calling context.
  /// )
  /// ```
  ///
  /// - Parameters:
  ///   - table: The table name to fetch the values from.
  ///   - filters: Filters to apply to the query.
  ///   - orderBy: An optional order by clause for the query.
  ///   - type: The return value type to decode.
  public func fetch<R: Decodable>(
    from table: String,
    where filters: [Filter],
    orderBy order: Order? = nil,
    as type: R.Type = R.self
  ) async throws -> [R] {
    try await self.withDatabase { database in
      try await database
        .from(table)
        .select()
        .filter(by: filters)
        .order(by: order)
        .execute()
        .value
    }
  }

  /// A helper for fetching items from the database, using the table name, Filter's, and Order types.
  ///
  /// ### Example
  ///
  /// ```swift
  /// let todos = try await databaseClient.fetch(
  ///   from: Table.todos,
  ///   where: [.equals("complete", "false")],
  ///   orderBy: .init(column: "description"),
  ///   as: TodoModel.self // this is generally inferred and not needed depending on calling context.
  /// )
  /// ```
  ///
  /// - Parameters:
  ///   - table: The table to fetch the values from.
  ///   - filters: Filters to apply to the query.
  ///   - orderBy: An optional order by clause for the query.
  ///   - type: The return value type to decode.
  public func fetch<R: Decodable, Table: TableRepresentable>(
    from table: Table,
    where filters: [Filter],
    orderBy order: Order? = nil,
    as type: R.Type = R.self
  ) async throws -> [R] {
    try await self.fetch(
      from: table.tableName,
      where: filters,
      orderBy: order,
      as: R.self
    )
  }

  /// A helper for fetching items from the database, using the table name, a Filter, and Order types.
  ///
  /// ### Example
  ///
  /// ```swift
  /// let todos = try await databaseClient.fetch(
  ///   from: "todos",
  ///   filteredBy: .equals("complete", "false"),
  ///   orderBy: .init(column: "description"),
  ///   as: TodoModel.self // this is generally inferred and not needed depending on calling context.
  /// )
  /// ```
  ///
  /// - Parameters:
  ///   - table: The table to fetch the values from.
  ///   - filters: Filter(s) to apply to the query.
  ///   - orderBy: An optional order by clause for the query.
  ///   - type: The return value type to decode.
  public func fetch<R: Decodable>(
    from table: String,
    filteredBy filters: Filter...,
    orderBy order: Order? = nil,
    as type: R.Type = R.self
  ) async throws -> [R] {
    try await self.fetch(from: table, where: filters, orderBy: order, as: R.self)
  }

  /// A helper for fetching items from the database, using the table name, a Filter, and Order types.
  ///
  /// ### Example
  ///
  /// ```swift
  /// let todos = try await databaseClient.fetch(
  ///   from: Table.todos,
  ///   filteredBy: .equals("complete", "false"),
  ///   orderBy: .init(column: "description"),
  ///   as: TodoModel.self // this is generally inferred and not needed depending on calling context.
  /// )
  /// ```
  ///
  /// - Parameters:
  ///   - table: The table to fetch the values from.
  ///   - filters: Filter(s) to apply to the query.
  ///   - orderBy: An optional order by clause for the query.
  ///   - type: The return value type to decode.
  public func fetch<R: Decodable, Table: TableRepresentable>(
    from table: Table,
    filteredBy filters: Filter...,
    orderBy order: Order? = nil,
    as type: R.Type = R.self
  ) async throws -> [R] {
    try await self.fetch(from: table, where: filters, orderBy: order, as: R.self)
  }

  // MARK: - Fetch One

  /// A helper for fetching as single item from the database, using the table name and Filter's.
  ///
  /// ### Example
  ///
  /// ```swift
  /// let todo = try await databaseClient.fetch(
  ///   from: "todos",
  ///   where: [.equals("id", UUID(0))],
  ///   as: TodoModel.self // this is generally inferred and not needed depending on calling context.
  /// )
  /// ```
  ///
  /// - Parameters:
  ///   - table: The table name to fetch the values from.
  ///   - filters: Filters to apply to the query.
  ///   - type: The return value type to decode.
  public func fetchOne<R: Decodable>(
    from table: String,
    where filters: [Filter],
    as type: R.Type = R.self
  ) async throws -> R {
    try await self.withDatabase { database in
      try await database
        .from(table)
        .select()
        .filter(by: filters)
        .single()
        .execute()
        .value
    }
  }

  /// A helper for fetching as single item from the database, using the table name and Filter's.
  ///
  /// ### Example
  ///
  /// ```swift
  /// let todo = try await databaseClient.fetch(
  ///   from: Table.todos,
  ///   where: [.equals("id", UUID(0))],
  ///   as: TodoModel.self // this is generally inferred and not needed depending on calling context.
  /// )
  /// ```
  ///
  /// - Parameters:
  ///   - table: The table name to fetch the values from.
  ///   - filters: Filters to apply to the query.
  ///   - type: The return value type to decode.
  public func fetchOne<R: Decodable, Table: TableRepresentable>(
    from table: Table,
    where filters: [Filter],
    as type: R.Type = R.self
  ) async throws -> R {
    try await self.fetchOne(
      from: table.tableName,
      where: filters,
      as: R.self
    )
  }

  /// A helper for fetching as single item from the database, using the table name and Filter's.
  ///
  /// ### Example
  ///
  /// ```swift
  /// let todo = try await databaseClient.fetch(
  ///   from: "todos",
  ///   filteredBy: .equals("id", UUID(0)),
  ///   as: TodoModel.self // this is generally inferred and not needed depending on calling context.
  /// )
  /// ```
  ///
  /// - Parameters:
  ///   - table: The table name to fetch the values from.
  ///   - filters: Filters to apply to the query.
  ///   - type: The return value type to decode.
  public func fetchOne<R: Decodable>(
    from table: String,
    filteredBy filters: Filter...,
    as type: R.Type = R.self
  ) async throws -> R {
    try await self.fetchOne(
      from: table,
      where: filters,
      as: R.self
    )
  }

  /// A helper for fetching as single item from the database, using the table name and Filter's.
  ///
  /// ### Example
  ///
  /// ```swift
  /// let todo = try await databaseClient.fetch(
  ///   from: Table.todos,
  ///   filteredBy: .equals("id", UUID(0)),
  ///   as: TodoModel.self // this is generally inferred and not needed depending on calling context.
  /// )
  /// ```
  ///
  /// - Parameters:
  ///   - table: The table name to fetch the values from.
  ///   - filters: Filters to apply to the query.
  ///   - type: The return value type to decode.
  public func fetchOne<R: Decodable, Table: TableRepresentable>(
    from table: Table,
    filteredBy filters: Filter...,
    as type: R.Type = R.self
  ) async throws -> R {
    try await self.fetchOne(
      from: table,
      where: filters,
      as: R.self
    )
  }

  /// A helper for fetching items from the database, using the table name and an id of an element.
  ///
  /// ### Example
  ///
  /// ```swift
  /// let todo = try await databaseClient.fetch(
  ///   id: UUID(0),
  ///   from: "todos",
  ///   as: TodoModel.self // this is generally inferred and not needed depending on calling context.
  /// )
  /// ```
  ///
  /// - Parameters:
  ///   - id: The id of the item to fetch from the database.
  ///   - table: The table to fetch the values from.
  ///   - type: The return value type to decode.
  public func fetchOne<R: Decodable>(
    id: R.ID,
    from table: String,
    as type: R.Type = R.self
  ) async throws -> R where R: Identifiable, R.ID: URLQueryRepresentable {
    try await self.fetchOne(
      from: table,
      where: [.id(id)],
      as: R.self
    )
  }

  /// A helper for fetching items from the database, using the table name and an id of an element.
  ///
  /// ### Example
  ///
  /// ```swift
  /// let todo = try await databaseClient.fetch(
  ///   id: UUID(0),
  ///   from: Table.todos,
  ///   as: TodoModel.self // this is generally inferred and not needed depending on calling context.
  /// )
  /// ```
  ///
  /// - Parameters:
  ///   - id: The id of the item to fetch from the database.
  ///   - table: The table to fetch the values from.
  ///   - type: The return value type to decode.
  public func fetchOne<R: Decodable, Table: TableRepresentable>(
    id: R.ID,
    from table: Table,
    as type: R.Type = R.self
  ) async throws -> R where R: Identifiable, R.ID: URLQueryRepresentable {
    try await self.fetchOne(
      from: table,
      where: [.id(id)],
      as: R.self
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
  ///   into: "todos",
  ///   returning: .representation,
  ///   as: TodoModel.self // this is generally inferred and not needed depending on the calling context.
  /// )
  /// ```
  ///
  /// - Parameters:
  ///   - table: The table to insert the values into.
  ///   - values: The row values.
  ///   - returningOptions: The postgres returning options (defaults to `.representation`)
  ///   - type: The return value type to decode from the response.
  public func insert<V: Encodable, R: Decodable>(
    _ values: V,
    into table: String,
    returning returningOptions: PostgrestReturningOptions? = .representation,
    as type: R.Type = R.self
  ) async throws -> R {
    try await self.withDatabase { database in
      try await database.from(table)
        .insert(values: values, returning: returningOptions)
        .single()
        .execute()
        .value
    }
  }

  /// Helper for inserting a new value into the database.
  ///
  /// ### Example
  ///
  /// ```swift
  /// let todo = try await databaseClient.insert(
  ///   into: Table.todos,
  ///   values: TodoInsertRequest(description: "New Todo", complete: false),
  ///   returning: .representation,
  ///   as: TodoModel.self // this is generally inferred and not needed depending on the calling context.
  /// )
  /// ```
  ///
  /// - Parameters:
  ///   - table: The table to insert the values into.
  ///   - values: The row values.
  ///   - returningOptions: The postgres returning options (defaults to `.representation`)
  ///   - type: The return value type to decode from the response.
  public func insert<V: Encodable, R: Decodable, Table: TableRepresentable>(
    _ values: V,
    into table: Table,
    returning returningOptions: PostgrestReturningOptions? = .representation,
    as type: R.Type = R.self
  ) async throws -> R {
    try await insert(
      values,
      into: table.tableName,
      returning: returningOptions,
      as: R.self
    )
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
  ///   as: TodoModel.self // this is generally inferred and not needed depending on the calling context.
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
  public func update<Values: Encodable, R: Decodable>(
    table: String,
    where filters: [Filter],
    values: Values,
    returning returningOptions: PostgrestReturningOptions = .representation,
    as type: R.Type = R.self
  ) async throws -> R {
    return try await self.withDatabase { database in
      try await database.from(table)
        .update(values: values, returning: returningOptions)
        .filter(by: filters)
        .single()
        .execute()
        .value
    }
  }

  /// A helper for updating an item in the database, using the table name and a filter for the item.
  ///
  /// ### Example
  ///
  /// ```swift
  /// let todo = try await databaseClient.update(
  ///   table: "todos",
  ///   filteredBy: .equals("id", UUID(0)),
  ///   values: TodoUpdateRequest(complete: true),
  ///   returning: .representation,
  ///   as: TodoModel.self // this is generally inferred and not needed depending on the calling context.
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
  public func update<Values: Encodable, R: Decodable>(
    table: String,
    filteredBy filters: Filter...,
    values: Values,
    returning returningOptions: PostgrestReturningOptions = .representation,
    as type: R.Type = R.self
  ) async throws -> R {
    try await update(
      table: table,
      where: filters,
      values: values,
      returning: returningOptions,
      as: R.self
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
  ///   as: TodoModel.self // this is generally inferred and not needed depending on the calling context.
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
  public func update<Values: Encodable, R: Decodable, Table: TableRepresentable>(
    table: Table,
    filteredBy filters: Filter...,
    values: Values,
    returning returningOptions: PostgrestReturningOptions = .representation,
    as type: R.Type = R.self
  ) async throws -> R {
    try await update(
      table: table.tableName,
      where: filters,
      values: values,
      returning: returningOptions,
      as: R.self
    )
  }

  /// A helper for updating an item in the database, using the table name and the item's id.
  ///
  /// ### Example
  ///
  /// ```swift
  /// let todo = try await databaseClient.update(
  ///   id: UUID(0)
  ///   in: "todo",
  ///   with: TodoUpdateRequest(complete: true),
  ///   returning: .representation,
  ///   as: TodoModel.self // this is generally inferred and not needed depending on the calling context.
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
  public func update<ID: URLQueryRepresentable, Values: Encodable, R: Decodable>(
    id: ID,
    in table: String,
    with values: Values,
    returning returningOptions: PostgrestReturningOptions = .representation,
    as type: R.Type = R.self
  ) async throws -> R {
    try await update(
      table: table,
      filteredBy: .id(id),
      values: values,
      returning: returningOptions,
      as: R.self
    )
  }

  /// A helper for updating an item in the database, using the table name and the item's id.
  ///
  /// ### Example
  ///
  /// ```swift
  /// let todo = try await databaseClient.update(
  ///   id: UUID(0)
  ///   in: Table.todo,
  ///   with: TodoUpdateRequest(complete: true),
  ///   returning: .representation,
  ///   as: TodoModel.self // this is generally inferred and not needed depending on the calling context.
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
    ID: URLQueryRepresentable, Values: Encodable, R: Decodable, Table: TableRepresentable
  >(
    id: ID,
    in table: Table,
    with values: Values,
    returning returningOptions: PostgrestReturningOptions = .representation,
    as type: R.Type = R.self
  ) async throws -> R {
    try await update(
      table: table,
      filteredBy: .id(id),
      values: values,
      returning: returningOptions,
      as: R.self
    )
  }
}
