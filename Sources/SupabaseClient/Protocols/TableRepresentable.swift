import Foundation

public protocol TableRepresentable {
  var tableName: String { get }
}

extension RawRepresentable where RawValue == String, Self: TableRepresentable {
  public var tableName: String { self.rawValue }
}
