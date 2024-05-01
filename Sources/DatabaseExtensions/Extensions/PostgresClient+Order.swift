import Foundation
import PostgREST

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
