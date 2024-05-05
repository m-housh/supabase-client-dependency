import Dependencies
import PostgREST

/// Represents a route collection for the database, generally for a single table or collection of routes that
/// are modeled as an enum.
public protocol RouteCollection: Sendable {

  /// Return the route container for the given route.
  func route() async throws -> DatabaseRoute
}
