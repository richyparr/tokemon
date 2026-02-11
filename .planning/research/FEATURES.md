# Feature Research

**Domain:** macOS Claude usage monitoring (menu bar app)
**Researched:** 2026-02-11
**Confidence:** HIGH

## Competitive Landscape

There are at least 8 existing Claude usage monitoring menu bar apps. This is a crowded niche, which means table stakes are well-established and differentiation is critical. Key competitors analyzed:

| App | Key Strength | Weakness |
|-----|-------------|----------|
| Claude Usage Tracker | Multi-profile, 5 icon styles, terminal statusline | Complex, many features but cluttered |
| ClaudeBar | Multi-provider (Claude + Codex + Gemini + Copilot) | Jack of all trades, master of none |
| ClaudeUsageBar | Minimal, under 5MB, clean UX | Too basic -- no graphs, no cost tracking |
| ClaudeMeter | JSON export, configurable thresholds | Limited visualization |
| SessionWatcher | Zero config, paid model ($1.99-5.99) | macOS 15+ only, no graphs |
| Usagebar | Pay-what-you-want, context warnings | Minimal feature set |
| CCSeva | 7-day charts, burn rate, glassmorphism UI | Claude Code only, no claude.ai/API |
| CCTray | Sparkline charts, MVVM architecture | Narrow scope |

**Key insight:** Most competitors are simple percentage-in-menu-bar apps. Almost none do trends/graphs well. None combine all three access methods (CLI + web + API) with rich visualization. The gap is in **unified monitoring with actionable intelligence** -- not just "what percent am I at" but "should I switch models, and when will I run out at this rate?"

## Feature Landscape

### Table Stakes (Users Expect These)

Features users assume exist. Missing these = product feels incomplete.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Menu bar icon with usage percentage | Every competitor has this; it is the core value prop of a menu bar usage app | LOW | Color-coded: green (<50%), orange (50-80%), red (>80%). Multiple icon styles (percentage text, gauge, progress bar) are common |
| 5-hour session usage display | This is the primary limit users hit; the #1 pain point per Reddit/HN feedback | LOW | Show utilization percentage + countdown timer to reset. Data from OAuth `/api/oauth/usage` endpoint `five_hour.utilization` and `five_hour.resets_at` |
| 7-day weekly usage display | Weekly limits are the second most impactful constraint, especially for Max users | LOW | Show utilization + reset date. From `seven_day.utilization` and `seven_day.resets_at` |
| Reset countdown timers | Users need to plan work around resets; every competitor shows this | LOW | Both 5-hour and 7-day countdowns. Show as "Resets in 2h 34m" not just a timestamp |
| Threshold-based alerts | Users consistently report being "surprised" by hitting limits; notifications at 50/75/90% are expected | MEDIUM | macOS native notifications via `UNUserNotificationCenter`. Customizable thresholds. CCSeva's cooldown approach (prevent notification spam) is best practice |
| Click-to-expand popover with details | Every menu bar monitoring app provides detailed info on click | MEDIUM | Show session usage, weekly usage, reset timers, and model breakdown in a clean popover. iStat Menus pattern: menu bar shows summary, popover shows detail |
| Launch at login | Standard for any always-on monitoring utility | LOW | `SMAppService.register()` on modern macOS. Users expect this toggle in preferences |
| Automatic refresh | Usage data must stay current without manual intervention | LOW | Default 30-60 second intervals. Competitors range from 5-300 seconds configurable |
| Privacy-first / local-only data | Every competitor advertises zero telemetry; users are sensitive about credential handling | LOW | Store OAuth tokens in macOS Keychain. No analytics, no cloud sync. Badge this prominently |
| Light/dark mode support | macOS standard; every competitor supports this | LOW | Follow system appearance via `@Environment(\.colorScheme)` in SwiftUI |

### Differentiators (Competitive Advantage)

