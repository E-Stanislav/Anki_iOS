import Foundation
import SQLite
import ZIPFoundation

final class ApkgParser {
    enum ParserError: Error {
        case invalidFile
        case extractionFailed
        case databaseNotFound
        case parseError(String)
    }

    struct ParsedDeck {
        var name: String
        var cards: [(front: String, back: String, tags: String)]
    }

    func parse(url: URL, progressHandler: ((Double) -> Void)? = nil) throws -> [ParsedDeck] {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)

        do {
            try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)

            defer {
                try? fileManager.removeItem(at: tempDir)
            }

            try extractApkg(at: url, to: tempDir)
            progressHandler?(0.3)

            let dbPath = tempDir.appendingPathComponent("base.db")
            guard fileManager.fileExists(atPath: dbPath.path) else {
                throw ParserError.databaseNotFound
            }

            progressHandler?(0.5)

            let decks = try parseDatabase(at: dbPath)
            progressHandler?(1.0)

            return decks
        } catch {
            throw error
        }
    }

    private func extractApkg(at sourceURL: URL, to destinationURL: URL) throws {
        guard let archive = Archive(url: sourceURL, accessMode: .read) else {
            throw ParserError.extractionFailed
        }

        for entry in archive {
            let entryPath = entry.path
            guard !entryPath.hasPrefix("__MACOSX/") else { continue }

            let destinationPath = destinationURL.appendingPathComponent(entryPath)
            let destinationDir = destinationPath.deletingLastPathComponent()

            if !FileManager.default.fileExists(atPath: destinationDir.path) {
                try FileManager.default.createDirectory(at: destinationDir, withIntermediateDirectories: true)
            }

            if entry.type == .directory {
                try FileManager.default.createDirectory(at: destinationPath, withIntermediateDirectories: true)
            } else {
                _ = try archive.extract(entry, to: destinationPath)
            }
        }
    }

    private func parseDatabase(at dbPath: URL) throws -> [ParsedDeck] {
        guard let db = try? Connection(dbPath.path, readonly: true) else {
            throw ParserError.parseError("Cannot open database")
        }

        var decksById: [Int64: String] = [:]
        var decks: [ParsedDeck] = []

        do {
            for row in try db.prepare("SELECT id, name FROM decks") {
                if let id = row[0] as? Int64,
                   let name = row[1] as? String {
                    decksById[id] = name
                }
            }
        } catch {
            print("Error reading decks table: \(error)")
        }

        let notesQuery = """
            SELECT notes.id, notes.flds, notes.tags, cards.did
            FROM notes
            INNER JOIN cards ON cards.nid = notes.id
            WHERE cards.ord = 0
        """

        var cardsByDeck: [Int64: [(front: String, back: String, tags: String)]] = [:]

        do {
            for row in try db.prepare(notesQuery) {
                if let _ = row[0] as? Int64,
                   let flds = row[1] as? String,
                   let tags = row[2] as? String,
                   let did = row[3] as? Int64 {
                    let parts = flds.split(separator: "\u{1F}", maxSplits: 1)
                    let front = parts.first.map(String.init) ?? ""
                    let back = parts.count > 1 ? String(parts[1]) : ""

                    if cardsByDeck[did] == nil {
                        cardsByDeck[did] = []
                    }
                    cardsByDeck[did]?.append((front: front, back: back, tags: tags))
                }
            }
        } catch {
            print("Error reading notes/cards: \(error)")
        }

        for (deckId, deckName) in decksById {
            if let cards = cardsByDeck[deckId] {
                decks.append(ParsedDeck(name: deckName, cards: cards))
            }
        }

        if decks.isEmpty && !decksById.isEmpty {
            for (deckId, deckName) in decksById {
                let allCardsQuery = "SELECT flds, tags FROM notes"
                var cards: [(front: String, back: String, tags: String)] = []

                do {
                    for row in try db.prepare(allCardsQuery) {
                        if let flds = row[0] as? String,
                           let tags = row[1] as? String {
                            let parts = flds.split(separator: "\u{1F}", maxSplits: 1)
                            let front = parts.first.map(String.init) ?? ""
                            let back = parts.count > 1 ? String(parts[1]) : ""
                            cards.append((front: front, back: back, tags: tags))
                        }
                    }
                } catch {
                    print("Error reading notes: \(error)")
                }

                decks.append(ParsedDeck(name: deckName, cards: cards))
            }
        }

        return decks
    }
}
