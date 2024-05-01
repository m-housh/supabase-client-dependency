import DatabaseExtensions
import Foundation
import PostgREST

// TODO: Rename to DatabaseRoute, requires the type to be deleted from SupabaseClientDependencies package.
#warning("Fix me.")
// TODO: Make struct.
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

public struct RouteContainer2: Equatable {
  let table: AnyTable
  let method: Method
  let data: AnyJSON?
  let filters: [DatabaseFilter]
  let order: DatabaseOrder?
  let returning: PostgrestReturningOptions

  init(
    table: AnyTable,
    method: Method,
    data: AnyJSON? = nil,
    filters: [DatabaseFilter] = [],
    order: DatabaseOrder? = nil,
    returning: PostgrestReturningOptions
  ) {
    self.table = table
    self.method = method
    self.data = data
    self.filters = filters
    self.order = order
    self.returning = returning
  }

  public enum Method {
    case delete
    case fetch
    case fetchOne
    case insert
    case update
    case upsert
  }

  func build(_ query: (AnyTable) throws -> PostgrestQueryBuilder) throws -> PostgrestBuilder {
    switch method {
    case .delete:
      return try query(table).delete(filteredBy: filters)
    case .fetch:
      return try query(table).fetch(filteredBy: filters, orderBy: order)
    case .fetchOne:
      return try query(table).fetchOne(filteredBy: filters)
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
      let query = try query(table).update(data, returning: returning, filteredBy: filters)
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

struct DataNotSuppliedError: Error { }

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
    return .delete(from: table, filteredBy: .id(id))
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

extension RouteContainer2 {
  public static func delete(
    from table: AnyTable,
    filteredBy filters: DatabaseFilter...
  ) -> Self {
    return .init(table: table, method: .delete, returning: .minimal)
  }

  public static func delete<ID: URLQueryRepresentable>(
    id: ID,
    from table: AnyTable
  ) -> Self {
    return .delete(from: table, filteredBy: .id(id))
  }

  public static func fetch(
    from table: AnyTable,
    filteredBy filters: DatabaseFilter...,
    order: DatabaseOrder? = nil
  ) -> Self {
    return .init(table: table, method: .fetch, filters: filters, order: order, returning: .representation)
  }

  public static func fetchOne(
    from table: AnyTable,
    filteredBy filters: DatabaseFilter...
  ) -> Self {
    return .init(table: table, method: .fetchOne, filters: filters, returning: .representation)
  }

  public static func insert<V>(
    _ value: V,
    into table: AnyTable,
    returning: PostgrestReturningOptions = .representation
  ) throws -> Self where V: Codable, V: Sendable {
    return try .init(table: table, method: .insert, data: .init(value), returning: returning)
  }

  public static func update<V>(
    _ value: V,
    in table: AnyTable,
    filteredBy filters: DatabaseFilter...,
    returning: PostgrestReturningOptions = .representation
  ) throws -> Self where V: Codable, V: Sendable {
    return try .init(table: table, method: .update, data: .init(value), filters: filters, returning: returning)
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
    return try .init(table: table, method: .upsert, data: .init(value), returning: returning)
  }
}
