import Foundation
import PostgREST

extension PostgrestFilterBuilder {

  /// Applies the database filters to a query.
  ///
  /// ### Example
  /// ```swift
  /// database.from("mytable").select().filter(by: [.id(1)]).single()
  /// ```
  ///
  /// - Parameters:
  ///   - filters: The filters to apply to the query.
  @discardableResult
  public func filter(by filters: [DatabaseFilter]) -> Self {
    filters.forEach { filter in
      _ = self.filter(
        filter.column.name,
        operator: filter.operator.rawValue,
        value: filter.value.queryValue
      )
    }
    return self
  }
  
  /// Applies the database filters to a query.
  ///
  /// ### Example
  /// ```swift
  /// database.from("mytable").select().filter(by: .id(1), "isComplete".equals(false)).single()
  /// ```
  ///
  /// - Parameters:
  ///   - filters: The filters to apply to the query.
  @discardableResult
  public func filter(_ filters: DatabaseFilter...) -> Self {
    self.filter(by: filters)
  }
  
  /// Applies the database filter to a query.
  ///
  /// ### Example
  /// ```swift
  /// database.from("mytable").select().filter(by: .id(1)).single()
  /// ```
  ///
  /// - Parameters:
  ///   - filters: The filters to apply to the query.
  @discardableResult
  public func filter(by filter: DatabaseFilter) -> Self {
    self.filter(by: [filter])
  }
}

/// Represents a filter for use in database queries.
///
public struct DatabaseFilter: Sendable {

  /// The column to filter the results by.
  public let column: DatabaseColumn

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
  public init(
    column: DatabaseColumn,
    operator postgrestOperator: PostgrestFilterBuilder.Operator,
    value: URLQueryRepresentable
  ) {
    self.column = column
    self.operator = postgrestOperator
    self.value = value.queryValue
  }

  public static func equals(
    column: DatabaseColumn,
    value: URLQueryRepresentable
  ) -> Self {
    .init(column: column, operator: .eq, value: value)
  }

  public static func id(_ value: URLQueryRepresentable) -> Self {
    .equals(column: .id, value: value)
  }
}

extension DatabaseFilter: Equatable {
  public static func == (lhs: DatabaseFilter, rhs: DatabaseFilter) -> Bool {
    lhs.column == rhs.column &&
    lhs.operator == rhs.operator &&
    lhs.value == rhs.value
  }
}

extension DatabaseColumn {

  public func equals(_ value: URLQueryRepresentable) -> DatabaseFilter {
    .equals(column: self, value: value)
  }
}
