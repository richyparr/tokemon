# Phase 5: Theming & Design Polish - Research

**Researched:** 2026-02-14
**Domain:** SwiftUI theming, macOS appearance system, design polish
**Confidence:** HIGH

## Summary

This phase implements a multi-theme system for a macOS menu bar app built with SwiftUI and Swift Package Manager. The app has two primary display surfaces (menu bar popover and floating window) that must be themed consistently. The codebase already uses `GradientColors` for usage-based color mapping and stores preferences via `@AppStorage`/`UserDefaults`.

SwiftUI provides robust theming support through the `@Environment(\.colorScheme)` environment value and `preferredColorScheme(_:)` modifier. For custom multi-theme systems, the recommended pattern is an `@Observable` theme manager that propagates theme colors through environment values. Since this is an SPM project without Xcode asset catalogs, colors should be defined programmatically using hex extensions or `NSColor`/`Color` initializers with light/dark variants.

The three themes map to different approaches: **Native macOS** follows the system appearance (no override), **Minimal Dark** forces `.dark` color scheme with muted tones, and **Anthropic-inspired** uses warm colors based on Anthropic's brand palette (#C15F3C primary, #faf9f5 light, #141413 dark).

**Primary recommendation:** Build a `ThemeManager` observable class with a `Theme` enum, propagate via `.environment()`, and create a `ThemeColors` struct that resolves semantic colors based on active theme and system color scheme.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI | macOS 14+ | UI framework | Native, already in use |
| Swift Charts | macOS 14+ | Chart theming | Native, already in use |
| AppKit (NSColor) | macOS 14+ | Color resolution, system colors | Required for menu bar text coloring |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| None required | - | - | Built-in SwiftUI capabilities sufficient |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Programmatic colors | Asset Catalog | SPM doesn't support asset catalogs in typical setups without extra bundling; programmatic is simpler |
| Observable ThemeManager | Environment-only pattern | Manager allows theme switching from anywhere in app, not just views |
| Enum-based Theme | Struct-based Theme | Enum simpler for 3 fixed themes; struct more flexible for dynamic themes |

**Installation:**
No additional dependencies required - uses native SwiftUI and AppKit.

## Architecture Patterns

### Recommended Project Structure
```
ClaudeMon/
├── Utilities/
│   ├── Theme.swift           # Theme enum, ThemeColors, ThemeManager
│   ├── GradientColors.swift  # (existing) - update to be theme-aware
│   └── Extensions.swift      # Color+Hex extension
├── Views/
│   ├── MenuBar/
│   │   ├── PopoverContentView.swift  # Add .environment(themeManager)
│   │   └── ...
│   ├── FloatingWindow/
│   │   └── FloatingWindowView.swift  # Add .environment(themeManager)
│   └── Settings/
│       └── AppearanceSettings.swift  # Theme picker UI
└── ClaudeMonApp.swift        # Root theme manager injection
```

### Pattern 1: Observable Theme Manager
**What:** Central theme state management using `@Observable` macro
**When to use:** Multi-surface apps where theme must be consistent
**Example:**
```swift
// Source: SwiftUI @Observable pattern + community best practices
import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case native = "Native macOS"
    case minimalDark = "Minimal Dark"
    case anthropic = "Anthropic"

    var id: String { rawValue }
}

@Observable
@MainActor
final class ThemeManager {
    var selectedTheme: AppTheme = .native {
        didSet {
            UserDefaults.standard.set(selectedTheme.rawValue, forKey: "selectedTheme")
        }
    }

    init() {
        if let stored = UserDefaults.standard.string(forKey: "selectedTheme"),
           let theme = AppTheme(rawValue: stored) {
            self.selectedTheme = theme
        }
    }
}
```

### Pattern 2: Theme-Aware Color Resolution
**What:** Semantic colors that resolve differently based on theme and system appearance
**When to use:** Any color that varies between themes
**Example:**
```swift
// Source: SwiftUI colorScheme environment pattern
struct ThemeColors {
    let theme: AppTheme
    let colorScheme: ColorScheme

    var primaryBackground: Color {
        switch theme {
        case .native:
            return Color(nsColor: .windowBackgroundColor)
        case .minimalDark:
            return Color(hex: 0x1a1a1a)
        case .anthropic:
            return colorScheme == .dark
                ? Color(hex: 0x141413)
                : Color(hex: 0xfaf9f5)
        }
    }

    var primaryAccent: Color {
        switch theme {
        case .native:
            return .accentColor
        case .minimalDark:
            return Color(hex: 0x4a9eff)
        case .anthropic:
            return Color(hex: 0xc15f3c) // Anthropic "Crail" orange
        }
    }
}
```

