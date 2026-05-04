# AGENTS.md - AnkiFlow iOS App

## Critical Rules

### TDD (Test-Driven Development) - MANDATORY
- **ANY new functionality MUST be developed using TDD**
- Step 1: Write a failing test that describes the expected behavior
- Step 2: Implement the minimum code to make the test pass
- Step 3: Refactor if needed, keeping tests green
- **All tests must pass before submitting changes**
- Run tests after every significant change

## Build & Test Commands

```bash
# Run all tests
xcodebuild -project AnkiFlow.xcodeproj -scheme AnkiFlowTests -configuration Debug -destination 'id=110BB9C6-3D24-425D-8E2C-1D8066C911A3' test

# Build main app
xcodebuild -project AnkiFlow.xcodeproj -scheme AnkiFlow -configuration Debug -destination 'id=110BB9C6-3D24-425D-8E2C-1D8066C911A3' build
```

## Project Structure

- **AnkiFlow/Sources/** - Main app source
  - **App/** - App entry point, SceneDelegate
  - **Models/** - Data models (Card, Deck, Note, ReviewLog, etc.)
  - **Views/** - SwiftUI views organized by feature (Home, Deck, Card, Review, Stats, Settings, Onboarding)
  - **ViewModels/** - ViewModels for state management
  - **Services/** - Business logic
    - **Storage/** - DatabaseService, CardRepository, DeckRepository (SQLite)
    - **Import/** - ApkgImporter for .apkg files
    - **Scheduler/** - SM2Scheduler for spaced repetition
  - **Extensions/**, **Utilities/**, **Resources/** - Misc
- **AnkiFlowTests/** - Unit tests

## Key Conventions

### Database Schema Changes
- Schema version is tracked in `DatabaseService.swift` (line 9: `schemaVersion`)
- Bump schema version to force database recreation during migration
- SQLite string binding uses `unsafeBitCast(-1, to: sqlite3_destructor_type.self)` for transient destructor

### .apkg Import Parsing (Important)
- Note type ID is stored as JSON **dictionary key**, not as `id` field inside model
- Template placeholders `{{FieldName}}` must be mapped to corresponding field values by name
- HTML tags must be stripped after template rendering using `stripHTML()` function

### Swipe-to-Delete
- Implemented on DeckRowView and CardRowView
- Uses confirmation alerts before deletion
- Cascade delete handled in DeckRepository

## iOS Version & Dependencies

- **iOS 16.0+** minimum deployment target
- **SwiftUI** for UI
- **SQLite3** (native) for local storage
- **No external dependencies** for zip/unzip - uses native Compression framework

## Common Issues & Fixes

### Cards not inserting despite FK-valid deck_id
- Check if database schema matches code - old constraints may persist
- **Fix**: Bump `schemaVersion` in DatabaseService.swift to trigger `dropAllTablesAndRecreate()`

### .apkg import returns 0 cards
- Verify `parseNoteTypes` uses JSON dictionary key as ID
- Verify `renderTemplate` correctly maps `{{Placeholder}}` to field by name

### Card content shows raw HTML
- HTML stripping is done in `ApkgImporter.stripHTML()`
- Template rendering calls `stripHTML()` before returning

## Test File Location
- Tests: `AnkiFlowTests/AnkiFlowTests.swift`
- Test data: `English A2 - Everyday + IT.apkg` (225 cards)
