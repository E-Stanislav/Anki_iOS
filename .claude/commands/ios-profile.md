# iOS Profile

Build app and launch Instruments for performance profiling.

**Usage:** `/ios-profile [scheme_name]`

**Parameters:**
- `scheme_name` — Optional. Scheme to profile (default: AnkiFlow)

**Available Templates:**
- **Allocations** — Track memory allocations
- **Leaks** — Detect memory leaks
- **Time Profiler** — Analyze CPU usage
- **Allocations** — Memory debug

**Best Practices:**
- Profile on actual device when possible
- Use Time Profiler during realistic usage
- Check Allocations for memory issues

**Requirements:**
- Xcode Instruments (built-in)