import Foundation
import Supabase

extension SupabaseClientDependency {
  public struct Configuration {
    let url: URL
    let anonKey: String
    let options: SupabaseClientOptions

    public init(
      url: URL,
      anonKey: String,
      options: SupabaseClientOptions = .init()
    ) {
      self.url = url
      self.anonKey = anonKey
      self.options = options
    }
  }
}

extension SupabaseClientDependency.Configuration {
  public static let local = Self.init(url: supabaseURL, anonKey: localAnonKey)
}

fileprivate let supabaseURL = URL(string: "http://localhost:54321")!
fileprivate let localAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0"
