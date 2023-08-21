import Foundation
import Supabase

extension SupabaseClientDependency {

  /// Represents a filter for use in database queries.
  ///
  public struct Filter {
    public let column: String
    public let `operator`: PostgrestFilterBuilder.Operator
    public let value: URLQueryRepresentable

    public init(
      column: String,
      operator postgrestOperator: PostgrestFilterBuilder.Operator,
      value: URLQueryRepresentable
    ) {
      self.column = column
      self.operator = postgrestOperator
      self.value = value
    }

    public init<C: ColumnRepresentable>(
      column: C,
      operator postgrestOperator: PostgrestFilterBuilder.Operator,
      value: URLQueryRepresentable
    ) {
      self.column = column.columnName
      self.operator = postgrestOperator
      self.value = value
    }

    public static func equals(
      column: String,
      value: URLQueryRepresentable
    ) -> Self {
      .init(column: column, operator: .eq, value: value)
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
  
  public func equals(_ value: URLQueryRepresentable) -> SupabaseClientDependency.Filter {
    .equals(column: self.columnName, value: value)
  }
}

extension PostgrestFilterBuilder {

  @discardableResult
  public func filter(by filters: [SupabaseClientDependency.Filter]) -> Self {
    filters.forEach { filter in
      _ = self.filter(
        column: filter.column,
        operator: filter.operator,
        value: filter.value
      )
    }
    return self
  }

  @discardableResult
  public func filter(_ filters: SupabaseClientDependency.Filter...) -> Self {
    self.filter(by: filters)
  }

  @discardableResult
  public func filter(by filter: SupabaseClientDependency.Filter) -> Self {
    self.filter(by: [filter])
  }
}
