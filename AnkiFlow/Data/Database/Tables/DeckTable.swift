import Foundation
import SQLite

struct DeckTable {
    static let table = Table("decks")

    static let id = Expression<String>("id")
    static let name = Expression<String>("name")
    static let createdAt = Expression<Date>("created_at")
    static let updatedAt = Expression<Date>("updated_at")

    static func insertDeck(_ deck: Deck) throws {
        guard let db = DatabaseManager.shared.getConnection() else {
            throw DatabaseError.connectionFailed
        }

        let insert = table.insert(
            id <- deck.id.uuidString,
            name <- deck.name,
            createdAt <- deck.createdAt,
            updatedAt <- deck.updatedAt
        )

        try db.run(insert)
    }

    static func fetchAllDecks() throws -> [Deck] {
        guard let db = DatabaseManager.shared.getConnection() else {
            throw DatabaseError.connectionFailed
        }

        var decks: [Deck] = []
        for row in try db.prepare(table.order(updatedAt.desc)) {
            if let uuid = UUID(uuidString: row[id]) {
                let deck = Deck(
                    id: uuid,
                    name: row[name],
                    createdAt: row[createdAt],
                    updatedAt: row[updatedAt]
                )
                decks.append(deck)
            }
        }
        return decks
    }

    static func deleteDeck(id deckId: UUID) throws {
        guard let db = DatabaseManager.shared.getConnection() else {
            throw DatabaseError.connectionFailed
        }

        let deck = table.filter(id == deckId.uuidString)
        try db.run(deck.delete())
    }

    static func updateDeck(_ deck: Deck) throws {
        guard let db = DatabaseManager.shared.getConnection() else {
            throw DatabaseError.connectionFailed
        }

        let deckRow = table.filter(id == deck.id.uuidString)
        try db.run(deckRow.update(
            name <- deck.name,
            updatedAt <- Date()
        ))
    }
}

enum DatabaseError: Error {
    case connectionFailed
    case insertFailed
    case fetchFailed
}
