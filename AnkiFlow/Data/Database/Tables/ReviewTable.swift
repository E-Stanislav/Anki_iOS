import Foundation
import SQLite

struct ReviewTable {
    static let table = Table("reviews")

    static let id = Expression<String>("id")
    static let cardId = Expression<String>("card_id")
    static let easeFactor = Expression<Double>("ease_factor")
    static let interval = Expression<Int>("interval")
    static let dueDate = Expression<Date>("due_date")
    static let lastReviewed = Expression<Date?>("last_reviewed")

    static func insertReview(_ review: Review) throws {
        guard let db = DatabaseManager.shared.getConnection() else {
            throw DatabaseError.connectionFailed
        }

        let insert = table.insert(
            id <- review.id.uuidString,
            cardId <- review.cardId.uuidString,
            easeFactor <- review.easeFactor,
            interval <- review.interval,
            dueDate <- review.dueDate,
            lastReviewed <- review.lastReviewed
        )

        try db.run(insert)
    }

    static func fetchReview(cardId cardUUID: UUID) throws -> Review? {
        guard let db = DatabaseManager.shared.getConnection() else {
            throw DatabaseError.connectionFailed
        }

        let query = table.filter(cardId == cardUUID.uuidString)
        if let row = try db.pluck(query),
           let uuid = UUID(uuidString: row[id]),
           let cardUUID = UUID(uuidString: row[cardId]) {
            return Review(
                id: uuid,
                cardId: cardUUID,
                easeFactor: row[easeFactor],
                interval: row[interval],
                dueDate: row[dueDate],
                lastReviewed: row[lastReviewed]
            )
        }
        return nil
    }

    static func fetchDueCards(deckId deckUUID: UUID) throws -> [Card] {
        guard let db = DatabaseManager.shared.getConnection() else {
            throw DatabaseError.connectionFailed
        }

        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

        var cards: [Card] = []

        let joinedQuery = table
            .join(CardTable.table, on: cardId == CardTable.id)
            .filter(CardTable.deckId == deckUUID.uuidString)
            .filter(CardTable.isSuspended == false)
            .filter(dueDate < tomorrow)

        for row in try db.prepare(joinedQuery) {
            if let uuid = UUID(uuidString: row[CardTable.id]),
               let deckUUID = UUID(uuidString: row[CardTable.deckId]) {
                let card = Card(
                    id: uuid,
                    deckId: deckUUID,
                    front: row[CardTable.front],
                    back: row[CardTable.back],
                    tags: row[CardTable.tags],
                    createdAt: row[CardTable.createdAt]
                )
                cards.append(card)
            }
        }

        return cards
    }

    static func getDueCount(deckId deckUUID: UUID) throws -> Int {
        guard let db = DatabaseManager.shared.getConnection() else {
            throw DatabaseError.connectionFailed
        }

        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

        let joinedQuery = table
            .join(CardTable.table, on: cardId == CardTable.id)
            .filter(CardTable.deckId == deckUUID.uuidString)
            .filter(CardTable.isSuspended == false)
            .filter(dueDate < tomorrow)

        return try db.scalar(joinedQuery.count)
    }

    static func updateReview(_ review: Review) throws {
        guard let db = DatabaseManager.shared.getConnection() else {
            throw DatabaseError.connectionFailed
        }

        let reviewRow = table.filter(id == review.id.uuidString)
        try db.run(reviewRow.update(
            easeFactor <- review.easeFactor,
            interval <- review.interval,
            dueDate <- review.dueDate,
            lastReviewed <- review.lastReviewed
        ))
    }

    static func deleteReview(cardId cardUUID: UUID) throws {
        guard let db = DatabaseManager.shared.getConnection() else {
            throw DatabaseError.connectionFailed
        }

        let review = table.filter(cardId == cardUUID.uuidString)
        try db.run(review.delete())
    }
}
