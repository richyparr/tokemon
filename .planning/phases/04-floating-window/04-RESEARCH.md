# Phase 4: Floating Window - Research

**Researched:** 2026-02-13
**Domain:** macOS floating windows, NSPanel, SwiftUI window management
**Confidence:** HIGH

## Summary

Implementing a floating window for Tokemon requires bridging SwiftUI views with AppKit's NSPanel for always-on-top behavior. While macOS 15 introduced native SwiftUI `.windowLevel(.floating)` support, Tokemon targets macOS 14+ where the NSPanel approach is required. The existing codebase already demonstrates this pattern in `SettingsWindowController.swift`, which uses `NSWindow` with `level = .floating`.

The recommended approach uses a custom `NSPanel` subclass hosted via `NSHostingController`, with `hidesOnDeactivate = false` for persistent visibility. Position persistence uses `NSWindow.setFrameAutosaveName()` which automatically stores/restores position in UserDefaults. The existing `UsageMonitor` service already provides all required usage data through its `@Observable` pattern.

**Primary recommendation:** Create a `FloatingWindowController` service using the same pattern as `SettingsWindowController`, but with an `NSPanel` subclass configured for always-visible floating behavior. Wire it to `UsageMonitor` via SwiftUI environment injection.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| AppKit NSPanel | macOS 14+ | Floating window base class | Built-in panel class with floating support |
| SwiftUI | macOS 14+ | View content rendering | Existing app framework |
| NSHostingController | macOS 14+ | Bridge SwiftUI to NSPanel | Apple's official SwiftUI-AppKit bridge |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| UserDefaults | Built-in | Position persistence | Frame autosave handles automatically |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| NSPanel subclass | SwiftUI Window + .windowLevel | Only works on macOS 15+, Tokemon targets 14+ |
| setFrameAutosaveName | Manual UserDefaults | Extra code, same result |
| Custom drag handling | isMovableByWindowBackground | Extra complexity, not needed with titlebar |

**Note:** No additional dependencies required. All functionality uses existing macOS frameworks.

## Architecture Patterns

### Recommended Project Structure
```
Tokemon/
├── Services/
│   ├── FloatingWindowController.swift  # NSPanel management (new)
│   └── SettingsWindowController.swift  # Existing pattern to follow
├── Views/
│   └── FloatingWindow/
│       └── FloatingWindowView.swift    # Compact usage display (new)
└── TokemonApp.swift                  # Wire up menu item + controller
```

### Pattern 1: NSPanel Subclass for Floating Window
**What:** Custom NSPanel class with floating panel configuration
**When to use:** Always-on-top windows that should remain visible across app deactivation
**Example:**
```swift
// Source: https://cindori.com/developer/floating-panel
class FloatingPanel: NSPanel {
    override init(contentRect: NSRect,
                  styleMask style: NSWindow.StyleMask,
                  backing backingStoreType: NSWindow.BackingStoreType,
                  defer flag: Bool) {
        super.init(contentRect: contentRect,
                   styleMask: [.titled, .closable, .fullSizeContentView, .nonactivatingPanel],
                   backing: backingStoreType,
                   defer: flag)

        // Core floating panel configuration
        self.isFloatingPanel = true
        self.level = .floating
        self.hidesOnDeactivate = false  // CRITICAL: Stay visible when app loses focus
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        // Visual configuration
        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true
        self.isMovableByWindowBackground = true
        self.isReleasedWhenClosed = false  // Keep in memory for reuse

        // Animation
        self.animationBehavior = .utilityWindow
    }

    // Allow becoming key (for any interactive elements)
    override var canBecomeKey: Bool { true }
}
```

