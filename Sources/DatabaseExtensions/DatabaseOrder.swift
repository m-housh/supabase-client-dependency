import Foundation

/// Represents an order by clause used for a database query.
///
public struct DatabaseOrder: Equatable {

  /// The column name to use for the order by clause.
  public let column: String

  /// Whether the values are returned in ascending or descending order.
  public let ascending: Bool

  /// Whether null values are returned at the front of the results.
  public let nullsFirst: Bool

  /// An foreign table to use if the column is a foreign column.
  public let foreignTable: String?

  /// Create a new order by clause for the result with the specified `column`.
  ///
  /// - Parameters:
  ///   - column: The column to order on.
  ///   - ascending: If `true`, the result will be in ascending order.
  ///   - nullsFirst: If `true`, `null`s appear first.
  ///   - foreignTable: The foreign table to use (if `column` is a foreign column).
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

  /// Create a new order by clause for the result with the specified `column`.
  ///
  /// - Parameters:
  ///   - column: The column to order on.
  ///   - ascending: If `true`, the result will be in ascending order.
  ///   - nullsFirst: If `true`, `null`s appear first.
  public init<C: ColumnRepresentable>(
    column: C,
    ascending: Bool = true,
    nullsFirst: Bool = false
  ) {
    self.column = column.columnName
    self.ascending = ascending
    self.nullsFirst = nullsFirst
    self.foreignTable = nil
  }
}

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
