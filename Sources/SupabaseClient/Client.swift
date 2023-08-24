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
//  private let client: Supabase.SupabaseClient

  /// The supabase authentication client for the application.
  ///
  /// - SeeAlso: ``SupabaseClientDependency/Auth-swift.struct``
  public var auth: Auth
  
  public var database: DatabaseClient

  /// Create a new supabase client dependency.
  ///
  /// - Parameters:
  ///   - client: The supabase client for the application.
  ///   - auth: The supabase authentication client dependency for the application.
//  public init(
//    client: Supabase.SupabaseClient,
//    auth: Auth
//  ) {
//    self.client = client
//    self.auth = auth
//  }
  
  /// Create a new supabase client dependency.
  ///
  /// - Parameters:
  ///   - configuration: The supabase client configuration for the application.
  ///   - auth: The supabase authentication client dependency for the application.
//  public init(
//    configuration: Configuration,
//    auth: Auth
//  ) {
//    self.init(client: configuration.client, auth: auth)
//  }

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
//  @discardableResult
//  public func withDatabase<R: Sendable>(
//    perform: @escaping @Sendable (PostgrestClient) async throws -> R
//  ) async rethrows -> R {
//    try await perform(self.client.database)
//  }

  public struct DatabaseClient {

    public var delete: (DeleteRequest) async throws -> Void
    public var fetch: (FetchRequest) async throws -> [[String: AnyJSON]]
    public var fetchOne: (FetchOneRequest) async throws -> [String: AnyJSON]
    public var insert: (InsertRequest) async throws -> [String: AnyJSON]
    public var update: (UpdateRequest) async throws -> [String: AnyJSON]
    
    public init(
      delete: @escaping (DeleteRequest) async throws -> Void,
      fetch: @escaping (FetchRequest) async throws -> [[String : AnyJSON]],
      fetchOne: @escaping (FetchOneRequest) async throws -> [String: AnyJSON],
      insert: @escaping (InsertRequest) async throws -> [String: AnyJSON],
      update: @escaping (UpdateRequest) async throws -> [String: AnyJSON]
    ) {
      self.delete = delete
      self.fetch = fetch
      self.fetchOne = fetchOne
      self.insert = insert
      self.update = update
    }
    
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
    
    public struct FetchOneRequest {
      
      public let table: TableRepresentable
      public let filters: [Filter]
      
      public init(
        table: TableRepresentable,
        filters: [Filter]
      ) {
        self.table = table
        self.filters = filters
      }
    }
    
    public struct InsertRequest {
      public let table: TableRepresentable
      public let returningOptions: PostgrestReturningOptions?
      public let values: any Encodable
      
      public init(
        table: TableRepresentable,
        returningOptions: PostgrestReturningOptions?,
        values: any Encodable
      ) {
        self.table = table
        self.returningOptions = returningOptions
        self.values = values
      }
    }
    
    public struct UpdateRequest {
      public let table: TableRepresentable
      public let filters: [Filter]
      public let returningOptions: PostgrestReturningOptions
      public let values: any Encodable
      
      public init(
        table: TableRepresentable,
        filters: [Filter],
        returningOptions: PostgrestReturningOptions,
        values: any Encodable
      ) {
        self.table = table
        self.filters = filters
        self.returningOptions = returningOptions
        self.values = values
      }
    }
  }

}

extension SupabaseClientDependency.DatabaseClient {
  static func live(client: PostgrestClient) -> Self {
    .init(
      delete: { request in
        try await client.from(request.table.tableName)
          .delete(returning: .minimal)
          .filter(by: request.filters)
          .execute()
          .value
      },
      fetch: { request in
        try await client.from(request.table.tableName)
          .select()
          .filter(by: request.filters)
          .order(by: request.order)
          .execute()
          .value
      },
      fetchOne: { request in
        try await client.from(request.table.tableName)
          .select()
          .filter(by: request.filters)
          .single()
          .execute()
          .value
      },
      insert: { request in
        try await client.from(request.table.tableName)
          .insert(values: request.values, returning: request.returningOptions)
          .single()
          .execute()
          .value
      },
      update: { request in
        try await client.from(request.table.tableName)
          .update(values: request.values, returning: request.returningOptions)
          .filter(by: request.filters)
          .single()
          .execute()
          .value
      }
      
    )
  }
}
private let dateFormatterWithFractionalSeconds = { () -> ISO8601DateFormatter in
  let formatter = ISO8601DateFormatter()
  formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
  return formatter
}()

private let dateFormatter = { () -> ISO8601DateFormatter in
  let formatter = ISO8601DateFormatter()
  formatter.formatOptions = [.withInternetDateTime]
  return formatter
}()

extension JSONDecoder {
  static let goTrue = { () -> JSONDecoder in
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .custom { decoder in
      let container = try decoder.singleValueContainer()
      let string = try container.decode(String.self)

      let supportedFormatters = [dateFormatterWithFractionalSeconds, dateFormatter]

      for formatter in supportedFormatters {
        if let date = formatter.date(from: string) {
          return date
        }
      }

      throw DecodingError.dataCorruptedError(
        in: container, debugDescription: "Invalid date format: \(string)"
      )
    }
    return decoder
  }()
}

extension JSONEncoder {
  static let goTrue = { () -> JSONEncoder in
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .custom { date, encoder in
      var container = encoder.singleValueContainer()
      let string = dateFormatter.string(from: date)
      try container.encode(string)
    }
    return encoder
  }()
}


extension Dictionary where Key == String, Value == AnyJSON {
  
  func decoding<T: Decodable>(as type: T.Type) throws -> T {
    print("Decoding dictionary: \(self)")
    let encoded = try JSONEncoder.goTrue.encode(self)
    return try JSONDecoder.goTrue.decode(T.self, from: encoded)
  }
}

extension Array where Element == [String: AnyJSON] {
  func decoding<T: Decodable>(as type: T.Type) throws -> [T] {
    try self.map { try $0.decoding(as: T.self) }
  }
  
}

extension SupabaseClientDependency.DatabaseClient {
  static let unimplemented = Self.init(
    delete: XCTestDynamicOverlay.unimplemented("\(Self.self).delete"),
    fetch: XCTestDynamicOverlay.unimplemented("\(Self.self).fetch", placeholder: []),
    fetchOne: XCTestDynamicOverlay.unimplemented("\(Self.self).fetchOne", placeholder: [:]),
    insert: XCTestDynamicOverlay.unimplemented("\(Self.self).insert", placeholder: [:]),
    update: XCTestDynamicOverlay.unimplemented("\(Self.self).update", placeholder: [:])
  )
}

extension SupabaseClientDependency: TestDependencyKey {

  /// The unimplemented supabase client dependency for usage in tests.
  public static var testValue: Self {
    Self.init(
//      client: unimplemented(
//        "\(Self.self).client",
//        placeholder: SupabaseClient(supabaseURL: URL(string: "/")!, supabaseKey: "")
//      ),
      auth: .unimplemented,
      database: .unimplemented
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
