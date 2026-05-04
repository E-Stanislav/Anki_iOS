import Foundation

struct Note: Identifiable, Codable, Hashable {
    let id: UUID
    var deckId: UUID
    var noteTypeId: UUID
    var fields: [String: String]
    var tags: [String]
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        deckId: UUID,
        noteTypeId: UUID,
        fields: [String: String] = [:],
        tags: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.deckId = deckId
        self.noteTypeId = noteTypeId
        self.fields = fields
        self.tags = tags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct NoteType: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var fields: [Field]
    var templates: [Template]
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        fields: [Field] = [],
        templates: [Template] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.fields = fields
        self.templates = templates
        self.createdAt = createdAt
    }
}

struct Field: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var order: Int

    init(id: UUID = UUID(), name: String, order: Int) {
        self.id = id
        self.name = name
        self.order = order
    }
}

struct Template: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var front: String
    var back: String
    var order: Int

    init(id: UUID = UUID(), name: String, front: String, back: String, order: Int) {
        self.id = id
        self.name = name
        self.front = front
        self.back = back
        self.order = order
    }
}