Features that set ClaudeMon apart. Not required, but create the value proposition.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| **Three display modes (menu bar + Notification Center widget + floating window)** | No competitor offers all three. Most are menu-bar-only. This is ClaudeMon's primary UX differentiator | HIGH | Menu bar: `NSStatusItem`. Widget: WidgetKit (macOS 14+, with new WWDC25 features in Tahoe). Floating window: `NSPanel` with `.floating` level or SwiftUI `.windowLevel(.floating)` on macOS 15+. Each mode serves a different workflow |
| **Usage trend graphs / sparklines** | Only CCSeva and CCTray have basic charts. Rich visualization of usage over time is a clear gap in the market | MEDIUM | Use DSFSparkline library or custom SwiftUI Charts. Show 7-day trend, daily breakdown, per-session history. Users want to see patterns, not just current state |
| **Burn rate projection** | "At your current pace, you will hit your limit in X hours" -- only CCSeva does basic burn rate; none do projections well | MEDIUM | Calculate tokens/hour from recent sessions. Linear projection to limit. This is the "actionable intelligence" gap -- telling users what to DO, not just showing numbers |
| **Unified monitoring across Claude Code + claude.ai + API** | Most competitors track only one source. ClaudeBar tracks multiple providers but not multiple Claude access methods | HIGH | OAuth endpoint covers Claude Code + claude.ai (shared session). API usage requires separate Admin API key with `/v1/organizations/usage_report/messages`. These are fundamentally different auth flows and data structures |
| **Cost tracking with model breakdown** | CCSeva does daily cost estimates; ClaudeMeter has JSON export; but none show per-model cost breakdown beautifully | MEDIUM | For API users: calculate from token counts x published per-token pricing. For subscribers: `/cost` and `/stats` commands provide session cost. Model breakdown from `model_breakdown` field in Claude Code usage report |
| **Three themes** | Goes beyond light/dark. Competitors offer at most light/dark + monochrome | LOW | System light, system dark, plus a third option (e.g., a "focus" theme with muted colors, or a high-contrast accessibility theme). Keep scope controlled -- three, not unlimited |
| **Smart model switching suggestions** | No competitor does this. When approaching limits, suggest "Switch to Sonnet for lighter tasks to conserve Opus quota" | MEDIUM | Based on `seven_day_opus` utilization from OAuth endpoint. When Opus usage is high but Sonnet is available, surface a suggestion. This turns monitoring into coaching |
| **Per-model usage breakdown (Opus vs Sonnet vs Haiku)** | The OAuth endpoint returns `seven_day_opus` separately. Users on Max plans care deeply about Opus allocation | LOW | Display Opus/Sonnet/Haiku separately in the detail popover. Color-code each. The API supports this data already |
| **Keyboard shortcut for quick access** | ClaudeUsageBar has Cmd+U; most others lack this. Power users expect keyboard-driven access | LOW | Global keyboard shortcut via `NSEvent.addGlobalMonitorForEvents`. Configurable in preferences. Default: Cmd+Shift+U |
| **Multi-profile support** | Claude Usage Tracker supports unlimited profiles. Valuable for users with work + personal accounts | MEDIUM | Store multiple OAuth tokens in Keychain. Profile switcher in popover. Not MVP but strong v1.x feature |

### Anti-Features (Commonly Requested, Often Problematic)

Features that seem good but create problems. Explicitly NOT building these.

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| **Multi-provider monitoring (Codex, Gemini, Copilot)** | ClaudeBar does this; seems like a competitive advantage | Splits focus, increases maintenance burden 5x, each provider has different APIs/auth/rate structures. ClaudeMon's value is being the BEST Claude monitor, not a mediocre everything monitor | Stay Claude-only. Do one thing extremely well. If demand is overwhelming, consider a plugin architecture in v3+ |
| **Conversation content access / reading chat history** | Users might want to see what conversations consumed the most tokens | Massive privacy concern. Accessing conversation content requires dangerous permissions. Anthropic may block access. Users would rightfully distrust an app reading their AI conversations | Show token counts and costs per session, never content. The official usage API provides this without content access |
| **Real-time token streaming / live counter during active use** | Watching tokens tick up in real-time feels satisfying | Requires hooking into active Claude sessions (impossible without being an IDE extension), or polling at sub-second intervals (wasteful, battery drain). The OAuth endpoint updates periodically, not in real-time | Refresh every 30 seconds. Show "last updated X seconds ago" timestamp. This is sufficient for planning decisions |
| **Custom widget designer / unlimited themes** | Users love customization | Enormous development surface for marginal value. Each theme must be tested across all three display modes. Maintenance nightmare | Offer three well-designed themes. Allow accent color customization. Quality over quantity |
| **Historical data export / CSV/JSON dump** | ClaudeMeter offers JSON export; power users want data portability | Adds complexity for a tiny fraction of users. Data format must be maintained as a contract. Version compatibility concerns | Defer to v2+. If built, keep it simple: JSON export of usage history. Not a priority for v1 |
| **Browser extension companion** | Could capture claude.ai usage more directly | Separate codebase (Chrome/Safari extension), different review processes, fragile (breaks on claude.ai redesigns), and the OAuth endpoint already captures claude.ai usage | The OAuth usage endpoint already tracks claude.ai usage. A browser extension adds zero data the API does not already provide |
| **Automatic model switching** | "When Opus runs low, auto-switch to Sonnet" | ClaudeMon is a monitor, not a proxy. Intercepting and modifying Claude requests is fragile, potentially TOS-violating, and architecturally wrong for a monitoring app | Suggest model switches via notifications. Let the user make the decision |
| **Team/org dashboard** | Enterprise use case for tracking team Claude usage | Anthropic already provides team analytics for Team/Enterprise plans. Competing with the vendor's own tooling is a losing game | Focus on individual users. Anthropic does not provide individual Pro/Max analytics -- that is the gap ClaudeMon fills |

