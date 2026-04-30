import Foundation

struct Review: Identifiable, Codable, Equatable {
    let id: UUID
    let cardId: UUID
    var easeFactor: Double
    var interval: Int
    var dueDate: Date
    var lastReviewed: Date?

    init(
        id: UUID = UUID(),
        cardId: UUID,
        easeFactor: Double = 2.5,
        interval: Int = 0,
        dueDate: Date = Date(),
        lastReviewed: Date? = nil
    ) {
        self.id = id
        self.cardId = cardId
        self.easeFactor = easeFactor
        self.interval = interval
        self.dueDate = dueDate
        self.lastReviewed = lastReviewed
    }
}
