# Project Research Summary

**Project:** Tokemon
**Domain:** Native macOS monitoring utility (menu bar + widget + floating window)
**Researched:** 2026-02-11
**Confidence:** HIGH

## Executive Summary

Tokemon is a native macOS menu bar utility for monitoring Claude API usage across multiple sources (Claude Code local logs, Claude API, and potentially claude.ai web). The research reveals this is a crowded but underserved niche with 8+ existing competitors, most of which are basic percentage-in-menu-bar apps that lack sophisticated trend analysis and unified monitoring across Claude's multiple access methods. The key opportunity is building a **best-in-class Claude-only monitor** with rich visualization and actionable intelligence (burn rate projections, smart model switching suggestions), rather than a mediocre multi-provider tool.

The recommended technical approach is Swift 6.1+ with SwiftUI for UI (targeting macOS 14+), SwiftData for persistence, and a modular data source architecture that prioritizes local JSONL parsing (works for all users) over API-dependent features (requires admin keys that individual users cannot obtain). The architecture must handle three display modes (menu bar popover, WidgetKit extension in Notification Center, and floating window) across two separate processes with App Group shared container communication.

Critical risks include: (1) undocumented Claude Code JSONL format instability requiring defensive parsing and cost calculation fallbacks, (2) Admin API requirement blocking individual users from API-based features, (3) App Sandbox restrictions on file system access requiring non-App-Store distribution, and (4) WidgetKit refresh budget constraints preventing real-time widget updates. Mitigation strategies are well-documented in the research and must be incorporated from Phase 1.

## Key Findings

### Recommended Stack

Swift 6.1+ with SwiftUI is the only viable approach for native macOS menu bar development, especially with MenuBarExtra, WidgetKit, and Swift Charts requirements. The minimum deployment target must be macOS 14.0 (Sonoma) to access SwiftData, @Observable macro, and interactive WidgetKit — targeting earlier versions would require falling back to Core Data and less performant observation patterns. The stack is remarkably dependency-light, requiring only KeychainAccess (4.2.2+) for secure API key storage while using exclusively built-in frameworks (SwiftUI, AppKit, WidgetKit, Swift Charts, SwiftData) for all other functionality.

**Core technologies:**
- **Swift 6.1+ (Xcode 16.4)**: Primary language with strict concurrency checking to prevent data races when polling multiple sources
- **SwiftUI**: Declarative UI for all views (MenuBarExtra, charts, settings); the only framework that supports MenuBarExtra and WidgetKit integration
- **AppKit**: System integration layer for NSPanel floating windows, NSStatusItem fallback, and window level management where SwiftUI alone is insufficient
- **SwiftData**: Modern ORM with @Model/@Query for historical usage data, shareable with widget via App Group ModelContainer
- **Swift Charts**: First-party charting for usage trend graphs (LineMark, BarMark, AreaMark)
- **WidgetKit**: Notification Center widget running in separate process, limited to 40-70 refreshes/day
- **URLSession async/await**: Zero-dependency HTTP for Anthropic API integration
- **KeychainAccess**: Battle-tested secure storage for API keys (raw Security.framework is too verbose)

**Version compatibility decision:** macOS 14 is the critical minimum — it unlocks SwiftData, @Observable, and interactive WidgetKit while still covering Sonoma (Sep 2023), Sequoia (Sep 2024), and Tahoe (Sep 2025) users. Targeting macOS 13 would lose these capabilities; targeting macOS 15+ would be ideal for native floating windows but cuts off too many users.

**Distribution constraint:** Must distribute outside Mac App Store as a notarized DMG because App Sandbox prevents reading ~/.claude/projects/ (the core data source). Non-sandboxed apps with Developer ID signing + notarization can freely read Claude Code's JSONL files.

### Expected Features

Tokemon enters a crowded competitive space where table stakes are well-established and differentiation is critical. Almost every competitor offers menu bar percentage display, 5-hour/7-day usage tracking, and threshold alerts. The gap in the market is **unified monitoring with rich visualization and actionable intelligence** — moving beyond "what percent am I at" to "should I switch models, and when will I run out at this rate?"