### Pattern 3: Color Scheme Override for Themes
**What:** Force dark mode for specific themes using `preferredColorScheme(_:)`
**When to use:** Themes that require specific light/dark appearance
**Example:**
```swift
// Source: Apple Developer Documentation - preferredColorScheme
struct ThemedView<Content: View>: View {
    @Environment(ThemeManager.self) var themeManager
    let content: Content

    var body: some View {
        content
            .preferredColorScheme(colorSchemeOverride)
    }

    private var colorSchemeOverride: ColorScheme? {
        switch themeManager.selectedTheme {
        case .native: return nil  // Follow system
        case .minimalDark: return .dark
        case .anthropic: return nil  // Theme handles its own colors
        }
    }
}
```

### Anti-Patterns to Avoid
- **Hard-coding colors in views:** Use semantic color properties from ThemeColors instead of inline hex values
- **Separate theme code per view:** Centralize in ThemeManager/ThemeColors, not scattered conditionals
- **Ignoring system color scheme for custom themes:** Even custom themes should respect accessibility/dynamic type
- **Forgetting floating window:** Theme changes must propagate to FloatingWindowController's hosted view

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Light/dark mode detection | Manual appearance observers | `@Environment(\.colorScheme)` | SwiftUI handles updates automatically |
| Color scheme forcing | NSAppearance manipulation | `preferredColorScheme(_:)` modifier | Cleaner, works with SwiftUI lifecycle |
| Hex color parsing | Manual string parsing | Verified extension (see Code Examples) | Edge cases: # prefix, alpha, invalid input |
| Chart theming | Manual mark coloring | `foregroundStyle()` with theme colors | Consistent with SwiftUI Charts API |

**Key insight:** SwiftUI's environment system handles most theming plumbing. The main work is defining the color palettes and wiring them to the environment.

## Common Pitfalls

### Pitfall 1: Floating Window Not Themed
**What goes wrong:** Theme changes apply to popover but floating window uses stale colors
**Why it happens:** FloatingWindowController creates its view once and doesn't observe theme changes
**How to avoid:** Pass ThemeManager via `.environment()` to FloatingWindowView; ensure NSHostingController recreates or updates
**Warning signs:** Floating window colors don't match popover after theme switch

### Pitfall 2: Menu Bar Text Ignoring Theme
**What goes wrong:** Menu bar percentage text stays one color regardless of theme
**Why it happens:** StatusItemManager uses GradientColors directly without theme awareness
**How to avoid:** Make GradientColors theme-aware or add theme parameter to color resolution
**Warning signs:** Menu bar text looks wrong in non-native themes

### Pitfall 3: preferredColorScheme Affecting System
**What goes wrong:** Setting `.dark` affects the entire app including Settings window
**Why it happens:** `preferredColorScheme` bubbles up and can affect presentations
**How to avoid:** Apply color scheme override only to specific view hierarchies (popover content, floating window)
**Warning signs:** Settings window goes dark when it shouldn't

### Pitfall 4: Chart Colors Hard-Coded
**What goes wrong:** Swift Charts gradient uses `.blue` regardless of theme
**Why it happens:** UsageChartView has hard-coded `colors: [.blue.opacity(0.4), .blue.opacity(0.1)]`
**How to avoid:** Replace with `themeColors.chartGradient` that varies by theme
**Warning signs:** Chart looks out of place in Anthropic warm theme

### Pitfall 5: NSColor vs SwiftUI Color Mismatch
**What goes wrong:** Colors look different in AppKit (menu bar) vs SwiftUI (popover)
**Why it happens:** Different color spaces, different rendering
**How to avoid:** Define colors in one place, convert consistently using `Color(nsColor:)` or `NSColor(Color())`
**Warning signs:** Same "orange" looks different in menu bar vs popover

## Code Examples

Verified patterns from official sources and best practices:

### Hex Color Extension (Cross-Platform)
```swift
// Source: Community pattern, verified working
extension Color {
    init(hex: UInt64, opacity: Double = 1.0) {
        let r = Double((hex >> 16) & 0xff) / 255.0
        let g = Double((hex >> 08) & 0xff) / 255.0
        let b = Double((hex >> 00) & 0xff) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }
}

extension NSColor {
    convenience init(hex: UInt64, alpha: CGFloat = 1.0) {
        let r = CGFloat((hex >> 16) & 0xff) / 255.0
        let g = CGFloat((hex >> 08) & 0xff) / 255.0
        let b = CGFloat((hex >> 00) & 0xff) / 255.0
        self.init(srgbRed: r, green: g, blue: b, alpha: alpha)
    }
}
```

