import Foundation

/// Represents a table column name type that can be extended to include your custom tables. This
/// allows using dot style syntax when creating filter or order by clauses.
///
/// It can also be created by a string literal when constructing database filter or order by clauses, if
/// you do not want to extend this type with static constants of your column names.
///
/// ### Example
///
/// ```swift
/// extension DatabaseColumn {
///   static let id: Self = "id"
/// }
/// ```
public struct DatabaseColumn: Equatable, Sendable {

  /// The database column's name.
  public let name: String

  /// Create a database column for the given column name.
  ///
  /// - Parameters:
  ///   - name: The column name.
  public init<S: StringProtocol>(_ name: S) {
    self.name = String(name)
  }
}

extension DatabaseColumn: ExpressibleByStringLiteral {

  public typealias StringLiteralType = String

  public init(stringLiteral value: String) {
    self.name = value
  }
}

extension DatabaseColumn {
  
  /// Represents an id column.
  public static let id: Self = "id"
}
