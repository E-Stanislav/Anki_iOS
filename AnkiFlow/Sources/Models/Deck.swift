import Foundation

struct Deck: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var description: String
    var parentId: UUID?
    var createdAt: Date
    var updatedAt: Date
    var isArchived: Bool
    var isFavorite: Bool
    var newCardsPerDay: Int
    var reviewCardsPerDay: Int

    init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        parentId: UUID? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isArchived: Bool = false,
        isFavorite: Bool = false,
        newCardsPerDay: Int = 20,
        reviewCardsPerDay: Int = 200
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.parentId = parentId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isArchived = isArchived
        self.isFavorite = isFavorite
        self.newCardsPerDay = newCardsPerDay
        self.reviewCardsPerDay = reviewCardsPerDay
    }
}

struct DeckStats: Hashable {
    let deckId: UUID
    var newCount: Int
    var learningCount: Int
    var reviewCount: Int
    var totalCount: Int
    var dueToday: Int
}