## Feature Dependencies

```
[OAuth Authentication]
    |
    +--requires--> [5-Hour Session Display]
    |                  +--enhances--> [Reset Countdown Timers]
    |                  +--enhances--> [Threshold Alerts]
    |                  +--enhances--> [Burn Rate Projection]
    |
    +--requires--> [7-Day Weekly Display]
    |                  +--enhances--> [Usage Trend Graphs]
    |                  +--enhances--> [Smart Model Suggestions]
    |
    +--requires--> [Per-Model Breakdown (Opus/Sonnet/Haiku)]

[Menu Bar Display]
    +--requires--> [Click-to-Expand Popover]
    |                  +--enhances--> [Usage Trend Graphs]
    |                  +--enhances--> [Cost Tracking]

[Menu Bar Display] --independent--> [Notification Center Widget]
[Menu Bar Display] --independent--> [Floating Window]

[API Key Authentication]  (separate from OAuth)
    +--requires--> [API Usage Monitoring]
    |                  +--enhances--> [Cost Tracking with Model Breakdown]
    |                  +--enhances--> [Per-Call Breakdown] (v2+)

[Threshold Alerts] --requires--> [macOS Notification Permission]

[Usage Trend Graphs] --requires--> [Local Usage History Storage]
    +--enhances--> [Burn Rate Projection]

[Multi-Profile Support] --requires--> [Profile Switcher UI]
    +--requires--> [Per-Profile Keychain Storage]
```

### Dependency Notes

- **OAuth Authentication is the foundation:** Everything downstream depends on successfully authenticating with the undocumented OAuth endpoint. This is the riskiest dependency -- Anthropic could change or block this endpoint at any time.
- **API monitoring requires separate auth:** The Admin Usage Report API uses API keys, not OAuth tokens. Supporting both Claude Code/claude.ai (OAuth) and API usage (Admin API) requires two separate authentication flows.
- **Display modes are independent:** Menu bar, widget, and floating window can be built independently. Menu bar should come first as the core experience, with widget and floating window as additive display modes.
- **Usage history enables trends:** Sparkline graphs and burn rate projections require storing historical usage data locally. This is a prerequisite that should be built into the data layer from the start, even if the UI comes later.
- **Alerts require notification permission:** macOS requires explicit user permission for notifications. The app must handle the permission flow gracefully and degrade to visual-only alerts if denied.

## MVP Definition

### Launch With (v1.0)

Minimum viable product -- what is needed to validate the concept and be competitive with existing tools.

- [ ] **Menu bar icon with color-coded usage percentage** -- Core value prop; this is what users see 100% of the time
- [ ] **Click-to-expand popover** -- Shows 5-hour session, 7-day weekly, per-model breakdown, and reset timers
- [ ] **5-hour session usage + countdown** -- The #1 user pain point
- [ ] **7-day weekly usage + countdown** -- The #2 user pain point
- [ ] **Per-model breakdown (Opus/Sonnet/Haiku)** -- Low complexity, high value; data already in OAuth response
- [ ] **Threshold alerts (50/75/90%)** -- Prevent the "surprise lockout" that is the primary complaint
- [ ] **Configurable refresh interval** -- Default 30s, range 10-300s
- [ ] **Light/dark mode** -- macOS standard
- [ ] **Launch at login** -- Expected for monitoring utilities
- [ ] **Keyboard shortcut** -- Cmd+Shift+U for instant access
- [ ] **Preferences window** -- Alert thresholds, refresh interval, keyboard shortcut, launch at login

### Add After Validation (v1.x)

Features to add once core is working and initial users confirm value.

