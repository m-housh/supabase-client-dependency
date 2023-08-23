import Dependencies
import Foundation
@_exported import GoTrue
@_exported import PostgREST
@_exported import Supabase
import XCTestDynamicOverlay

extension DependencyValues {

  /// Access the supbase client as a dependency in the application.
  public var supabaseClient: SupabaseClientDependency {
    get { self[SupabaseClientDependency.self] }
    set { self[SupabaseClientDependency.self] = newValue }
  }
}

/// A wrapper around the `SupabaseClient` that can be used as a dependency in your projects that integrate
/// with supabase.
///
/// This adds some niceties around database operations and also includes an `auth` client.
///
public struct SupabaseClientDependency {

  /// The supabase client for the application.
  private let client: Supabase.SupabaseClient

  /// The supabase authentication client for the application.
  ///
  /// - SeeAlso: ``SupabaseClientDependency/Auth-swift.struct``
  public var auth: Auth

  /// Create a new supabase client dependency.
  ///
  /// - Parameters:
  ///   - client: The supabase client for the application.
  ///   - auth: The supabase authentication client dependency for the application.
  public init(
    client: Supabase.SupabaseClient,
    auth: Auth
  ) {
    self.client = client
    self.auth = auth
  }
  
  /// Create a new supabase client dependency.
  ///
  /// - Parameters:
  ///   - configuration: The supabase client configuration for the application.
  ///   - auth: The supabase authentication client dependency for the application.
  public init(
    configuration: Configuration,
    auth: Auth
  ) {
    self.init(client: configuration.client, auth: auth)
  }

  /// Perform a database request on the postgres client.
  ///
  ///  This is useful when you need to perform a custom query beyond what is provided by this library.
  ///
  /// ### Example
  ///
  /// ```swift
  ///  try await client.withDatabase { database in
  ///     database.from("todos")
  ///       .select()
  ///       .execute()
  ///       .value
  ///  }
  /// ```
  ///
  /// - Parameters:
  ///   - perform: The action to perform on the supabase database.
  @discardableResult
  public func withDatabase<R: Sendable>(
    perform: @escaping @Sendable (PostgrestClient) async throws -> R
  ) async rethrows -> R {
    try await perform(self.client.database)
  }

  public struct DatabaseClient {

    var delete: VoidExecutor<DeleteRequest>
    var fetch: DecodableExecutor<FetchRequest>

    public struct DeleteRequest {
      public let table: TableRepresentable
      public let filters: [Filter]

      public init(table: TableRepresentable, filters: [Filter]) {
        self.table = table
        self.filters = filters
      }
    }

    public struct FetchRequest {
      public let table: TableRepresentable
      public let filters: [Filter]
      public let order: Order?

      public init(
        table: TableRepresentable,
        filters: [Filter],
        order: Order?
      ) {
        self.table = table
        self.filters = filters
        self.order = order
      }
    }
  }

}


public struct VoidExecutor<Request> {
  var execute: () async throws -> Void
}

extension VoidExecutor where Request == SupabaseClientDependency.DatabaseClient.DeleteRequest {
  static func delete(_ request: Request, using client: PostgrestClient) -> Self {
    .init {
      try await client.from(request.table.tableName)
        .delete(returning: .minimal)
        .filter(by: request.filters)
        .execute()
        .value
    }
  }
}

public struct DecodableExecutor<Request> {

  struct DecoderF<Model: Decodable> {

  }
}

extension DecodableExecutor where Request == SupabaseClientDependency.DatabaseClient.FetchRequest {

  func fetch<Response: Decodable>(
    _ request: Request,
    using client: PostgrestClient,
    decoding type: Response.Type = Response.self
  ) async throws -> Response {
    try await client.from(request.table.tableName)
      .select()
      .filter(by: request.filters)
      .order(by: request.order)
      .execute()
      .value
  }
}



extension SupabaseClientDependency: TestDependencyKey {

  /// The unimplemented supabase client dependency for usage in tests.
  public static var testValue: Self {
    Self.init(
      client: unimplemented(
        "\(Self.self).client",
        placeholder: SupabaseClient(supabaseURL: URL(string: "/")!, supabaseKey: "")
      ),
      auth: .unimplemented
    )
  }
}

#if DEBUG
  extension User {
    public static let mock = Self.init(
      id: UUID(0),
      appMetadata: [:],
      userMetadata: [:],
      aud: "",
      createdAt: Date(),
      updatedAt: Date()
    )
  }

  extension Session {
    public static let mock = Self.init(
      accessToken: "",
      tokenType: "",
      expiresIn: 1,
      refreshToken: "",
      user: .mock
    )
  }
#endif
