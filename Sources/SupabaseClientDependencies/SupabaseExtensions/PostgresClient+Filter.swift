import Foundation
import PostgREST


public typealias DatabaseFilter = SupabaseClientDependency.DatabaseClient.Filter

// TODO: Just rename filter struct to DatabaseFilter
extension SupabaseClientDependency.DatabaseClient {

  /// Represents a filter for use in database queries.
  ///
  public struct Filter {

    /// The column to filter the results by.
    public let column: String

    /// The operator to use to filter the results by.
    public let `operator`: PostgrestFilterBuilder.Operator

    /// The value used to compare the column value to.
    public let value: URLQueryRepresentable

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
      self.value = value
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
}

extension ColumnRepresentable {

  public func equals(_ value: URLQueryRepresentable)
    -> SupabaseClientDependency.DatabaseClient.Filter
  {
    .equals(column: self.columnName, value: value)
  }
}

extension PostgrestFilterBuilder {

  @discardableResult
  public func filter(by filters: [DatabaseFilter]) -> Self {
    filters.forEach { filter in
      _ = self.filter(
        filter.column,
        operator: filter.operator.rawValue,
        value: filter.value.queryValue
      )
    }
    return self
  }

  @discardableResult
  public func filter(_ filters: DatabaseFilter...) -> Self {
    self.filter(by: filters)
  }

  @discardableResult
  public func filter(by filter: DatabaseFilter) -> Self {
    self.filter(by: [filter])
  }
}
