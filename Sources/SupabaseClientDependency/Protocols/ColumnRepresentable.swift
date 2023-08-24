import Foundation

/// A helper type that allows you to model a table's columns generally as an enum.
///
/// This can help prevent mis-spellings by not using strings in database queries.
///
public protocol ColumnRepresentable {

  /// The column's name.
  var columnName: String { get }
}

extension RawRepresentable where RawValue == String, Self: ColumnRepresentable {
  public var columnName: String { rawValue }
}

extension String: ColumnRepresentable {
  public var columnName: String { self }
}
