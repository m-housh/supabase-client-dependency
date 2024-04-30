import CasePaths
import Dependencies
import Foundation
import Supabase

public struct DatabaseRouter<Routes> {

  public init() { }

  public func run<T: TableRouter>(
    _ route: T,
    table: CaseKeyPath<Routes, T>
  ) async throws {
    @Dependency(\.databaseExecutor) var executor
    return try await executor.run(route)
  }

  public func run<A: Decodable, T: TableRouter>(
    _ route: T,
    table: CaseKeyPath<Routes, T>
  ) async throws -> A {
    @Dependency(\.databaseExecutor) var executor
    return try await executor.run(route)
  }
}