- [ ] **Usage trend sparklines / 7-day graph** -- Add when local history storage is proven stable
- [ ] **Burn rate projection** -- "You will hit your limit in ~X hours at current pace"
- [ ] **Notification Center widget** -- Second display mode, requires WidgetKit
- [ ] **Floating window mode** -- Third display mode, `NSPanel` with floating level
- [ ] **Third theme** -- After light/dark prove solid, add a focus/accessibility theme
- [ ] **Smart model switching suggestions** -- When Opus is running low, suggest Sonnet
- [ ] **Multi-profile support** -- For users with work + personal Claude accounts
- [ ] **API usage monitoring** -- Separate auth flow using Admin API key for `/v1/organizations/usage_report/messages`
- [ ] **Cost tracking** -- Calculate costs from token usage x per-token pricing

### Future Consideration (v2+)

Features to defer until product-market fit is established.

- [ ] **Agent team tracking** -- Monitor multi-agent Claude Code sessions (agent teams use ~7x tokens). Requires understanding of agent team session structure
- [ ] **Per-call / per-session breakdown** -- Detailed cost attribution per conversation. Requires either Claude Code log parsing or Agent SDK integration
- [ ] **Historical data export (JSON)** -- For power users who want to analyze usage externally
- [ ] **Usage predictions / ML-based forecasting** -- Go beyond linear burn rate to pattern-based predictions
- [ ] **Shortcuts/Automations integration** -- Expose usage data to macOS Shortcuts for user-defined workflows

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Menu bar usage percentage | HIGH | LOW | P1 |
| 5-hour session display + timer | HIGH | LOW | P1 |
| 7-day weekly display + timer | HIGH | LOW | P1 |
| Click-to-expand popover | HIGH | MEDIUM | P1 |
| Threshold notifications | HIGH | MEDIUM | P1 |
| Per-model breakdown | MEDIUM | LOW | P1 |
| Launch at login | MEDIUM | LOW | P1 |
| Light/dark mode | MEDIUM | LOW | P1 |
| Keyboard shortcut | MEDIUM | LOW | P1 |
| Preferences window | MEDIUM | MEDIUM | P1 |
| Usage trend graphs | HIGH | MEDIUM | P2 |
| Burn rate projection | HIGH | MEDIUM | P2 |
| Notification Center widget | MEDIUM | HIGH | P2 |
| Floating window | MEDIUM | MEDIUM | P2 |
| Smart model suggestions | MEDIUM | MEDIUM | P2 |
| Multi-profile support | MEDIUM | MEDIUM | P2 |
| API usage monitoring | MEDIUM | HIGH | P2 |
| Cost tracking | MEDIUM | MEDIUM | P2 |
| Third theme | LOW | LOW | P2 |
| Agent team tracking | MEDIUM | HIGH | P3 |
| Per-call breakdown | MEDIUM | HIGH | P3 |
| Historical data export | LOW | LOW | P3 |
| Usage predictions | LOW | HIGH | P3 |
| Shortcuts integration | LOW | MEDIUM | P3 |

**Priority key:**
- P1: Must have for launch
- P2: Should have, add in v1.x releases
- P3: Nice to have, future consideration for v2+

## Competitor Feature Analysis

| Feature | Claude Usage Tracker | ClaudeBar | ClaudeUsageBar | CCSeva | ClaudeMon (Our Plan) |
|---------|---------------------|-----------|----------------|--------|---------------------|
| Menu bar percentage | Yes, 5 icon styles | Yes | Yes | Yes | Yes, 3+ icon styles |
| 5-hour session | Yes | Yes | Yes | Yes | Yes |
| 7-day weekly | Yes | Yes | Yes | Yes | Yes |
| Reset timers | Yes | Yes | Yes | No | Yes |
| Per-model breakdown | Yes (Opus separate) | No | No | No | Yes |
| Threshold alerts | 75/90/95% | Warning/critical | 25/50/75/90% | 70/90% | 50/75/90% configurable |
| Trend graphs | No | No | No | 7-day basic | Yes, sparklines |
| Burn rate | No | No | No | Basic | Yes, with projection |
| Notification Center widget | No | No | No | No | Yes (v1.x) |
| Floating window | Detachable popover | No | No | No | Yes (v1.x) |
| Multi-provider | No | Yes (6 providers) | No | No | No (Claude-only by design) |
| Multi-profile | Yes, unlimited | No | No | No | Yes (v1.x) |
| Cost tracking | Extra usage only | No | No | Daily estimate | Yes, per-model |
| API monitoring | Via console | No | No | No | Yes (v1.x) |
| Smart suggestions | No | No | No | No | Yes (v1.x) |
| Themes | 5 icon styles + mono | 4 themes | Light/dark | Glassmorphism | 3 themes |
| Terminal integration | Yes, statusline | No | No | No | No (out of scope) |
| Keyboard shortcut | No | Cmd+D/Cmd+R | Cmd+U | No | Cmd+Shift+U |
| Privacy | Keychain, zero telemetry | Code-signed | No analytics | Auto-detect config | Keychain, zero telemetry |