### Pattern 2: Controller Service (Follow SettingsWindowController)
**What:** Singleton service managing window lifecycle
**When to use:** Single-instance utility windows
**Example:**
```swift
// Source: Tokemon/Services/SettingsWindowController.swift (existing pattern)
@MainActor
final class FloatingWindowController {
    static let shared = FloatingWindowController()

    private var panel: FloatingPanel?
    private var monitor: UsageMonitor?

    func setMonitor(_ monitor: UsageMonitor) {
        self.monitor = monitor
    }

    func showFloatingWindow() {
        if let existingPanel = panel {
            existingPanel.makeKeyAndOrderFront(nil)
            return
        }

        guard let monitor = monitor else { return }

        let contentView = FloatingWindowView()
            .environment(monitor)

        let hostingController = NSHostingController(rootView: contentView)

        let newPanel = FloatingPanel(
            contentRect: NSRect(x: 0, y: 0, width: 180, height: 80),
            styleMask: [.titled, .closable, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        newPanel.contentViewController = hostingController

        // Position persistence - stores in UserDefaults automatically
        newPanel.setFrameAutosaveName("TokemonFloatingWindow")

        // Position in corner if no saved position
        if newPanel.frame.origin == .zero {
            newPanel.setPosition(vertical: .top, horizontal: .right, padding: 20)
        }

        self.panel = newPanel
        newPanel.makeKeyAndOrderFront(nil)
    }

    func hideFloatingWindow() {
        panel?.close()
    }

    var isVisible: Bool {
        panel?.isVisible ?? false
    }
}
```

### Pattern 3: Window Position Helpers
**What:** Extension methods for corner positioning
**When to use:** Setting initial position, corner snapping
**Example:**
```swift
// Source: https://gist.github.com/ABridoux/b935c21c7ead92033d39b357fae6366b
extension NSWindow {
    struct Position {
        enum Horizontal { case left, center, right }
        enum Vertical { case top, center, bottom }

        var vertical: Vertical
        var horizontal: Horizontal
        var padding: CGFloat = 16
    }

    func setPosition(_ position: Position, in screen: NSScreen? = nil) {
        guard let visibleFrame = (screen ?? self.screen)?.visibleFrame else { return }

        let x: CGFloat
        switch position.horizontal {
        case .left: x = visibleFrame.minX + position.padding
        case .center: x = visibleFrame.midX - frame.width / 2
        case .right: x = visibleFrame.maxX - frame.width - position.padding
        }

        let y: CGFloat
        switch position.vertical {
        case .top: y = visibleFrame.maxY - frame.height - position.padding
        case .center: y = visibleFrame.midY - frame.height / 2
        case .bottom: y = visibleFrame.minY + position.padding
        }

        setFrameOrigin(CGPoint(x: x, y: y))
    }

    func setPosition(vertical: Position.Vertical, horizontal: Position.Horizontal, padding: CGFloat = 16) {
        setPosition(Position(vertical: vertical, horizontal: horizontal, padding: padding), in: nil)
    }
}
```

### Pattern 4: Compact SwiftUI View for Floating Window
**What:** Minimal usage display pulling from UsageMonitor
**When to use:** Floating window content
**Example:**
```swift
struct FloatingWindowView: View {
    @Environment(UsageMonitor.self) private var monitor

    var body: some View {
        VStack(spacing: 4) {
            // Big percentage number
            Text(monitor.currentUsage.menuBarText)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(usageColor)

            // Status indicator
            Text(statusText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(minWidth: 100, minHeight: 60)
    }

    private var usageColor: Color {
        let pct = monitor.currentUsage.primaryPercentage
        return Color(nsColor: GradientColors.color(for: pct))
    }

    private var statusText: String {
        if monitor.currentUsage.primaryPercentage >= 100 {
            return "Limit reached"
        } else if monitor.currentUsage.primaryPercentage >= 80 {
            return "Approaching limit"
        }
        return "5-hour usage"
    }
}
```

### Anti-Patterns to Avoid
- **Using WindowGroup for floating windows:** WindowGroup allows multiple instances and doesn't support always-on-top on macOS 14
- **Setting hidesOnDeactivate = true:** Default NSPanel behavior hides when app loses focus - explicitly set to false
- **Manual UserDefaults for position:** setFrameAutosaveName handles persistence automatically
- **Using .floating level on NSWindow (not NSPanel):** NSPanel has isFloatingPanel property for proper behavior

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Window position persistence | Manual UserDefaults storage | `setFrameAutosaveName()` | Handles serialization, screen changes, edge cases |
| Always-on-top behavior | Custom window level management | NSPanel with `isFloatingPanel = true` | Apple's built-in panel type |
| Corner positioning | Complex screen math | NSWindow Position extension | Reusable, handles menu bar/dock |
| SwiftUI in NSWindow | Custom view hosting | NSHostingController | Apple's official bridge |