### Reading Color Scheme
```swift
// Source: Apple Developer Documentation - colorScheme
struct AdaptiveView: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Text("Hello")
            .foregroundColor(colorScheme == .dark ? .white : .black)
    }
}
```

### Theme Picker in Settings
```swift
// Source: Standard SwiftUI Picker pattern
struct ThemePicker: View {
    @Environment(ThemeManager.self) var themeManager

    var body: some View {
        @Bindable var manager = themeManager

        Picker("Theme", selection: $manager.selectedTheme) {
            ForEach(AppTheme.allCases) { theme in
                Text(theme.rawValue).tag(theme)
            }
        }
        .pickerStyle(.radioGroup)
    }
}
```

### Theming Swift Charts
```swift
// Source: Swift with Majid - Mastering Charts
Chart {
    ForEach(dataPoints) { point in
        AreaMark(
            x: .value("Time", point.timestamp),
            y: .value("Usage", point.percentage)
        )
        .foregroundStyle(
            LinearGradient(
                colors: themeColors.chartGradientColors,
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}
```

## Anthropic Brand Colors Reference

Based on official branding research:

| Color Name | Hex | Usage |
|------------|-----|-------|
| Crail (Primary) | #C15F3C | Accent color, warm orange |
| Light Background | #faf9f5 | Off-white, light mode background |
| Dark Background | #141413 | Near-black, dark mode background |
| Mid Gray | #b0aea5 | Secondary text |
| Light Gray | #e8e6dc | Borders, subtle backgrounds |
| Orange Accent | #d97757 | Alternative accent |
| Blue Accent | #6a9bcc | Secondary accent |
| Green Accent | #788c5d | Tertiary accent |

**Design philosophy:** Warm, approachable, avoiding harsh contrasts. Evokes calmness and intellectual depth.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `NSAppearance` manipulation | `preferredColorScheme(_:)` | macOS 11 / SwiftUI 2 | Cleaner, declarative |
| `@ObservableObject` + `@Published` | `@Observable` macro | Swift 5.9 / macOS 14 | Less boilerplate |
| Manual color scheme observation | `@Environment(\.colorScheme)` | SwiftUI 1.0 | Automatic updates |

**Deprecated/outdated:**
- `ObservableObject` protocol: Still works but `@Observable` preferred for new code
- Asset catalog color sets: Work in Xcode projects but complex with SPM; programmatic colors simpler

## Open Questions

1. **Should the floating window background be translucent?**
   - What we know: NSPanel supports vibrancy materials, SwiftUI has `.ultraThinMaterial`
   - What's unclear: Whether this adds value for a small usage display
   - Recommendation: Keep opaque for now; add as polish item if time permits

2. **Should themes affect the menu bar icon style choice?**
   - What we know: Currently only "Percentage" is implemented
   - What's unclear: If logo/gauge modes would need theme variants
   - Recommendation: Theme applies to colors only; icon style is orthogonal

## Sources

### Primary (HIGH confidence)
- Apple Developer Documentation - ColorScheme: https://developer.apple.com/documentation/swiftui/colorscheme
- Apple Developer Documentation - preferredColorScheme: Official SwiftUI modifier
- nilcoalescing.com - Reading and Setting Color Scheme in SwiftUI: https://nilcoalescing.com/blog/ReadingAndSettingColorSchemeInSwiftUI/
- Swift with Majid - Mastering Charts in SwiftUI: https://swiftwithmajid.com/2023/01/18/mastering-charts-in-swiftui-mark-styling/

### Secondary (MEDIUM confidence)
- Alexander Weiss - Effortless SwiftUI Theming (Jan 2025): https://alexanderweiss.dev/blog/2025-01-19-effortless-swiftui-theming
- Claila.com - Claude Logo Analysis (Anthropic brand colors): https://www.claila.com/blog/claude-logo
- Daniel Saidi - Creating Hex-Based Colors: https://danielsaidi.com/blog/2022/05/06/creating-hex-based-colors-in-uikit-appkit-and-swiftui

### Tertiary (LOW confidence)
- WebSearch results for Anthropic brand guidelines (multiple sources, colors verified against multiple articles)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - native SwiftUI, well-documented
- Architecture: HIGH - established patterns, multiple sources confirm approach
- Pitfalls: MEDIUM - based on macOS SwiftUI experience, specific edge cases may exist
- Anthropic colors: MEDIUM - sourced from brand analysis articles, not official style guide

**Research date:** 2026-02-14
**Valid until:** 60 days (stable SwiftUI theming patterns)
