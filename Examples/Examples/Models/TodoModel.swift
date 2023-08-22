import Dependencies
import Foundation

struct TodoModel: Codable, Equatable, Identifiable, Sendable {
  var id: UUID
  var createdAt: Date
  var description: String
  var isComplete: Bool = false
  
  init(
    id: UUID,
    createdAt: Date? = nil,
    description: String,
    isComplete: Bool
  ) {
    @Dependency(\.date.now) var now;
    self.id = id
    self.createdAt = createdAt ?? now
    self.description = description
    self.isComplete = isComplete
  }
  
  private enum CodingKeys: String, CodingKey {
    case id
    case createdAt = "created_at"
    case description
    case isComplete = "complete"
  }
}

#if DEBUG
extension TodoModel {
  static var mocks: [TodoModel] {
    return [
      .init(id: UUID(0), createdAt: Date(), description: "Buy milk.", isComplete: Bool.random()),
      .init(id: UUID(1), createdAt: Date(), description: "Get gas.", isComplete: Bool.random()),
      .init(id: UUID(2), createdAt: Date(), description: "Pay electric bill.", isComplete: Bool.random())
    ]
  }
}
#endif
