import Foundation
import PostgREST

extension PostgrestFilterBuilder {

  /// Applies an optional order by clause to a database query.
  ///
  ///  - Parameters:
  ///   - order: The optional order by clause to apply to the query if applicable.
  public func order(by order: DatabaseRoute.Order?) -> PostgrestTransformBuilder {
    if let order {
      return self.order(
        order.column.name,
        ascending: order.ascending,
        nullsFirst: order.nullsFirst,
        referencedTable: order.foreignTable?.name
      )
    }
    return self
  }
}

extension DatabaseRoute {
  
  /// Represents an order by clause used for a database query.
  ///
  public struct Order: Equatable, Sendable {
    
    /// The column name to use for the order by clause.
    public let column: DatabaseRoute.Column
    
    /// Whether the values are returned in ascending or descending order.
    public let ascending: Bool
    
    /// Whether null values are returned at the front of the results.
    public let nullsFirst: Bool
    
    /// An foreign table to use if the column is a foreign column.
    public let foreignTable: DatabaseRoute.Table?
    
    /// Create a new order by clause for the result with the specified `column`.
    ///
    /// - Parameters:
    ///   - column: The column to order on.
    ///   - ascending: If `true`, the result will be in ascending order.
    ///   - nullsFirst: If `true`, `null`s appear first.
    ///   - foreignTable: The foreign table to use (if `column` is a foreign column).
    public init(
      column: DatabaseRoute.Column,
      ascending: Bool = true,
      nullsFirst: Bool = false,
      foreignTable: DatabaseRoute.Table? = nil
    ) {
      self.column = column
      self.ascending = ascending
      self.nullsFirst = nullsFirst
      self.foreignTable = foreignTable
    }
    
    /// Create a new order by clause for the result with the specified `column`.
    ///
    /// - Parameters:
    ///   - column: The column to order on.
    ///   - ascending: If `true`, the result will be in ascending order.
    ///   - nullsFirst: If `true`, `null`s appear first.
    public init(
      column: DatabaseRoute.Column,
      ascending: Bool = true,
      nullsFirst: Bool = false
    ) {
      self.column = column
      self.ascending = ascending
      self.nullsFirst = nullsFirst
      self.foreignTable = nil
    }
  }
}

extension DatabaseRoute.Order {

  /// Allows creating an ascending ``DatabaseRoute.Order`` from a column.
  ///
  /// ### Example
  /// ```swift
  ///   database.from("mytable").select().order(by: .ascending(.myColumn))
  ///  ```
  ///
  /// - Parameters:
  ///   - column: The column to order by.
  ///   - nullsFirst: If `true`, `null`s appear first.
  ///   - foreignTable: The foreign table to use (if `column` is a foreign column).
  public static func ascending(
    _ column: DatabaseRoute.Column,
    nullsFirst: Bool = false,
    foreignTable: DatabaseRoute.Table? = nil
  ) -> DatabaseRoute.Order {
    .init(
      column: column,
      ascending: true,
      nullsFirst: nullsFirst,
      foreignTable: foreignTable
    )
  }
  
  /// Allows creating a descending ``DatabaseRoute.Order`` from a column.
  ///
  /// ### Example
  /// ```swift
  ///   database.from("mytable").select().order(by: .descending(.myColumn))
  ///  ```
  ///
  /// - Parameters:
  ///   - column: The column to order by.
  ///   - nullsFirst: If `true`, `null`s appear first.
  ///   - foreignTable: The foreign table to use (if `column` is a foreign column).
 
  public static func descending(
    _ column: DatabaseRoute.Column,
    nullsFirst: Bool = false,
    foreignTable: DatabaseRoute.Table? = nil
  ) -> DatabaseRoute.Order {
    .init(
      column: column,
      ascending: false,
      nullsFirst: nullsFirst,
      foreignTable: foreignTable
    )
  }
}


extension DatabaseRoute.Column {

  /// Allows creating an ascending ``DatabaseRoute.Order`` from a column.
  ///
  /// ### Example
  /// ```swift
  ///   database.from("mytable").select().order(by: "myColumn".ascending())
  ///  ```
  ///
  /// - Parameters:
  ///   - nullsFirst: If `true`, `null`s appear first.
  ///   - foreignTable: The foreign table to use (if `column` is a foreign column).
  public func ascending(
    nullsFirst: Bool = false,
    foreignTable: DatabaseRoute.Table? = nil
  ) -> DatabaseRoute.Order {
    .init(
      column: self,
      ascending: true,
      nullsFirst: nullsFirst,
      foreignTable: foreignTable
    )
  }
  
  /// Allows creating a descending ``DatabaseRoute.Order`` from a column.
  ///
  /// ### Example
  /// ```swift
  ///   database.from("mytable").select().order(by: "myColumn".descending())
  ///  ```
  ///
  /// - Parameters:
  ///   - nullsFirst: If `true`, `null`s appear first.
  ///   - foreignTable: The foreign table to use (if `column` is a foreign column).
 
  public func descending(
    nullsFirst: Bool = false,
    foreignTable: DatabaseRoute.Table? = nil
  ) -> DatabaseRoute.Order {
    .init(
      column: self,
      ascending: false,
      nullsFirst: nullsFirst,
      foreignTable: foreignTable
    )
  }
}
