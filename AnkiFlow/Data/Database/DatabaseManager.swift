import Foundation
import SQLite

final class DatabaseManager {
    static let shared = DatabaseManager()

    private var db: Connection?

    private init() {
        setupDatabase()
    }

    private func setupDatabase() {
        do {
            let fileManager = FileManager.default
            let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let appFolder = appSupportURL.appendingPathComponent("AnkiFlow", isDirectory: true)

            if !fileManager.fileExists(atPath: appFolder.path) {
                try fileManager.createDirectory(at: appFolder, withIntermediateDirectories: true, attributes: nil)
            }

            let dbPath = appFolder.appendingPathComponent("AnkiFlow.sqlite").path
            db = try Connection(dbPath)

            createTables()
        } catch {
            print("Database setup error: \(error)")
        }
    }

    private func createTables() {
        guard let db = db else { return }

        do {
            try db.run(DeckTable.table.create(ifNotExists: true) { t in
                t.column(DeckTable.id, primaryKey: true)
                t.column(DeckTable.name)
                t.column(DeckTable.createdAt)
                t.column(DeckTable.updatedAt)
            })

            try db.run(CardTable.table.create(ifNotExists: true) { t in
                t.column(CardTable.id, primaryKey: true)
                t.column(CardTable.deckId)
                t.column(CardTable.front)
                t.column(CardTable.back)
                t.column(CardTable.tags)
                t.column(CardTable.createdAt)
                t.column(CardTable.isSuspended, defaultValue: false)
            })

            try db.run(ReviewTable.table.create(ifNotExists: true) { t in
                t.column(ReviewTable.id, primaryKey: true)
                t.column(ReviewTable.cardId)
                t.column(ReviewTable.easeFactor, defaultValue: 2.5)
                t.column(ReviewTable.interval, defaultValue: 0)
                t.column(ReviewTable.dueDate)
                t.column(ReviewTable.lastReviewed)
            })

            try db.run("CREATE INDEX IF NOT EXISTS idx_cards_deck ON cards(deck_id)")
            try db.run("CREATE INDEX IF NOT EXISTS idx_reviews_card ON reviews(card_id)")
            try db.run("CREATE INDEX IF NOT EXISTS idx_reviews_due ON reviews(due_date)")
        } catch {
            print("Table creation error: \(error)")
        }
    }

    func getConnection() -> Connection? {
        return db
    }
}
