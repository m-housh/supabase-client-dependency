import Foundation

/// A concrete ``ColumnRepresentable`` type that can be extended to include your custom tables.
///
/// **Example**
/// ```swift
/// extension AnyColumn {
///   static let id: Self = .init("id")
/// }
/// ```
public struct AnyColumn: Equatable, ColumnRepresentable {

  public let columnName: String

  public init<T: ColumnRepresentable>(_ column: T) {
    self.columnName = column.columnName
  }
}

extension AnyColumn: ExpressibleByStringLiteral {

  public typealias StringLiteralType = String

  public init(stringLiteral value: String) {
    self.columnName = value
  }
}

extension ColumnRepresentable {
  public func eraseToAnyColumn() -> AnyColumn { .init(self) }
}
