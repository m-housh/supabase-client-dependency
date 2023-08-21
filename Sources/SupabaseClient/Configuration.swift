import Foundation
import Supabase

extension SupabaseClientDependency {

  /// Represents the configuration for the supabase client dependency.
  ///
  public struct Configuration {

    /// The url to connect to supabase.
    let url: URL

    /// The anonymous key used to connect to supabase.
    let anonymousKey: String

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
      anonymousKey: String,
      options: SupabaseClientOptions = .init()
    ) {
      self.url = url
      self.anonymousKey = anonymousKey
      self.options = options
    }

    /// Generate's a `Supabase.SupabaseClient` from the configuration.
    public var client: SupabaseClient { .init(configuration: self) }

  }

}

extension SupabaseClient {

  /// Create a new client from the configuration.
  ///
  /// - Parameters:
  ///   - configuration: The configuration values used to generate the client.
  public convenience init(configuration: SupabaseClientDependency.Configuration) {
    self.init(
      supabaseURL: configuration.url,
      supabaseKey: configuration.anonymousKey,
      options: configuration.options
    )
  }
}

extension SupabaseClientDependency.Configuration {

  /// A configuration for a local supabase instance.
  ///
  /// In general this may not be the same for different machines and should not be used in production.
  public static let local = Self.init(url: supabaseURL, anonymousKey: localAnonKey)
}

private let supabaseURL = URL(string: "http://localhost:54321")!
private let localAnonKey =
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0"
