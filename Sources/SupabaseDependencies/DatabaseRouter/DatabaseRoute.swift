import ConcurrencyExtras
import Foundation
import PostgREST

public struct DatabaseRoute: Sendable {
  
  // A unique identifier if applicable, that can be set to differentiate routes.
  let id: String?

  // The table that the route operates on.
  let table: DatabaseRoute.Table

  // The route method.
  let method: Method

  // Any associated data for the route (used in insert, update, and upsert requests).
  let data: AnyJSON?

  // Any associated database filters.
  let filters: [Filter]

  // Any associated database order.
  let order: Order?

  // The returning options used for many of the query types.
  let returning: PostgrestReturningOptions

  // A handler for building a custom route, only used if the method type is `.custom`
  @UncheckedSendable
  var customBuilder: ((PostgrestQueryBuilder) throws -> PostgrestBuilder)?

  // Internal initialization only.
  init(
    id: String? = nil,
    table: DatabaseRoute.Table,
    method: Method,
    data: AnyJSON? = nil,
    filters: [Filter] = [],
    order: Order? = nil,
    returning: PostgrestReturningOptions,
    customBuilder: ((PostgrestQueryBuilder) throws -> PostgrestBuilder)? = nil
  ) {
    self.id = id
    self.table = table
    self.method = method
    self.data = data
    self.filters = filters
    self.order = order
    self.returning = returning
    self.customBuilder = customBuilder
  }

  /// Represents the query method on the database.
  public enum Method: Sendable {
    /// Used to provide a custom query.
    case custom
    /// Represents a delete query.
    case delete
    /// Represents a fetch query that returns mutliple values.
    case fetch
    /// Represents a fetch query that only returns a single value.
    case fetchOne
    /// Represents an insert query.
    case insert
    /// Represents an update query.
    case update
    /// Represents an upsert query.
    case upsert
  }

  // An internal helper that builds the entire database query to be executed.
  func build(_ query: (DatabaseRoute.Table) throws -> PostgrestQueryBuilder) throws -> PostgrestBuilder {
    switch method {
    case .custom:
      guard let customBuilder else {
        throw CustomBuilderNotSuppliedError()
      }
      return try customBuilder(query(table))
    case .delete:
      return try query(table).delete(returning: .minimal).filter(by: filters)
    case .fetch:
      return try query(table).select().filter(by: filters).order(by: order)
    case .fetchOne:
      return try query(table).select().filter(by: filters).single()
    case .insert:
      guard let data else {
        throw DataNotSuppliedError()
      }
      let query = try query(table).insert(data, returning: returning)
      guard case .object = data else { return query }
      return query.single()
    case .update:
      guard let data else {
        throw DataNotSuppliedError()
      }
      let query = try query(table).update(data, returning: returning).filter(by: filters)
      guard case .object = data else { return query }
      return query.single()
    case .upsert:
      guard let data else {
        throw DataNotSuppliedError()
      }
      let query = try query(table).upsert(data, returning: returning)
      guard case .object = data else { return query }
      return query.single()
    }
  }
}

// Needs custom equality check because of the custom builder, which is ignored
// in equality checking, but all other properties are checked for equality.
extension DatabaseRoute: Equatable {
  
  public static func == (lhs: DatabaseRoute, rhs: DatabaseRoute) -> Bool {
    return lhs.table == rhs.table &&
    lhs.method == rhs.method &&
    lhs.data == rhs.data &&
    lhs.filters == rhs.filters &&
    lhs.order == rhs.order &&
    lhs.returning == rhs.returning &&
    lhs.id == rhs.id
  }
}

// MARK: - Helpers
extension DatabaseRoute {
  /// Create a route container that generates a custom query.
  ///
  /// - Parameters:
  ///   - table: The table to build the initial query for that gets passed into the build argument.
  ///   - routeId: An optional id that can be used to differentiate queries in overrides.
  ///   - build: The operation used to buld the final query.
  public static func custom(
    on table: DatabaseRoute.Table,
    routeId: String? = nil,
    build: @escaping (PostgrestQueryBuilder) throws -> PostgrestBuilder
  ) -> Self {
    .init(id: routeId, table: table, method: .custom, returning: .representation, customBuilder: build)
  }

  /// Create a route container that generates a delete query.
  ///
  /// - Parameters:
  ///   - table: The table to build the initial query for that gets passed into the build argument.
  ///   - filters: The filters for the row to delete.
  ///   - routeId: An optional id that can be used to differentiate queries in overrides.
  public static func delete(
    from table: DatabaseRoute.Table,
    filteredBy filters: [DatabaseRoute.Filter],
    routeId: String? = nil
  ) -> Self {
    return .init(id: routeId, table: table, method: .delete, filters: filters, returning: .minimal)
  }

