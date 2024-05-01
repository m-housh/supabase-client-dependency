import DatabaseExtensions

/// Represents a router for a given database table.
///
/// Generally modeled as an enum for the routes.
public protocol TableRouter {
  
  /// The table that the router operates on.
  static var table: AnyTable { get }
  
  /// The query builder for the table, which handles routing for the table.
  var build: QueryBuilder<Self> { get }
}


