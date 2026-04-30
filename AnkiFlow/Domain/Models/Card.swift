import Foundation

struct Card: Identifiable, Codable, Equatable {
    let id: UUID
    let deckId: UUID
    var front: String
    var back: String
    var tags: String
    var createdAt: Date

    init(id: UUID = UUID(), deckId: UUID, front: String, back: String, tags: String = "", createdAt: Date = Date()) {
        self.id = id
        self.deckId = deckId
        self.front = front
        self.back = back
        self.tags = tags
        self.createdAt = createdAt
    }
}