## Data Sources and API Availability

Understanding what data is actually available is critical for scoping features:

| Data Source | Auth Method | What It Provides | Availability |
|-------------|-------------|------------------|--------------|
| OAuth Usage Endpoint (`/api/oauth/usage`) | Bearer token from Keychain | 5-hour utilization, 7-day utilization, 7-day Opus utilization, reset timestamps | All individual Claude users (Pro/Max). **Undocumented** -- could break |
| Claude Code `/cost` command | Local CLI | Session token counts, cost, duration | API-billed users only. Not relevant for subscribers |
| Claude Code `/stats` command | Local CLI | Usage patterns for subscribers | Subscription users only |
| Admin Usage Report API (`/v1/organizations/usage_report/messages`) | Admin API key | Per-model token breakdown, cost, time-bucketed data (1m/1h/1d) | Team/Enterprise/API Console admins only |
| Admin Claude Code Report (`/v1/organizations/usage_report/claude_code`) | Admin API key | Sessions, lines of code, commits, model breakdown with estimated cost | Team/Enterprise admins only |
| `~/.claude/.credentials.json` | File system | OAuth access token for API calls | Local file, requires file read permission |

**Critical risk:** The primary data source (OAuth usage endpoint) is undocumented. Every competitor relies on it. If Anthropic changes or blocks it, all these apps break simultaneously. ClaudeMon should architect for this possibility with graceful degradation.

## Sources

- [Claude Usage Tracker (GitHub)](https://github.com/hamed-elfayome/Claude-Usage-Tracker) -- Most feature-complete competitor, HIGH confidence
- [ClaudeBar (GitHub)](https://github.com/tddworks/ClaudeBar) -- Multi-provider competitor, HIGH confidence
- [ClaudeUsageBar](https://www.claudeusagebar.com/) -- Minimal competitor, HIGH confidence
- [ClaudeMeter](https://eddmann.com/ClaudeMeter/) -- JSON export competitor, HIGH confidence
- [SessionWatcher](https://www.sessionwatcher.com/) -- Paid competitor, MEDIUM confidence
- [Usagebar](https://usagebar.com) -- Pay-what-you-want competitor, MEDIUM confidence
- [CCSeva (GitHub)](https://github.com/Iamshankhadeep/ccseva) -- Analytics-focused competitor, HIGH confidence
- [Anthropic Usage Report API Docs](https://platform.claude.com/docs/en/api/admin/usage_report) -- Official API documentation, HIGH confidence
- [Claude Code Cost Management Docs](https://code.claude.com/docs/en/costs) -- Official cost tracking docs, HIGH confidence
- [Claude Agent SDK Cost Tracking](https://platform.claude.com/docs/en/agent-sdk/cost-tracking) -- Official SDK docs, HIGH confidence
- [Claude Code Usage Limits Statusline Guide](https://codelynx.dev/posts/claude-code-usage-limits-statusline) -- OAuth endpoint reverse engineering, MEDIUM confidence
- [iStat Menus 7 Review (TheSweetBits)](https://thesweetbits.com/tools/istat-menus-review/) -- Menu bar UX patterns, MEDIUM confidence
- [Stats macOS Monitor (GitHub)](https://github.com/exelban/stats) -- Open source menu bar patterns, HIGH confidence
- [DSFSparkline (GitHub)](https://github.com/dagronf/DSFSparkline) -- Sparkline library for macOS, HIGH confidence
- [SwiftUI Floating Window Guide (polpiella.dev)](https://www.polpiella.dev/creating-a-floating-window-using-swiftui-in-macos-15) -- Floating panel implementation, MEDIUM confidence
- [Hacker News Discussion](https://news.ycombinator.com/item?id=46544524) -- User feedback on Claude trackers, MEDIUM confidence
- [Claude devs usage limits complaints (The Register)](https://www.theregister.com/2026/01/05/claude_devs_usage_limits/) -- User pain points, MEDIUM confidence
- [Apple WidgetKit WWDC25](https://developer.apple.com/videos/play/wwdc2025/278/) -- Widget capabilities, HIGH confidence
- [Apple Notification Center Docs](https://developer.apple.com/documentation/notificationcenter) -- Widget development, HIGH confidence

---
*Feature research for: macOS Claude usage monitoring*
*Researched: 2026-02-11*
