import Foundation
import Compression
import SQLite3

final class ApkgImporter {
    private let db = DatabaseService.shared
    private let cardRepo = CardRepository()
    private let deckRepo = DeckRepository()

    func importFile(at url: URL, options: ImportOptions) async throws -> ImportResult {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)

        do {
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            try unzipFile(at: url, to: tempDir)

            guard let collectionDb = findCollectionDb(in: tempDir) else {
                throw ApkgImportError.invalidFormat
            }

            let mediaDir = tempDir.appendingPathComponent("media")
            let mediaFiles = try loadMediaFiles(from: mediaDir)

            let collectionCopy = copyToDocuments(collectionDb)
            defer {
                if let copy = collectionCopy {
                    try? FileManager.default.removeItem(at: copy)
                }
            }

            let collection = try parseCollectionDb(at: collectionCopy ?? collectionDb)
            let result = try processCollection(collection, mediaFiles: mediaFiles, options: options)

            try? FileManager.default.removeItem(at: tempDir)
            return result
        } catch {
            try? FileManager.default.removeItem(at: tempDir)
            throw error
        }
    }

    private func copyToDocuments(_ url: URL) -> URL? {
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let destURL = documentsDir.appendingPathComponent("import_\(UUID().uuidString).db")

        do {
            try FileManager.default.copyItem(at: url, to: destURL)
            return destURL
        } catch {
            print("DEBUG: Failed to copy collection to documents: \(error)")
            return nil
        }
    }

    private func findCollectionDb(in directory: URL) -> URL? {
        let possibleNames = ["collection.anki21", "collection.anki20", "collection.anki2", "collection21.anki", "collection"]
        for name in possibleNames {
            let path = directory.appendingPathComponent(name)
            if FileManager.default.fileExists(atPath: path.path) {
                print("DEBUG: Found collection at: \(name)")
                return path
            }
        }

        let contents = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        if let files = contents {
            for file in files {
                print("DEBUG: Found file in extracted dir: \(file.lastPathComponent)")
                if file.lastPathComponent.hasPrefix("collection") {
                    print("DEBUG: Using collection file: \(file.lastPathComponent)")
                    return file
                }
            }
        }

        return nil
    }