**Key insight:** NSPanel exists specifically for floating utility windows. Don't fight AppKit's window management - use the panel infrastructure it provides.

## Common Pitfalls

### Pitfall 1: Window Disappears When Clicking Elsewhere
**What goes wrong:** Floating window vanishes when user clicks on other apps
**Why it happens:** NSPanel's default `hidesOnDeactivate = true`
**How to avoid:** Explicitly set `hidesOnDeactivate = false` in panel initialization
**Warning signs:** Window only visible while Tokemon is active

### Pitfall 2: Window Steals Focus From User's Work
**What goes wrong:** Clicking floating window activates Tokemon, interrupting workflow
**Why it happens:** Not using `.nonactivatingPanel` style mask
**How to avoid:** Include `.nonactivatingPanel` in styleMask, or use `becomesKeyOnlyIfNeeded = true`
**Warning signs:** Clicking panel changes which app is active

### Pitfall 3: Position Not Persisting
**What goes wrong:** Window appears at default position after restart
**Why it happens:** `setFrameAutosaveName()` must be called BEFORE the window is shown, or autosave name is empty
**How to avoid:** Call `setFrameAutosaveName()` immediately after creating the panel, before `makeKeyAndOrderFront`
**Warning signs:** Position saved in UserDefaults under wrong key or not at all

### Pitfall 4: App Quits When Floating Window Closed
**What goes wrong:** Closing floating window terminates the entire app
**Why it happens:** `applicationShouldTerminateAfterLastWindowClosed` returning true by default
**How to avoid:** Tokemon is already an LSUIElement app (no dock icon), so this shouldn't happen. But ensure `isReleasedWhenClosed = false` to keep panel in memory.
**Warning signs:** App terminates unexpectedly when closing floating window

### Pitfall 5: Observable Not Updating in NSPanel
**What goes wrong:** Usage data in floating window doesn't update live
**Why it happens:** SwiftUI environment not properly injected into NSHostingController
**How to avoid:** Pass monitor via `.environment(monitor)` to the root view before creating NSHostingController
**Warning signs:** Stale data, view doesn't react to UsageMonitor changes

## Code Examples

Verified patterns from official sources and existing Tokemon code:

### Opening Floating Window from Menu Bar Context Menu
```swift
// Source: Tokemon/TokemonApp.swift (existing context menu pattern)
// Update the disabled menu item in showContextMenu():
let floatingItem = NSMenuItem(
    title: "Open Floating Window",
    action: #selector(ContextMenuActions.openFloatingWindow),
    keyEquivalent: "f"
)
floatingItem.target = actions
menu.addItem(floatingItem)

// Add to ContextMenuActions:
@objc func openFloatingWindow() {
    FloatingWindowController.shared.showFloatingWindow()
}
```

### NSPanel Configuration (Full Setup)
```swift
// Source: https://developer.apple.com/documentation/appkit/nspanel
// Combined with https://cindori.com/developer/floating-panel

// Style mask for floating utility panel
let styleMask: NSWindow.StyleMask = [
    .titled,              // Has title bar (for close button)
    .closable,            // Can be closed
    .fullSizeContentView, // Content extends under title bar
    .nonactivatingPanel   // Doesn't activate app when clicked
]

// Panel configuration
panel.isFloatingPanel = true           // Panel-specific: floats above windows
panel.level = .floating                // Window level: above normal windows
panel.hidesOnDeactivate = false        // CRITICAL: Stay visible always
panel.collectionBehavior = [
    .canJoinAllSpaces,     // Visible on all Spaces/desktops
    .fullScreenAuxiliary   // Visible alongside fullscreen apps
]
panel.isMovableByWindowBackground = true  // Drag anywhere to move
panel.titleVisibility = .hidden           // Hide title text
panel.titlebarAppearsTransparent = true   // Blend title bar with content
panel.isReleasedWhenClosed = false        // Keep in memory for reopening
```

### Frame Autosave (Position Persistence)
```swift
// Source: https://developer.apple.com/documentation/appkit/nswindow/setframeautosavename(_:)

// Set autosave name - must be called before showing window
panel.setFrameAutosaveName("TokemonFloatingWindow")

// Position is automatically:
// - Saved to UserDefaults when window moves/resizes
// - Restored on next app launch
// - Key format: "NSWindow Frame TokemonFloatingWindow"
```

