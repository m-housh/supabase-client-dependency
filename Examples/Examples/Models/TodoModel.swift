import Dependencies
import Foundation

struct TodoModel: Codable, Equatable, Identifiable, Sendable {
  var id: UUID
  var description: String
  var isComplete: Bool = false
  
  private enum CodingKeys: String, CodingKey {
    case id
    case description
    case isComplete = "complete"
  }
}

#if DEBUG
extension TodoModel {
  static var mocks: [TodoModel] {
    return [
      .init(id: UUID(0), description: "Buy milk.", isComplete: Bool.random()),
      .init(id: UUID(1), description: "Get gas.", isComplete: Bool.random()),
      .init(id: UUID(2), description: "Pay electric bill.", isComplete: Bool.random())
    ]
  }
}
#endif
