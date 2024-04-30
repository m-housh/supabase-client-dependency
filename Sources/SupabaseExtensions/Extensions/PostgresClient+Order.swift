import Foundation
import PostgREST

extension ColumnRepresentable {

  public func ascending<T: TableRepresentable>(
    nullsFirst: Bool = false,
    foreignTable: T? = nil
  ) -> DatabaseOrder {
    .init(
      column: self,
      ascending: true,
      nullsFirst: nullsFirst,
      foreignTable: foreignTable
    )
  }

  public func ascending(
    nullsFirst: Bool = false,
    foreignTable: String? = nil
  ) -> DatabaseOrder {
    .init(
      column: self,
      ascending: true,
      nullsFirst: nullsFirst,
      foreignTable: foreignTable
    )
  }

  public func descending<T: TableRepresentable>(
    nullsFirst: Bool = false,
    foreignTable: T? = nil
  ) -> DatabaseOrder {
    .init(
      column: self,
      ascending: false,
      nullsFirst: nullsFirst,
      foreignTable: foreignTable
    )
  }

  public func descending(
    nullsFirst: Bool = false,
    foreignTable: String? = nil
  ) -> DatabaseOrder {
    .init(
      column: self,
      ascending: false,
      nullsFirst: nullsFirst,
      foreignTable: foreignTable
    )
  }

}

extension PostgrestFilterBuilder {

  /// Applies an optional order by clause to a database query.
  ///
  ///  - Parameters:
  ///   - order: The optional order by clause to apply to the query if applicable.
  public func order(by order: DatabaseOrder?)
    -> PostgrestTransformBuilder
  {
    if let order {
      return self.order(
        order.column.columnName,
        ascending: order.ascending,
        nullsFirst: order.nullsFirst,
        referencedTable: order.foreignTable
      )
    }
    return self
  }
}
