import Foundation
import SQLite

struct CardTable {
    static let table = Table("cards")

    static let id = Expression<String>("id")
    static let deckId = Expression<String>("deck_id")
    static let front = Expression<String>("front")
    static let back = Expression<String>("back")
    static let tags = Expression<String>("tags")
    static let createdAt = Expression<Date>("created_at")
    static let isSuspended = Expression<Bool>("is_suspended")

    static func insertCard(_ card: Card) throws {
        guard let db = DatabaseManager.shared.getConnection() else {
            throw DatabaseError.connectionFailed
        }

        let insert = table.insert(
            id <- card.id.uuidString,
            deckId <- card.deckId.uuidString,
            front <- card.front,
            back <- card.back,
            tags <- card.tags,
            createdAt <- card.createdAt,
            isSuspended <- false
        )

        try db.run(insert)

        let review = Review(cardId: card.id)
        try ReviewTable.insertReview(review)
    }

    static func fetchCardsByDeck(deckId deckUUID: UUID) throws -> [Card] {
        guard let db = DatabaseManager.shared.getConnection() else {
            throw DatabaseError.connectionFailed
        }

        var cards: [Card] = []
        let query = table.filter(deckId == deckUUID.uuidString)

        for row in try db.prepare(query) {
            if let uuid = UUID(uuidString: row[id]),
               let deckUUID = UUID(uuidString: row[deckId]) {
                let card = Card(
                    id: uuid,
                    deckId: deckUUID,
                    front: row[front],
                    back: row[back],
                    tags: row[tags],
                    createdAt: row[createdAt]
                )
                cards.append(card)
            }
        }
        return cards
    }

    static func getCardCount(deckId deckUUID: UUID) throws -> Int {
        guard let db = DatabaseManager.shared.getConnection() else {
            throw DatabaseError.connectionFailed
        }

        let query = table.filter(deckId == deckUUID.uuidString)
        return try db.scalar(query.count)
    }

    static func deleteCardsByDeck(deckId deckUUID: UUID) throws {
        guard let db = DatabaseManager.shared.getConnection() else {
            throw DatabaseError.connectionFailed
        }

        let cards = table.filter(deckId == deckUUID.uuidString)
        try db.run(cards.delete())
    }

    static func searchCards(query searchQuery: String, deckId deckUUID: UUID) throws -> [Card] {
        guard let db = DatabaseManager.shared.getConnection() else {
            throw DatabaseError.connectionFailed
        }

        var cards: [Card] = []
        let query = table.filter(
            deckId == deckUUID.uuidString &&
            (front.like("%\(searchQuery)%") || back.like("%\(searchQuery)%"))
        )

        for row in try db.prepare(query) {
            if let uuid = UUID(uuidString: row[id]),
               let deckUUID = UUID(uuidString: row[deckId]) {
                let card = Card(
                    id: uuid,
                    deckId: deckUUID,
                    front: row[front],
                    back: row[back],
                    tags: row[tags],
                    createdAt: row[createdAt]
                )
                cards.append(card)
            }
        }
        return cards
    }

    static func toggleSuspension(cardId cardUUID: UUID) throws {
        guard let db = DatabaseManager.shared.getConnection() else {
            throw DatabaseError.connectionFailed
        }

        let card = table.filter(id == cardUUID.uuidString)
        if let row = try db.pluck(card) {
            let currentState = row[isSuspended]
            try db.run(card.update(isSuspended <- !currentState))
        }
    }
}
