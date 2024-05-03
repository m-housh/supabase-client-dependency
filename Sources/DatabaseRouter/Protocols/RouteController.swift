import DatabaseExtensions
import Dependencies
import PostgREST

/// Represents a router for the database, generally for a single table or collection of routes that are modeled as an enum.
public protocol RouteController {

  /// Return the route container for the given route.
  func route() async throws -> DatabaseRoute
}
