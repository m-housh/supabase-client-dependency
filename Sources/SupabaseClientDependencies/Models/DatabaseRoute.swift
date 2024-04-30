import Foundation
import Supabase

public typealias RouteHandler<Input> = (Input, PostgrestQueryBuilder) -> PostgrestBuilder

public struct DatabaseRoute<Input, Output> {
  let table: AnyTable
  let queryType: QueryType
  let handler: RouteHandler<Input>
  
  public enum QueryType: Equatable {
    case delete
    case fetch
    case insert
    case update
    case upsert
  }
}

extension DatabaseRoute: Equatable {
  public static func == (lhs: DatabaseRoute, rhs: DatabaseRoute) -> Bool {
    return lhs.table == rhs.table && 
      lhs.queryType == rhs.queryType
  }
}

extension PostgrestClient {
  
   func execute<Input>(
    _ route: DatabaseRoute<Input, Void>,
    _ input: Input
  ) async throws {
    try await route.handler(
      input,
      self.from(route.table.tableName)
    )
    .execute()
    .value
  }
  
  func execute<Input, Output: Decodable>(
    _ route: DatabaseRoute<Input, Output>,
    _ input: Input
  ) async throws -> Output {
    try await route.handler(
      input,
      self.from(route.table.tableName)
    )
    .execute()
    .value
  }
}
