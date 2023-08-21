import Dependencies
import Foundation
import SupabaseClient

extension SupabaseClientDependency: DependencyKey {
  public static var liveValue: SupabaseClientDependency {
    .live(configuration: .local)
  }
}
