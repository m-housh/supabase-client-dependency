import DatabaseExtensions
import Dependencies
import DependenciesMacros
import Foundation
import PostgREST

extension DependencyValues {

  /// Access the database executor that can execute queries on the database.
  public var databaseExecutor: DatabaseExecutor {
    get { self[DatabaseExecutor.self] }
    set { self[DatabaseExecutor.self] = newValue }
  }
}

/// Execute queries on the database and decode the results.
///
///
@DependencyClient
public struct DatabaseExecutor {
  
  /// The json decoder used to decode responses.
  public var decoder: JSONDecoder = .init()
  
  /// Execute commands on the database and return the data.
  public var execute: (PostgrestBuilder) async throws -> Data
  
  /// Create a query builder for the given table.
  public var query: (AnyTable) throws -> PostgrestQueryBuilder

  /// Run the table route on the database.
  public func run<T: TableRouter>(_ route: T) async throws {
    _ = try await self.execute(
      route.build(query: query(T.table), route: route)
    )
  }

  /// Run the table route on the database.
  @discardableResult
  public func run<A: Decodable, T: TableRouter>(
    _ route: T
  ) async throws -> A {
    let data = try await self.execute(
      route.build(query: query(T.table), route: route)
    )
    return try decoder.decode(A.self, from: data)
  }

}

extension DatabaseExecutor: TestDependencyKey {
  public static let testValue = Self.init()
}

extension DatabaseExecutor {
  public static func live(database: PostgrestClient) -> Self {
    .init(
      decoder: database.configuration.decoder,
      execute: { try await $0.execute().data },
      query: { database.from($0.tableName) }
    )
  }
}
