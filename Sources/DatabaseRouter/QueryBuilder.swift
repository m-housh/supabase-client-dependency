import Foundation
import PostgREST

/// Handles routes for a table, returning the database queries that can be executed for the
/// given table.
///
public struct QueryBuilder<TableRoute> {
  
  let build: (PostgrestQueryBuilder, TableRoute) throws -> PostgrestBuilder

  public init(build: @escaping (PostgrestQueryBuilder, TableRoute) throws -> PostgrestBuilder) {
    self.build = build
  }
  
  public func callAsFunction(query: PostgrestQueryBuilder, route: TableRoute) throws -> PostgrestBuilder {
    try build(query, route)
  }
}
