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

  private var overrides: [(route: AnyOverride, value: Any)] = []

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
    let route = try route.route()
    if let match = overrides.first(where: { $0.route.matches(route) }) { return }
    try await executor.run(route)
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
    let route = try route.route()
    if let match = overrides.first(where: { $0.route.matches(route) }) {
      guard let value = match.value as? A else {
        throw UnmatchedOverrideError()
      }
      return value
    }
    return try await executor.run(route)
  }

  // MARK: - Overrides

  public mutating func override<A>(
    _ route: Routes,
    with value: A
  ) {
    guard let route = try? route.route() else { return }
    overrides.insert(
      (route: .route(route), value: value as Any),
      at: 0
    )
  }

  public mutating func override(
    _ route: Routes
  ) {
    guard let route = try? route.route() else { return }
    overrides.insert(
      (route: .route(route), value: () as Any),
      at: 0
    )
  }

  public mutating func override<A>(
    _ method: RouteMethod,
    in table: AnyTable,
    with value: A
  ) {
    overrides.insert(
      (route: .partial(table: table, method: method), value: value as Any),
      at: 0
    )
  }

  public mutating func override(
    _ method: RouteMethod,
    in table: AnyTable
  ) {
    overrides.insert(
      (route: .partial(table: table, method: method), value: () as Any),
      at: 0
    )
  }
}

public enum RouteMethod {
  case delete
  case fetch
  case fetchOne
  case insert
  case update
  case upsert
}

fileprivate enum AnyOverride: Equatable {

  case route(RouteContainer)
  case partial(table: AnyTable, method: RouteMethod)

  func matches(_ route: RouteContainer) -> Bool {
    switch self {
    case let .route(route):
      return route == route
    case let .partial(table: table, method: method):
      let (otherTable, otherMethod) = parse(route: route)
      return table == otherTable && method == otherMethod
    }
  }

  func parse(route: RouteContainer) -> (AnyTable, RouteMethod) {
    switch route {
    case let .delete(table: table, filters: _):
      return (table, .delete)
    case let .fetch(table: table, filters: _, order: _):
      return (table, .fetch)
    case let .fetchOne(table: table, filters: _):
      return (table, .fetchOne)
    case let .insert(table: table, data: _, returning: _):
      return (table, .insert)
    case let .update(table: table, data: _, filters: _, returning: _):
      return (table, .update)
    case let .upsert(table: table, data: _, returning: _):
      return (table, .upsert)
    }
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

struct UnmatchedOverrideError: Error { }