**Must have (table stakes):**
- Menu bar icon with color-coded usage percentage (green <50%, orange 50-80%, red >80%)
- 5-hour session usage + countdown timer (the #1 user pain point)
- 7-day weekly usage + countdown timer (the #2 user pain point)
- Per-model breakdown (Opus/Sonnet/Haiku) — data already in OAuth response
- Threshold alerts (50/75/90%) at user-configured levels
- Click-to-expand popover with detailed usage summary
- Launch at login, configurable refresh interval (default 30s), light/dark mode
- Privacy-first (Keychain storage, zero telemetry, no cloud sync)

**Should have (competitive differentiation):**
- **Three display modes** (menu bar + Notification Center widget + floating window) — no competitor offers all three
- **Usage trend graphs/sparklines** — only CCSeva and CCTray have basic charts; rich 7-day visualization is a clear market gap
- **Burn rate projection** — "At your current pace, you will hit your limit in X hours" with linear projection
- **Unified monitoring** across Claude Code + claude.ai + API (OAuth endpoint covers Code/web, Admin API adds org-level data)
- **Smart model switching suggestions** — when approaching Opus limits, suggest switching to Sonnet for lighter tasks
- **Cost tracking with model breakdown** — calculate from token counts x published pricing when costUSD field is absent
- **Multi-profile support** — for users with work + personal Claude accounts
- **Keyboard shortcut** (Cmd+Shift+U) for instant access

**Defer to v2+ (explicitly NOT building):**
- Multi-provider monitoring (Codex, Gemini, Copilot) — ClaudeBar proves this splits focus and dilutes quality
- Conversation content access — massive privacy concern; show token/cost only, never content
- Real-time token streaming — impossible without IDE extension architecture
- Automatic model switching — Tokemon is a monitor, not a proxy; suggest only
- Team/org dashboard — Anthropic already provides this; focus on individual Pro/Max users

### Architecture Approach

The system runs across two separate processes (main app + widget extension) with a single @Observable state owner pattern in the main app and App Group shared container for widget communication. The main app is an LSUIElement agent (no Dock icon) with MenuBarExtra as primary UI, floating windows summoned on demand, and settings accessed via hybrid activation policy management.

**Major components:**
1. **UsageMonitor (@Observable singleton)** — Central state owned by App, drives all UI via SwiftUI observation; delegates to protocol-based data source services; writes to SwiftData after each refresh
2. **Protocol-based Data Sources** — LogFileParser (Claude Code JSONL), ClaudeAPIClient (Admin API), WebUsageService (optional claude.ai); abstraction enables graceful degradation when sources unavailable
3. **MenuBarExtra (.window style)** — Primary UI surface showing status icon + rich popover with charts, breakdowns, and timers; always available
4. **WidgetKit Extension (separate process)** — Reads pre-computed data from App Group shared container (JSON file + UserDefaults); runs on system-controlled schedule (~15-60 min intervals)
5. **Floating Window** — Optional always-on-top display using NSPanel (macOS 14) or .windowLevel(.floating) (macOS 15+)
6. **SwiftData ModelContainer (App Group)** — Historical usage records, persistent across launches, shareable with widget for trend queries
7. **NotificationManager** — Wraps UNUserNotificationCenter; evaluates thresholds after each refresh and schedules local notifications

**Data flow:** Timer-driven polling (every 30s default) gathers from all available sources → merges into UsageSnapshot → updates @Observable properties → SwiftUI views auto-render → writes to SwiftData + App Group container → triggers WidgetCenter.reloadAllTimelines() → evaluates notification thresholds.

**Process boundary constraint:** Widget extension cannot call main app code, cannot share memory, cannot subscribe to @Observable objects. Communication is strictly one-directional via filesystem (App Group container). Widget shows aggregate/stale data; menu bar shows real-time data.

### Critical Pitfalls

Research identified 6 critical pitfalls that must be designed around from Phase 1:

1. **Admin API Key Requirement Blocks Individual Users** — The Anthropic Usage/Cost APIs require Admin keys (`sk-ant-admin...`) only available to organization admins, not individual Pro/Max users (the primary target audience). **Mitigation:** Design data source layer with local JSONL parsing as primary source (works for everyone); Admin API as optional power-user feature. App must function fully with zero API keys.

2. **Claude Code JSONL Format Is Unstable** — The `~/.claude/projects/<project>/<session>.jsonl` format is undocumented and has already changed (costUSD field removed in v1.0.9). **Mitigation:** Build versioned parser with defensive field access; calculate costs from token counts + pricing table when costUSD absent; store normalized data in local SwiftData so historical data survives schema changes; unit test with fixtures from multiple Claude Code versions.

3. **Claude.ai Web Usage Has No API** — There is no programmatic access to claude.ai subscription usage; the settings page shows only current period without history or export. **Mitigation:** Explicitly descope claude.ai web monitoring; communicate clearly in UI which sources are active; OAuth endpoint already captures claude.ai usage for Code users anyway. Monitor Anthropic changelog for future API.

4. **App Sandbox Blocks ~/.claude Access** — Mac App Store apps in sandbox cannot read ~/.claude/projects/ without user-initiated file selection per session (breaks core feature). **Mitigation:** Distribute as notarized DMG outside App Store; use Developer ID signing + Hardened Runtime; non-sandboxed apps can freely read Claude Code files with better UX.

5. **WidgetKit Refresh Budget Prevents Real-Time Updates** — Widgets get only 40-70 refreshes/day (~15-60 min intervals) controlled by system; cannot force frequent updates. **Mitigation:** Design widget to show aggregate/trend data that remains useful when 30 min stale; use menu bar popover for real-time data; include "Updated X ago" timestamp; trigger reloads from main app only when significant changes occur to preserve budget.

6. **Menu Bar Lifecycle Mismanagement** — Default SwiftUI lifecycle creates unwanted main windows, Dock icons, and broken popover dismissal; SettingsLink doesn't work inside MenuBarExtra. **Mitigation:** Set LSUIElement=true in Info.plist; handle applicationShouldTerminateAfterLastWindowClosed; use hybrid SwiftUI (70%) + AppKit (30%) approach for system integration points; get menu bar lifecycle correct in Phase 1 before building features.

## Implications for Roadmap

Based on research, the recommended phase structure prioritizes a working end-to-end slice (menu bar with local JSONL data) before expanding to additional display modes or data sources:

### Phase 1: Foundation & Core Menu Bar
**Rationale:** Establish the architectural foundation and prove the core value proposition — menu bar monitoring with local JSONL parsing — before adding complexity. This phase addresses the highest-risk pitfall (JSONL parsing instability) and validates that the app delivers value with zero configuration.

**Delivers:**
- Working menu bar app (LSUIElement agent, no Dock icon)
- MenuBarExtra with .window style popover
- Color-coded status icon (green/orange/red)
- UsageMonitor @Observable singleton with polling
- LogFileParser (Claude Code JSONL) with defensive parsing
- SwiftData persistence with App Group container
- Basic popover showing 5-hour/7-day usage + reset timers
- Per-model breakdown (Opus/Sonnet/Haiku)

**Addresses pitfalls:**
- JSONL format instability (versioned parser with unit tests)
- Menu bar lifecycle (LSUIElement + proper window management)
- Individual user access (works with zero API keys)
- App Sandbox (project setup chooses non-sandboxed distribution)

**Features from FEATURES.md:** All table-stakes features except notifications and keyboard shortcut

**Research flag:** Standard patterns — MenuBarExtra, SwiftData, JSONL parsing all have community precedent

### Phase 2: Notifications & Polish
**Rationale:** Add threshold-based alerts (users' #1 request per competitor analysis) and keyboard shortcut for power users. These are high-value, low-complexity enhancements that complete the MVP feature set.

**Delivers:**
- NotificationManager with UNUserNotificationCenter integration
- Threshold evaluation (50/75/90% configurable)
- macOS native notifications with actionable content
- Global keyboard shortcut (Cmd+Shift+U)
- Preferences window (thresholds, refresh interval, keyboard shortcut, launch at login)

**Addresses pitfalls:** None (low-risk phase)

**Features from FEATURES.md:** Completes all P1 table-stakes features

**Research flag:** Skip research-phase (well-documented macOS patterns)

### Phase 3: Usage Trends & Burn Rate
**Rationale:** Add the first competitive differentiator — rich visualization and actionable intelligence. This moves beyond "what percent" to "what will happen" and is a clear gap in the competitive landscape.

**Delivers:**
- Swift Charts integration for 7-day trend graphs
- Sparkline visualization in popover
- Burn rate calculation (tokens/hour from recent sessions)
- Linear projection to limit ("You will hit your limit in X hours")
- Enhanced popover with trend section

**Addresses pitfalls:** SwiftData query performance (implement date-range predicates for efficient charting)

**Features from FEATURES.md:** Usage trend graphs (P2), Burn rate projection (P2)

**Research flag:** Skip research-phase (Swift Charts well-documented)

### Phase 4: Widget Extension
**Rationale:** Add second display mode (Notification Center widget) after core functionality is stable. Widget reads from App Group container already established in Phase 1, so integration risk is low.

**Delivers:**
- WidgetKit extension target
- TimelineProvider reading from App Group container
- Small/Medium widget sizes showing usage summary + trend sparkline
- .never refresh policy with app-triggered reloads

**Addresses pitfalls:**
- WidgetKit refresh budget (aggregate data design, timestamp display, app-triggered reloads)
- Process boundary (reads only from shared container)

**Features from FEATURES.md:** Notification Center widget (P2 differentiator)

**Research flag:** Skip research-phase (WidgetKit with App Group is standard pattern)

### Phase 5: Floating Window
**Rationale:** Add third display mode (optional always-on-top window) for users who prefer persistent visibility. Independent of widget, can be built in parallel with Phase 4 if desired.

**Delivers:**
- NSPanel subclass for macOS 14 compatibility
- Runtime check for macOS 15+ .windowLevel(.floating) SwiftUI API
- Compact floating view reading from same UsageMonitor instance
- Toggle from menu bar to show/hide floating window

**Addresses pitfalls:** Activation policy toggling when showing windows from LSUIElement app

**Features from FEATURES.md:** Floating window (P2 differentiator)

**Research flag:** Skip research-phase (NSPanel patterns documented in community sources)

### Phase 6: Admin API & Cost Tracking
**Rationale:** Add optional API-based data source for organization users with admin keys. Protocol-based abstraction makes this a clean plugin to existing architecture.

**Delivers:**
- ClaudeAPIClient service (URLSession async/await)
- Admin API key Keychain storage via KeychainAccess
- /v1/organizations/usage_report/messages polling
- /v1/organizations/cost_report daily data
- Cost calculation from token counts + pricing table
- Model breakdown with cost attribution
- Settings for API key entry + validation

**Addresses pitfalls:**
- Admin API requirement (explicit as optional feature, clear UI when unavailable)
- Cost calculation when costUSD absent (use pricing table)
- Key security (Keychain storage)

**Features from FEATURES.md:** API usage monitoring (P2), Cost tracking (P2)

**Research flag:** Skip research-phase (Admin API documented by Anthropic)

### Phase 7: Smart Suggestions & Multi-Profile
**Rationale:** Add intelligence layer (model switching suggestions) and convenience feature (profile switching) after core monitoring is mature.

**Delivers:**
- Suggestion engine comparing Opus vs Sonnet/Haiku utilization
- Notification/banner when Opus high but Sonnet available
- Multi-profile Keychain storage (separate OAuth tokens + API keys)
- Profile switcher in popover
- Per-profile usage history

**Addresses pitfalls:** None (low-risk enhancement)

**Features from FEATURES.md:** Smart model suggestions (P2), Multi-profile support (P2)

**Research flag:** Skip research-phase (builds on existing patterns)

### Phase 8: Design Polish
**Rationale:** Per user's global instructions, include a dedicated design phase after all features built to polish aesthetics consistently across all display modes.

**Delivers:**
- Three themes (System Light, System Dark, Focus)
- Color scheme refinement
- Typography and spacing polish
- Component styling (gauges, charts, badges)
- Consistent visual language across menu bar + widget + floating window

**Addresses pitfalls:** None (purely visual)

**Features from FEATURES.md:** Three themes (P2)

**Research flag:** No research needed (design iteration)

### Phase Ordering Rationale

- **Foundation-first:** Phase 1 establishes core architecture (data layer, state management, menu bar lifecycle) that all later phases depend on. Getting this right prevents expensive refactoring.
- **Value-early:** Phases 1-3 deliver a fully functional menu bar app with monitoring + alerts + trends before adding additional display modes. This ensures early validation.
- **Display mode independence:** Widget (Phase 4) and floating window (Phase 5) are independent and could be built in parallel; sequenced here for focused development.
- **API as enhancement:** Admin API integration (Phase 6) comes late because it's optional and only works for a subset of users; local JSONL parsing is proven first.
- **Intelligence on top:** Smart suggestions (Phase 7) require stable usage data and burn rate calculations from earlier phases.
- **Design last:** Per user preference, design polish comes after features are complete to enable consistent refinement.

### Research Flags

**Phases with standard patterns (skip `/gsd:research-phase`):**
- **Phase 1:** MenuBarExtra, SwiftData, JSONL parsing — multiple community examples and Apple docs
- **Phase 2:** UNUserNotificationCenter, keyboard shortcuts — standard macOS APIs
- **Phase 3:** Swift Charts — first-party Apple framework, extensive documentation
- **Phase 4:** WidgetKit with App Group — well-documented pattern
- **Phase 5:** NSPanel floating windows — multiple community tutorials
- **Phase 6:** URLSession + Anthropic API — official Anthropic docs
- **Phase 7:** Multi-profile pattern — standard Keychain multi-key storage
- **Phase 8:** Design iteration — no research needed

**All phases have sufficient research confidence to proceed without additional research phase.** The initial project research covered all major integration points and platform-specific concerns.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All technologies verified against official Apple/Anthropic docs; deployment target decision matrix confirmed; KeychainAccess vetted with 7k+ stars |
| Features | HIGH | Competitive analysis of 8+ existing apps establishes clear table stakes and differentiation opportunities; feature-to-phase dependencies mapped |
| Architecture | HIGH | Process boundary constraints (App Group), state management (@Observable), and menu bar lifecycle patterns all documented across multiple sources; build order implications clear |
| Pitfalls | MEDIUM-HIGH | Top 6 pitfalls verified with official docs and community post-mortems; mitigation strategies proven by existing tools; some uncertainty around JSONL schema evolution but defensive parsing addresses this |

**Overall confidence:** HIGH

The research provides a strong foundation for roadmap creation. All major architectural decisions (deployment target, distribution channel, data source priority, display mode sequencing) are supported by evidence. The competitive landscape is well-understood with clear differentiation strategy.

### Gaps to Address

**Minor gaps that will resolve during implementation:**

- **JSONL schema versioning strategy:** While defensive parsing is well-understood, the specific version detection logic (which fields indicate which Claude Code version) will need to be refined as more schema samples are collected. **Mitigation:** Build comprehensive test fixtures early in Phase 1; expect parser updates in point releases.

- **Widget timeline policy tuning:** The exact refresh frequency and `.never` vs `.atEnd` policy tradeoffs can only be validated in production with real widget refresh budget observation. **Mitigation:** Start with conservative `.never` policy + app-triggered reloads; instrument to track reload success rate; adjust in v1.x.

- **Floating window activation policy timing:** The exact sequence of `NSApp.setActivationPolicy()` calls to show/hide floating windows from an LSUIElement app may require experimentation to avoid focus stealing or window layering bugs. **Mitigation:** Reference Cindori's floating panel code as baseline; test on multiple macOS versions (14, 15, 26) in Phase 5.

- **Cost calculation pricing table freshness:** Anthropic's per-token pricing changes with new models; hardcoded pricing will become stale. **Mitigation:** For MVP (Phases 1-6), hardcode current pricing; in v1.x+, move to updatable JSON file bundled with app or fetched from remote config.

None of these gaps block roadmap creation or phase planning. They are implementation details that will be resolved during their respective phases.

## Sources

### Primary (HIGH confidence)
- [Anthropic Usage and Cost API](https://platform.claude.com/docs/en/build-with-claude/usage-cost-api) — API requirements, authentication, response schemas verified
- [Anthropic Claude Code Analytics API](https://platform.claude.com/docs/en/api/claude-code-analytics-api) — Admin API capabilities and limitations confirmed
- [Apple MenuBarExtra Documentation](https://developer.apple.com/documentation/swiftui/menubarextra) — SwiftUI menu bar API verified
- [Apple WidgetKit Documentation](https://developer.apple.com/documentation/widgetkit/keeping-a-widget-up-to-date) — Refresh budget and timeline policies confirmed
- [Apple SwiftData Documentation](https://developer.apple.com/documentation/swiftdata) — App Group container sharing verified
- [Apple Swift Charts Documentation](https://developer.apple.com/documentation/Charts) — Chart types and SwiftUI integration confirmed
- [Apple Observation Framework](https://developer.apple.com/documentation/Observation) — @Observable macro availability (macOS 14+) verified
- [Apple App Sandbox Documentation](https://developer.apple.com/documentation/security/accessing-files-from-the-macos-app-sandbox) — File access constraints confirmed
- [Xcode Releases](https://xcodereleases.com/) — Swift 6.1 with Xcode 16.4 verified
- [KeychainAccess GitHub](https://github.com/kishikawakatsumi/KeychainAccess) — Library maturity and API verified

### Secondary (MEDIUM confidence)
- [Claude Usage Tracker (GitHub)](https://github.com/hamed-elfayome/Claude-Usage-Tracker) — Competitive feature analysis
- [ClaudeBar (GitHub)](https://github.com/tddworks/ClaudeBar) — Multi-provider approach trade-offs
- [CCSeva (GitHub)](https://github.com/Iamshankhadeep/ccseva) — Burn rate and chart implementation precedent
- [ccusage (GitHub)](https://github.com/ryoppippi/ccusage) — JSONL parsing approach, cost calculation when costUSD absent
- [Nil Coalescing: Build a macOS menu bar utility](https://nilcoalescing.com/blog/BuildAMacOSMenuBarUtilityInSwiftUI/) — MenuBarExtra lifecycle patterns
- [Polpiella: Floating window in macOS 15](https://www.polpiella.dev/creating-a-floating-window-using-swiftui-in-macos-15) — Native SwiftUI floating windows
- [Cindori: Floating panel in SwiftUI](https://cindori.com/developer/floating-panel) — NSPanel approach for macOS 14 compatibility
- [Peter Steinberger: Settings from menu bar items](https://steipete.me/posts/2025/showing-settings-from-macos-menu-bar-items) — SettingsLink bug documentation
- [Hacking with Swift: SwiftData in widgets](https://www.hackingwithswift.com/quick-start/swiftdata/how-to-access-a-swiftdata-container-from-widgets) — App Group container tutorial
- [Analyzing Claude Code Logs with DuckDB](https://liambx.com/blog/claude-code-log-analysis-with-duckdb) — JSONL structure details
- [What I Learned Building a Native macOS Menu Bar App](https://medium.com/@p_anhphong/what-i-learned-building-a-native-macos-menu-bar-app-eacbc16c2e14) — Real-world menu bar app post-mortem
- [Stats macOS Monitor (GitHub)](https://github.com/exelban/stats) — Reference architecture for menu bar monitoring apps

### Tertiary (LOW confidence)
- [Preslav Rachev: Claude Code token usage on toolbar](https://preslav.me/2025/08/04/put-claude-code-token-usage-macos-toolbar/) — JSONL format details (single source, may not cover all schema versions)
- [Claude Code feature request #13892](https://github.com/anthropics/claude-code/issues/13892) — Confirms lack of claude.ai usage API, but is user-submitted issue not official statement

---
*Research completed: 2026-02-11*
*Ready for roadmap: yes*

---

# v2 Pro Features Research Summary

**Synthesized:** 2026-02-14
**Scope:** Analytics, Multi-account, Licensing, Shareable Moments
**Confidence:** HIGH

## Key Findings

### Stack Additions
- **Only 1 new dependency:** `swift-lemon-squeezy-license` (v1.0.1) for licensing
- **PDF/CSV/Images:** All use native `ImageRenderer` — no third-party libraries needed
- **Multi-account:** Uses existing `KeychainAccess` with unique account identifiers

### Build Order (Dependencies)
1. **Licensing** — Foundation for all Pro features (must be first)
2. **Multi-Account** — Depends on licensing for Pro gating
3. **Extended Analytics** — Depends on licensing; extends HistoryStore
4. **Export (PDF/CSV)** — Depends on analytics for aggregation
5. **Shareable Images** — Can parallel with export

### Critical Pitfalls
| Pitfall | Prevention |
|---------|------------|
| LemonSqueezy License API is separate from main API | Use `swift-lemon-squeezy-license` package |
| No built-in grace period for subscriptions | Implement 3-7 day grace with local caching |
| Keychain credential collision in multi-account | Unique `kSecAttrAccount` per user ID |
| Feature gating scattered throughout code | Centralized `FeatureAccessManager` |
| PDF tutorials use UIKit (unavailable on macOS) | Use `ImageRenderer` or `PDFKit` |

### New Components Needed
- `LicenseManager` (@Observable) — License validation, caching, grace periods
- `LemonSqueezyClient` — API wrapper (or use package)
- `FeatureAccessManager` — Centralized Pro feature gating
- `AccountManager` — Multi-account credential storage
- `ExportManager` — PDF/CSV generation
- `ShareableCardView` — Social card templates

### Modified Components
- `UsageMonitor` — Account-aware data fetching
- `TokenManager` — Multi-credential support
- `HistoryStore` — Extended retention (90 days for Pro)
- `SettingsView` — License, accounts, export sections

## Roadmap Implications

**Recommended phase structure:**
- Phase 6: Licensing Foundation (LemonSqueezy, trial, feature gating)
- Phase 7: Multi-Account (Keychain expansion, account switcher)
- Phase 8: Analytics & Export (extended history, PDF/CSV)
- Phase 9: Shareable Moments (card templates, share sheet)

**Estimated complexity:**
- Licensing: MEDIUM (new integration, grace period logic)
- Multi-Account: MEDIUM (Keychain schema, account-aware state)
- Analytics/Export: LOW-MEDIUM (extends existing HistoryStore, ImageRenderer)
- Shareable: LOW (template-based image generation)

---
*v2 Research completed: 2026-02-14*

---

# v4.0 Raycast Extension Research Summary

**Synthesized:** 2026-02-18
**Scope:** Standalone Raycast extension for Claude usage monitoring
**Confidence:** HIGH (official Raycast docs verified, competitor extensions analyzed)

## Executive Summary

The Tokemon Raycast extension is a standalone TypeScript/React application that monitors Claude usage directly via OAuth, operating independently of Tokemon.app. The critical constraint is that Raycast Store policy prohibits Keychain access, meaning the extension cannot read credentials from Claude Code directly. Users must manually enter OAuth tokens via Raycast password preferences, which the extension then uses for token refresh and API calls.

The extension enters a competitive space with three existing solutions (ccusage, raycast-llm-usage, ClaudeCast), but Tokemon differentiates through multi-profile support (unique among competitors), configurable alert thresholds, and no CLI dependency. The architecture follows Raycast's ephemeral process model with aggressive caching via `useCachedState` and background refresh for the menu bar command.

Research identified 25 pitfalls, with the most critical being: (1) Keychain access causing automatic store rejection, (2) OAuth state mismatch during hot reload development, (3) `isLoading` stuck true causing battery drain, and (4) API rate limits interpreted as auth failures. All have documented mitigations.

## Stack Additions for v4.0

| Technology | Version | Purpose | Notes |
|------------|---------|---------|-------|
| **TypeScript** | 5.8+ | Primary language | Raycast requires TS/JS; type safety matches Swift models |
| **React** | 19.x | UI framework | Raycast components are React-based |
| **Node.js** | 22.14+ | Runtime | Raycast's required runtime version |
| **@raycast/api** | ^1.104.x | Core extension API | OAuth, storage, MenuBarExtra, preferences |
| **@raycast/utils** | ^1.17.x | Utilities | useFetch, useLocalStorage, useCachedPromise |

**No external dependencies required.** All functionality uses built-in Raycast APIs.

## Feature Table Stakes

Features users expect from a Claude usage Raycast extension (based on competitor analysis):

| Feature | Complexity | Raycast Pattern | Competitor Parity |
|---------|------------|-----------------|-------------------|
| Current session usage (%) | LOW | MenuBarExtra title | All have this |
| Weekly usage (%) | LOW | Metadata panel | All have this |
| Reset countdown timer | LOW | Metadata label | All have this |
| Menu bar icon with usage | LOW | MenuBarExtra | All have this |
| Manual refresh action | LOW | ActionPanel | All have this |
| Loading states | LOW | isLoading prop | Expected UX |
| Error handling | MEDIUM | Toast, EmptyView | Required |
| Pace indicator | LOW | Color-coded accessory | ClaudeCast has this |

**Tokemon Differentiators (unique):**
- **Multi-profile support** — Work/personal/client accounts (no competitor has this)
- **Alert configuration from Raycast** — Set thresholds without opening Tokemon.app
- **No CLI dependency** — Direct OAuth (ccusage requires npx/bunx)
- **Native app companion** — "Open in Tokemon" for deeper analytics

## Architecture Decisions

### Process Model
Raycast extensions are ephemeral — loaded on command invocation, unloaded after execution. Menu bar commands persist only while `isLoading: true`. All state must be persisted to LocalStorage or useCachedState between invocations.

### Credential Handling
**Critical constraint:** Raycast Store rejects extensions requesting Keychain access.

**Solution:** Manual token entry via password preferences + automatic refresh.
1. User copies tokens from Keychain Access.app (one-time setup)
2. Extension stores in Raycast's encrypted LocalStorage
3. Auto-refresh maintains session without re-entry

### Caching Strategy
```
Layer 1: useCachedState (instant UI on command open)
Layer 2: LocalStorage (OAuth tokens, usage history)
Layer 3: useFetch (stale-while-revalidate for API calls)
```

### Component Structure
```
src/
  index.tsx              # Dashboard command (List + Detail)
  menu-bar.tsx           # MenuBarExtra with background refresh
  configure-alerts.tsx   # Alert threshold settings (Form)
  switch-profile.tsx     # Profile switcher (future)
  api/
    oauth-client.ts      # Token refresh logic
    usage-client.ts      # Fetch usage data
    types.ts             # OAuthUsageResponse, etc.
  hooks/
    useUsageData.ts      # SWR-based usage fetching
    useCredentials.ts    # Token management
```

## Watch Out For (Top 5 Pitfalls)

| Pitfall | Severity | Phase | Prevention |
|---------|----------|-------|------------|
| **Keychain access causes store rejection** | CRITICAL | Foundation | Use Raycast OAuth utils + password preferences ONLY |
| **OAuth state mismatch during dev hot reload** | CRITICAL | Foundation | Never save files during active OAuth redirect |
| **isLoading stuck true drains battery** | CRITICAL | Menu Bar | Use try/finally, prefer usePromise hooks |
| **Rate limits (429) treated as auth failure** | HIGH | Foundation | Explicit 429 handling, retain auth state |
| **Duplicate MenuBarExtra items break onAction** | HIGH | Menu Bar | Ensure unique titles for sibling items |

**Full pitfall list:** 25 pitfalls documented in `/Users/richardparr/Tokemon/.planning/milestones/v4-research/PITFALLS.md`

## Roadmap Implications

### Suggested Phase Structure

**Phase 1: Extension Foundation (Days 1-2)**
- Project scaffolding (`npm init raycast-extension`)
- Type definitions (port from Swift models)
- Credential management (password preferences + LocalStorage)
- Custom extension icon (512x512)
- MIT license configuration

**Phase 2: Core Data Fetching (Days 3-4)**
- OAuth client with token refresh
- Usage fetching with `useFetch` + SWR
- Response parsing to `UsageSnapshot`
- Error handling (429 vs 401 differentiation)
- Graceful offline degradation (show cached data)

**Phase 3: Dashboard Command (Days 4-5)**
- List view with usage metrics
- Detail view for each metric
- Manual refresh action (Cmd+R)
- Loading states (no flicker on initial load)

**Phase 4: Menu Bar Command (Days 5-6)**
- MenuBarExtra with dynamic icon/title
- Background refresh (5m interval)
- LaunchType detection for background vs foreground
- Proper isLoading lifecycle

**Phase 5: Polish & Store Submission (Days 7-8)**
- Multi-profile support (LocalStorage profiles + profile switcher)
- Alert configuration (Form command)
- README with setup instructions
- Store submission

### Phase Ordering Rationale

1. **Foundation first** — Credential handling determines entire architecture; Keychain rejection is catastrophic
2. **Data before UI** — OAuth + API client must work before building views
3. **Dashboard before menu bar** — Simpler lifecycle, validates data flow
4. **Menu bar last** — Most complex lifecycle (background refresh, isLoading)
5. **Polish for submission** — Store requirements (icon, license, README) before publish

### Research Flags

**Needs deeper research:**
- **Phase 1:** Claude OAuth PKCE compatibility with Raycast redirect URIs (may need fallback to manual token entry)

**Standard patterns (skip research):**
- **Phase 2-5:** All use documented Raycast APIs with official examples

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Official Raycast docs verified; package versions confirmed on npm |
| Features | HIGH | 3 competitors analyzed; differentiation opportunities clear |
| Architecture | HIGH | Raycast lifecycle docs explicit; process model well-documented |
| Pitfalls | HIGH | 25 pitfalls verified against official docs and real extension issues |

**Overall confidence:** HIGH

### Gaps to Address

- **Claude OAuth PKCE with Raycast:** Unknown if Claude's OAuth supports Raycast's redirect URIs. Plan: Attempt PKCE flow; fall back to manual token entry if it fails.
- **Raycast Store review timeline:** Unknown review duration. Plan: Submit early; have Homebrew distribution as backup.

## Sources

### Official Raycast Documentation (HIGH confidence)
- [Raycast API Introduction](https://developers.raycast.com)
- [OAuth | Raycast API](https://developers.raycast.com/api-reference/oauth)
- [Menu Bar Commands](https://developers.raycast.com/api-reference/menu-bar-commands)
- [Storage | Raycast API](https://developers.raycast.com/api-reference/storage)
- [Security | Raycast API](https://developers.raycast.com/information/security)
- [Background Refresh](https://developers.raycast.com/information/lifecycle/background-refresh)
- [Best Practices](https://developers.raycast.com/information/best-practices)
- [Store Submission Guidelines](https://developers.raycast.com/basics/prepare-an-extension-for-store)

### Competitor Analysis (MEDIUM confidence)
- [ccusage Raycast Extension](https://www.raycast.com/nyatinte/ccusage) — 5,981 installs, CLI dependency
- [raycast-llm-usage](https://github.com/markhudsonn/raycast-llm-usage) — Direct Keychain (not store-compatible)
- [ClaudeCast](https://www.raycast.com/qazi0/claudecast) — Feature bloat, AI integration focus

### Tokemon Codebase (HIGH confidence)
- `Tokemon/Utilities/Constants.swift` — OAuth endpoints, client ID
- `Tokemon/Models/OAuthUsageResponse.swift` — Response model to port
- `Tokemon/Services/OAuthClient.swift` — Token refresh logic to port

---
*v4 Research completed: 2026-02-18*
*Ready for roadmap: yes*