private func unzipFile(at source: URL, to destination: URL) throws {
        let fileManager = FileManager.default
        let zipPath = source.path

        guard let zipData = fileManager.contents(atPath: zipPath) else {
            throw ApkgImportError.invalidFormat
        }

        print("DEBUG: ZIP file size: \(zipData.count) bytes")

        try fileManager.createDirectory(at: destination, withIntermediateDirectories: true)

        var offset = 0
        var fileCount = 0
        while offset < zipData.count {
            guard offset + 30 <= zipData.count else { break }

            let sig0 = zipData[offset]
            let sig1 = zipData[offset + 1]

            if sig0 == 0x50 && sig1 == 0x4b {
                guard offset + 30 < zipData.count else { break }

                let compressionMethod = UInt16(zipData[offset+8]) | (UInt16(zipData[offset+9]) << 8)

                let filenameLen = Int(UInt16(zipData[offset+26]) | (UInt16(zipData[offset+27]) << 8))
                let extraLen = Int(UInt16(zipData[offset+28]) | (UInt16(zipData[offset+29]) << 8))

                let headerEnd = offset + 30 + filenameLen + extraLen

                if headerEnd > zipData.count { break }
                if offset + 30 + filenameLen > zipData.count { break }

                let filenameData = zipData.subdata(in: offset+30..<offset+30+filenameLen)
                let filename = String(data: filenameData, encoding: .utf8) ?? ""

                let localHeaderOffset = offset
                offset = headerEnd

                guard localHeaderOffset + 25 < zipData.count else { break }

                let compressedSize = Int(UInt32(zipData[localHeaderOffset+18]) | (UInt32(zipData[localHeaderOffset+19]) << 8) | (UInt32(zipData[localHeaderOffset+20]) << 16) | (UInt32(zipData[localHeaderOffset+21]) << 24))
                let uncompressedSize = Int(UInt32(zipData[localHeaderOffset+22]) | (UInt32(zipData[localHeaderOffset+23]) << 8) | (UInt32(zipData[localHeaderOffset+24]) << 16) | (UInt32(zipData[localHeaderOffset+25]) << 24))

                if !filename.isEmpty && !filename.hasSuffix("/") && compressedSize > 0 && uncompressedSize > 0 {
                    guard offset + compressedSize <= zipData.count else {
                        print("DEBUG: Skipping \(filename) - compressed size exceeds file bounds")
                        break
                    }

                    let compressedData = zipData.subdata(in: offset..<offset+compressedSize)
                    let uncompressedData: Data

                    if compressionMethod == 0 {
                        uncompressedData = compressedData
                    } else if compressionMethod == 8 {
                        uncompressedData = try decompress(data: compressedData, expectedSize: uncompressedSize)
                    } else {
                        print("DEBUG: Unknown compression method \(compressionMethod) for file \(filename)")
                        offset += compressedSize
                        continue
                    }

                    let filePath = destination.appendingPathComponent(filename)
                    let fileDir = filePath.deletingLastPathComponent()

                    if !fileManager.fileExists(atPath: fileDir.path) {
                        try fileManager.createDirectory(at: fileDir, withIntermediateDirectories: true)
                    }

                    try uncompressedData.write(to: filePath)
                    fileCount += 1
                    print("DEBUG: Extracted \(fileCount): \(filename), compressed: \(compressedSize), uncompressed: \(uncompressedSize)")
                }

                offset += compressedSize
            } else {
                print("DEBUG: Invalid signature at offset \(offset): \(sig0), \(sig1)")
                break
            }
        }
        print("DEBUG: Extracted \(fileCount) files total")
    }

    private func decompress(data: Data, expectedSize: Int) throws -> Data {
        let destinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: expectedSize)
        defer { destinationBuffer.deallocate() }

        let decompressedSize = data.withUnsafeBytes { (sourcePtr: UnsafeRawBufferPointer) -> Int in
            guard let baseAddress = sourcePtr.baseAddress else { return 0 }
            return compression_decode_buffer(
                destinationBuffer,
                expectedSize,
                baseAddress.assumingMemoryBound(to: UInt8.self),
                data.count,
                nil,
                COMPRESSION_ZLIB
            )
        }

        guard decompressedSize > 0 else {
            throw ApkgImportError.corruptedMedia
        }

        return Data(bytes: destinationBuffer, count: decompressedSize)
    }

    private func loadMediaFiles(from dir: URL) throws -> [String: Data] {
        guard FileManager.default.fileExists(atPath: dir.path) else {
            print("DEBUG: Media directory does not exist")
            return [:]
        }

        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: dir.path, isDirectory: &isDirectory) else {
            return [:]
        }

        if !isDirectory.boolValue {
            print("DEBUG: Media is a file, not a directory - skipping media load")
            return [:]
        }

        print("DEBUG: Loading media files from directory")

        var files: [String: Data] = [:]
        let contents = try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)

        for file in contents {
            print("DEBUG: Reading media file: \(file.lastPathComponent)")
            let data = try Data(contentsOf: file)
            files[file.lastPathComponent] = data
        }

        print("DEBUG: Loaded \(files.count) media files")
        return files
    }

    private func parseCollectionDb(at url: URL) throws -> AnkiCollection {
        var collection = AnkiCollection()

        print("DEBUG: parseCollectionDb starting for \(url.path)")

        guard FileManager.default.fileExists(atPath: url.path) else {
            print("DEBUG: File does not exist at path")
            throw ApkgImportError.invalidFormat
        }

        var db: OpaquePointer?
        guard sqlite3_open(url.path, &db) == SQLITE_OK else {
            if let db = db {
                sqlite3_close(db)
            }
            throw ApkgImportError.invalidFormat
        }
        defer { sqlite3_close(db) }

        let tables = getTableNames(from: db)
        print("DEBUG: Found tables: \(tables)")

        let hasColTable = tables.contains("col")
        print("DEBUG: Has col table: \(hasColTable)")

        let colData = getColData(from: db)
        collection.deckName = colData.deckName ?? "Imported Deck"
        let noteTypes = colData.noteTypes

        print("DEBUG: Got deck name: \(collection.deckName)")
        print("DEBUG: Got \(noteTypes.count) note types from col")

        collection.notes = getNotes(from: db)
        print("DEBUG: Got \(collection.notes.count) notes")

        collection.cards = getCards(from: db, noteTypes: noteTypes)
        print("DEBUG: Got \(collection.cards.count) cards")

        print("DEBUG: Parsed collection complete")

        return collection
    }

    private func getColData(from db: OpaquePointer?) -> (deckName: String?, noteTypes: [Int64: NoteTypeInfo]) {
        let sql = "SELECT decks, models FROM col LIMIT 1"
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            return (nil, [:])
        }
        defer { sqlite3_finalize(statement) }

        if sqlite3_step(statement) == SQLITE_ROW {
            let decksJson = sqlite3_column_text(statement, 0).map { String(cString: $0) } ?? "{}"
            let modelsJson = sqlite3_column_text(statement, 1).map { String(cString: $0) } ?? "{}"

            let deckName = parseDeckName(from: decksJson)
            let noteTypes = parseNoteTypes(from: modelsJson)

            return (deckName, noteTypes)
        }

        return (nil, [:])
    }

    private func parseDeckName(from json: String) -> String? {
        guard let data = json.data(using: .utf8),
              let decks = try? JSONSerialization.jsonObject(with: data) as? [String: [String: Any]] else {
            print("DEBUG: parseDeckName failed to parse JSON: \(json.prefix(100))")
            return nil
        }

        for (_, deck) in decks {
            if let name = deck["name"] as? String {
                return name
            }
        }
        return nil
    }

    private func parseNoteTypes(from json: String) -> [Int64: NoteTypeInfo] {
        guard let data = json.data(using: .utf8),
              let models = try? JSONSerialization.jsonObject(with: data) as? [String: [String: Any]] else {
            print("DEBUG: parseNoteTypes failed to parse JSON: \(json.prefix(200))")
            return [:]
        }

        var result: [Int64: NoteTypeInfo] = [:]

        for (key, model) in models {
            guard let idNum = Int64(key) else { continue }

            guard let name = model["name"] as? String else { continue }
            guard let flds = model["flds"] as? [[String: Any]] else { continue }
            guard let tmpls = model["tmpls"] as? [[String: Any]] else { continue }

            var fields: [String] = []
            for fld in flds {
                if let fieldName = fld["name"] as? String {
                    fields.append(fieldName)
                }
            }

            var templates: [(front: String, back: String)] = []
            for tmpl in tmpls {
                if let qfmt = tmpl["qfmt"] as? String,
                   let afmt = tmpl["afmt"] as? String {
                    templates.append((front: qfmt, back: afmt))
                }
            }

            result[idNum] = NoteTypeInfo(id: idNum, name: name, fields: fields, templates: templates)
        }

        return result
    }

    private func getTableNames(from db: OpaquePointer?) -> [String] {
        let sql = "SELECT name FROM sqlite_master WHERE type='table'"
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { return [] }
        defer { sqlite3_finalize(statement) }

        var tables: [String] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            if let cString = sqlite3_column_text(statement, 0) {
                tables.append(String(cString: cString))
            }
        }
        return tables
    }

    private func getDeckName(from db: OpaquePointer?, hasColTable: Bool) -> String? {
        var sql: String
        if hasColTable {
            sql = "SELECT name FROM decks WHERE id = (SELECT did FROM col LIMIT 1)"
        } else {
            sql = "SELECT name FROM decks LIMIT 1"
        }

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { return nil }
        defer { sqlite3_finalize(statement) }

        if sqlite3_step(statement) == SQLITE_ROW {
            if let cString = sqlite3_column_text(statement, 0) {
                return String(cString: cString)
            }
        }
        return nil
    }

    private func getNotes(from db: OpaquePointer?) -> [AnkiNote] {
        let sql = "SELECT id, guid, mid, flds, tags FROM notes"
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            print("DEBUG: Failed to prepare notes query")
            return []
        }
        defer { sqlite3_finalize(statement) }

        var notes: [AnkiNote] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            let id = sqlite3_column_int64(statement, 0)
            let guid = sqlite3_column_text(statement, 1).map { String(cString: $0) } ?? ""
            let mid = sqlite3_column_int64(statement, 2)
            let fieldsData = sqlite3_column_text(statement, 3).map { String(cString: $0) } ?? ""
            let tags = sqlite3_column_text(statement, 4).map { String(cString: $0) } ?? ""

            let fields = parseAnkiFields(fieldsData)
            let noteTags = parseAnkiTags(tags)

            notes.append(AnkiNote(id: id, guid: guid, noteTypeId: mid, fields: fields, tags: noteTags))
        }
        print("DEBUG: getNotes returned \(notes.count) notes")
        return notes
    }

    private func getCards(from db: OpaquePointer?, noteTypes: [Int64: NoteTypeInfo]) -> [AnkiCard] {
        let sql = "SELECT id, nid, did, ord FROM cards"

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            print("DEBUG: Failed to prepare cards query")
            return []
        }
        defer { sqlite3_finalize(statement) }

        let notesDict = getNotesDict(from: db)

        var cards: [AnkiCard] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            let id = sqlite3_column_int64(statement, 0)
            let nid = sqlite3_column_int64(statement, 1)
            let did = sqlite3_column_int64(statement, 2)
            let ord = Int(sqlite3_column_int64(statement, 3))

            guard let note = notesDict[nid] else {
                continue
            }

            guard let noteType = noteTypes[note.noteTypeId] else {
                continue
            }

            let fields = note.fields
            let front: String
            let back: String

            if ord < noteType.templates.count {
                front = renderTemplate(noteType.templates[ord].front, fields: fields, fieldNames: noteType.fields)
                back = renderTemplate(noteType.templates[ord].back, fields: fields, fieldNames: noteType.fields)
            } else {
                front = fields.first ?? ""
                back = fields.count > 1 ? fields[1] : ""
            }

            cards.append(AnkiCard(id: id, noteId: nid, deckId: did, templateIndex: ord, front: front, back: back))
        }
        print("DEBUG getCards: returned \(cards.count) cards")
        return cards
    }

    private func getNotesDict(from db: OpaquePointer?) -> [Int64: AnkiNote] {
        let sql = "SELECT id, guid, mid, flds, tags FROM notes"
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            return [:]
        }
        defer { sqlite3_finalize(statement) }

        var notes: [Int64: AnkiNote] = [:]
        while sqlite3_step(statement) == SQLITE_ROW {
            let id = sqlite3_column_int64(statement, 0)
            let guid = sqlite3_column_text(statement, 1).map { String(cString: $0) } ?? ""
            let mid = sqlite3_column_int64(statement, 2)
            let fieldsData = sqlite3_column_text(statement, 3).map { String(cString: $0) } ?? ""
            let tags = sqlite3_column_text(statement, 4).map { String(cString: $0) } ?? ""

            let fields = parseAnkiFields(fieldsData)
            let noteTags = parseAnkiTags(tags)

            notes[id] = AnkiNote(id: id, guid: guid, noteTypeId: mid, fields: fields, tags: noteTags)
        }
        return notes
    }

    private func renderTemplate(_ template: String, fields: [String], fieldNames: [String]) -> String {
        var result = template
        result = result.replacingOccurrences(of: "{{FrontSide}}", with: "")
        if let regex = try? NSRegularExpression(pattern: "\\{\\{([^}]+)\\}\\}", options: []) {
            let matches = regex.matches(in: result, options: [], range: NSRange(result.startIndex..., in: result))
            for match in matches.reversed() {
                if let fullRange = Range(match.range, in: result),
                   let fieldNameRange = Range(match.range(at: 1), in: result) {
                    let fieldName = String(result[fieldNameRange])
                    if let fieldIndex = fieldNames.firstIndex(of: fieldName),
                       fieldIndex < fields.count {
                        result.replaceSubrange(fullRange, with: fields[fieldIndex])
                    }
                }
            }
        }
        result = stripHTML(result)
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func stripHTML(_ html: String) -> String {
        var result = html
        result = result.replacingOccurrences(of: "<br\\s*/?>", with: "\n", options: .regularExpression)
        result = result.replacingOccurrences(of: "</p>", with: "\n\n", options: .caseInsensitive)
        result = result.replacingOccurrences(of: "</div>", with: "\n", options: .caseInsensitive)
        if let regex = try? NSRegularExpression(pattern: "<[^>]+>", options: []) {
            let range = NSRange(result.startIndex..., in: result)
            result = regex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: "")
        }
        result = result.replacingOccurrences(of: "&nbsp;", with: " ")
        result = result.replacingOccurrences(of: "&amp;", with: "&")
        result = result.replacingOccurrences(of: "&lt;", with: "<")
        result = result.replacingOccurrences(of: "&gt;", with: ">")
        result = result.replacingOccurrences(of: "&quot;", with: "\"")
        return result
    }

    private func getNoteTypes(from db: OpaquePointer?) -> [AnkiNoteType] {
        let sql = "SELECT id, name, flds, templates FROM notetypes"
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            print("DEBUG: Failed to prepare notetypes query")
            return []
        }
        defer { sqlite3_finalize(statement) }

        var noteTypes: [AnkiNoteType] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            let id = sqlite3_column_int64(statement, 0)
            let name = sqlite3_column_text(statement, 1).map { String(cString: $0) } ?? ""
            let flds = sqlite3_column_text(statement, 2).map { String(cString: $0) } ?? ""
            let tmpls = sqlite3_column_text(statement, 3).map { String(cString: $0) } ?? "[]"

            let fields = flds.components(separatedBy: "\u{1F}")
            let templates = parseAnkiTemplates(tmpls)

            noteTypes.append(AnkiNoteType(id: id, name: name, fields: fields, templates: templates))
        }
        print("DEBUG: getNoteTypes returned \(noteTypes.count) note types")
        return noteTypes
    }

    private func parseAnkiFields(_ data: String) -> [String] {
        return data.components(separatedBy: "\u{1F}")
    }

    private func parseAnkiTags(_ data: String) -> [String] {
        guard !data.isEmpty else { return [] }
        return data.components(separatedBy: " ").filter { !$0.isEmpty }
    }

    private func parseAnkiTemplates(_ data: String) -> [(front: String, back: String)] {
        // Anki templates are JSON: [{"name": "...", "qfmt": "...", "afmt": "..."}]
        guard let jsonData = data.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]] else {
            return []
        }

        return json.compactMap { template -> (front: String, back: String)? in
            guard let qfmt = template["qfmt"] as? String,
                  let afmt = template["afmt"] as? String else { return nil }
            return (front: stripAnkiTemplate(qfmt), back: stripAnkiTemplate(afmt))
        }
    }

    private func stripAnkiTemplate(_ template: String) -> String {
        var result = template
        result = result.replacingOccurrences(of: "{{FrontSide}}", with: "")
        if let regex = try? NSRegularExpression(pattern: "\\{\\{[^}]+\\}\\}", options: []) {
            let range = NSRange(result.startIndex..., in: result)
            result = regex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: "")
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func processCollection(_ collection: AnkiCollection, mediaFiles: [String: Data], options: ImportOptions) throws -> ImportResult {
        var addedCards = 0
        var skippedDuplicates = 0
        var errors: [String] = []

        let deck = Deck(name: collection.deckName, description: "Imported from Anki")
        deckRepo.save(deck)

        for ankiCard in collection.cards {
            let card = Card(
                noteId: UUID(),
                deckId: deck.id,
                front: ankiCard.front,
                back: ankiCard.back
            )
            cardRepo.save(card)

            let schedule = CardSchedule(cardId: card.id)
            cardRepo.saveSchedule(schedule)
            addedCards += 1
        }

        return ImportResult(
            deckName: collection.deckName,
            totalCards: collection.cards.count,
            addedCards: addedCards,
            updatedCards: 0,
            skippedDuplicates: skippedDuplicates,
            errors: errors
        )
    }
}

