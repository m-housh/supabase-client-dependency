import Foundation
import Supabase

extension SupabaseClientDependency {

  /// Represents the configuration for the supabase client dependency.
  ///
  public struct Configuration {

    /// The url to connect to supabase.
    let url: URL

    /// The anonymous key used to connect to supabase.
    let anonKey: String

    /// The supabase client options.
    let options: SupabaseClientOptions

    /// Create a new supabase client configuration.
    ///
    /// - Parameters:
    ///   - url: The url to connect to supabase.
    ///   - anonKey: The anonymous key used to connect to supabase.
    ///   - options: The supabase client options.
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

extension SupabaseClient {

  public convenience init(configuration: SupabaseClientDependency.Configuration) {
    self.init(
      supabaseURL: configuration.url,
      supabaseKey: configuration.anonKey,
      options: configuration.options
    )
  }
}

extension SupabaseClientDependency.Configuration {
  public static let local = Self.init(url: supabaseURL, anonKey: localAnonKey)
}

private let supabaseURL = URL(string: "http://localhost:54321")!
private let localAnonKey =
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0"
