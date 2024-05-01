import Foundation
import PostgREST

extension PostgrestFilterBuilder {

  @discardableResult
  public func filter(by filters: [DatabaseFilter]) -> Self {
    filters.forEach { filter in
      _ = self.filter(
        filter.column.columnName,
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
