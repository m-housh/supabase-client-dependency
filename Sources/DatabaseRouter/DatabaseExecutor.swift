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
/// This type  needs to be extended to provide the live implementation in your application,
/// by  passing in a `PostgrestClient` and using the ``live(database:)`` helper.
///
@DependencyClient
public struct DatabaseExecutor {
  
  /// The json decoder used to decode responses.
  public var decoder: JSONDecoder = .init()
  
  /// Execute commands on the database and return the data.
  public var execute: (PostgrestBuilder) async throws -> Data
  
  /// Create a query builder for the given table.
  public var query: (AnyTable) throws -> PostgrestQueryBuilder

  /// Run the route on the database.
  public func run(_ route: RouteContainer) async throws {
    _ = try await self.execute(
      route.build(self.query)
    )
  }

  /// Run the route on the database and decode the output.
  @discardableResult
  public func run<A: Decodable>(
    _ route: RouteContainer
  ) async throws -> A {
    let data = try await self.execute(
      route.build(self.query)
    )
    return try decoder.decode(A.self, from: data)
  }

  /// Run the route on the database, ignoring any output.
  public func run<T: RouteController>(_ router: T) async throws {
    try await self.run(router.route())
  }

  /// Run the table route on the database.
  @discardableResult
  public func run<A: Decodable, T: RouteController>(
    _ router: T
  ) async throws -> A {
    try await self.run(router.route())
  }

}

extension DatabaseExecutor: TestDependencyKey {
  public static let testValue = Self.init()
}

extension DatabaseExecutor {

  /// A helper to create the live dependency from the given `PostgrestClient`.
  ///
  public static func live(database: PostgrestClient) -> Self {
    .init(
      decoder: database.configuration.decoder,
      execute: { try await $0.execute().data },
      query: { database.from($0.tableName) }
    )
  }
}
