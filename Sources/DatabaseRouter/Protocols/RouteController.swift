import DatabaseExtensions
import Dependencies
import PostgREST

/// Represents a router for the database, generally for a single table or collection of routes that are modeled as an enum.
public protocol RouteController {

  /// Return the route container for the given route.
  func route() throws -> RouteContainer
}

extension RouteController {

  /// Run the route, ignoring any output.
  public func run() async throws {
    @Dependency(\.databaseExecutor) var executor
    try await executor.run(route())
  }

  /// Run the route, decoding the output.
  @discardableResult
  public func run<A: Decodable>() async throws -> A {
    @Dependency(\.databaseExecutor) var executor
    return try await executor.run(route())
  }
}
