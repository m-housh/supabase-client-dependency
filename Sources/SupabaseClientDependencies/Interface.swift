@_exported import AuthController
@_exported import DatabaseExtensions
@_exported import DatabaseRouter
import Dependencies
import Foundation
@_exported import PostgREST
@_exported import Supabase

@dynamicMemberLookup
public struct SupabaseClientDependency<Routes: DatabaseController> {

  public var auth: AuthController
  public let client: SupabaseClient
  public var router: DatabaseRouter<Routes>

  public init(
    auth: AuthController? = nil,
    client: SupabaseClient,
    router: DatabaseRouter<Routes>? = nil
  ) {
    self.auth = auth ?? .live(auth: client.auth)
    self.client = client
    self.router = router ?? .init()
  }

  /// Create a database query for the given table.
  ///
  /// - Parameters:
  ///   - table: The table to create the query on.
  public func from(_ table: AnyTable) -> PostgrestQueryBuilder {
    self.client.from(table.tableName)
  }

  /// Access the properties on the supabase client.
  public subscript<T>(dynamicMember keyPath: KeyPath<SupabaseClient, T>) -> T {
    client[keyPath: keyPath]
  }
}

extension SupabaseClientDependency: TestDependencyKey {
  static public var testValue: SupabaseClientDependency<Routes> {
    let client = SupabaseClient.local()
    return .init(
      auth: XCTestDynamicOverlay.unimplemented("\(Self.self).auth", placeholder: .live(auth: client.auth)),
      client: XCTestDynamicOverlay.unimplemented("\(Self.self).client", placeholder: client),
      router: XCTestDynamicOverlay.unimplemented("\(Self.self).router", placeholder: .init())
    )
  }
}

extension SupabaseClientDependency {

  /// A helper to generate a live ``SupabaseClientDependency``.
  ///
  /// This is generally used to conform the supabase client dependency to `DependencyKey` and
  /// provide it's `liveValue` in your project.
  ///
  /// - Parameters:
  ///   - client: The supabase client to use.
  public static func live(client: SupabaseClient) -> Self {
    .init(client: client)
  }
}

extension SupabaseClient {

  /// A configuration for a local supabase instance.
  ///
  /// In general this may not be the same for different machines and should not be used in production.
  public static func local() -> Self {
    Self.init(supabaseURL: supabaseURL, supabaseKey: localAnonKey)
  }

}

private let supabaseURL = URL(string: "http://localhost:54321")!
private let localAnonKey =
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9." +
  "eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9." +
  "CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0"
