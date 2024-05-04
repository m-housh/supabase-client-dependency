import Foundation

/// Represents table name type that can be extended to include your custom tables.  This allows
/// using dot style syntax for filters, orders, and overrides.
///
/// It can also be created by a string literal when constructing database queries or order by clauses, if
/// you do not want to extend this type with static constants of your table names.
///
/// **Example**
/// ```swift
/// extension AnyTable {
///   static let todos: Self = "todos"
/// }
/// ```
public struct DatabaseTable: Equatable, Sendable {

  /// The database table's name.
  public let name: String
  
  /// Create a database table for the given name.
  ///
  /// - Parameters:
  ///   - name: The table name.
  public init<T: StringProtocol>(_ name: T) {
    self.name = String(name)
  }
}

extension DatabaseTable: ExpressibleByStringLiteral {

  public typealias StringLiteralType = String

  public init(stringLiteral value: String) {
    self.name = value
  }
}
