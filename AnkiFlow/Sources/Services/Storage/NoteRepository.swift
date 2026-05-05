import Foundation

protocol NoteRepositoryProtocol {
    func getAll(for deckId: UUID) -> [Note]
    func getById(_ id: UUID) -> Note?
    func save(_ note: Note)
    func delete(_ id: UUID)
}

final class NoteRepository: NoteRepositoryProtocol {
    private let db = DatabaseService.shared

    func getAll(for deckId: UUID) -> [Note] {
        let rows = db.query("SELECT * FROM notes WHERE deck_id = ?", parameters: [deckId.uuidString])
        return rows.compactMap { decodeNote(from: $0) }
    }

    func getById(_ id: UUID) -> Note? {
        let rows = db.query("SELECT * FROM notes WHERE id = ?", parameters: [id.uuidString])
        return rows.first.flatMap { decodeNote(from: $0) }
    }

    func save(_ note: Note) {
        let sql = """
        INSERT OR REPLACE INTO notes (id, deck_id, note_type_id, fields, tags, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?)
        """
        db.execute(sql, parameters: [
            note.id.uuidString,
            note.deckId.uuidString,
            note.noteTypeId.uuidString,
            encodeFields(note.fields),
            note.tags.joined(separator: " "),
            note.createdAt.timeIntervalSince1970,
            note.updatedAt.timeIntervalSince1970
        ])
    }

    func delete(_ id: UUID) {
        db.execute("DELETE FROM notes WHERE id = ?", parameters: [id.uuidString])
    }

    private func decodeNote(from row: [String: Any]) -> Note? {
        guard let idString = row["id"] as? String,
              let id = UUID(uuidString: idString),
              let deckIdString = row["deck_id"] as? String,
              let deckId = UUID(uuidString: deckIdString),
              let noteTypeIdString = row["note_type_id"] as? String,
              let noteTypeId = UUID(uuidString: noteTypeIdString),
              let createdAt = row["created_at"] as? Double,
              let updatedAt = row["updated_at"] as? Double else {
            return nil
        }

        let fieldsJson = row["fields"] as? String ?? "{}"
        let tagsString = row["tags"] as? String ?? ""

        return Note(
            id: id,
            deckId: deckId,
            noteTypeId: noteTypeId,
            fields: decodeFields(from: fieldsJson),
            tags: tagsString.isEmpty ? [] : tagsString.components(separatedBy: " "),
            createdAt: Date(timeIntervalSince1970: createdAt),
            updatedAt: Date(timeIntervalSince1970: updatedAt)
        )
    }

    private func encodeFields(_ fields: [String: String]) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: fields),
              let json = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return json
    }

    private func decodeFields(from json: String) -> [String: String] {
        guard let data = json.data(using: .utf8),
              let fields = try? JSONSerialization.jsonObject(with: data) as? [String: String] else {
            return [:]
        }
        return fields
    }
}