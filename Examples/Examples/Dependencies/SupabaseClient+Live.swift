import Dependencies
import Foundation
import IdentifiedStorage
import SupabaseDependencies
import Supabase

extension DependencyValues {
  var supabase: SupabaseDependency<DatabaseRoutes> {
    get { self[SapabaseKey.self].supabase }
    set { self[SapabaseKey.self].supabase = newValue }
  }
}

struct SapabaseKey: DependencyKey {
  var supabase: SupabaseDependency<DatabaseRoutes>
  
  static var testValue: SapabaseKey { .init(supabase: .testValue) }
  static var previewValue: SapabaseKey {
    let todos = IdentifiedStorageOf<TodoModel>(initialValues: TodoModel.mocks)
    var preview = Self.init(supabase: .init(
      auth: .mock(session: .mock),
      client: .testValue,
      router: .previewValue
    ))
    preview.supabase.router.override(\.todos) { route in
      // Overrides for preview mode.
      switch route {
      case let .delete(id: id):
        return await .init { try await todos.delete(id: id) }
      case .fetch:
        return await .init { try await todos.fetch() }
      case let .insert(todo):
        return await .init { try await todos.insert(request: todo) }
      case let .update(id: id, updates: updates):
        return await .init { try await todos.update(id: id, request: updates) }
      }
    }
    
    return preview
  }
  
  static var liveValue: SapabaseKey {
    .init(supabase: .live(client: .init(
      supabaseURL: Secrets.supabaseUrl,
      supabaseKey: Secrets.supabaseAnonKey
    )))
  }
}
