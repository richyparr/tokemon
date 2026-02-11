# Phase 1: Foundation & Core Monitoring - Context

**Gathered:** 2026-02-11
**Status:** Ready for planning

<domain>
## Phase Boundary

Native macOS menu bar app with popover showing Claude usage from OAuth endpoint (primary) and Claude Code JSONL (fallback). User can see current usage, limits remaining, and manage data source settings. This phase delivers the core monitoring loop — alerts, trends, floating window, and theming are separate phases.

</domain>

<decisions>
## Implementation Decisions

### Menu Bar Icon
- Default display: text percentage (e.g., "45%") in menu bar
- User can change to: stylized Claude logo or abstract gauge/meter in settings
- Color: subtle gradient based on usage level — not harsh traffic light colors
- Click behavior: opens popover
- Right-click behavior: shows quick menu with: Refresh now, Open floating window, Settings, Quit

### Popover Layout
- Top section: big usage percentage number (dominant, first thing user sees)
- Below percentage: limit remaining, reset time, messages/tokens breakdown
- Density: comfortable — breathing room, easy to read (not cramped or overly spacious)
- Settings access: gear icon in popover footer opens settings section/sheet
- No source indicator needed in main view

### Data Refresh & Loading
- Refresh interval: user configurable in settings
- Default interval: 1 minute
- Loading indication: subtle spinner during refresh + "last updated" timestamp always visible
- Background refresh: continues even when popover is closed (menu bar icon stays current)

### Error States
- OAuth failure: notify user once ("Switching to backup data source"), then silently fallback to JSONL
- Both sources fail: show error indicator in menu bar (obvious but not alarming)
- Recovery strategy: auto-retry 3 times at refresh interval spacing, then require manual retry button
- Error messages: user-friendly primary message + "Show details" expander for technical info

### Claude's Discretion
- Exact spinner design and placement
- Typography and spacing within constraints
- Animation and transitions
- "Show details" technical info formatting

</decisions>

<specifics>
## Specific Ideas

- Menu bar percentage should feel unobtrusive — subtle gradient colors, not screaming red/yellow/green
- Popover should be "comfortable" density — like a well-designed utility app, not cramped or wasteful
- Error recovery is smart but not aggressive — 3 retries at normal pace, then stop bothering

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 01-foundation-core-monitoring*
*Context gathered: 2026-02-11*
