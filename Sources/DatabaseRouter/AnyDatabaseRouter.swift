import Foundation
import Supabase

//public struct AnyDatabaseRouter<Route>: DatabaseRouter {
//  private let _baseRouter: any DatabaseRouter<Route>
//
//  public init<D: DatabaseRouter<Route>>(_ router: D) {
//    self._baseRouter = router
//  }
//
//  public func execute(_ route: Route, on client: PostgrestClient) async throws {
//    try await self._baseRouter.execute(route, on: client)
//  }
//  
//  public func execute<A>(_ route: Route, on client: PostgrestClient) async throws -> A where A : Decodable {
//    try await self._baseRouter.execute(route, on: client)
//  }
//}
//
//extension DatabaseRouter {
//  public func eraseToAnyRouter() -> AnyDatabaseRouter<Route> {
//    AnyDatabaseRouter(self)
//  }
//}
