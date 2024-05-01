import CasePaths
import Dependencies
import Foundation

public struct DatabaseRouter<Routes> {

  public init() { }
  
  public func callAsFunction<T: TableRouter>(
    _ table: CaseKeyPath<Routes, T>,
    _ route: T
  ) async throws {
    try await self.execute(route, table)
  }
  
  @discardableResult
  public func callAsFunction<A: Decodable, T: TableRouter>(
    _ table: CaseKeyPath<Routes, T>,
    _ route: T
  ) async throws -> A {
    try await self.execute(route, table)
  }
  
  @discardableResult
  public func callAsFunction<A: Decodable, T: TableRouter>(
    _ table: CaseKeyPath<Routes, T>,
    _ route: () -> T
  ) async throws -> A {
    try await self.execute(route(), table)
  }
  
  @discardableResult
  private func execute<A: Decodable, T: TableRouter>(
    _ route: T,
    _ table: CaseKeyPath<Routes, T>
  ) async throws -> A {
    @Dependency(\.databaseExecutor) var executor
    return try await executor.run(route)
  }
  
  private func execute<T: TableRouter>(
    _ route: T,
    _ table: CaseKeyPath<Routes, T>
  ) async throws {
    @Dependency(\.databaseExecutor) var executor
    return try await executor.run(route)
  }
}

