import CasePaths
import Foundation

#if DEBUG
extension DatabaseRouter {
  
  /// Override a route with the database result.
  ///
  /// This override is used when the result handler needs access to the input of the route or
  /// to override a sub-route when the `Route` is modeled as case pathable enumeration.
  ///
  /// ### Example
  /// ```swift
  /// router.override(\.todos) { route in
  ///   switch route {
  ///     ...
  ///   }
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - caseKeyPath: The case key path used to match a route.
  ///   - result: The result handler to use when the route is called.
  public mutating func override<T>(
    _ caseKeyPath: CaseKeyPath<Route, T>,
    with result: @escaping @Sendable (T) async throws -> DatabaseResult
  ) where Route: CasePathable {
    self.override(.case(caseKeyPath, with: result))
  }
  
  /// Override a route with the database result.
  ///
  /// This override is used when the result handler needs access to the input of the route or
  /// to override a sub-route when the `Route` is modeled as case pathable enumeration.
  ///
  /// ### Example
  /// ```swift
  /// router.override(\.todos.delete, with: .failure(MyError))
  /// ```
  ///
  /// - Parameters:
  ///   - caseKeyPath: The case key path used to match a route.
  ///   - result: The result handler to use when the route is called.
  public mutating func override<T>(
    _ caseKeyPath: CaseKeyPath<Route, T>,
    with result: DatabaseResult = .success()
  ) where Route: CasePathable {
    self.override(.case(caseKeyPath, with: result))
  }
  
  /// Override a route with the database result.
  ///
  /// This override is used when the result handler needs access to the input of the route or
  /// to override a sub-route when the `Route` is modeled as case pathable enumeration.
  ///
  /// ### Example
  /// ```swift
  /// router.override(\.todos.fetch, with: Todo.mocks)
  /// ```
  ///
  /// - Parameters:
  ///   - caseKeyPath: The case key path used to match a route.
  ///   - result: The result handler to use when the route is called.
  public mutating func override<T, A: Codable>(
    _ caseKeyPath: CaseKeyPath<Route, T>,
    with result: A
  ) where Route: CasePathable {
    self.override(.case(caseKeyPath, with: result))
  }

  /// Override the given route with the given override.
  ///
  /// ### Example
  ///
  /// ```swift
  /// router.override(.method(.insert, in: "todos", with: Todo.mocks[0]))
  /// ```
  ///
  /// - Parameters:
  ///   - override: The override used for matching the route and returning the result.
  ///
  /// - SeeAlso: ``DatabaseRouter/Override``
  public mutating func override(
    _ override: Override
  ) {
    overrides.insert(override)
  }

  // TODO: Make this match on DatabaseRoute or perhaps make it not be nested in
  // in the router and make it's route be generic.

  /// Used to match a route for an override.
  public struct Override: Sendable {

    let match: @Sendable (Route) async throws -> Bool
    let result: @Sendable (Route) async throws -> DatabaseResult

    public init(
      matching match: @escaping @Sendable (Route) async throws -> Bool,
      with result: @escaping @Sendable (Route) async throws -> DatabaseResult
    ) {
      self.match = match
      self.result = result
    }
    
    public init(
      matching match: @escaping @Sendable (Route) async throws -> Bool,
      with result: DatabaseResult
    ) {
      self.match = match
      self.result = { _ in result }
    }
    
    public init<A: Codable>(
      matching match: @escaping @Sendable (Route) async throws -> Bool,
      with result: A
    ) {
      self.match = match
      self.result = { _ in .success(result) }
    }

    /// Create an override matching on the case key path to the route.
    ///
    /// - Parameters:
    ///   - caseKeyPath: The case key path to the route to override.
    ///   - result: The result to return when the route is called.
    public static func `case`<T>(
      _ caseKeyPath: CaseKeyPath<Route, T>,
      with result: @escaping @Sendable (T) async throws -> DatabaseResult
    ) -> Self where Route: CasePathable {
      .init(
        matching: { AnyCasePath(caseKeyPath).extract(from: $0) != nil },
        with: { route in
          guard let input = AnyCasePath(caseKeyPath).extract(from: route) else {
            throw UnexpectedRouteError()
          }
          return try await result(input)
        }
      )
    }
    
    /// Create an override matching on the case key path to the route.
    ///
    /// - Parameters:
    ///   - caseKeyPath: The case key path to the route to override.
    ///   - result: The result to return when the route is called.
    public static func `case`<T>(
      _ caseKeyPath: CaseKeyPath<Route, T>,
      with result: DatabaseResult = .success()
    ) -> Self where Route: CasePathable {
      self.case(caseKeyPath, with: { _ in result })
    }
    
    /// Create an override matching on the case key path to the route.
    ///
    /// - Parameters:
    ///   - caseKeyPath: The case key path to the route to override.
    ///   - result: The result to return when the route is called.
    public static func `case`<T, A: Codable>(
      _ caseKeyPath: CaseKeyPath<Route, T>,
      with result: A
    ) -> Self where Route: CasePathable {
      self.case(caseKeyPath, with: { _ in .success(result) })
    }
    
