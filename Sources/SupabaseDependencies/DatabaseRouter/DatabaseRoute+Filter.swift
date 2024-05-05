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
  public func filter(by filters: [DatabaseRoute.Filter]) -> Self {
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
  public func filter(_ filters: DatabaseRoute.Filter...) -> Self {
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
  public func filter(by filter: DatabaseRoute.Filter) -> Self {
    self.filter(by: [filter])
  }
}

extension DatabaseRoute {
  /// Represents a filter for use in database queries.
  ///
  public struct Filter: Sendable {
    
    /// The column to filter the results by.
    public let column: DatabaseRoute.Column
    
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
      column: DatabaseRoute.Column,
      operator postgrestOperator: PostgrestFilterBuilder.Operator,
      value: URLQueryRepresentable
    ) {
      self.column = column
      self.operator = postgrestOperator
      self.value = value.queryValue
    }
    
    public static func equals(
      column: DatabaseRoute.Column,
      value: URLQueryRepresentable
    ) -> Self {
      .init(column: column, operator: .eq, value: value)
    }
    
    public static func id(_ value: URLQueryRepresentable) -> Self {
      .equals(column: .id, value: value)
    }
  }
}

extension DatabaseRoute.Filter: Equatable {
  public static func == (lhs: DatabaseRoute.Filter, rhs: DatabaseRoute.Filter) -> Bool {
    lhs.column == rhs.column &&
    lhs.operator == rhs.operator &&
    lhs.value == rhs.value
  }
}

extension DatabaseRoute.Column {

  public func equals(_ value: URLQueryRepresentable) -> DatabaseRoute.Filter {
    .equals(column: self, value: value)
  }
}
