import Dependencies
import Foundation
import IdentifiedStorage
import SupabaseClientDependencies
import Supabase

extension DependencyValues {
  var auth: AuthController {
    get { self[AuthController.self] }
    set { self[AuthController.self] = newValue }
  }
}

private let supabaseClient = SupabaseClient.local()

extension AuthController: DependencyKey {
  public static var liveValue: AuthController = .init(client: supabaseClient.auth)
}

extension DatabaseRoutes: DependencyKey {
  static var liveValue: DatabaseRoutes = .init(todos: .live(database: supabaseClient.schema("public")))
}

//extension DependencyValues {
//  var supabase: SupabaseClientDependency<DatabaseRoutes> {
//    get { self[SupabaseClientKey.self].client }
//    set { self[SupabaseClientKey.self].client = newValue }
//  }
//}
//
//struct SupabaseClientKey: DependencyKey {
//  var client: SupabaseClientDependency<DatabaseRoutes>
//
//  static var testValue: SupabaseClientKey = .init(client: .testValue)
//  static var liveValue: SupabaseClientKey = .init(client: .liveValue)
//}
//
//extension SupabaseClientDependency<DatabaseRoutes> {
//  static var liveValue: Self {
//    .live(client: .local())
//  }
//}
//
//extension DatabaseExecutor: DependencyKey {
//  public static var liveValue: DatabaseExecutor {
//    @Dependency(\.supabase) var supabase
//    return .live(database: supabase.client.schema("public"))
//  }
//}
//
//extension SupabaseClientKey {
//
//  static var previewValue: Self {
//    let storage = IdentifiedStorageOf<TodoModel>(initialValues: TodoModel.mocks)
//    var mock = Self.testValue
//    mock.router.override(
//      .delete
//      in: .todos
//    )
//    mock.router.override(
//      .fetch,
//      in: .todos,
//      with: { try await storage.delete(id: )}
//    )
//  }
//}
