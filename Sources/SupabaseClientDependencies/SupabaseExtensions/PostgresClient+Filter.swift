import Foundation
import PostgREST

extension ColumnRepresentable {

  public func equals(_ value: URLQueryRepresentable)
    -> DatabaseRequest.Filter
  {
    .equals(column: self.columnName, value: value)
  }
}

extension PostgrestFilterBuilder {

  @discardableResult
  public func filter(by filters: [DatabaseRequest.Filter]) -> Self {
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
  public func filter(_ filters: DatabaseRequest.Filter...) -> Self {
    self.filter(by: filters)
  }

  @discardableResult
  public func filter(by filter: DatabaseRequest.Filter) -> Self {
    self.filter(by: [filter])
  }
}
