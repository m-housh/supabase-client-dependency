import Foundation
import PostgREST

extension PostgrestQueryBuilder {
  
  /// A helper for deleting a database item by the provided filters.
  ///
  /// ### Example
  ///
  /// ```swift
  ///  try await database.from("todos").delete(
  ///     filteredBy: [
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
    filteredBy filters: [DatabaseFilter]
  ) -> PostgrestFilterBuilder {
    self.delete(returning: .minimal).filter(by: filters)
  }
  
  /// A helper for deleting a database item by the provided filters.
  ///
  /// ### Example
  ///
  /// ```swift
  ///  try await database.from("todos").delete(
  ///     filteredBy: .equals(column: "complete", value: false),
  ///                 .equals(column: "description", value: "Buy milk")
  ///  )
  /// ```
  ///
  /// - Parameters:
  ///   - table: The table name to delete the item from.
  ///   - filters: The filters for the row to be deleted from the database.
  public func delete(
    filteredBy filters: DatabaseFilter...
  ) -> PostgrestFilterBuilder {
    self.delete(filteredBy: filters)
  }
  
  /// A helper for deleting a database item by the id.
  ///
  /// ### Example
  ///
  /// ```swift
  ///  try await database.from("todos").delete(id: 1)
  /// ```
  ///
  /// - Parameters:
  ///   - table: The table name to delete the item from.
  ///   - filters: The filters for the row to be deleted from the database.
  public func delete<ID: URLQueryRepresentable>(
    id: ID
  ) -> PostgrestFilterBuilder {
    self.delete(filteredBy: .id(id))
  }

  // MARK: - Fetch
  
  /// A helper for fetching items from the database, using the table name, Filter's, and Order types.
  ///
  /// ### Example
  ///
  /// ```swift
  /// let todos = try await database.from("todos).fetch(
  ///   filteredBy: [.equals("complete", "false")],
  ///   orderBy: .init(column: "description").ascending()
  /// )
  /// ```
  ///
  /// - Parameters:
  ///   - filters: Filters to apply to the query.
  ///   - orderBy: An optional order by clause for the query.
  public func fetch(
    filteredBy filters: [DatabaseFilter] = [],
    orderBy order: DatabaseOrder? = nil
  ) -> PostgrestTransformBuilder {
    self.select().filter(by: filters).order(by: order)
  }
  
  /// A helper for fetching items from the database, using the table name, Filter's, and Order types.
  ///
  /// ### Example
  ///
  /// ```swift
  /// let todos = try await database.from("todos).fetch(
  ///   filteredBy: .equals("complete", "false"),
  ///   orderBy: .init(column: "description").ascending()
  /// )
  /// ```
  ///
  /// - Parameters:
  ///   - filters: Filters to apply to the query.
  ///   - orderBy: An optional order by clause for the query.
  public func fetch(
    filteredBy filters: DatabaseFilter...,
    orderBy order: DatabaseOrder? = nil
  ) -> PostgrestTransformBuilder  {
    self.fetch(filteredBy: filters, orderBy: order)
  }
  
  /// A helper for fetching a single tems from the database using the given filters.
  ///
  /// ### Example
  ///
  /// ```swift
  /// let todo = try await database.from("todos).fetchOne(
  ///   filteredBy: [.equals("complete", "false")]
  /// )
  /// ```
  ///
  /// - Parameters:
  ///   - filters: Filters to apply to the query.
  public func fetchOne(
    filteredBy filters: [DatabaseFilter]
  ) -> PostgrestTransformBuilder {
    self.fetch(filteredBy: filters).single()
  }
  /// A helper for fetching a single tems from the database given filters.
  ///
  /// ### Example
  ///
  /// ```swift
  /// let todo = try await database.from("todos).fetchOne(
  ///   filteredBy: .equals("complete", "false")
  /// )
  /// ```
  ///
  /// - Parameters:
  ///   - filters: Filters to apply to the query.
  public func fetchOne(
    filteredBy filters: DatabaseFilter...
  ) -> PostgrestTransformBuilder {
    self.fetchOne(filteredBy: filters)
  }
  
  /// A helper for fetching a single tems from the database, using the id.
  ///
  /// ### Example
  ///
  /// ```swift
  /// let todo = try await database.from("todos).fetchOne(
  ///   id: 1
  /// )
  /// ```
  ///
  /// - Parameters:
  ///   - filters: Filters to apply to the query.
  public func fetchOne<ID: URLQueryRepresentable>(
    id: ID
  ) -> PostgrestTransformBuilder {
    self.fetchOne(filteredBy: .id(id))
  }

  // MARK: - Update
  
  /// A helper for updating an item in the database, using the filters for the item.
  ///
  /// ### Example
  ///
  /// ```swift
  /// let todo = try await database.from("todos).update(
  ///   TodoUpdateRequest(complete: true),
  ///   returning: .representation,
  ///   filteredBy: [.equals("id", UUID(0))]
  /// )
  /// ```
  ///
  /// - Parameters:
  ///   - values: The values to updated in the row.
  ///   - returningOptions: The postgres returning options (defaults to `.representation`)
  ///   - filters: The filter(s) for the row query.
  public func update<Values: Encodable>(
    _ values: Values,
    returning returningOptions: PostgrestReturningOptions = .representation,
    filteredBy filters: [DatabaseFilter]
  ) throws -> PostgrestTransformBuilder {
    try self.update(values, returning: returningOptions)
      .filter(by: filters)
  }
  /// A helper for updating an item in the database, using the filters for the item.
  ///
  /// ### Example
  ///
  /// ```swift
  /// let todo = try await database.from("todos).update(
  ///   TodoUpdateRequest(complete: true),
  ///   returning: .representation,
  ///   filteredBy: .equals("id", UUID(0))
  /// )
  /// ```
  ///
  /// - Parameters:
  ///   - values: The values to updated in the row.
  ///   - returningOptions: The postgres returning options (defaults to `.representation`)
  ///   - filters: The filter(s) for the row query.
  public func update<Values: Encodable>(
    _ values: Values,
    returning returningOptions: PostgrestReturningOptions = .representation,
    filteredBy filters: DatabaseFilter...
  ) throws -> PostgrestTransformBuilder {
    try self.update(values, returning: returningOptions, filteredBy: filters)
  }
  
  /// A helper for updating an item in the database, using the id for the item.
  ///
  /// ### Example
  ///
  /// ```swift
  /// let todo = try await database.from("todos).update(
  ///   id: 1,
  ///   with: TodoUpdateRequest(complete: true),
  ///   returning: .representation
  /// )
  /// ```
  ///
  /// - Parameters:
  ///   - values: The values to updated in the row.
  ///   - returningOptions: The postgres returning options (defaults to `.representation`)
  ///   - filters: The filter(s) for the row query.
  public func update<
    ID: URLQueryRepresentable, Values: Encodable
  >(
    id: ID,
    with values: Values,
    returning returningOptions: PostgrestReturningOptions = .representation
  ) throws -> PostgrestTransformBuilder {
    try self.update(values, returning: returningOptions, filteredBy: .id(id)).single()
  }

}
