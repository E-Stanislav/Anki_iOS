import Foundation

protocol DeckRepositoryProtocol {
    func getAll() -> [Deck]
    func getById(_ id: UUID) -> Deck?
    func save(_ deck: Deck)
    func delete(_ id: UUID)
    func getStats(for deckId: UUID) -> DeckStats?
}

final class DeckRepository: DeckRepositoryProtocol {
    private let db = DatabaseService.shared

    func getAll() -> [Deck] {
        let rows = db.query("SELECT * FROM decks ORDER BY updated_at DESC")
        return rows.compactMap { decodeDeck(from: $0) }
    }

    func getById(_ id: UUID) -> Deck? {
        let rows = db.query("SELECT * FROM decks WHERE id = ?", parameters: [id.uuidString])
        return rows.first.flatMap { decodeDeck(from: $0) }
    }

    func save(_ deck: Deck) {
        let sql = """
        INSERT OR REPLACE INTO decks (id, name, description, parent_id, created_at, updated_at, is_archived, is_favorite, new_cards_per_day, review_cards_per_day)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """
        db.execute(sql, parameters: [
            deck.id.uuidString,
            deck.name,
            deck.description,
            deck.parentId?.uuidString,
            deck.createdAt.timeIntervalSince1970,
            deck.updatedAt.timeIntervalSince1970,
            deck.isArchived ? 1 : 0,
            deck.isFavorite ? 1 : 0,
            deck.newCardsPerDay,
            deck.reviewCardsPerDay
        ])
    }

    func delete(_ id: UUID) {
        db.execute("DELETE FROM card_schedules WHERE card_id IN (SELECT id FROM cards WHERE deck_id = ?)", parameters: [id.uuidString])
        db.execute("DELETE FROM cards WHERE deck_id = ?", parameters: [id.uuidString])
        db.execute("DELETE FROM decks WHERE id = ?", parameters: [id.uuidString])
    }

    func deleteAll() {
        db.execute("PRAGMA foreign_keys = OFF")
        db.execute("DELETE FROM card_schedules")
        db.execute("DELETE FROM cards")
        db.execute("DELETE FROM decks")
        db.execute("PRAGMA foreign_keys = ON")
    }

    func getStats(for deckId: UUID) -> DeckStats? {
        let newCount = db.query(
            "SELECT COUNT(*) as count FROM cards c JOIN card_schedules cs ON c.id = cs.card_id WHERE c.deck_id = ? AND cs.status = 'new'",
            parameters: [deckId.uuidString]
        ).first?["count"] as? Int ?? 0

        let learningCount = db.query(
            "SELECT COUNT(*) as count FROM cards c JOIN card_schedules cs ON c.id = cs.card_id WHERE c.deck_id = ? AND cs.status = 'learning'",
            parameters: [deckId.uuidString]
        ).first?["count"] as? Int ?? 0

        let reviewCount = db.query(
            "SELECT COUNT(*) as count FROM cards c JOIN card_schedules cs ON c.id = cs.card_id WHERE c.deck_id = ? AND cs.status = 'review' AND cs.due <= ?",
            parameters: [deckId.uuidString, Date().timeIntervalSince1970]
        ).first?["count"] as? Int ?? 0

        let totalCount = db.query(
            "SELECT COUNT(*) as count FROM cards WHERE deck_id = ?",
            parameters: [deckId.uuidString]
        ).first?["count"] as? Int ?? 0

        return DeckStats(
            deckId: deckId,
            newCount: newCount,
            learningCount: learningCount,
            reviewCount: reviewCount,
            totalCount: totalCount,
            dueToday: newCount + learningCount + reviewCount
        )
    }

    private func decodeDeck(from row: [String: Any]) -> Deck? {
        guard let idString = row["id"] as? String,
              let id = UUID(uuidString: idString),
              let name = row["name"] as? String,
              let createdAt = row["created_at"] as? Double,
              let updatedAt = row["updated_at"] as? Double else {
            return nil
        }

        return Deck(
            id: id,
            name: name,
            description: row["description"] as? String ?? "",
            parentId: (row["parent_id"] as? String).flatMap { UUID(uuidString: $0) },
            createdAt: Date(timeIntervalSince1970: createdAt),
            updatedAt: Date(timeIntervalSince1970: updatedAt),
            isArchived: (row["is_archived"] as? Int ?? 0) == 1,
            isFavorite: (row["is_favorite"] as? Int ?? 0) == 1,
            newCardsPerDay: row["new_cards_per_day"] as? Int ?? 20,
            reviewCardsPerDay: row["review_cards_per_day"] as? Int ?? 200
        )
    }
}
