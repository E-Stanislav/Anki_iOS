# iOS Analyze

Run static analysis to detect issues before runtime.

**Usage:** `/ios-analyze [scheme_name]`

**Parameters:**
- `scheme_name` — Optional. Scheme to analyze (default: AnkiFlow)

**Best Practices Applied:**
- Full static analysis pass
- Memory safety checks
- API availability validation

**Detects:**
- Unused variables and imports
- Memory leaks (ARC issues)
- Type safety problems
- API misuse

**Requirements:**
- Xcode static analyzer (built-in)