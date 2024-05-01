import DatabaseExtensions
import Foundation
import PostgREST

// TODO: Rename to DatabaseRoute, requires the type to be deleted from SupabaseClientDependencies package.
#warning("Fix me.")
public enum RouteContainer: Equatable {
  case delete(table: AnyTable, filters: [DatabaseFilter])
  case fetch(table: AnyTable, filters: [DatabaseFilter] = [], order: DatabaseOrder? = nil)
  case fetchOne(table: AnyTable, filters: [DatabaseFilter] = [])
  case insert(table: AnyTable, data: AnyJSON, returning: PostgrestReturningOptions = .representation)
  case update(table: AnyTable, data: AnyJSON, filters: [DatabaseFilter] = [], returning: PostgrestReturningOptions = .representation)
  case upsert(table: AnyTable, data: AnyJSON, returning: PostgrestReturningOptions = .representation)

  func build(_ query: (AnyTable) throws -> PostgrestQueryBuilder) throws -> PostgrestBuilder {
    switch self {
    case .delete(table: let table, filters: let filters):
      return try query(table).delete(filteredBy: filters)
    case .fetch(table: let table, filters: let filters, order: let order):
      return try query(table).fetch(filteredBy: filters, orderBy: order)
    case .fetchOne(table: let table, filters: let filters):
      return try query(table).fetchOne(filteredBy: filters)
    case .insert(table: let table, data: let data, returning: let returning):
      let query = try query(table).insert(data, returning: returning, count: nil)
      guard case .object = data else { return query }
      return query.single()
    case .update(table: let table, data: let data, filters: let filters, returning: let returning):
      let query = try query(table).update(data, returning: returning, filteredBy: filters)
      guard case .object = data else { return query }
      return query.single()
    case .upsert(table: let table, data: let data, returning: let returning):
      let query = try query(table).upsert(data, returning: returning)
      guard case .object = data else { return query }
      return query.single()
    }
  }
}

// MARK: - Helpers
extension RouteContainer {
  public static func delete(
    from table: AnyTable,
    filteredBy filters: DatabaseFilter...
  ) -> Self {
    return .delete(table: table, filters: filters)
  }

  public static func delete<ID: URLQueryRepresentable>(
    id: ID,
    from table: AnyTable
  ) -> Self {
    return .delete(table: table, filteredBy: .id(id))
  }

  public static func fetch(
    from table: AnyTable,
    filteredBy filters: DatabaseFilter...,
    order: DatabaseOrder? = nil
  ) -> Self {
    return .fetch(table: table, filters: filters, order: order)
  }

  public static func fetchOne(
    from table: AnyTable,
    filteredBy filters: DatabaseFilter...
  ) -> Self {
    return .fetchOne(table: table, filters: filters)
  }

  public static func insert<V>(
    _ value: V,
    into table: AnyTable,
    returning: PostgrestReturningOptions = .representation
  ) throws -> Self where V: Codable, V: Sendable {
    return try .insert(table: table, data: .init(value), returning: returning)
  }

  public static func update<V>(
    _ value: V,
    in table: AnyTable,
    filteredBy filters: DatabaseFilter...,
    returning: PostgrestReturningOptions = .representation
  ) throws -> Self where V: Codable, V: Sendable {
    return try .update(table: table, data: .init(value), filters: filters, returning: returning)
  }

  public static func update<ID: URLQueryRepresentable, V>(
    id: ID,
    in table: AnyTable,
    with value: V,
    returning: PostgrestReturningOptions = .representation
  ) throws -> Self where V: Codable, V: Sendable {
    try .update(value, in: table, filteredBy: .id(id), returning: returning)
  }

  public static func upsert<V>(
    _ value: V,
    in table: AnyTable,
    returning: PostgrestReturningOptions = .representation
  ) throws -> Self where V: Codable, V: Sendable {
    return try .upsert(table: table, data: .init(value), returning: returning)
  }
}
