import CasePaths
import Dependencies
import Foundation
import OSLog
@_exported import Supabase

/// A supabase client dependency, which holds a supabase client and provides an authentication
/// controller and database router.
///
/// You need to extend this type to provide the live dependency in your application, generally using
/// the ``SupabaseDependency/live(client:schema:logger:)`` helper.
///
/// ### Example
/// ```swift
///
/// extension DatabaseRoute.Table {
///   static var todos: Self = "todos"
/// }
///
/// @CasePathable
/// enum TodoRoute: RouteCollection {
///   case delete(id: Todo.ID)
///   case fetch(filteredBy: [DatabaseRoute.Filter] = [], orderedBy: DatabaseRoute.Order? = nil)
///   case fetchOne(id: Todo.ID)
///   case save(Todo)
///
///   func route() async throws -> DatabaseRoute {
///     switch self {
///     case let .delete(id):
///       return .delete(id: id, from: .todos)
///     case let .fetch(filters, order):
///       return .fetch(from: .todos, filters: filters, order: order)
///     case .fetchOne(id: let id):
///       return .fetchOne(from: .todos, filteredBy: .id(id))
///     case let .save(todo):
///       return try .upsert(todo, into: .todos)
///     }
///   }
/// }
///
/// @CasePathable
/// enum DatabaseRoute: RouteCollection {
///
///   case todos(TodoRoute)
///    ... // Other database routes.
///
///   func route() async throws -> DatabaseRoute {
///     switch self {
///     case let .todos(todos):
///       return try await todos.route()
///
///     ... // Handle other routes.
///     }
///   }
/// }
///
/// // Setup the live dependencies.
/// extension DependencyValues {
///   var supabase: SupabaseDependency<DatabaseRoute> {
///     get { self[SupabaseDependency<DatabaseRoute>.self] }
///     set { self[SupabaseDependency<DatabaseRoute>.self] = newValue }
///   }
/// }
///
/// extension SupabaseDependency<DatabaseRoute>: DependencyKey {
///   static let liveValue: Self = .live(client: SupabaseClient(...), schema: "public")
/// }
///
/// // Basic usage.
/// @Dependency(\.supabase.auth) var auth
/// @Dependency(\.supabase.router) var router
///
/// // Use the auth controller to login / sign-up users.
/// let credentials = Credentials(...)
/// try await auth.signUp(with: .credentials(credentials))
/// try await auth.login(credentials: credentials)
///
/// // Use the router to call the todos fetch route.
/// let todos: [Todo] = try await router(.todos(.fetch()))
///
/// // Override route in a view preview.
/// #Preview {
///   TodoListView(
///     store: Store(initialState: .init()) {
///       TodoListFeature()
///     } withDependencies: {
///       $0.router.override(.case(\.todos.fetch), with: Todo.mocks)
///     }
///   )
/// }
///
///```
@dynamicMemberLookup
public struct SupabaseDependency<Routes>: Sendable {

  /// The authentication controller, which gives control over the current user, session, and offers
  /// convenience methods for signing-up and logging in users.
  ///
  ///
  public var auth: AuthController
  
  /// The supabase client to use.
  public var client: SupabaseClient

  /// The database router used for database routing, which offers some convienence methods for
  /// overriding database routes for previews and tests.  And allows you to model your database routes as
  /// enum's.
  ///
  public var router: DatabaseRouter<Routes>

  public init(
    auth: AuthController? = nil,
    client: SupabaseClient,
    router: DatabaseRouter<Routes>
  ) {
    self.auth = auth ?? .live(auth: client.auth)
    self.client = client
    self.router = router
  }
  
  /// Create a database query for the given table.
  ///
  /// - Parameters:
  ///   - table: The table to create the query on.
  public func from(_ table: DatabaseRoute.Table) -> PostgrestQueryBuilder {
    self.client.from(table.name)
  }

  /// Access the properties on the supabase client.
  public subscript<T>(dynamicMember keyPath: KeyPath<SupabaseClient, T>) -> T {
    client[keyPath: keyPath]
  }
}

extension SupabaseDependency: TestDependencyKey {
  static public var testValue: SupabaseDependency<Routes> {
    return .init(
      auth: XCTestDynamicOverlay.unimplemented("\(Self.self).auth", placeholder: .testValue),
      client: XCTestDynamicOverlay.unimplemented("\(Self.self).client", placeholder: .testValue),
      router: XCTestDynamicOverlay.unimplemented("\(Self.self).router", placeholder: .testValue)
    )
  }
}

extension SupabaseDependency {
  /// A helper to generate a live ``SupabaseDependency``.
  ///
  /// This is generally used to conform the supabase client dependency to `DependencyKey` and
  /// provide it's `liveValue` in your project.
  ///
  /// - Parameters:
  ///   - client: The supabase client to use.
  ///   - schema: The database schema to use to create the database router with.
  ///   - logger: An optional logger to use..
  public static func live(
    client: SupabaseClient,
    schema: String = "public",
    logger: Logger? = nil
  ) -> Self {
    .init(
      client: client,
      router: .init(database: client.schema(schema), logger: logger)
    )
  }
}

extension SupabaseClient: TestDependencyKey {

  /// An unimplemented supabase client.
  public static var testValue: SupabaseClient {
    .init(
      supabaseURL: XCTestDynamicOverlay.unimplemented("\(Self.self).supabaseUrl", placeholder: URL(string: "/")!),
      supabaseKey: XCTestDynamicOverlay.unimplemented("\(Self.self).supabaseKey", placeholder: "")
    )
  }
}
