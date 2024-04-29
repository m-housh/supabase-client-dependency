import Foundation

public struct AnyTable: TableRepresentable {
  
  public let tableName: String
  
  public init<T: TableRepresentable>(_ table: T) {
    self.tableName = table.tableName
  }
}
