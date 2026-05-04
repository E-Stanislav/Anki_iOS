import Foundation
import SQLite3

final class DatabaseService {
    static let shared = DatabaseService()

    private var db: OpaquePointer?
    private let queue = DispatchQueue(label: "com.ankiflow.database", qos: .userInitiated)
    private let schemaVersion = 3

    private init() {
        openDatabase()
        migrateSchemaIfNeeded()
        createTables()
    }

    deinit {
        sqlite3_close(db)
    }

    private func openDatabase() {
        let fileURL = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ankiflow.sqlite")

        if sqlite3_open(fileURL.path, &db) != SQLITE_OK {
            print("Error opening database")
        }
        execute("PRAGMA foreign_keys = ON")
    }

    private func migrateSchemaIfNeeded() {
        let currentVersion = getUserVersion()
        if currentVersion < schemaVersion {
            dropAllTablesAndRecreate()
            setUserVersion(schemaVersion)
        }
    }

    private func dropAllTablesAndRecreate() {
        sqlite3_close(db)
        let fileURL = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ankiflow.sqlite")
        try? FileManager.default.removeItem(at: fileURL)
        sqlite3_open(fileURL.path, &db)
        execute("PRAGMA foreign_keys = OFF")
    }

    private func getUserVersion() -> Int {
        let rows = query("PRAGMA user_version")
        return rows.first?["user_version"] as? Int ?? 0
    }

    private func setUserVersion(_ version: Int) {
        execute("PRAGMA user_version = \(version)")
    }

    private func dropAllTables() {
        execute("DROP TABLE IF EXISTS card_schedules")
        execute("DROP TABLE IF EXISTS cards")
        execute("DROP TABLE IF EXISTS notes")
        execute("DROP TABLE IF EXISTS decks")
        execute("DROP TABLE IF EXISTS notetypes")
        execute("DROP TABLE IF EXISTS revlog")
        execute("DROP TABLE IF EXISTS graves")
        execute("DROP TABLE IF EXISTS media_files")
        execute("DROP TABLE IF EXISTS import_jobs")
        execute("DROP TABLE IF EXISTS sync_state")
    }

    private func createTables() {
        let createDecks = """
        CREATE TABLE IF NOT EXISTS decks (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            description TEXT DEFAULT '',
            parent_id TEXT,
            created_at REAL NOT NULL,
            updated_at REAL NOT NULL,
            is_archived INTEGER DEFAULT 0,
            is_favorite INTEGER DEFAULT 0,
            new_cards_per_day INTEGER DEFAULT 20,
            review_cards_per_day INTEGER DEFAULT 200
        );
        """

        let createNotes = """
        CREATE TABLE IF NOT EXISTS notes (
            id TEXT PRIMARY KEY,
            deck_id TEXT NOT NULL,
            note_type_id TEXT NOT NULL,
            fields TEXT DEFAULT '{}',
            tags TEXT DEFAULT '[]',
            created_at REAL NOT NULL,
            updated_at REAL NOT NULL,
            FOREIGN KEY (deck_id) REFERENCES decks(id)
        );
        """

        let createCards = """
        CREATE TABLE IF NOT EXISTS cards (
            id TEXT PRIMARY KEY,
            note_id TEXT,
            deck_id TEXT NOT NULL,
            template_index INTEGER DEFAULT 0,
            front TEXT NOT NULL,
            back TEXT NOT NULL,
            created_at REAL NOT NULL,
            updated_at REAL NOT NULL,
            FOREIGN KEY (deck_id) REFERENCES decks(id)
        );
        """

        let createCardSchedules = """
        CREATE TABLE IF NOT EXISTS card_schedules (
            card_id TEXT PRIMARY KEY,
            status TEXT NOT NULL,
            due REAL NOT NULL,
            interval INTEGER DEFAULT 0,
            ease_factor REAL DEFAULT 2.5,
            reps INTEGER DEFAULT 0,
            lapses INTEGER DEFAULT 0,
            FOREIGN KEY (card_id) REFERENCES cards(id)
        );
        """

        let createNoteTypes = """
        CREATE TABLE IF NOT EXISTS note_types (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            fields TEXT DEFAULT '[]',
            templates TEXT DEFAULT '[]',
            created_at REAL NOT NULL
        );
        """

        let createReviewLogs = """
        CREATE TABLE IF NOT EXISTS review_logs (
            id TEXT PRIMARY KEY,
            card_id TEXT NOT NULL,
            reviewed_at REAL NOT NULL,
            rating INTEGER NOT NULL,
            interval INTEGER NOT NULL,
            ease_factor REAL NOT NULL,
            time_taken REAL NOT NULL,
            FOREIGN KEY (card_id) REFERENCES cards(id)
        );
        """

        let createMediaFiles = """
        CREATE TABLE IF NOT EXISTS media_files (
            id TEXT PRIMARY KEY,
            note_id TEXT NOT NULL,
            filename TEXT NOT NULL,
            mime_type TEXT DEFAULT 'application/octet-stream',
            size INTEGER DEFAULT 0,
            created_at REAL NOT NULL,
            FOREIGN KEY (note_id) REFERENCES notes(id)
        );
        """

        let createImportJobs = """
        CREATE TABLE IF NOT EXISTS import_jobs (
            id TEXT PRIMARY KEY,
            filename TEXT NOT NULL,
            started_at REAL NOT NULL,
            completed_at REAL,
            status TEXT NOT NULL,
            total_items INTEGER DEFAULT 0,
            processed_items INTEGER DEFAULT 0,
            added_cards INTEGER DEFAULT 0,
            updated_cards INTEGER DEFAULT 0,
            skipped_duplicates INTEGER DEFAULT 0,
            errors TEXT DEFAULT '[]'
        );
        """

        let createSyncState = """
        CREATE TABLE IF NOT EXISTS sync_state (
            id TEXT PRIMARY KEY,
            last_sync_at REAL,
            pending_changes INTEGER DEFAULT 0
        );
        """

        executeSQL(createDecks)
        executeSQL(createNotes)
        executeSQL(createCards)
        executeSQL(createCardSchedules)
        executeSQL(createNoteTypes)
        executeSQL(createReviewLogs)
        executeSQL(createMediaFiles)
        executeSQL(createImportJobs)
        executeSQL(createSyncState)
    }

