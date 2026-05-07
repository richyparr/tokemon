# Liquid Glass Redesign Plan

## Branch: `feature/liquid-glass-redesign` (already created)

## macOS 26 Liquid Glass API Summary

### Key APIs
- `.glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))` — applies glass
- `.glassEffect(.regular.tint(.blue))` — tinted glass for semantic meaning
- `GlassEffectContainer(spacing:)` — groups glass elements (glass can't sample glass)
- `.glassEffectID(_:in:)` + `@Namespace` — morphing transitions
- `.buttonStyle(.glass)` — translucent secondary buttons
- `.buttonStyle(.glassProminent)` — opaque primary buttons
- `.backgroundExtensionEffect()` — mirrors content under sidebars/toolbars
- `.scrollEdgeEffectStyle(.soft, for: .top)` — scroll edge behavior

### Glass Variants
- `.regular` — medium transparency, heavy diffusion (default, best for readability)
- `.clear` — high transparency, minimal blur (needs dimming layer)
- `.identity` — disables glass (for conditional toggle)

### Auto-Glass (no code needed, just recompile for macOS 26)
- NSPopover (our menu bar popover)
- Toolbar / NavigationBar
- Sidebar
- TabBar
- Sheets / Alerts
- Window controls
- Toggles, Sliders, Segmented Pickers (during interaction)

### Design Rules
1. **Glass = navigation layer ONLY** (toolbars, popovers, floating panels, buttons)
2. **Content = NO glass** (lists, cards, charts, gauges, tables)
3. **Never stack glass on glass** — use GlassEffectContainer
4. **Tint only for semantic meaning** (primary actions, state), never decoration
5. **Never mix .regular and .clear** in same group
6. **Max 5-10 glass elements** for performance
7. Text on glass auto-gets vibrant treatment — use .primary/.secondary, not custom colors

## Changes Required

### 1. Deployment Target → macOS 26
- `Package.swift`: `.macOS(.v14)` → `.macOS(.v26)` (or use `#available` checks)
- `project.yml`: `deploymentTarget.macOS: "14.0"` → `"26.0"`
- `Tokemon.xcodeproj/project.pbxproj`: `MACOSX_DEPLOYMENT_TARGET = 14.0` → `26.0`
- `Info.plist`: `LSMinimumSystemVersion` → `26.0`

### 2. Theme.swift — Simplify for Glass
- Remove solid `primaryBackground` — glass backgrounds replace them
- Keep `primaryAccent` for tinting and interactive elements
- Keep `usageColor()` for percentage coloring (content layer)
- Keep `chartGradientColors` for Swift Charts
- Consider removing Light/Dark theme variants — glass adapts automatically
- Or keep themes but make backgrounds transparent/clear instead of solid

### 3. PopoverContentView.swift
- **Remove** `.background(themeColors.primaryBackground.ignoresSafeArea())`
- NSPopover auto-gets glass — just remove the solid background
- Remove `preferredColorScheme` and NSWindow appearance overrides (glass handles this)
- Content text will auto-get vibrant treatment on glass

### 4. FloatingWindowView.swift
- Remove `.background(themeColors.primaryBackground)`
- Apply `.glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))` to the container

### 5. FloatingWindowController.swift
- Set window background to `.clear`
- Set `isOpaque = false`
- Window level stays `.floating`
- May need `window.backgroundColor = .clear` on the NSPanel

### 6. SettingsWindowController.swift
- Toolbar auto-gets glass
- May want `.windowStyle(.hiddenTitleBar)` for seamless glass
- Content area stays standard

### 7. Settings Tabs (all)
- Form `.grouped` style should work well with glass
- Update status indicator circles if needed for contrast

### 8. ErrorBannerView.swift
- Replace `Color.orange.opacity(0.1)` background with `.glassEffect(.regular.tint(.orange))`
- Same for UpdateBannerView (blue tint)

### 9. Buttons throughout
- Settings/refresh buttons → `.buttonStyle(.glass)`
- Primary actions (Retry, Save, Connect) → `.buttonStyle(.glassProminent)`

### 10. Stat Cards (OrgUsageView, TeamUsageSummaryView, ForecastView)
- These are CONTENT, not navigation — do NOT apply glass
- Replace `Color.secondary.opacity(0.1)` fills with lighter, glass-compatible fills
- Use `.foregroundStyle(.primary)` / `.foregroundStyle(.secondary)` for auto-vibrant text

### 11. Charts (UsageChartView, ExtendedHistoryChartView)
- Content layer — no glass
- Ensure chart gradients have enough contrast on glass backgrounds
- Test readability with reduce transparency enabled

### 12. BudgetGaugeView
- Content layer — no glass on the gauge
- Colors should work fine as-is (green/orange/red are high contrast)

### 13. ShareableCardView / PDFReportView
- NO changes — these render in ImageRenderer context, glass won't work
- Keep hardcoded colors

## Implementation Order
1. Deployment target changes (all config files)
2. Theme.swift rework
3. PopoverContentView (remove background)
4. FloatingWindow (glass effect + controller)
5. Settings window
6. Buttons throughout
7. Banners (glass tint)
8. Stat cards (lighter fills)
9. Test and iterate
