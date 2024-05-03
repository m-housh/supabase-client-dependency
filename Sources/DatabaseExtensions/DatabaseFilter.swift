import Foundation
import PostgREST

/// Represents a filter for use in database queries.
///
public struct DatabaseFilter: Sendable {

  /// The column to filter the results by.
  public let column: String

  /// The operator to use to filter the results by.
  public let `operator`: PostgrestFilterBuilder.Operator

  /// The value used to compare the column value to.
  public let value: String

  /// Create a new filter.
  ///
  /// - Parameters:
  ///   - column: The column to filter the results by.
  ///   - operator: The operator to use to compare the column value to.
  ///   - value: The value to use for the column filter.
  public init<C: ColumnRepresentable>(
    column: C,
    operator postgrestOperator: PostgrestFilterBuilder.Operator,
    value: URLQueryRepresentable
  ) {
    self.column = column.columnName
    self.operator = postgrestOperator
    self.value = value.queryValue
  }

  public static func equals<C: ColumnRepresentable>(
    column: C,
    value: URLQueryRepresentable
  ) -> Self {
    .init(column: column, operator: .eq, value: value)
  }

  public static func id(_ value: URLQueryRepresentable) -> Self {
    .equals(column: "id", value: value)
  }
}

extension DatabaseFilter: Equatable {
  public static func == (lhs: DatabaseFilter, rhs: DatabaseFilter) -> Bool {
    lhs.column == rhs.column &&
    lhs.operator == rhs.operator &&
    lhs.value == rhs.value
  }
}

extension ColumnRepresentable {

  public func equals(_ value: URLQueryRepresentable) -> DatabaseFilter {
    .equals(column: self.columnName, value: value)
  }
}
