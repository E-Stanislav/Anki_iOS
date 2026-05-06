# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test Commands

```bash
# Build main app
xcodebuild -project AnkiFlow.xcodeproj -scheme AnkiFlow -configuration Debug -destination 'id=<DEVICE_ID>' build

# Run tests (requires development team signing)
xcodebuild -project AnkiFlow.xcodeproj -scheme AnkiFlowTests -configuration Debug -destination 'id=<DEVICE_ID>' test

# Lint
swiftlint lint
```

## Architecture

- **AppState** — global app state (theme, onboarding, userId) in App/
- **Repository pattern** — CardRepository, DeckRepository, NoteRepository, ReviewLogRepository in Services/Storage/
- **SM2Scheduler** — pure scheduling logic, implements SchedulerProtocol
- **DatabaseService** — SQLite3 singleton with WAL mode, foreign keys enabled

## Database Conventions

- Schema version tracked at `DatabaseService.swift:9` (`schemaVersion = 4`)
- Bump schemaVersion to force database recreation (no migration, wipes data)
- SQLite string binding: `unsafeBitCast(-1, to: sqlite3_destructor_type.self)` for transient destructor
- PRAGMA: foreign_keys=ON, journal_mode=WAL, synchronous=NORMAL

## .apkg Import Parsing

- Note type ID stored as JSON **dictionary key**, not as `id` field
- Template placeholders `{{FieldName}}` mapped to field values by name (case-sensitive)
- HTML stripped in `ApkgImporter.stripHTML()` after template rendering

## TDD Requirement (from AGENTS.md)

All new functionality MUST be developed using TDD:
1. Write a failing test first → 2. Implement minimum code to pass → 3. Refactor keeping tests green
4. All tests must pass before submitting

## SwiftLint

Located at `.swiftlint.yml`. Notable disabled rules: force_cast, force_try, nesting, file_length, function_body_length, cyclomatic_complexity.

## Key Limitations

- Schema version bump recreates database (no migration)
- .apkg import strips HTML (no media support in cards)
- Tests require development team signing (can't run from CLI without provisioning profile)
- SM2Scheduler lacks unit tests