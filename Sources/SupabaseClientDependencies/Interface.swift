@_exported import AuthController
import CasePaths
@_exported import DatabaseRouter
import Dependencies
import Foundation
import Supabase

/// A supabase client dependency, which holds a supabase client and provides an authentication
/// controller and database router.
///
/// You need to extend this type to provide the live dependency in your application, generally using
/// the ``live(client:)`` helper.
///
/// ### Example
/// ```swift
/// @CasePathable
/// enum TodoRoute: RouteController {
///   static var table: AnyTable { AnyTable.todos }
///
///   case delete(filteredBy: [DatabaseFilter])
///   case fetch(filteredBy: [DatabaseFilter] = [], orderedBy: DatabaseOrder?)
///   case fetchOne(id: Todo.ID)
///   case insert(InsertRequest)
///   case update(id: Todo.ID, updates: TodoUpdateRequest)
///   case upsert(Todo)
///
///   public func route() async throws -> DatabaseRoute {
///     switch self {
///     case let .delete(filters):
///       return .delete(from: Self.table, filters: filters)
///     case let .fetch(filters, order):
///       return .fetch(from: Self.table, filters: filters, order: order)
///     case .fetchOne(id: let id):
///       return .fetchOne(from: Self.table, filteredBy: .id(id))
///     case let .insert(request):
///       switch request {
///       case let .single(todo):
///         return try .insert(todo, into: Self.table)
///       case let .many(todos):
///         return try .insert(todos, into: Self.table)
///       }
///     case .update(id: let id, updates: let updates):
///       return try .update(id: id, in: Self.table, with: updates)
///     case let .upsert(todo):
///       return try .upsert(todo, in: Self.table)
///     }
///   }
/// }
///
/// @CasePathable
/// enum DbRoutes: DatabaseController {
///
///   case todos(TodoRoute)
///   ...
///
///   func route() async throws -> DatabaseRoute {
///     switch self {
///     case let .todos(todos):
///       return try todos.route()
///      ...
///     }
///   }
/// }
///
/// // Setup the live dependencies.
///
/// extension DependencyValues {
///   var supabase: SupabaseClientDependency<DbRoutes> {
///     get { self[SupabaseClientDependency<DbRoutes>.self] }
///     set { self[SupabaseClientDependency<DbRoutes>.self] = newValue }
///   }
/// }
///
/// private let client = SupabaseClient(...)
///
/// extension SupabaseClientDependency<DbRoutes>: DependencyKey {
///   static let liveValue: Self = .live(client: client)
/// }
///
/// extension DatabaseExecutor: DependencyKey {
///   static let liveValue: Self = .live(database: client.schema("public"))
/// }
///```
@dynamicMemberLookup
public struct SupabaseClientDependency<Routes: RouteCollection> where Routes: CasePathable {

  /// The authentication controller, which gives control over the current user, session, and offers
  /// convenience methods for signing-up and logging in users.
  ///
  ///
  public var auth: AuthController
  
  /// The supabase client to use.
  public let client: SupabaseClient
  
  /// The database router used for database routing, which offers some convienence methods for
  /// overriding database routes for previews and tests.  And allows you to model your database routes as
  /// enum's.
  ///
//  public var router: DatabaseRouter<Routes>

  public init(
    auth: AuthController? = nil,
    client: SupabaseClient
//    router: DatabaseRouter<Routes>? = nil
  ) {
    self.auth = auth ?? .live(auth: client.auth)
    self.client = client
//    self.router = router ?? .init()
  }

  /// Create a database query for the given table.
  ///
  /// - Parameters:
  ///   - table: The table to create the query on.
  public func from(_ table: DatabaseTable) -> PostgrestQueryBuilder {
    self.client.from(table.name)
  }

  /// Access the properties on the supabase client.
  public subscript<T>(dynamicMember keyPath: KeyPath<SupabaseClient, T>) -> T {
    client[keyPath: keyPath]
  }
}

extension SupabaseClientDependency: TestDependencyKey {
  static public var testValue: SupabaseClientDependency<Routes> {
    let client = SupabaseClient.local()
    return .init(
      auth: XCTestDynamicOverlay.unimplemented("\(Self.self).auth", placeholder: .live(auth: client.auth)),
      client: XCTestDynamicOverlay.unimplemented("\(Self.self).client", placeholder: client)
//      router: XCTestDynamicOverlay.unimplemented("\(Self.self).router", placeholder: .init())
    )
  }
}

extension SupabaseClientDependency {

  /// A helper to generate a live ``SupabaseClientDependency``.
  ///
  /// This is generally used to conform the supabase client dependency to `DependencyKey` and
  /// provide it's `liveValue` in your project.
  ///
  /// - Parameters:
  ///   - client: The supabase client to use.
  public static func live(client: SupabaseClient) -> Self {
    .init(client: client)
  }
}

extension SupabaseClient {

  /// A configuration for a local supabase instance.
  ///
  /// In general this may not be the same for different machines and should not be used in production.
  public static func local() -> Self {
    Self.init(supabaseURL: supabaseURL, supabaseKey: localAnonKey)
  }

}

private let supabaseURL = URL(string: "http://localhost:54321")!
private let localAnonKey =
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9." +
  "eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9." +
  "CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0"
