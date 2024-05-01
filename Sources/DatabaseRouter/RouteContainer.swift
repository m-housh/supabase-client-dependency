import DatabaseExtensions
import Foundation
import PostgREST

// TODO: Rename to DatabaseRoute, requires the type to be deleted from SupabaseClientDependencies package.
#warning("Fix me.")
public struct RouteContainer {
  
  let id: String?
  let table: AnyTable
  let method: Method
  let data: AnyJSON?
  let filters: [DatabaseFilter]
  let order: DatabaseOrder?
  let returning: PostgrestReturningOptions
  let customBuilder: ((PostgrestQueryBuilder) throws -> PostgrestBuilder)?

  init(
    id: String? = nil,
    table: AnyTable,
    method: Method,
    data: AnyJSON? = nil,
    filters: [DatabaseFilter] = [],
    order: DatabaseOrder? = nil,
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

  public enum Method {
    case custom
    case delete
    case fetch
    case fetchOne
    case insert
    case update
    case upsert
  }

  func build(_ query: (AnyTable) throws -> PostgrestQueryBuilder) throws -> PostgrestBuilder {
    switch method {
    case .custom:
      guard let customBuilder else {
        throw CustomBuilderNotSuppliedError()
      }
      return try customBuilder(query(table))
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

// Needs custom equality check because of the custom builder, which is ignored
// in equality checking, but all other properties are checked.
extension RouteContainer: Equatable {
  
  public static func == (lhs: RouteContainer, rhs: RouteContainer) -> Bool {
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
extension RouteContainer {
  
  public static func custom(
    _ table: AnyTable,
    routeId: String? = nil,
    build: @escaping (PostgrestQueryBuilder) throws -> PostgrestBuilder
  ) -> Self {
    .init(id: routeId, table: table, method: .custom, returning: .representation, customBuilder: build)
  }
  
  public static func delete(
    from table: AnyTable,
    filters: [DatabaseFilter],
    routeId: String? = nil
  ) -> Self {
    return .init(id: routeId, table: table, method: .delete, filters: filters, returning: .minimal)
  }
  
  public static func delete(
    from table: AnyTable,
    filteredBy filters: DatabaseFilter...,
    routeId: String? = nil
  ) -> Self {
    return .delete(from: table, filters: filters, routeId: routeId)
  }

  public static func delete<ID: URLQueryRepresentable>(
    id: ID,
    from table: AnyTable,
    routeId: String? = nil
  ) -> Self {
    return .delete(from: table, filteredBy: .id(id), routeId: routeId)
  }
  
  public static func fetch(
    from table: AnyTable,
    filters: [DatabaseFilter],
    order: DatabaseOrder? = nil,
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

  public static func fetch(
    from table: AnyTable,
    filteredBy filters: DatabaseFilter...,
    order: DatabaseOrder? = nil,
    routeId: String? = nil
  ) -> Self {
    return .fetch(from: table, filters: filters, order: order, routeId: routeId)
  }

  public static func fetchOne(
    from table: AnyTable,
    filters: [DatabaseFilter],
    routeId: String? = nil
  ) -> Self {
    return .init(id: routeId, table: table, method: .fetchOne, filters: filters, returning: .representation)
  }
  
  public static func fetchOne(
    from table: AnyTable,
    filteredBy filters: DatabaseFilter...,
    routeId: String? = nil
  ) -> Self {
    return .fetchOne(from: table, filters: filters, routeId: routeId)
  }

  public static func insert<V>(
    _ value: V,
    into table: AnyTable,
    returning: PostgrestReturningOptions = .representation,
    routeId: String? = nil
  ) throws -> Self where V: Codable, V: Sendable {
    return try .init(id: routeId, table: table, method: .insert, data: .init(value), returning: returning)
  }

  public static func update<V>(
    _ value: V,
    in table: AnyTable,
    filteredBy filters: DatabaseFilter...,
    returning: PostgrestReturningOptions = .representation,
    routeId: String? = nil
  ) throws -> Self where V: Codable, V: Sendable {
    return try .init(id: routeId, table: table, method: .update, data: .init(value), filters: filters, returning: returning)
  }

  public static func update<ID: URLQueryRepresentable, V>(
    id: ID,
    in table: AnyTable,
    with value: V,
    returning: PostgrestReturningOptions = .representation,
    routeId: String? = nil
  ) throws -> Self where V: Codable, V: Sendable {
    try .update(value, in: table, filteredBy: .id(id), returning: returning, routeId: routeId)
  }

  public static func upsert<V>(
    _ value: V,
    in table: AnyTable,
    returning: PostgrestReturningOptions = .representation,
    routeId: String? = nil
  ) throws -> Self where V: Codable, V: Sendable {
    return try .init(id: routeId, table: table, method: .upsert, data: .init(value), returning: returning)
  }
}

struct DataNotSuppliedError: Error { }
struct CustomBuilderNotSuppliedError: Error { }
