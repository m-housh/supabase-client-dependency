import CasePaths
import Dependencies
import Foundation

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
/// struct RouterKey: DependencyKey where {
///   var router: DatabaseRouter<DBRoutes>
///
///   static let testValue: Self = .init(router: .init())
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
///
/// func fetchTodos() async throws -> [Todo] {
///   @Dependency(\.router) var router
///   return try await router(.todos(.fetch))
/// }
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
  public subscript<T>(dynamicMember keyPath: KeyPath<AllCasePaths, T>) -> T {
    Self.allCasePaths[keyPath: keyPath]
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
    try await self.embed(value).run()
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
    try await self.embed(value).run()
  }
}