  /// Create a route container that generates a delete query.
  ///
  /// - Parameters:
  ///   - table: The table to build the initial query for that gets passed into the build argument.
  ///   - filters: The filters for the row to delete.
  ///   - routeId: An optional id that can be used to differentiate queries in overrides.
  public static func delete(
    from table: DatabaseRoute.Table,
    filteredBy filters: DatabaseRoute.Filter...,
    routeId: String? = nil
  ) -> Self {
    return .delete(from: table, filteredBy: filters, routeId: routeId)
  }

  /// Create a route container that generates a delete query.
  ///
  /// - Parameters:
  ///   - id: The identifier for the row to delete.
  ///   - table: The table to build the initial query for that gets passed into the build argument.
  ///   - routeId: An optional id that can be used to differentiate queries in overrides.
  public static func delete<ID: URLQueryRepresentable>(
    id: ID,
    from table: DatabaseRoute.Table,
    routeId: String? = nil
  ) -> Self {
    return .delete(from: table, filteredBy: .id(id), routeId: routeId)
  }

  /// Create a route container that generates a fetch query.
  ///
  /// - Parameters:
  ///   - table: The table to build the initial query for that gets passed into the build argument.
  ///   - filters: The filters for the query.
  ///   - order: An optional order by clause for the return values.
  ///   - routeId: An optional id that can be used to differentiate queries in overrides.
  public static func fetch(
    from table: DatabaseRoute.Table,
    filteredBy filters: [DatabaseRoute.Filter] = [],
    order: Order? = nil,
    routeId: String? = nil
  ) -> Self {
    return .init(
      id: routeId,
      table: table,
      method: .fetch,
      filters: filters,
      order: order,
      returning: .representation
    )
  }

  /// Create a route container that generates a fetch query.
  ///
  /// - Parameters:
  ///   - table: The table to build the initial query for that gets passed into the build argument.
  ///   - filters: The filters for the query.
  ///   - order: An optional order by clause for the return values.
  ///   - routeId: An optional id that can be used to differentiate queries in overrides.
  public static func fetch(
    from table: DatabaseRoute.Table,
    filteredBy filters: DatabaseRoute.Filter...,
    order: Order? = nil,
    routeId: String? = nil
  ) -> Self {
    return .fetch(from: table, filteredBy: filters, order: order, routeId: routeId)
  }

  /// Create a route container that generates a fetch query for a single row.
  ///
  /// - Parameters:
  ///   - table: The table to build the initial query for that gets passed into the build argument.
  ///   - filters: The filters for the query.
  ///   - routeId: An optional id that can be used to differentiate queries in overrides.
  public static func fetchOne(
    from table: DatabaseRoute.Table,
    filteredBy filters: [DatabaseRoute.Filter] = [],
    routeId: String? = nil
  ) -> Self {
    return .init(id: routeId, table: table, method: .fetchOne, filters: filters, returning: .representation)
  }

  /// Create a route container that generates a fetch query for a single row.
  ///
  /// - Parameters:
  ///   - table: The table to build the initial query for that gets passed into the build argument.
  ///   - filters: The filters for the query.
  ///   - routeId: An optional id that can be used to differentiate queries in overrides.
  public static func fetchOne(
    from table: DatabaseRoute.Table,
    filteredBy filters: DatabaseRoute.Filter...,
    routeId: String? = nil
  ) -> Self {
    return .fetchOne(from: table, filteredBy: filters, routeId: routeId)
  }

  /// Create a route container that generates a fetch query for a single row.
  ///
  /// - Parameters:
  ///   - id: The id to filter the query by.
  ///   - table: The table to build the initial query for that gets passed into the build argument.
  ///   - routeId: An optional id that can be used to differentiate queries in overrides.
  public static func fetchOne<ID: URLQueryRepresentable>(
    id: ID,
    from table: DatabaseRoute.Table,
    routeId: String? = nil
  ) -> Self {
    return .fetchOne(from: table, filteredBy: .id(id), routeId: routeId)
  }

  /// Create a route container that generates an insert query.
  ///
  /// - Parameters:
  ///   - value: The value(s) to insert into the database.
  ///   - table: The table to build the initial query for that gets passed into the build argument.
  ///   - returning: The returning options (defaults to .representation).
  ///   - routeId: An optional id that can be used to differentiate queries in overrides.
  public static func insert<V>(
    _ value: V,
    into table: DatabaseRoute.Table,
    returning: PostgrestReturningOptions = .representation,
    routeId: String? = nil
  ) throws -> Self where V: Codable, V: Sendable {
    return try .init(id: routeId, table: table, method: .insert, data: .init(value), returning: returning)
  }

