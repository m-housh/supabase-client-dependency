import Dependencies
import Foundation
import SupabaseClientDependency

extension SupabaseClientDependency: DependencyKey {
  public static var liveValue: SupabaseClientDependency {
    .live(configuration: .local)
  }
}