### Wiring UsageMonitor to Floating Window
```swift
// Source: Existing pattern in TokemonApp.swift

// In TokemonApp, where monitor is available:
FloatingWindowController.shared.setMonitor(monitor)

// The controller passes monitor to SwiftUI view:
let contentView = FloatingWindowView()
    .environment(monitor)
    .environment(alertManager)  // If needed for alert level colors

let hostingController = NSHostingController(rootView: contentView)
panel.contentViewController = hostingController
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Pure AppKit NSPanel | NSPanel + NSHostingController | macOS 10.15+ | SwiftUI views in AppKit windows |
| Manual position storage | setFrameAutosaveName | Always existed | Built-in persistence |
| Custom window drag | isMovableByWindowBackground | Always existed | One line vs. gesture handling |
| NSPanel + AppKit | SwiftUI .windowLevel(.floating) | macOS 15 | Pure SwiftUI (future migration) |

**Deprecated/outdated:**
- None for macOS 14 target. The NSPanel approach is current and stable.

**Future consideration (macOS 15+):**
```swift
// When dropping macOS 14 support, can migrate to pure SwiftUI:
WindowGroup(id: "floating-usage") {
    FloatingWindowView()
}
.windowLevel(.floating)
.windowStyle(.plain)
.windowResizability(.contentSize)
```

## Open Questions

1. **Corner Snapping UI**
   - What we know: macOS 15 added system-level window snapping to corners
   - What's unclear: Whether to implement custom snap-to-corner behavior or rely on manual positioning
   - Recommendation: Start simple - let user drag freely, position persists. Add snapping in Phase 5 if requested.

2. **Keyboard Shortcut for Floating Window**
   - What we know: Context menu has "Open Floating Window" item
   - What's unclear: Should there be a global hotkey (Cmd+Shift+C or similar)?
   - Recommendation: Start with menu-only access. Global hotkey would require `NSEvent.addGlobalMonitorForEvents` which is already used for right-click.

3. **Multiple Screens**
   - What we know: setFrameAutosaveName stores screen info with position
   - What's unclear: Behavior when a saved screen is no longer connected
   - Recommendation: Test this scenario. AppKit likely handles gracefully, but verify.

## Sources

### Primary (HIGH confidence)
- [NSPanel Apple Documentation](https://developer.apple.com/documentation/appkit/nspanel) - Panel class reference
- [NSWindow.Level Apple Documentation](https://developer.apple.com/documentation/appkit/nswindow/level-swift.struct) - Window level enumeration
- [becomesKeyOnlyIfNeeded Apple Documentation](https://developer.apple.com/documentation/appkit/nspanel/becomeskeyonlyifneeded) - Panel key behavior
- [setFrameAutosaveName Apple Documentation](https://developer.apple.com/documentation/appkit/nswindow/setframeautosavename(_:)?language=objc) - Position persistence
- Tokemon/Services/SettingsWindowController.swift - Existing pattern in codebase

### Secondary (MEDIUM confidence)
- [Cindori: Make a floating panel in SwiftUI for macOS](https://cindori.com/developer/floating-panel) - Complete FloatingPanel implementation
- [Pol Piella: Creating a floating window using SwiftUI in macOS 15](https://www.polpiella.dev/creating-a-floating-window-using-swiftui-in-macos-15) - Future SwiftUI approach
- [GitHub Gist: NSWindow Position Extension](https://gist.github.com/ABridoux/b935c21c7ead92033d39b357fae6366b) - Corner positioning helpers
- [Hacking with Swift: WindowDragGesture](https://www.hackingwithswift.com/quick-start/swiftui/how-to-lets-users-drag-anywhere-to-move-a-window) - macOS 15 drag gesture
- [Swift with Majid: Window management in SwiftUI](https://swiftwithmajid.com/2022/11/02/window-management-in-swiftui/) - Window/WindowGroup patterns

### Tertiary (LOW confidence)
- None - all critical patterns verified with primary or secondary sources

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - AppKit NSPanel is the established pattern, verified in Apple docs
- Architecture: HIGH - Follows existing SettingsWindowController pattern in codebase
- Pitfalls: HIGH - Common issues documented in multiple sources, verified behavior

**Research date:** 2026-02-13
**Valid until:** 2026-04-13 (stable AppKit APIs, 60 days)
