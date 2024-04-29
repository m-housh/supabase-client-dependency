import Foundation
import Supabase

// TODO: Remove tables.
public enum DatabaseRequest {

  /// Represents a filter for use in database queries.
  ///
  public struct Filter {

    /// The column to filter the results by.
    public let column: String

    /// The operator to use to filter the results by.
    public let `operator`: PostgrestFilterBuilder.Operator

    /// The value used to compare the column value to.
    public let value: URLQueryRepresentable

    /// Create a new filter.
    ///
    /// - Parameters:
    ///   - column: The column to filter the results by.
    ///   - operator: The operator to use to compare the column value to.
    ///   - value: The value to use for the column filter.
    public init<C: ColumnRepresentable>(
      column: C,
      operator postgrestOperator: PostgrestFilterBuilder.Operator,
      value: URLQueryRepresentable
    ) {
      self.column = column.columnName
      self.operator = postgrestOperator
      self.value = value
    }

    public static func equals<C: ColumnRepresentable>(
      column: C,
      value: URLQueryRepresentable
    ) -> Self {
      .init(column: column, operator: .eq, value: value)
    }

    public static func id(_ value: URLQueryRepresentable) -> Self {
      .equals(column: "id", value: value)
    }
  }

  /// Represents an order by clause used for a database query.
  ///
  public struct Order: Equatable {

    /// The column name to use for the order by clause.
    public let column: String

    /// Whether the values are returned in ascending or descending order.
    public let ascending: Bool

    /// Whether null values are returned at the front of the results.
    public let nullsFirst: Bool

    /// An foreign table to use if the column is a foreign column.
    public let foreignTable: String?

    /// Create a new order by clause for the result with the specified `column`.
    ///
    /// - Parameters:
    ///   - column: The column to order on.
    ///   - ascending: If `true`, the result will be in ascending order.
    ///   - nullsFirst: If `true`, `null`s appear first.
    ///   - foreignTable: The foreign table to use (if `column` is a foreign column).
    public init<C: ColumnRepresentable, T: TableRepresentable>(
      column: C,
      ascending: Bool = true,
      nullsFirst: Bool = false,
      foreignTable: T? = nil
    ) {
      self.column = column.columnName
      self.ascending = ascending
      self.nullsFirst = nullsFirst
      self.foreignTable = foreignTable?.tableName
    }
  }

  /// Represents the parameters for a delete request on the database.
  ///
  /// You generally do not instantiate this type directly, instead use one of the helper methods on the database client, such as
  /// ``delete(id:from:)``.
  ///
  public struct DeleteRequest: Equatable {

    /// The table to perform the delete on.
    public let table: AnyTable

    /// The row filters for the delete request.
    public let filters: [Filter]

    /// Create a new delete request.
    ///
    /// You generally do not instantiate this type directly, instead use one of the helper methods on the database client, such as
    /// ``delete(id:from:)``.
    ///
    ///  - Parameters:
    ///   - table: The table to perform the delete request on.
    ///   - filters: The row filters for the delete request.
    public init<T: TableRepresentable>(table: T, filters: [Filter]) {
      self.table = table.eraseToAnyTable()
      self.filters = filters
    }

    public init(table: AnyTable, filters: [Filter]) {
      self.table = table
      self.filters = filters
    }
  }

  /// Represents the requst parameters for a database fetch request.
  ///
  /// You generally do not instantiate this type directly, instead use one of the helper methods on the database client, such as
  /// ``fetch(from:filteredBy:orderBy:decoding:)``.
  ///
  public struct FetchRequest: Equatable {

    /// The table to perform the fetch on.
    public let table: AnyTable

    /// The row filters for the request.
    public let filters: [Filter]

    /// The order by clause for the request.
    public let order: Order?

