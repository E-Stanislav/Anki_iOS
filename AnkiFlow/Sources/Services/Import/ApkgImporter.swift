import Foundation
import Compression

final class ApkgImporter {
    private let db = DatabaseService.shared
    private let cardRepo = CardRepository()
    private let deckRepo = DeckRepository()

    func importFile(at url: URL, options: ImportOptions) async throws -> ImportResult {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)

        do {
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            try unzipFile(at: url, to: tempDir)

            let collectionDb = tempDir.appendingPathComponent("collection.anki21")
            guard FileManager.default.fileExists(atPath: collectionDb.path) else {
                throw ApkgImportError.invalidFormat
            }

            let mediaDir = tempDir.appendingPathComponent("media")
            let mediaFiles = try loadMediaFiles(from: mediaDir)

            let collection = try parseCollectionDb(at: collectionDb)
            let result = try processCollection(collection, mediaFiles: mediaFiles, options: options)

            try? FileManager.default.removeItem(at: tempDir)
            return result
        } catch {
            try? FileManager.default.removeItem(at: tempDir)
            throw error
        }
    }

    private func unzipFile(at source: URL, to destination: URL) throws {
        let fileManager = FileManager.default
        let zipPath = source.path

        guard let zipData = fileManager.contents(atPath: zipPath) else {
            throw ApkgImportError.invalidFormat
        }

        try fileManager.createDirectory(at: destination, withIntermediateDirectories: true)

        var offset = 0
        while offset < zipData.count {
            guard offset + 30 <= zipData.count else { break }

            let signature = zipData.subdata(in: offset..<offset+4)
            let sigBytes = [UInt8](signature)

            if sigBytes[0] == 0x50 && sigBytes[1] == 0x4b {
                let compressionMethod = UInt16(zipData[offset+8]) | (UInt16(zipData[offset+9]) << 8)

                let filenameLen = Int(UInt16(zipData[offset+26]) | (UInt16(zipData[offset+27]) << 8))
                let extraLen = Int(UInt16(zipData[offset+28]) | (UInt16(zipData[offset+29]) << 8))

                let headerEnd = offset + 30 + filenameLen + extraLen

                if headerEnd > zipData.count { break }

                let filenameData = zipData.subdata(in: offset+30..<offset+30+filenameLen)
                let filename = String(data: filenameData, encoding: .utf8) ?? ""

                let localHeaderOffset = offset
                offset = headerEnd

                let compressedSize = Int(UInt32(zipData[localHeaderOffset+18]) | (UInt32(zipData[localHeaderOffset+19]) << 8) | (UInt32(zipData[localHeaderOffset+20]) << 16) | (UInt32(zipData[localHeaderOffset+21]) << 24))
                let uncompressedSize = Int(UInt32(zipData[localHeaderOffset+22]) | (UInt32(zipData[localHeaderOffset+23]) << 8) | (UInt32(zipData[localHeaderOffset+24]) << 16) | (UInt32(zipData[localHeaderOffset+25]) << 24))

                if !filename.isEmpty && !filename.hasSuffix("/") && compressedSize > 0 && uncompressedSize > 0 {
                    let compressedData = zipData.subdata(in: offset..<offset+compressedSize)
                    let uncompressedData: Data

                    if compressionMethod == 0 {
                        uncompressedData = compressedData
                    } else {
                        uncompressedData = try decompress(data: compressedData, expectedSize: uncompressedSize)
                    }

                    let filePath = destination.appendingPathComponent(filename)
                    let fileDir = filePath.deletingLastPathComponent()

                    if !fileManager.fileExists(atPath: fileDir.path) {
                        try fileManager.createDirectory(at: fileDir, withIntermediateDirectories: true)
                    }

                    try uncompressedData.write(to: filePath)
                }

                offset += compressedSize
            } else {
                break
            }
        }
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
        guard FileManager.default.fileExists(atPath: dir.path) else { return [:] }

        var files: [String: Data] = [:]
        let contents = try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)

        for file in contents {
            let data = try Data(contentsOf: file)
            files[file.lastPathComponent] = data
        }

        return files
    }

    private func parseCollectionDb(at url: URL) throws -> AnkiCollection {
        return AnkiCollection()
    }

    private func processCollection(_ collection: AnkiCollection, mediaFiles: [String: Data], options: ImportOptions) throws -> ImportResult {
        return ImportResult(
            deckName: collection.deckName,
            totalCards: collection.cards.count,
            addedCards: collection.cards.count,
            updatedCards: 0,
            skippedDuplicates: 0,
            errors: []
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

enum ApkgImportError: Error {
    case invalidFormat
    case corruptedMedia
    case incompatibleNoteType
    case duplicateCard
    case rollback
}
