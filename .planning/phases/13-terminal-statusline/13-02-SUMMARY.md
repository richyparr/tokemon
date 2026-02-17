---
phase: 13-terminal-statusline
plan: 02
completed: 2026-02-17T08:45:00Z
status: complete
duration: 3min
---

# Plan 13-02 Summary: Settings UI and App Integration

## What Was Built

Wired the StatuslineExporter into the app refresh cycle and created the full Settings UI:

1. **StatuslineSettings.swift** - Full configuration UI:
   - Enable toggle with explanation caption
   - Field selection (session %, weekly %, reset timer)
   - Format options (separator, prefix, suffix, ANSI colors)
   - Live preview with current format settings
   - Shell integration section with:
     - Source command display
     - "Copy Install Command" button with "Copied!" feedback
     - "Add to ~/.zshrc" one-click install button
     - Auto-detects shell from $SHELL env
   - Advanced section noting JSON availability

2. **SettingsView.swift** - Added Terminal tab:
   - Placed after Appearance, before Alerts
   - Uses "terminal" SF Symbol (macOS 14+)

3. **UsageMonitor.swift** - Added statusline callback:
   - `onStatuslineExport` callback property
   - Called in all three refresh paths:
     - OAuth success
     - JSONL fallback success
     - Both failed (for cleanup)

4. **TokemonApp.swift** - Wired StatuslineExporter:
   - `@State private var statuslineExporter`
   - `monitor.onStatuslineExport` wired to `statuslineExporter.export()`
   - Config change notification observer for live updates
   - `installShellHelper()` called at app launch

5. **Package.swift** - Added shell script resource:
   - `.copy("Resources/tokemon-statusline.sh")` in resources array

## Verification

- [x] `swift build` succeeds with all changes
- [x] StatuslineSettings compiles with all sections
- [x] SettingsView includes Terminal tab
- [x] UsageMonitor has onStatuslineExport callback
- [x] Package.swift includes shell script resource

## Files Changed

| File | Action | Lines |
|------|--------|-------|
| `Tokemon/Views/Settings/StatuslineSettings.swift` | Created | 198 |
| `Tokemon/Views/Settings/SettingsView.swift` | Modified | +5 |
| `Tokemon/Services/UsageMonitor.swift` | Modified | +7 |
| `Tokemon/TokemonApp.swift` | Modified | +22 |
| `Package.swift` | Modified | +1 |

## End-to-End Pipeline

Complete data flow now wired:
1. App refreshes (timer tick or manual)
2. UsageMonitor calls `onStatuslineExport` callback
3. StatuslineExporter writes to `~/.tokemon/statusline`, `statusline-color`, `status.json`
4. User sources `~/.tokemon/tokemon-statusline.sh` in their shell
5. Shell prompt calls `tokemon_statusline` function
6. Function reads cache file and displays formatted usage

## Requirements Satisfied

- **TERM-01**: User can display usage in terminal via `tokemon_statusline()` function
- **TERM-02**: Shows session %, weekly %, reset timer (all configurable)
- **TERM-03**: User can customize format in Settings (fields, separator, colors, prefix/suffix)
- **TERM-04**: One-click install via "Add to ~/.zshrc" button + auto-installed shell script