    /// Create a new fetch request.
    ///
    /// You generally do not instantiate this type directly, instead use one of the helper methods on the database client, such as
    /// ``SupabaseClientDependency/DatabaseClient/fetch(from:filteredBy:orderBy:decoding:)``.
    ///
    /// - Parameters:
    ///   - table: The table to perform the fetch requst on.
    ///   - filters: The row filters for the request.
    ///   - order: The order by clause for the request.
    public init(
      table: AnyTable,
      filters: [Filter] = [],
      order: Order? = nil
    ) {
      self.table = table
      self.filters = filters
      self.order = order
    }

    /// Create a new fetch request.
    ///
    /// You generally do not instantiate this type directly, instead use one of the helper methods on the database client, such as
    /// ``SupabaseClientDependency/DatabaseClient/fetch(from:filteredBy:orderBy:decoding:)``.
    ///
    /// - Parameters:
    ///   - table: The table to perform the fetch requst on.
    ///   - filters: The row filters for the request.
    ///   - order: The order by clause for the request.
    public init<T: TableRepresentable>(
      table: T,
      filters: [Filter] = [],
      order: Order? = nil
    ) {
      self.table = table.eraseToAnyTable()
      self.filters = filters
      self.order = order
    }
  }

  /// Represents a single row fetch request on the database.
  ///
  /// You generally do not instantiate this type directly, instead use one of the helper methods on the database client, such as
  /// ``fetchOne(id:from:decoding:)``.
  ///
  public struct FetchOneRequest: Equatable {

    /// The table to perform the request on.
    public let table: AnyTable

    /// Filters for the request.
    public let filters: [Filter]

    /// Create a new single row fetch request.
    ///
    /// You generally do not instantiate this type directly, instead use one of the helper methods on the database client, such as
    /// ``SupabaseClientDependency/DatabaseClient/fetchOne(id:from:decoding:)``.
    ///
    /// - Parameters:
    ///   - table: The table to perform the request on.
    ///   - filters: The filters for the request.
    public init<T: TableRepresentable>(
      table: T,
      filters: [Filter] = []
    ) {
      self.table = table.eraseToAnyTable()
      self.filters = filters
    }

    public init(
      table: AnyTable,
      filters: [Filter] = []
    ) {
      self.table = table
      self.filters = filters
    }
  }

  /// Represents an insert request on the database.
  ///
  /// You generally do not instantiate this type directly, instead use one of the helper methods on the database client, such as
  /// ``insert(_:into:returning:decoding:)-731w6``
  ///
  public struct InsertRequest<Value: Encodable> {

    /// The table to insert the values into.
    public let table: AnyTable

    /// The returning options for the request.
    public let returningOptions: PostgrestReturningOptions?

    /// The values to insert into the database.
    public let values: Value

    /// Create a new insert request.
    ///
    /// You generally do not instantiate this type directly, instead use one of the helper methods on the database client, such as
    /// ``SupabaseClientDependency/DatabaseClient/insert(_:into:returning:decoding:)-731w6``.
    ///
    /// - Parameters:
    ///   - table: The table to insert the values into.
    ///   - values: The values to insert into the database.
    ///   - returningOptions: The returning options for the response values.
    public init<T: TableRepresentable>(
      table: T,
      values: Value,
      returningOptions: PostgrestReturningOptions? = nil
    ) {
      self.table = table.eraseToAnyTable()
      self.returningOptions = returningOptions
      self.values = values
    }

    public init(
      table: AnyTable,
      values: Value,
      returningOptions: PostgrestReturningOptions? = nil
    ) {
      self.table = table
      self.returningOptions = returningOptions
      self.values = values
    }
  }

  /// Represents an insert many request on the database.
  ///
  /// You generally do not instantiate this type directly, instead use one of the helper methods on the database client, such as
  /// ``insert(_:into:returning:decoding:)-630da``.
  ///
  public struct InsertManyRequest<Value: Encodable> {

    /// The table to insert the values into.
    public let table: AnyTable

    /// The returning options for the request.
    public let returningOptions: PostgrestReturningOptions?

    /// The values to insert into the database.
    public let values: [Value]

