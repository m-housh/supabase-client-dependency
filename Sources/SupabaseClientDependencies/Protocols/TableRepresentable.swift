import Foundation
import Supabase

/// A helper type that allows you to model table's generally as an enum.
///
/// This can help prevent mis-spellings by not using strings in database queries.
///
public protocol TableRepresentable {

  /// The table's name.
  var tableName: String { get }
}

extension RawRepresentable where RawValue == String, Self: TableRepresentable {
  public var tableName: String { self.rawValue }
}

extension String: TableRepresentable {

  public var tableName: String { self }
}

