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
  static var liveValue: DatabaseRoutes = .init(
    todos: .init(database: supabaseClient.schema("public"))
  )
}
