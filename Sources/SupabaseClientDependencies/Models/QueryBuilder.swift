import Foundation
import Supabase

public struct QueryBuilder<Table> {
  let build: (PostgrestQueryBuilder, Table) throws -> PostgrestBuilder

  public init(build: @escaping (PostgrestQueryBuilder, Table) throws -> PostgrestBuilder) {
    self.build = build
  }
}
