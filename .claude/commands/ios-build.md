# iOS Build

Build the AnkiFlow iOS application with best practices.

**Usage:** `/ios-build [scheme_name]`

**Parameters:**
- `scheme_name` — Optional. Target scheme (default: AnkiFlow)

**Best Practices Applied:**
- Parallel target building using all CPU cores
- Code signing disabled for CI/local builds
- Clean output for easier debugging

**Requirements:**
- XcodeGen must generate the project first
- Valid simulator destination ID required