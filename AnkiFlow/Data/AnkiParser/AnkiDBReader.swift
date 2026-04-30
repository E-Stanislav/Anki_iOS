import Foundation
import SQLite

final class AnkiDBReader {
    private let connection: Connection

    init(path: String) throws {
        self.connection = try Connection(path, readonly: true)
    }

    func readDecks() throws -> [(id: Int64, name: String)] {
        var decks: [(id: Int64, name: String)] = []

        for row in try connection.prepare("SELECT id, name FROM decks") {
            if let id = row[0] as? Int64, let name = row[1] as? String {
                decks.append((id: id, name: name))
            }
        }

        return decks
    }

    func readNotes() throws -> [(id: Int64, fields: String, tags: String)] {
        var notes: [(id: Int64, fields: String, tags: String)] = []

        for row in try connection.prepare("SELECT id, flds, tags FROM notes") {
            if let id = row[0] as? Int64,
               let fields = row[1] as? String,
               let tags = row[2] as? String {
                notes.append((id: id, fields: fields, tags: tags))
            }
        }

        return notes
    }

    func readCards() throws -> [(id: Int64, noteId: Int64, deckId: Int64, ord: Int64)] {
        var cards: [(id: Int64, noteId: Int64, deckId: Int64, ord: Int64)] = []

        for row in try connection.prepare("SELECT id, nid, did, ord FROM cards") {
            if let id = row[0] as? Int64,
               let noteId = row[1] as? Int64,
               let deckId = row[2] as? Int64,
               let ord = row[3] as? Int64 {
                cards.append((id: id, noteId: noteId, deckId: deckId, ord: ord))
            }
        }

        return cards
    }

    func readMedia() throws -> [Int64: String] {
        var media: [Int64: String] = [:]

        for row in try connection.prepare("SELECT id, fname FROM media") {
            if let id = row[0] as? Int64, let fname = row[1] as? String {
                media[id] = fname
            }
        }

        return media
    }
}
