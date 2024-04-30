
public protocol DatabaseRouter {
  func execute(on client: PostgrestClient) async throws

  @discardableResult
  func execute<A: Decodable>(on client: PostgrestClient) async throws -> A
}
