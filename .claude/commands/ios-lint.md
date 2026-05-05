# iOS Lint

Run SwiftLint for code quality and style enforcement.

**Usage:** `/ios-lint [path]`

**Parameters:**
- `path` — Optional. Path to lint (default: AnkiFlow/Sources)

**Best Practices Applied:**
- Auto-correct formatting issues
- JSON reporter for CI integration
- SwiftLint auto-install if missing

**Rules Followed:**
- Swift official style guidelines
- Raywenderlich Swift style guide conventions
- Project-specific configuration via `.swiftlint.yml`

**Requirements:**
- SwiftLint installed (`brew install swiftlint`)