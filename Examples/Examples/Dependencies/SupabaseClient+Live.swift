import Dependencies
import Foundation
import SupabaseClientLive

extension SupabaseClientDependency: DependencyKey {
  public static var liveValue: SupabaseClientDependency {
    .live(configuration: .local)
  }
}