    /// Create a new insert request.
    ///
    /// You generally do not instantiate this type directly, instead use one of the helper methods on the database client, such as
    /// ``SupabaseClientDependency/DatabaseClient/insert(_:into:returning:decoding:)-630da``.
    ///
    /// - Parameters:
    ///   - table: The table to insert the values into.
    ///   - values: The values to insert into the database.
    ///   - returningOptions: The returning options for the response values.
    public init<T: TableRepresentable>(
      table: T,
      values: [Value],
      returningOptions: PostgrestReturningOptions? = nil
    ) {
      self.table = table.eraseToAnyTable()
      self.returningOptions = returningOptions
      self.values = values
    }

    public init(
      table: AnyTable,
      values: [Value],
      returningOptions: PostgrestReturningOptions? = nil
    ) {
      self.table = table
      self.returningOptions = returningOptions
      self.values = values
    }
  }

  /// Represents the parameters need for a remote function call on the database.
  ///
  /// You generally do not instantiate this type directly, instead use one of the helper methods on the database client, such as
  /// ``rpc(_:params:count:decoding:perform:)``.
  ///
  public struct RpcRequest {

    /// The remote function name.
    public let functionName: String

    /// The parameters for the function.
    public let params: any Encodable

    /// The count options for the function, if applicable.
    public let count: CountOption?

    /// Create a new rpc request.
    ///
    /// You generally do not instantiate this type directly, instead use one of the helper methods on the database client, such as
    /// ``SupabaseClientDependency/DatabaseClient/rpc(_:params:count:decoding:perform:)``.
    ///
    /// - Parameters:
    ///   - function: The remote function name.
    ///   - params: The parameters for the function, if applicable.
    ///   - count: The count options for the function, if applicable.
    public init(
      function: RpcRepresentable,
      params: (any Encodable)? = nil,
      count: CountOption? = nil
    ) {
      self.functionName = function.functionName
      self.params = params ?? NoParams()
      self.count = count
    }

    struct NoParams: Encodable {}
  }

  /// Represents an update request on the database.
  ///
  /// You generally do not instantiate this type directly, instead use one of the helper methods on the database client, such as
  /// ``update(id:in:with:returning:decoding:)``.
  ///
  public struct UpdateRequest<Value: Encodable> {

    /// The table to perform the update request on.
    public let table: AnyTable

    /// The filters for the request.
    public let filters: [Filter]

    /// The returning options for the response type.
    public let returningOptions: PostgrestReturningOptions

    /// The values to update in the database.
    public let values: Value

    /// Create a new update request.
    ///
    /// You generally do not instantiate this type directly, instead use one of the helper methods on the database client, such as
    /// ``SupabaseClientDependency/DatabaseClient/update(id:in:with:returning:decoding:)``.
    ///
    /// - Parameters:
    ///   - table: The table to perform the request on.
    ///   - filters: The row filters for the request.
    ///   - returningOptions: The returning options for the response type.
    ///   - values: The values to update in the database.
    public init<T: TableRepresentable>(
      table: T,
      filters: [Filter],
      returningOptions: PostgrestReturningOptions = .representation,
      values: Value
    ) {
      self.table = table.eraseToAnyTable()
      self.filters = filters
      self.returningOptions = returningOptions
      self.values = values
    }

    public init(
      table: AnyTable,
      filters: [Filter],
      returningOptions: PostgrestReturningOptions = .representation,
      values: Value
    ) {
      self.table = table
      self.filters = filters
      self.returningOptions = returningOptions
      self.values = values
    }
  }
}

extension DatabaseRequest.Filter: Equatable {
  public static func == (lhs: DatabaseRequest.Filter, rhs: DatabaseRequest.Filter) -> Bool {
    lhs.column == rhs.column &&
    lhs.operator == rhs.operator &&
    lhs.value.queryValue == rhs.value.queryValue
  }
}

extension DatabaseRequest.InsertRequest: Equatable where Value: Equatable { }
extension DatabaseRequest.InsertManyRequest: Equatable where Value: Equatable { }
extension DatabaseRequest.UpdateRequest: Equatable where Value: Equatable { }
