import Foundation

struct Card: Identifiable, Codable, Hashable {
    let id: UUID
    var noteId: UUID
    var deckId: UUID
    var templateIndex: Int
    var front: String
    var back: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        noteId: UUID,
        deckId: UUID,
        templateIndex: Int = 0,
        front: String,
        back: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.noteId = noteId
        self.deckId = deckId
        self.templateIndex = templateIndex
        self.front = front
        self.back = back
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

enum CardStatus: String, Codable, CaseIterable {
    case new
    case learning
    case review
    case suspended
}

struct CardSchedule: Codable, Hashable {
    let cardId: UUID
    var status: CardStatus
    var due: Date
    var interval: Int
    var easeFactor: Double
    var reps: Int
    var lapses: Int

    init(
        cardId: UUID,
        status: CardStatus = .new,
        due: Date = Date(),
        interval: Int = 0,
        easeFactor: Double = 2.5,
        reps: Int = 0,
        lapses: Int = 0
    ) {
        self.cardId = cardId
        self.status = status
        self.due = due
        self.interval = interval
        self.easeFactor = easeFactor
        self.reps = reps
        self.lapses = lapses
    }
}
