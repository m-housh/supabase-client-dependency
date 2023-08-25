import Foundation

/// A helper type that allows you to model a remote function calls generally as an enum.
///
/// This can help prevent mis-spellings by not using strings in database queries.
///
public protocol RpcRepresentable {

  /// The remote function's name.
  var functionName: String { get }
}

extension RawRepresentable where RawValue == String, Self: RpcRepresentable {
  var functionName: String { self.rawValue }
}

extension String: RpcRepresentable {
  public var functionName: String { self }
}
