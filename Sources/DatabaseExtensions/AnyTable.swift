import Foundation

/// A concrete ``TableRepresentable`` type that can be extended to include your custom tables.
///
/// **Example**
/// ```swift
/// extension AnyTable {
///   static let todos: Self = .init("todos")
/// }
/// ```
public struct AnyTable: Equatable, Sendable, TableRepresentable {

  public let tableName: String

  public init<T: TableRepresentable>(_ table: T) {
    self.tableName = table.tableName
  }
}

extension AnyTable: ExpressibleByStringLiteral {

  public typealias StringLiteralType = String

  public init(stringLiteral value: String) {
    self.tableName = value
  }
}

extension TableRepresentable {
  public func eraseToAnyTable() -> AnyTable { .init(self) }
}
