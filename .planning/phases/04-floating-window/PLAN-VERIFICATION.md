# Phase 4: Floating Window - Plan Verification

**Verified:** 2026-02-13
**Plans checked:** 04-01-PLAN.md, 04-02-PLAN.md
**Status:** PASSED

## Phase Goal

> User can keep a compact, always-visible usage display on screen while working

## Success Criteria Coverage

| Success Criterion | Plans | Tasks | Status |
|-------------------|-------|-------|--------|
| 1. User can open a compact floating window from the menu bar that stays on top of other windows | 04-01 T2, 04-02 T2 | FloatingPanel with `.floating` level + context menu item | COVERED |
| 2. User can position the floating window in any screen corner and it remembers its position between sessions | 04-01 T1, T2 | `setFrameAutosaveName` + NSWindow Position extension | COVERED |
| 3. Floating window shows minimal usage info (percentage, limit status) drawn from the same live data as the menu bar | 04-02 T1, T2 | FloatingWindowView with `@Environment(UsageMonitor.self)` | COVERED |
| 4. User can close the floating window without quitting the app | 04-01 T2, 04-02 T3 | LSUIElement app + `isReleasedWhenClosed = false` | COVERED |

## Dimension 1: Requirement Coverage

**Status:** PASSED

All 4 success criteria have covering tasks:

1. **Always-on-top floating window from menu bar:**
   - Plan 04-01 Task 2: Creates `FloatingPanel` with `level = .floating`, `isFloatingPanel = true`
   - Plan 04-02 Task 2: Adds "Show Floating Window" context menu item

2. **Position persistence:**
   - Plan 04-01 Task 1: NSWindow Position extension for corner positioning
   - Plan 04-01 Task 2: `setFrameAutosaveName("ClaudeMonFloatingWindow")` called before showing

3. **Live usage data display:**
   - Plan 04-02 Task 1: FloatingWindowView with `@Environment(UsageMonitor.self)`
   - Plan 04-02 Task 2: Wires view to controller with `.environment(monitor)`

