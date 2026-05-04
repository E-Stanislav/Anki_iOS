import Foundation

struct MediaFile: Identifiable, Codable, Hashable {
    let id: UUID
    var noteId: UUID
    var filename: String
    var mimeType: String
    var size: Int64
    var createdAt: Date

    init(
        id: UUID = UUID(),
        noteId: UUID,
        filename: String,
        mimeType: String = "application/octet-stream",
        size: Int64 = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.noteId = noteId
        self.filename = filename
        self.mimeType = mimeType
        self.size = size
        self.createdAt = createdAt
    }
}

struct ImportJob: Identifiable, Codable {
    let id: UUID
    let filename: String
    let startedAt: Date
    var completedAt: Date?
    var status: ImportStatus
    var totalItems: Int
    var processedItems: Int
    var addedCards: Int
    var updatedCards: Int
    var skippedDuplicates: Int
    var errors: [ImportError]

    init(
        id: UUID = UUID(),
        filename: String,
        startedAt: Date = Date(),
        completedAt: Date? = nil,
        status: ImportStatus = .pending,
        totalItems: Int = 0,
        processedItems: Int = 0,
        addedCards: Int = 0,
        updatedCards: Int = 0,
        skippedDuplicates: Int = 0,
        errors: [ImportError] = []
    ) {
        self.id = id
        self.filename = filename
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.status = status
        self.totalItems = totalItems
        self.processedItems = processedItems
        self.addedCards = addedCards
        self.updatedCards = updatedCards
        self.skippedDuplicates = skippedDuplicates
        self.errors = errors
    }
}

enum ImportStatus: String, Codable {
    case pending
    case parsing
    case importing
    case completed
    case failed
    case cancelled
}

struct ImportError: Identifiable, Codable {
    let id: UUID
    let cardId: UUID?
    let message: String
}
