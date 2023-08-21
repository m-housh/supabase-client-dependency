import Dependencies
import SupabaseClient

extension SupabaseClientDependency: DependencyKey {
  
  public static var liveValue: SupabaseClientDependency {
    // Using the local configuration, declared in the `SupabaseClient` package.
    //
    // You would generally use a custom configuration for your supabase instance.
    .live(configuration: .local)
  }
}