4. **Close without quit:**
   - Plan 04-01 Task 2: `isReleasedWhenClosed = false`
   - App is LSUIElement (no dock icon, doesn't terminate on window close)
   - Plan 04-02 Task 3 explicitly verifies this behavior

## Dimension 2: Task Completeness

**Status:** PASSED

All tasks have required fields (Files, Action, Verify, Done).

| Plan | Task | Files | Action | Verify | Done |
|------|------|-------|--------|--------|------|
| 04-01 | 1 | Y | Y | Y | Y |
| 04-01 | 2 | Y | Y | Y | Y |
| 04-02 | 1 | Y | Y | Y | Y |
| 04-02 | 2 | Y | Y | Y | Y |
| 04-02 | 3 (checkpoint) | Y | Y | Y | Y |

Actions are specific with full code samples. Verify commands are runnable (`swift build`). Done criteria are measurable.

## Dimension 3: Dependency Correctness

**Status:** PASSED

```
04-01 (Wave 1) -- depends_on: []
  |
  v
04-02 (Wave 2) -- depends_on: ["04-01"]
```

- No circular dependencies
- All references valid (04-02 references 04-01, which exists)
- Wave assignments consistent with dependencies

## Dimension 4: Key Links Planned

**Status:** PASSED

| Link | From | To | Via | Task |
|------|------|----|-----|------|
| Panel lifecycle | FloatingWindowController | FloatingPanel | `panel` property | 04-01 T2 |
| Position persistence | FloatingWindowController | UserDefaults | `setFrameAutosaveName` | 04-01 T2 |
| Live data | FloatingWindowView | UsageMonitor | `@Environment(UsageMonitor.self)` | 04-02 T1 |
| Color gradient | FloatingWindowView | GradientColors | `GradientColors.color(for:)` | 04-02 T1 |
| Menu integration | ClaudeMonApp | FloatingWindowController | `toggleFloatingWindow()` | 04-02 T2 |
| Environment injection | FloatingWindowController | FloatingWindowView | `.environment(monitor)` | 04-02 T2 |

All critical wiring is explicitly planned in task actions.

## Dimension 5: Scope Sanity

**Status:** PASSED

| Plan | Tasks | Files | Assessment |
|------|-------|-------|------------|
| 04-01 | 2 | 2 | Optimal (foundation only) |
| 04-02 | 3 | 3 | Good (includes checkpoint) |

Both plans are within scope thresholds:
- Tasks per plan: 2-3 (target)
- Files per plan: 2-3 (well under 5-8 target)

## Dimension 6: Verification Derivation

**Status:** PASSED

### Plan 04-01 must_haves

```yaml
truths:
  - "FloatingPanel stays visible when user clicks on other apps"  # User-observable
  - "FloatingPanel does not steal focus from user's current work"  # User-observable
  - "FloatingWindowController can show and hide the panel"         # Functional
  - "Panel position is automatically saved and restored"           # User-observable
```

### Plan 04-02 must_haves

```yaml
truths:
  - "User can open floating window from right-click context menu"  # User-observable
  - "Floating window shows live usage percentage that updates"     # User-observable
  - "Floating window shows status text based on alert level"       # User-observable
  - "Floating window uses gradient colors matching menu bar"       # User-observable
  - "User can close floating window without quitting app"          # User-observable
  - "User can drag floating window and it remembers position"      # User-observable
```

All truths are user-observable (not implementation-focused). Good.

## Dimension 7: NSPanel Configuration Verification

**Status:** PASSED

The plans correctly implement all required NSPanel configurations per research:

| Configuration | Value | Research Requirement | Plan Location |
|---------------|-------|---------------------|---------------|
| `hidesOnDeactivate` | `false` | CRITICAL: Pitfall #1 | 04-01 T2 line 157 |
| `.nonactivatingPanel` | In styleMask | CRITICAL: Pitfall #2 | 04-01 T2 line 151 |
| `setFrameAutosaveName` | Before showing | CRITICAL: Pitfall #3 | 04-01 T2 line 227 |
| `isReleasedWhenClosed` | `false` | Reuse panel, not quit | 04-01 T2 line 164 |
| `isFloatingPanel` | `true` | Always-on-top | 04-01 T2 line 155 |
| `level` | `.floating` | Window level | 04-01 T2 line 156 |
| `collectionBehavior` | `[.canJoinAllSpaces, .fullScreenAuxiliary]` | Multi-space support | 04-01 T2 line 158 |
| `isMovableByWindowBackground` | `true` | Drag anywhere | 04-01 T2 line 163 |

All research pitfalls are explicitly addressed in the plan.

## Dimension 8: Existing Pattern Compliance

**Status:** PASSED

The plans correctly follow existing patterns in the codebase:

1. **SettingsWindowController pattern:** FloatingWindowController uses same singleton + setMonitor/setAlertManager pattern
2. **GradientColors usage:** Plan 04-02 Task 1 uses `GradientColors.color(for: pct)` matching existing menu bar
3. **UsageMonitor environment:** Plan 04-02 uses `@Environment(UsageMonitor.self)` matching PopoverContentView
4. **Context menu pattern:** Plan 04-02 Task 2 adds action to existing ContextMenuActions class

## Coverage Summary

| Requirement (FLOAT-*) | Plan | Task | Verified |
|----------------------|------|------|----------|
| FLOAT-01: Open from menu bar | 04-02 | T2 | Y |
| FLOAT-02: Stays on top | 04-01 | T2 | Y |
| FLOAT-03: Position anywhere | 04-01 | T1 | Y |
| FLOAT-04: Remember position | 04-01 | T2 | Y |
| FLOAT-05: Show usage info | 04-02 | T1 | Y |
| FLOAT-06: Close without quit | 04-01/02 | Multiple | Y |

## Plan Summary

| Plan | Tasks | Files | Wave | Status |
|------|-------|-------|------|--------|
| 04-01 | 2 | 2 | 1 | Valid |
| 04-02 | 3 | 3 | 2 | Valid |

## Issues Found

None. All verification dimensions passed.

## Verification Result

**PASSED**

Plans verified. The phase plans will achieve the goal when executed:
- All success criteria have covering tasks
- NSPanel configuration is correct for always-on-top, non-activating behavior
- Position persistence uses setFrameAutosaveName (called before showing)
- Live data wiring uses established UsageMonitor environment pattern
- Scope is appropriate (2-3 tasks per plan)
- Dependencies are valid (04-02 depends on 04-01)
- Checkpoint in 04-02 Task 3 provides human verification of complete experience

Run `/gsd:execute-phase 4` to proceed.
