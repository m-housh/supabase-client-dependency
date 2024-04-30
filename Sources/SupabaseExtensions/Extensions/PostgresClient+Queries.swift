import Dependencies
import Foundation
import PostgREST

extension PostgrestQueryBuilder {
  public func delete(
    filteredBy filters: [DatabaseFilter]
  ) -> PostgrestFilterBuilder {
    self.delete(returning: .minimal).filter(by: filters)
  }

  public func delete(
    filteredBy filters: DatabaseFilter...
  ) -> PostgrestFilterBuilder {
    self.delete(filteredBy: filters)
  }

  public func delete<ID: URLQueryRepresentable>(
    id: ID
  ) -> PostgrestFilterBuilder {
    self.delete(filteredBy: .id(id))
  }

  // MARK: - Fetch
  public func fetch(
    filteredBy filters: [DatabaseFilter] = [],
    orderBy order: DatabaseOrder? = nil
  ) -> PostgrestTransformBuilder {
    self.select().filter(by: filters).order(by: order)
  }

  public func fetch(
    filteredBy filters: DatabaseFilter...,
    orderBy order: DatabaseOrder? = nil
  ) -> PostgrestTransformBuilder  {
    self.fetch(filteredBy: filters, orderBy: order)
  }

  public func fetchOne(
    filteredBy filters: [DatabaseFilter]
  ) -> PostgrestTransformBuilder {
    self.fetch(filteredBy: filters).single()
  }

  public func fetchOne(
    filteredBy filters: DatabaseFilter...
  ) -> PostgrestTransformBuilder {
    self.fetchOne(filteredBy: filters)
  }

  // MARK: - Update
  public func update<Values: Encodable>(
    _ values: Values,
    returning returningOptions: PostgrestReturningOptions = .representation,
    filteredBy filters: [DatabaseFilter]
  ) throws -> PostgrestTransformBuilder {
    try self.update(values, returning: returningOptions).filter(by: filters)
  }

  public func update<Values: Encodable>(
    _ values: Values,
    returning returningOptions: PostgrestReturningOptions = .representation,
    filteredBy filters: DatabaseFilter...
  ) throws -> PostgrestTransformBuilder {
    try self.update(values, returning: returningOptions, filteredBy: filters)
  }

  public func update<
    ID: URLQueryRepresentable, Values: Encodable
  >(
    id: ID,
    with values: Values,
    returning returningOptions: PostgrestReturningOptions = .representation
  ) throws -> PostgrestTransformBuilder {
    try self.update(values, returning: returningOptions, filteredBy: .id(id)).single()
  }

}
