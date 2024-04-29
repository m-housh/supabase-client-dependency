import Foundation

public struct AnyTable: TableRepresentable {
  
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
