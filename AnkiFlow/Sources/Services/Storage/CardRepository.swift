import Foundation

protocol CardRepositoryProtocol {
    func getAll(for deckId: UUID) -> [Card]
    func getById(_ id: UUID) -> Card?
    func getDueCards(for deckId: UUID, limit: Int) -> [Card]
    func save(_ card: Card)
    func saveSchedule(_ schedule: CardSchedule)
    func getSchedule(for cardId: UUID) -> CardSchedule?
    func delete(_ id: UUID)
}

final class CardRepository: CardRepositoryProtocol {
    private let db = DatabaseService.shared

    func getAll(for deckId: UUID) -> [Card] {
        let rows = db.query("SELECT * FROM cards WHERE deck_id = ?", parameters: [deckId.uuidString])
        return rows.compactMap { decodeCard(from: $0) }
    }

    func getById(_ id: UUID) -> Card? {
        let rows = db.query("SELECT * FROM cards WHERE id = ?", parameters: [id.uuidString])
        return rows.first.flatMap { decodeCard(from: $0) }
    }

    func getDueCards(for deckId: UUID, limit: Int) -> [Card] {
        let sql = """
        SELECT c.* FROM cards c
        JOIN card_schedules cs ON c.id = cs.card_id
        WHERE c.deck_id = ? AND cs.due <= ?
        ORDER BY cs.due ASC
        LIMIT ?
        """
        let rows = db.query(sql, parameters: [
            deckId.uuidString,
            Date().timeIntervalSince1970,
            limit
        ])
        return rows.compactMap { decodeCard(from: $0) }
    }

    func save(_ card: Card) {
        let sql = """
        INSERT OR REPLACE INTO cards (id, note_id, deck_id, template_index, front, back, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """
        db.execute(sql, parameters: [
            card.id.uuidString,
            card.noteId.uuidString,
            card.deckId.uuidString,
            card.templateIndex,
            card.front,
            card.back,
            card.createdAt.timeIntervalSince1970,
            card.updatedAt.timeIntervalSince1970
        ])
    }

    func saveSchedule(_ schedule: CardSchedule) {
        let sql = """
        INSERT OR REPLACE INTO card_schedules (card_id, status, due, interval, ease_factor, reps, lapses)
        VALUES (?, ?, ?, ?, ?, ?, ?)
        """
        db.execute(sql, parameters: [
            schedule.cardId.uuidString,
            schedule.status.rawValue,
            schedule.due.timeIntervalSince1970,
            schedule.interval,
            schedule.easeFactor,
            schedule.reps,
            schedule.lapses
        ])
    }

    func getSchedule(for cardId: UUID) -> CardSchedule? {
        let rows = db.query("SELECT * FROM card_schedules WHERE card_id = ?", parameters: [cardId.uuidString])
        return rows.first.flatMap { decodeSchedule(from: $0) }
    }

    func delete(_ id: UUID) {
        db.execute("DELETE FROM card_schedules WHERE card_id = ?", parameters: [id.uuidString])
        db.execute("DELETE FROM cards WHERE id = ?", parameters: [id.uuidString])
    }

    private func decodeCard(from row: [String: Any]) -> Card? {
        guard let idString = row["id"] as? String,
              let id = UUID(uuidString: idString),
              let noteIdString = row["note_id"] as? String,
              let noteId = UUID(uuidString: noteIdString),
              let deckIdString = row["deck_id"] as? String,
              let deckId = UUID(uuidString: deckIdString),
              let front = row["front"] as? String,
              let back = row["back"] as? String,
              let createdAt = row["created_at"] as? Double,
              let updatedAt = row["updated_at"] as? Double else {
            return nil
        }

        return Card(
            id: id,
            noteId: noteId,
            deckId: deckId,
            templateIndex: row["template_index"] as? Int ?? 0,
            front: front,
            back: back,
            createdAt: Date(timeIntervalSince1970: createdAt),
            updatedAt: Date(timeIntervalSince1970: updatedAt)
        )
    }

    private func decodeSchedule(from row: [String: Any]) -> CardSchedule? {
        guard let cardIdString = row["card_id"] as? String,
              let cardId = UUID(uuidString: cardIdString),
              let statusString = row["status"] as? String,
              let status = CardStatus(rawValue: statusString),
              let due = row["due"] as? Double else {
            return nil
        }

        return CardSchedule(
            cardId: cardId,
            status: status,
            due: Date(timeIntervalSince1970: due),
            interval: row["interval"] as? Int ?? 0,
            easeFactor: row["ease_factor"] as? Double ?? 2.5,
            reps: row["reps"] as? Int ?? 0,
            lapses: row["lapses"] as? Int ?? 0
        )
    }
}
