import Foundation
import PostgREST

extension SupabaseClientDependency {
  
  // Represents an order by clause used for a database query.
  public struct Order {
    public let column: String
    public let ascending: Bool
    public let nullsFirst: Bool
    public let foreignTable: String?

    public init(
      column: String,
      ascending: Bool = true,
      nullsFirst: Bool = false,
      foreignTable: String? = nil
    ) {
      self.column = column
      self.ascending = ascending
      self.nullsFirst = nullsFirst
      self.foreignTable = foreignTable
    }

    public init<C: ColumnRepresentable>(
      column: C,
      ascending: Bool = true,
      nullsFirst: Bool = false,
      foreignTable: String? = nil
    ) {
      self.column = column.columnName
      self.ascending = ascending
      self.nullsFirst = nullsFirst
      self.foreignTable = foreignTable
    }
    
    public init<C: ColumnRepresentable, T: TableRepresentable>(
      column: C,
      ascending: Bool = true,
      nullsFirst: Bool = false,
      foreignTable: T? = nil
    ) {
      self.column = column.columnName
      self.ascending = ascending
      self.nullsFirst = nullsFirst
      self.foreignTable = foreignTable?.tableName
    }
  }
}

extension PostgrestFilterBuilder {
  
  public func order(by order: SupabaseClientDependency.Order?) -> PostgrestTransformBuilder {
    if let order {
      return self.order(
        column: order.column,
        ascending: order.ascending,
        nullsFirst: order.nullsFirst,
        foreignTable: order.foreignTable
      )
    }
    return self
  }
}
