import Foundation

public protocol ColumnRepresentable {
  var columnName: String { get }
}

extension RawRepresentable where RawValue == String, Self: ColumnRepresentable {
  public var columnName: String { rawValue }
}

