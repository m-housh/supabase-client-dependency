import Foundation

public protocol RpcRepresentable {

  var functionName: String { get }
}

extension RawRepresentable where RawValue == String, Self: RpcRepresentable {

  var functionName: String { self.rawValue }
}

extension String: RpcRepresentable {
  public var functionName: String { self }
}
