import Foundation

public struct AnyDatabaseRouter: DatabaseRouter {
  private let _baseRouter: any DatabaseRouter

  public init<D: DatabaseRouter>(_ router: D) {
    self._baseRouter = router
  }

  public func execute(on client: PostgREST.PostgrestClient) async throws {
    try await self._baseRouter.execute(on: client)
  }
  
  public func execute<A>(on client: PostgREST.PostgrestClient) async throws -> A where A : Decodable {
    try await self._baseRouter.execute(on: client)
  }
}
