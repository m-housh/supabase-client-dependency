import Dependencies
import Supabase
import SupabaseExtensions

public protocol TableRouter {
  var table: AnyTable { get }
  var builder: QueryBuilder<Self> { get }
}

extension TableRouter {
  func execute(
    query: @escaping (AnyTable) throws -> PostgrestQueryBuilder,
    execute: @escaping (PostgrestBuilder) async throws -> Void
  ) async throws {
    return try await execute(
      builder.build(query(self.table), self)
    )
  }

  @discardableResult
  func execute<A: Decodable>(
    query: @escaping (AnyTable) throws -> PostgrestQueryBuilder,
    execute: @escaping (PostgrestBuilder) async throws -> A
  ) async throws -> A {
    return try await execute(
      builder.build(query(self.table), self)
    )
  }
}
