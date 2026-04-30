import Foundation
import SQLite
import ZIPFoundation

final class ApkgParser {
    enum ParserError: Error, LocalizedError {
        case invalidFile
        case extractionFailed
        case databaseNotFound
        case parseError(String)

        var errorDescription: String? {
            switch self {
            case .invalidFile: return "Invalid Anki file format"
            case .extractionFailed: return "Failed to extract archive"
            case .databaseNotFound: return "No deck data found in file"
            case .parseError(let msg): return "Parse error: \(msg)"
            }
        }
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

            // Try different database names
            let dbPath = findDatabase(in: tempDir)
            guard let finalDbPath = dbPath else {
                throw ParserError.databaseNotFound
            }

            progressHandler?(0.5)

            let decks = try parseDatabase(at: finalDbPath)
            progressHandler?(1.0)

            return decks
        } catch {
            throw error
        }
    }

    private func findDatabase(in directory: URL) -> URL? {
        let fileManager = FileManager.default

        // Try base.db first (standard format)
        let baseDb = directory.appendingPathComponent("base.db")
        if fileManager.fileExists(atPath: baseDb.path) {
            return baseDb
        }

        // Try collection.anki2 (older format)
        let anki2 = directory.appendingPathComponent("collection.anki2")
        if fileManager.fileExists(atPath: anki2.path) {
            return anki2
        }

        // Try to find any .anki2 or .db file recursively
        if let enumerator = fileManager.enumerator(at: directory, includingPropertiesForKeys: nil) {
            while let fileURL = enumerator.nextObject() as? URL {
                let ext = fileURL.pathExtension.lowercased()
                if ext == "anki2" || ext == "db" {
                    return fileURL
                }
            }
        }

        return nil
    }

    private func extractApkg(at sourceURL: URL, to destinationURL: URL) throws {
        do {
            try FileManager.default.createDirectory(at: destinationURL, withIntermediateDirectories: true)

            // Use the throwing initializer
            let archive = try Archive(url: sourceURL, accessMode: .read)

            for entry in archive {
                let entryPath = entry.path

                // Skip macOS metadata
                guard !entryPath.hasPrefix("__MACOSX/") else { continue }

                // Skip hidden files
                let fileName = (entryPath as NSString).lastPathComponent
                if fileName.hasPrefix(".") { continue }

                let destinationPath = destinationURL.appendingPathComponent(entryPath)
                let destinationDir = destinationPath.deletingLastPathComponent()

                if !FileManager.default.fileExists(atPath: destinationDir.path) {
                    try FileManager.default.createDirectory(at: destinationDir, withIntermediateDirectories: true)
                }

                // Check if it's a directory
                var isDirectory: ObjCBool = false
                if entry.type == .directory ||
                   (FileManager.default.fileExists(atPath: destinationPath.path) &&
                    FileManager.default.fileExists(atPath: destinationPath.path, isDirectory: &isDirectory) &&
                    isDirectory.boolValue) {
                    try FileManager.default.createDirectory(at: destinationPath, withIntermediateDirectories: true)
                } else {
                    _ = try archive.extract(entry, to: destinationPath)
                }
            }
        } catch {
            print("Extraction error: \(error)")
            throw ParserError.extractionFailed
        }
    }

    private func parseDatabase(at dbPath: URL) throws -> [ParsedDeck] {
        var db: Connection?
        do {
            db = try Connection(dbPath.path, readonly: true)
        } catch {
            throw ParserError.parseError("Cannot open database: \(error)")
        }

        guard let database = db else {
            throw ParserError.parseError("Database connection failed")
        }

        var decksById: [Int64: String] = [:]
        var decks: [ParsedDeck] = []

        // Read decks
        do {
            for row in try database.prepare("SELECT id, name FROM decks") {
                if let id = row[0] as? Int64,
                   let name = row[1] as? String {
                    decksById[id] = name
                }
            }
        } catch {
            print("Error reading decks table: \(error)")
        }

        // If no decks found in decks table, check col table
        if decksById.isEmpty {
            do {
                for row in try database.prepare("SELECT id, name FROM col") {
                    if let id = row[0] as? Int64,
                       let name = row[1] as? String {
                        decksById[id] = name
                    }
                }
            } catch {
                print("Error reading col table: \(error)")
            }
        }

        // Read notes and cards
        let notesQuery = """
            SELECT notes.id, notes.flds, notes.tags, cards.did
            FROM notes
            INNER JOIN cards ON cards.nid = notes.id
            WHERE cards.ord = 0
        """

        var cardsByDeck: [Int64: [(front: String, back: String, tags: String)]] = [:]

        do {
            for row in try database.prepare(notesQuery) {
                if let _ = row[0] as? Int64,
                   let flds = row[1] as? String,
                   let tags = row[2] as? String,
                   let did = row[3] as? Int64 {
                    let parts = flds.split(separator: "\u{1F}", maxSplits: 1)
                    let front = parts.first.map(String.init)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    let back = parts.count > 1 ? String(parts[1]).trimmingCharacters(in: .whitespacesAndNewlines) : ""

                    if !front.isEmpty || !back.isEmpty {
                        if cardsByDeck[did] == nil {
                            cardsByDeck[did] = []
                        }
                        cardsByDeck[did]?.append((front: front, back: back, tags: tags))
                    }
                }
            }
        } catch {
            print("Error reading notes/cards: \(error)")
        }

        // Match decks with cards
        for (deckId, deckName) in decksById {
            if let cards = cardsByDeck[deckId] {
                decks.append(ParsedDeck(name: deckName, cards: cards))
            }
        }

        // Fallback: if decks exist but no cards matched, create deck with all cards
        if decks.isEmpty && !decksById.isEmpty {
            for (deckId, deckName) in decksById {
                let allCardsQuery = "SELECT flds, tags FROM notes"
                var cards: [(front: String, back: String, tags: String)] = []

                do {
                    for row in try database.prepare(allCardsQuery) {
                        if let flds = row[0] as? String,
                           let tags = row[1] as? String {
                            let parts = flds.split(separator: "\u{1F}", maxSplits: 1)
                            let front = parts.first.map(String.init)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                            let back = parts.count > 1 ? String(parts[1]).trimmingCharacters(in: .whitespacesAndNewlines) : ""

                            if !front.isEmpty {
                                cards.append((front: front, back: back, tags: tags))
                            }
                        }
                    }
                } catch {
                    print("Error reading notes: \(error)")
                }

                if !cards.isEmpty {
                    decks.append(ParsedDeck(name: deckName, cards: cards))
                }
            }
        }

        // Final fallback: if still no decks, create a default deck
        if decks.isEmpty {
            let allCardsQuery = "SELECT flds, tags FROM notes"
            var cards: [(front: String, back: String, tags: String)] = []

            do {
                for row in try database.prepare(allCardsQuery) {
                    if let flds = row[0] as? String,
                       let tags = row[1] as? String {
                        let parts = flds.split(separator: "\u{1F}", maxSplits: 1)
                        let front = parts.first.map(String.init)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                        let back = parts.count > 1 ? String(parts[1]).trimmingCharacters(in: .whitespacesAndNewlines) : ""

                        if !front.isEmpty {
                            cards.append((front: front, back: back, tags: tags))
                        }
                    }
                }
            } catch {
                print("Error reading all notes: \(error)")
            }

            if !cards.isEmpty {
                decks.append(ParsedDeck(name: "Imported Deck", cards: cards))
            }
        }

        if decks.isEmpty {
            throw ParserError.databaseNotFound
        }

        return decks
    }
}
