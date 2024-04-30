import Supabase

extension SupabaseClient {
  public func from(_ table: AnyTable) -> PostgrestQueryBuilder {
    self.from(table.tableName)
  }
}
