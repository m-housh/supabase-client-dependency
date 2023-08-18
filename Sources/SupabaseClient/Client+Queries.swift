import Foundation
import PostgREST

extension SupabaseClientDependency {
  
  // MARK: - Delete
    
  /// A helper for deleting a database item by it's id.
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
        .delete()
        .filter(by: filters)
        .execute()
        .value
    }
  }
  
  /// A helper for deleting a database item by it's id.
  ///
  /// - Parameters:
  ///   - table: The table name to delete the item from.
  ///   - filters: The filters for the row to be deleted from the database.
  public func delete(
    from table: String,
    filters: Filter...
  ) async throws {
    try await self.withDatabase { database in
      try await database.from(table)
        .delete()
        .filter(by: filters)
        .execute()
        .value
    }
  }
  
  /// A helper for deleting a database item by it's id.
  ///
  /// - Parameters:
  ///   - table: The table name to delete the item from.
  ///   - filter: The filter for the row to be deleted from the database.
  public func delete(
    from table: String,
    filteredBy filter: Filter
  ) async throws {
    try await self.withDatabase { database in
      try await database.from(table)
        .delete()
        .filter(by: filter)
        .execute()
        .value
    }
  }
  
  /// A helper for deleting a database item by it's id.
  ///
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
  /// - Parameters:
  ///   - table: The table name to fetch the values from.
  ///   - filters: Filters to apply to the query.
  ///   - orderBy: An optional order by clause for the query.
  ///   - type: The return value type to decode.
  public func fetch<R: Decodable>(
    from table: String,
    where filters: [Filter] = [],
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
  /// - Parameters:
  ///   - table: The table to fetch the values from.
  ///   - filters: Filters to apply to the query.
  ///   - orderBy: An optional order by clause for the query.
  ///   - type: The return value type to decode.
  public func fetch<R: Decodable, Table: TableRepresentable>(
    from table: Table,
    where filters: [Filter] = [],
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
  /// - Parameters:
  ///   - table: The table to fetch the values from.
  ///   - filter: Filter to apply to the query.
  ///   - orderBy: An optional order by clause for the query.
  ///   - type: The return value type to decode.
  public func fetch<R: Decodable>(
    from table: String,
    filteredBy filter: Filter,
    orderBy order: Order? = nil,
    as type: R.Type = R.self
  ) async throws -> [R] {
    try await self.fetch(from: table, where: [filter], orderBy: order, as: R.self)
  }
  
  /// A helper for fetching items from the database, using the table name, a Filter, and Order types.
  ///
  /// - Parameters:
  ///   - table: The table to fetch the values from.
  ///   - filter: Filter to apply to the query.
  ///   - orderBy: An optional order by clause for the query.
  ///   - type: The return value type to decode.
  public func fetch<R: Decodable, Table: TableRepresentable>(
    from table: Table,
    filteredBy filter: Filter,
    orderBy order: Order? = nil,
    as type: R.Type = R.self
  ) async throws -> [R] {
    try await self.fetch(from: table, where: [filter], orderBy: order, as: R.self)
  }
  
  // MARK: - Fetch One
    
  /// A helper for fetching items from the database, using the table name, Filter's, and Order types.
  ///
  /// - Parameters:
  ///   - table: The table name to fetch the values from.
  ///   - filters: Filters to apply to the query.
  ///   - orderBy: An optional order by clause for the query.
  ///   - type: The return value type to decode.
  public func fetchOne<R: Decodable>(
    from table: String,
    where filters: [Filter] = [],
    orderBy order: Order? = nil,
    as type: R.Type = R.self
  ) async throws -> R {
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
  /// - Parameters:
  ///   - table: The table to fetch the values from.
  ///   - filters: Filters to apply to the query.
  ///   - orderBy: An optional order by clause for the query.
  ///   - type: The return value type to decode.
  public func fetchOne<R: Decodable, Table: TableRepresentable>(
    from table: Table,
    where filters: [Filter] = [],
    orderBy order: Order? = nil,
    as type: R.Type = R.self
  ) async throws -> R {
    try await self.fetchOne(
      from: table.tableName,
      where: filters,
      orderBy: order,
      as: R.self
    )
  }
  
  /// A helper for fetching items from the database, using the table name, a Filter, and Order types.
  ///
  /// - Parameters:
  ///   - table: The table to fetch the values from.
  ///   - filter: Filter to apply to the query.
  ///   - orderBy: An optional order by clause for the query.
  ///   - type: The return value type to decode.
  public func fetchOne<R: Decodable>(
    from table: String,
    filteredBy filter: Filter,
    orderBy order: Order? = nil,
    as type: R.Type = R.self
  ) async throws -> R {
    try await self.fetchOne(from: table, where: [filter], orderBy: order, as: R.self)
  }
  
  /// A helper for fetching items from the database, using the table name, a Filter, and Order types.
  ///
  /// - Parameters:
  ///   - table: The table to fetch the values from.
  ///   - filter: Filter to apply to the query.
  ///   - orderBy: An optional order by clause for the query.
  ///   - type: The return value type to decode.
  public func fetchOne<R: Decodable, Table: TableRepresentable>(
    from table: Table,
    filteredBy filter: Filter,
    orderBy order: Order? = nil,
    as type: R.Type = R.self
  ) async throws -> R {
    try await self.fetchOne(from: table, where: [filter], orderBy: order, as: R.self)
  }
  
  // MARK: - Insert
  
  /// Helper for inserting a new value into the database.
  ///
  /// - Parameters:
  ///   - table: The table to insert the values into.
  ///   - values: The row values.
  ///   - type: The return value type to decode from the response.
  public func insert<V: Encodable, R: Decodable>(
    into table: String,
    values: V,
    as type: R.Type = R.self
  ) async throws -> R {
    try await self.withDatabase { database in
      try await database.from(table)
        .insert(values: values, returning: .representation)
        .single()
        .execute()
        .value
    }
  }
  
  /// Helper for inserting a new value into the database.
  ///
  /// - Parameters:
  ///   - table: The table to insert the values into.
  ///   - values: The row values.
  ///   - type: The return value type to decode from the response.
  public func insert<V: Encodable, R: Decodable, Table: TableRepresentable>(
    into table: Table,
    values: V,
    as type: R.Type = R.self
  ) async throws -> R {
    try await insert(into: table.tableName, values: values, as: R.self)
  }
  
  // MARK: - Update
  
  /// A helper for updating an item in the database, using the table name and a filter for the item.
  ///
  /// - Parameters:
  ///   - table: The table name to update the row.
  ///   - filter: The filter for the row query.
  ///   - values: The values to updated in the row.
  ///   - type: The type to decode from the response.
  @discardableResult
  public func update<Values: Encodable, R: Decodable>(
    table: String,
    filteredBy filter: Filter,
    values: Values,
    as type: R.Type = R.self
  ) async throws -> R {
    return try await self.withDatabase { database in
      try await database.from(table)
        .update(values: values, returning: .representation)
        .filter(by: filter)
        .single()
        .execute()
        .value
    }
  }
  
  /// A helper for updating an item in the database, using the table name and a filter for the item.
  ///
  /// - Parameters:
  ///   - table: The table to update the row.
  ///   - filter: The filter for the row query.
  ///   - values: The values to updated in the row.
  ///   - type: The type to decode from the response.
  @discardableResult
  public func update<Values: Encodable, R: Decodable, Table: TableRepresentable>(
    table: Table,
    filteredBy filter: Filter,
    values: Values,
    as type: R.Type = R.self
  ) async throws -> R {
    try await update(
      table: table.tableName,
      filteredBy: filter,
      values: values,
      as: R.self
    )
  }
  
  /// A helper for updating an item in the database, using the table name and the item's id.
  ///
  /// - Parameters:
  ///   - id: The item's id.
  ///   - table: The table to update the row.
  ///   - filter: The filter for the row query.
  ///   - values: The values to updated in the row.
  ///   - type: The type to decode from the response.
  @discardableResult
  public func update<ID: URLQueryRepresentable, Values: Encodable, R: Decodable>(
    id: ID,
    table: String,
    values: Values,
    as type: R.Type = R.self
  ) async throws -> R {
    try await update(
      table: table,
      filteredBy: .id(id),
      values: values,
      as: R.self
    )
  }
  
  /// A helper for updating an item in the database, using the table name and the item's id.
  ///
  /// - Parameters:
  ///   - id: The item's id.
  ///   - table: The table to update the row.
  ///   - filter: The filter for the row query.
  ///   - values: The values to updated in the row.
  ///   - type: The type to decode from the response.
  @discardableResult
  public func update<ID: URLQueryRepresentable, Values: Encodable, R: Decodable, Table: TableRepresentable>(
    id: ID,
    table: Table,
    values: Values,
    as type: R.Type = R.self
  ) async throws -> R {
    try await update(
      table: table,
      filteredBy: .id(id),
      values: values,
      as: R.self
    )
  }
}
