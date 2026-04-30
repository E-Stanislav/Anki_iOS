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

        let sql = """
            SELECT c.id, c.deck_id, c.front, c.back, c.tags, c.created_at
            FROM cards c
            INNER JOIN reviews r ON c.id = r.card_id
            WHERE c.deck_id = ? AND c.is_suspended = 0 AND r.due_date < ?
        """

        let dueTimestamp = tomorrow.timeIntervalSince1970

        for row in try db.prepare(sql, deckUUID.uuidString, dueTimestamp) {
            if let idStr = row[0] as? String,
               let deckIdStr = row[1] as? String,
               let id = UUID(uuidString: idStr),
               let deckId = UUID(uuidString: deckIdStr) {
                let createdAt: Date
                if let timestamp = row[5] as? Double {
                    createdAt = Date(timeIntervalSince1970: timestamp)
                } else {
                    createdAt = Date()
                }

                let card = Card(
                    id: id,
                    deckId: deckId,
                    front: row[2] as? String ?? "",
                    back: row[3] as? String ?? "",
                    tags: row[4] as? String ?? "",
                    createdAt: createdAt
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
        let dueTimestamp = tomorrow.timeIntervalSince1970

        let sql = """
            SELECT COUNT(*) FROM cards c
            INNER JOIN reviews r ON c.id = r.card_id
            WHERE c.deck_id = ? AND c.is_suspended = 0 AND r.due_date < ?
        """

        let result = try db.scalar(sql, deckUUID.uuidString, dueTimestamp)
        if let count = result as? Int64 {
            return Int(count)
        }
        return 0
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