  /// Create a route container that generates an update query.
  ///
  /// - Parameters:
  ///   - value: The value to update into the database.
  ///   - table: The table to build the initial query for that gets passed into the build argument.
  ///   - filters: The filters for the query.
  ///   - returning: The returning options (defaults to .representation).
  ///   - routeId: An optional id that can be used to differentiate queries in overrides.
  public static func update<V>(
    _ value: V,
    in table: DatabaseRoute.Table,
    filteredBy filters: DatabaseRoute.Filter...,
    returning: PostgrestReturningOptions = .representation,
    routeId: String? = nil
  ) throws -> Self where V: Codable, V: Sendable {
    return try .init(id: routeId, table: table, method: .update, data: .init(value), filters: filters, returning: returning)
  }

  /// Create a route container that generates an update query.
  ///
  /// - Parameters:
  ///   - id: The identifier for the row.
  ///   - table: The table to build the initial query for that gets passed into the build argument.
  ///   - value: The value to update into the database.
  ///   - returning: The returning options (defaults to .representation).
  ///   - routeId: An optional id that can be used to differentiate queries in overrides.
  public static func update<ID: URLQueryRepresentable, V>(
    id: ID,
    in table: DatabaseRoute.Table,
    with value: V,
    returning: PostgrestReturningOptions = .representation,
    routeId: String? = nil
  ) throws -> Self where V: Codable, V: Sendable {
    try .update(value, in: table, filteredBy: .id(id), returning: returning, routeId: routeId)
  }

  /// Create a route container that generates an upsert query.
  ///
  /// - Parameters:
  ///   - value: The value(s) to upsert in the database.
  ///   - table: The table to build the initial query for that gets passed into the build argument.
  ///   - returning: The returning options (defaults to .representation).
  ///   - routeId: An optional id that can be used to differentiate queries in overrides.
  public static func upsert<V>(
    _ value: V,
    in table: DatabaseRoute.Table,
    returning: PostgrestReturningOptions = .representation,
    routeId: String? = nil
  ) throws -> Self where V: Codable, V: Sendable {
    return try .init(id: routeId, table: table, method: .upsert, data: .init(value), returning: returning)
  }
}


extension DatabaseRoute {
  /// Represents a table column name type that can be extended to include your custom tables. This
  /// allows using dot style syntax when creating filter or order by clauses.
  ///
  /// It can also be created by a string literal when constructing database filter or order by clauses, if
  /// you do not want to extend this type with static constants of your column names.
  ///
  /// ### Example
  ///
  /// ```swift
  /// extension DatabaseRoute.Column {
  ///   static let id: Self = "id"
  /// }
  /// ```
  public struct Column: Equatable, Sendable {
    
    /// The database column's name.
    public let name: String
    
    /// Create a database column for the given column name.
    ///
    /// - Parameters:
    ///   - name: The column name.
    public init<S: StringProtocol>(_ name: S) {
      self.name = String(name)
    }
  }
}

extension DatabaseRoute.Column: ExpressibleByStringLiteral {

  public typealias StringLiteralType = String

  public init(stringLiteral value: String) {
    self.name = value
  }
}

extension DatabaseRoute.Column {
  
  /// Represents an id column.
  public static let id: Self = "id"
}

extension DatabaseRoute {
  
  /// Represents table name type that can be extended to include your custom tables.  This allows
  /// using dot style syntax for filters, orders, and overrides.
  ///
  /// It can also be created by a string literal when constructing database queries or order by clauses, if
  /// you do not want to extend this type with static constants of your table names.
  ///
  /// **Example**
  /// ```swift
  /// extension DatabaseRoute.Table {
  ///   static let todos: Self = "todos"
  /// }
  /// ```
  public struct Table: Equatable, Sendable {
    
    /// The database table's name.
    public let name: String
    
    /// Create a database table for the given name.
    ///
    /// - Parameters:
    ///   - name: The table name.
    public init<T: StringProtocol>(_ name: T) {
      self.name = String(name)
    }
  }
}

extension DatabaseRoute.Table: ExpressibleByStringLiteral {

  public typealias StringLiteralType = String

  public init(stringLiteral value: String) {
    self.name = value
  }
}

extension RawRepresentable where RawValue == String {
  public var column: DatabaseRoute.Column { .init(rawValue) }
  public var table: DatabaseRoute.Table { .init(rawValue) }
}

struct DataNotSuppliedError: Error { }
struct CustomBuilderNotSuppliedError: Error { }
