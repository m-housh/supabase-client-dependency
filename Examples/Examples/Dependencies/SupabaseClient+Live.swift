import Dependencies
import Foundation
import SupabaseClientDependencies

extension SupabaseClientDependency: DependencyKey {
  public static var liveValue: SupabaseClientDependency {
    .live(configuration: .local)
  }
}