    func executeSQL(_ sql: String) {
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) != SQLITE_DONE {
                print("Error executing SQL: \(sql)")
            }
        }
        sqlite3_finalize(statement)
    }

    func prepareStatement(_ sql: String) -> OpaquePointer? {
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            return statement
        }
        return nil
    }

    func execute(_ sql: String, parameters: [Any?] = []) -> Bool {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            print("DB ERROR: Failed to prepare statement: \(sql)")
            return false
        }
        defer { sqlite3_finalize(statement) }

        for (index, param) in parameters.enumerated() {
            let idx = Int32(index + 1)
            if let value = param as? String {
                let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
                value.withCString { cString in
                    sqlite3_bind_text(statement, idx, cString, -1, transient)
                }
            } else if let value = param as? Int {
                sqlite3_bind_int64(statement, idx, Int64(value))
            } else if let value = param as? Int64 {
                sqlite3_bind_int64(statement, idx, value)
            } else if let value = param as? Double {
                sqlite3_bind_double(statement, idx, value)
            } else if let value = param as? Bool {
                sqlite3_bind_int(statement, idx, value ? 1 : 0)
            } else if param == nil {
                sqlite3_bind_null(statement, idx)
            }
        }

        let result = sqlite3_step(statement)
        if result != SQLITE_DONE {
            let errMsg = String(cString: sqlite3_errmsg(db))
            print("DB ERROR: Step failed with result \(result) for SQL: \(sql), error: \(errMsg)")
        }
        return result == SQLITE_DONE
    }

    func query(_ sql: String, parameters: [Any?] = []) -> [[String: Any]] {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            print("DB ERROR: Failed to prepare query: \(sql)")
            return []
        }
        defer { sqlite3_finalize(statement) }

        for (index, param) in parameters.enumerated() {
            let idx = Int32(index + 1)
            if let value = param as? String {
                let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
                value.withCString { cString in
                    sqlite3_bind_text(statement, idx, cString, -1, transient)
                }
            } else if let value = param as? Int {
                sqlite3_bind_int64(statement, idx, Int64(value))
            } else if let value = param as? Int64 {
                sqlite3_bind_int64(statement, idx, value)
            } else if let value = param as? Double {
                sqlite3_bind_double(statement, idx, value)
            } else if let value = param as? Bool {
                sqlite3_bind_int(statement, idx, value ? 1 : 0)
            } else if param == nil {
                sqlite3_bind_null(statement, idx)
            }
        }

        var results: [[String: Any]] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            var row: [String: Any] = [:]
            let columnCount = sqlite3_column_count(statement)
            for i in 0..<columnCount {
                let name = String(cString: sqlite3_column_name(statement, i))
                let type = sqlite3_column_type(statement, i)
                switch type {
                case SQLITE_TEXT:
                    row[name] = String(cString: sqlite3_column_text(statement, i))
                case SQLITE_INTEGER:
                    row[name] = Int(sqlite3_column_int64(statement, i))
                case SQLITE_FLOAT:
                    row[name] = sqlite3_column_double(statement, i)
                case SQLITE_NULL:
                    row[name] = nil
                default:
                    row[name] = nil
                }
            }
            results.append(row)
        }
        if results.isEmpty {
        }
        return results
    }

    func beginTransaction() {
        execute("BEGIN TRANSACTION")
    }

    func commitTransaction() {
        execute("COMMIT")
    }

    func rollbackTransaction() {
        execute("ROLLBACK")
    }
}
