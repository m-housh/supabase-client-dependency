import CasePaths
import DatabaseExtensions
import Dependencies
import Foundation
import PostgREST

/// A router for the database, this generally wraps a type that knows how to handle all the routes to the database and is
/// used to declare a dependency that can be used in the application.
///
/// ### Example
/// ```swift
/// @CasePathable
/// enum TodosRouter: RouteController {
///   static let table: AnyTable = "todos"
///
///   case fetch
///   case delete(id: Todo.ID)
///   ...
///
///   func routes() throws -> RouteContainer {
///     switch self {
///       case .fetch:
///         return .fetch(from: Self.table)
///       case let .delete(id: id):
///         return .delete(id: id, from: Self.table)
///       ...
///     }
///   }
/// }
///
/// @CasePathable
/// enum DBRoutes: DatabaseController {
///   case todos(TodosRouter)
///   ...
///
///   func routes() throws -> RouteContainer {
///     switch self {
///       case let .todos(todos):
///         return try todos.route()
///        ...
///     }
///   }
/// }
///
/// struct RouterKey: DependencyKey {
///   var router: DatabaseRouter<DBRoutes> = .init()
///
///   static let testValue: Self = .init()
///   static var liveValue: Self { .testValue }
/// }
///
/// extension DependencyValues {
///   var router: DatabaseRouter<DBRoutes> {
///     get { self[RouterKey.self].router }
///     set { self[RouterKey.self].router = newValue }
///   }
/// }
///
/// // Example of using the router in your application.
/// func fetchTodos() async throws -> [Todo] {
///   @Dependency(\.router) var router
///   return try await router(.todos(.fetch))
/// }
///
/// // Can also narrow down the scope to just the todos route controller.
/// func fetchTodos2() async throws -> [Todo] {
///   @Dependency(\.router.todos) var todos
///   return try await todos(.fetch)
/// }
///
/// ```
@dynamicMemberLookup
public struct DatabaseRouter<Routes: DatabaseController>: CasePathable {
  
  public typealias AllCasePaths = Routes.AllCasePaths
  
  public init() { }
  
  public static var allCasePaths: AllCasePaths {
    Routes.allCasePaths
  }
  
  /// Access a route controller from the router.   This is used when narrowing down to a controller
  /// from the router.
  ///
  /// - Parameters:
  ///   - keyPath: The keypath to the route controller.
  public subscript<T>(
    dynamicMember keyPath: KeyPath<AllCasePaths, T>
  ) -> T {
    let casePath = Self.allCasePaths[keyPath: keyPath]
    return casePath
  }
  
  /// Execute the given route, ignoring the output.
  ///
  /// ### Example
  /// ```swift
  /// @Dependency(\.router) var router
  ///
  /// try await router(.todos(.delete(id: 1)))
  /// ```
  ///
  /// - Parameters:
  ///   - route: The route to execute.
  public func callAsFunction(_ route: Routes) async throws {
    @Dependency(\.databaseExecutor) var executor
    try await executor.run(route.route())
  }
  
  /// Execute the given route, decoding the output.
  ///
  /// ### Example
  /// ```swift
  /// @Dependency(\.router) var router
  ///
  /// let todos: [Todo] = try await router(.todos(.fetch))
  /// ```
  ///
  /// - Parameters:
  ///   - route: The route to execute.
  @discardableResult
  public func callAsFunction<A: Decodable>(
    _ route: Routes
  ) async throws -> A {
    @Dependency(\.databaseExecutor) var executor
    return try await executor.run(route.route())
  }
  
}

#if DEBUG
extension DatabaseRouter {
  // MARK: - Overrides
  private func insertOverride<V>(route: AnyOverride, value: V) {
    DatabaseExecutor.currentOverrides.insert(route, value: value)
  }
  /// Override the given route with the value.
  ///
  /// - Parameters:
  ///   - route: The route to override.
  ///   - value: The value to return when the route is called.
  public func override<A>(
    _ route: Routes,
    with value: A
  ) {
    let route = try! route.route()
    insertOverride(route: .route(route), value: value)
  }
  /// Override the given route with a void value.
  ///
  /// - Parameters:
  ///   - route: The route to override.
  public func override(
    _ route: Routes
  ) {
    let route = try! route.route()
    insertOverride(route: .route(route), value: ())
  }
  /// Override the given route method with the value.
  ///
  /// - Parameters:
  ///   - method: The route method to override.
  ///   - table: The table to override the method in.
  ///   - value: The value to return when the route is called.
  public func override<A>(
    _ method: DatabaseRoute.Method,
    in table: AnyTable,
    with value: A
  ) {
    insertOverride(route: .partial(table: table, method: method), value: value)
  }
  /// Override the given route with a void value.
  ///
  /// - Parameters:
  ///   - method: The route method to override.
  ///   - table: The table to override the method in.
  public func override(
    _ method: DatabaseRoute.Method,
    in table: AnyTable
  ) {
    insertOverride(route: .partial(table: table, method: method), value: ())
  }
  /// Override the given route method with the value.
  ///
  /// - Parameters:
  ///   - id: The route identifier to override.
  ///   - table: The table to override the method in.
  ///   - value: The value to return when the route is called.
  public func override<A>(
    id: String,
    in table: AnyTable,
    with value: A
  ) {
    insertOverride(route: .id(id, table: table), value: value)
  }
  /// Override the given route with a void value.
  ///
  /// - Parameters:
  ///   - id: The route identifier to override.
  ///   - table: The table to override the method in.
  public func override(
    id: String,
    in table: AnyTable
  ) {
    insertOverride(route: .id(id, table: table), value: ())
  }
}
#endif

extension AnyCasePath where Root: RouteController {

  /// Provides functionality to treat a case path that wraps a ``RouteController`` like a
  /// controller. This is used when narrowing down a dependency on a ``DatabaseRouter`` in
  /// your application to a particular route controller.
  ///
  /// ### Example
  /// ```swift
  /// @Depencency(\.router.todos) var todos
  ///
  /// try await todos(.delete(id: 1))
  /// ```
  ///
  /// - Parameters:
  ///   - value: The route to embed in the case path / call.
  public func callAsFunction(_ value: Value) async throws {
    @Dependency(\.databaseExecutor) var executor
    try await executor.run(self.embed(value))
  }

  /// Provides functionality to treat a case path that wraps a ``RouteController`` like a
  /// controller. This is used when narrowing down a dependency on a ``DatabaseRouter`` in
  /// your application to a particular route controller.
  ///
  /// ### Example
  /// ```swift
  /// @Depencency(\.router.todos) var todos
  ///
  /// let todos: [Todo] = try await todos(.fetch)
  /// ```
  ///
  /// - Parameters:
  ///   - value: The route to embed in the case path / call.
  @discardableResult
  public func callAsFunction<A: Decodable>(_ value: Value) async throws -> A {
    @Dependency(\.databaseExecutor) var executor
    return try await executor.run(self.embed(value))
  }
}

struct UnmatchedOverrideError: Error { }