    /// Create an override matching on the route id and an optional table.
    ///
    /// - Parameters:
    ///   - id: The id used to match the route to override.
    ///   - table: An optional table used to match the override to.
    ///   - result: The result to return when the route is called.
    public static func id(
      _ id: String,
      in table: DatabaseRoute.Table? = nil,
      with result: @escaping @Sendable (Route) async throws -> DatabaseResult
    ) -> Self where Route: RouteCollection {
      self.init(
        matching: { route in
          let route = try await route.route()
          return route.id == id && checkTable(route: route, table: table)
        },
        with: result
      )
    }
    
    /// Create an override matching on the route id and an optional table.
    ///
    /// - Parameters:
    ///   - id: The id used to match the route to override.
    ///   - table: An optional table used to match the override to.
    ///   - result: The result to return when the route is called.
    public static func id(
      _ id: String,
      in table: DatabaseRoute.Table? = nil,
      with result: DatabaseResult = .success()
    ) -> Self where Route: RouteCollection {
      self.id(id, in: table, with: { _ in result })
    }
    
    /// Create an override matching on the route id and an optional table.
    ///
    /// - Parameters:
    ///   - id: The id used to match the route to override.
    ///   - table: An optional table used to match the override to.
    ///   - result: The result to return when the route is called.
    public static func id<A: Codable>(
      _ id: String,
      in table: DatabaseRoute.Table? = nil,
      with result: A
    ) -> Self where Route: RouteCollection {
      self.id(id, in: table, with: { _ in .success(result) })
    }
    
    /// Create an override matching on the ``DatabaseRoute/Method`` and an optional table.
    ///
    /// - Parameters:
    ///   - method: The database route method used to match the route to override.
    ///   - table: An optional table used to match the override to.
    ///   - result: The result to return when the route is called.
    public static func method(
      _ method: DatabaseRoute.Method,
      in table: DatabaseRoute.Table? = nil,
      with result: @escaping @Sendable (Route) async throws -> DatabaseResult
    ) -> Self where Route: RouteCollection {
      self.init(
        matching: { route in
          let route = try await route.route()
          return route.method == method && checkTable(route: route, table: table)
        },
        with: result
      )
    }
    
    /// Create an override matching on the ``DatabaseRoute/Method`` and an optional table.
    ///
    /// - Parameters:
    ///   - method: The database route method used to match the route to override.
    ///   - table: An optional table used to match the override to.
    public static func method(
      _ method: DatabaseRoute.Method,
      in table: DatabaseRoute.Table? = nil,
      with result: DatabaseResult = .success()
    ) -> Self where Route: RouteCollection {
      self.method(method, in: table, with: { _ in result })
    }
    
    /// Create an override matching on the ``DatabaseRoute/Method`` and an optional table.
    ///
    /// - Parameters:
    ///   - method: The database route method used to match the route to override.
    ///   - table: An optional table used to match the override to.
    public static func method<A: Codable>(
      _ method: DatabaseRoute.Method,
      in table: DatabaseRoute.Table? = nil,
      with result: A
    ) -> Self where Route: RouteCollection {
      self.method(method, in: table, with: { _ in .success(result) })
    }
    
    /// Create an override matching on the entire route.
    ///
    /// > Note: This matches all the properties of a route, so it if there are any filter or order by clauses
    /// > they will be used in the match of the route.  You can match on a case path or method if you want
    /// > override all calls to a given route with a less restrictive match.
    ///
    /// - Parameters:
    ///   - route: The route to override.
    public static func route(
      _ route: DatabaseRoute,
      with result: @escaping @Sendable (Route) async throws -> DatabaseResult
    ) -> Self where Route: RouteCollection {
      self.init(
        matching: { try await $0.route() == route },
        with: result
      )
    }
    
    /// Create an override matching on the entire route.
    ///
    /// > Note: This matches all the properties of a route, so it if there are any filter or order by clauses
    /// > they will be used in the match of the route.  You can match on a case path or method if you want
    /// > override all calls to a given route with a less restrictive match.
    ///
    /// - Parameters:
    ///   - route: The route to override.
    public static func route(
      _ route: DatabaseRoute,
      with result: DatabaseResult = .success()
    ) -> Self where Route: RouteCollection {
      self.route(route, with: { _ in result })
    }
    
    /// Create an override matching on the entire route.
    ///
    /// > Note: This matches all the properties of a route, so it if there are any filter or order by clauses
    /// > they will be used in the match of the route.  You can match on a case path or method if you want
    /// > override all calls to a given route with a less restrictive match.
    ///
    /// - Parameters:
    ///   - route: The route to override.
    public static func route<A: Codable>(
      _ route: DatabaseRoute,
      with result: A
    ) -> Self where Route: RouteCollection {
      self.route(route, with: { _ in .success(result) })
    }
    
    private static func checkTable(route: DatabaseRoute, table: DatabaseRoute.Table?) -> Bool {
      guard let table else { return true }
      return route.table == table
    }

  }
}
#endif

fileprivate struct UnexpectedRouteError: Error { }
