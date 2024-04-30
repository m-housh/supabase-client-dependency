import Dependencies
import DependenciesMacros
import Foundation
import Supabase
import SupabaseExtensions

extension DependencyValues {

  public var databaseExecutor: DatabaseExecutor {
    get { self[DatabaseExecutor.self] }
    set { self[DatabaseExecutor.self] = newValue }
  }
}

@DependencyClient
public struct DatabaseExecutor {
  public var decoder: JSONDecoder = .init()
  public var execute: (PostgrestBuilder) async throws -> Data
  public var query: (AnyTable) throws -> PostgrestQueryBuilder

  func run(_ builder: PostgrestBuilder) async throws {
    _ = try await self.execute(builder)
  }

  @discardableResult
  func run<A: Decodable>(
    _ builder: PostgrestBuilder
  ) async throws -> A {
    let data = try await self.execute(builder)
    return try decoder.decode(A.self, from: data)
  }

  public func run<T: TableRouter>(_ route: T) async throws {
    try await route.execute(query: self.query, execute: self.run)
  }

  @discardableResult
  public func run<A: Decodable, T: TableRouter>(
    _ route: T
  ) async throws -> A {
    try await route.execute(query: self.query, execute: self.run)
  }

}

extension DatabaseExecutor: TestDependencyKey {
  public static let testValue = Self.init()
}