struct ImportOptions {
    var importProgress: Bool = false
    var updateExisting: Bool = true
    var mergeStrategy: MergeStrategy = .update

    enum MergeStrategy {
        case update
        case keepLocal
        case merge
    }
}

struct ImportResult {
    let deckName: String
    let totalCards: Int
    let addedCards: Int
    let updatedCards: Int
    let skippedDuplicates: Int
    let errors: [String]
}

struct AnkiCollection {
    var deckName: String = ""
    var cards: [AnkiCard] = []
    var notes: [AnkiNote] = []
    var noteTypes: [AnkiNoteType] = []
}

struct AnkiCard {
    let id: Int64
    let noteId: Int64
    let deckId: Int64
    let templateIndex: Int
    let front: String
    let back: String
}

struct AnkiNote {
    let id: Int64
    let guid: String
    let noteTypeId: Int64
    let fields: [String]
    let tags: [String]
}

struct AnkiNoteType {
    let id: Int64
    let name: String
    let fields: [String]
    let templates: [(front: String, back: String)]
}

struct NoteTypeInfo {
    let id: Int64
    let name: String
    let fields: [String]
    let templates: [(front: String, back: String)]
}

enum ApkgImportError: Error {
    case invalidFormat
    case corruptedMedia
    case incompatibleNoteType
    case duplicateCard
    case rollback
}
