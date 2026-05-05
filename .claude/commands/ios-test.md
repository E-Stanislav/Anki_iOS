# iOS Test

Run unit tests with TDD best practices (mandatory per AGENTS.md).

**Usage:** `/ios-test [scheme_name]`

**Parameters:**
- `scheme_name` — Optional. Test scheme (default: AnkiFlowTests)

**Best Practices Applied:**
- Parallel test execution
- Code coverage enabled
- All tests must pass before committing

**TDD Workflow:**
1. Write failing test first
2. Implement minimum code
3. Refactor keeping tests green

**Requirements:**
- Test scheme must exist in project