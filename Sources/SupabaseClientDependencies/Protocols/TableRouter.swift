public protocol TableRouter {
  var table: AnyTable { get }
  var builder: QueryBuilder<Self> { get }
}

extension TableRouter {
  public func execute(on client: PostgrestClient) async throws {
    try await builder.build(client.from(table.tableName), self).execute().value
  }

  @discardableResult
  public func execute<A: Decodable>(on client: PostgrestClient) async throws -> A {
    try await builder.build(client.from(table.tableName), self).execute().value
  }
}
