# Feature Landscape: Tokemon v4.0 Raycast Extension

**Domain:** Raycast extension for Claude usage monitoring
**Researched:** 2026-02-18
**Confidence:** HIGH (official Raycast docs verified, competitor extensions analyzed)

**Context:** This research covers the Raycast extension milestone. Tokemon.app already provides: usage dashboard (session %, weekly %, reset timer), menu bar icon, alert configuration, multi-profile support. The extension is standalone -- fetches data directly via OAuth, works without Tokemon.app running.

---

## 1. Raycast UI Patterns for Claude Usage

### Primary Components

| Component | Best For | Tokemon Use Case | Notes |
|-----------|----------|------------------|-------|
| **List** | Structured data with search, selection, actions | Profile list, alert configuration list | Built-in filtering, accessories for status badges |
| **List.Item.Detail** | Right-side panel with markdown + metadata | Usage detail view when profile selected | Show session %, weekly %, reset timers in metadata panel |
| **Detail** | Standalone markdown + metadata view | Dedicated dashboard command | Full-width usage visualization |
| **MenuBarExtra** | Persistent menu bar presence | Usage percentage in menu bar | Quick access without invoking Raycast |
| **Form** | User input collection | Alert threshold configuration, profile add | Validation, drafts, dropdown for profile selection |
| **Grid** | Image-focused content | Not applicable | Tokemon is data-focused, not visual |

### Data Fetching Patterns

| Hook | Purpose | Tokemon Use Case |
|------|---------|------------------|
| **useCachedPromise** | Stale-while-revalidate caching | Fetch OAuth usage data, show cached immediately, refresh in background |
| **useCachedState** | Persistent state between command runs | Store selected profile, alert thresholds |
| **useLocalStorage** | Key-value persistence | Profile configurations, alert settings |
| **Background Refresh** | Scheduled command execution | Menu bar command updates every 5m |

### Preference Patterns

| Type | Use Case | Notes |
|------|----------|-------|
| **textfield** | Custom CLI path | For users with non-standard Claude Code installs |
| **dropdown** | Default profile selection | List of configured profiles |
| **checkbox** | Enable/disable features | Auto-refresh toggle, alert sounds |
| **password** | Manual API key entry | Fallback if keychain read fails |

---

## 2. Table Stakes

Features users expect from a Claude usage Raycast extension. Missing = users choose competitor.

| Feature | Why Expected | Complexity | Raycast Pattern | Notes |
|---------|--------------|------------|-----------------|-------|
| **Current session usage (%)** | Core value prop. ccusage, raycast-llm-usage, ClaudeCast all show this | LOW | MenuBarExtra title, List.Item accessory | Must be prominent, updated on each refresh |
| **Weekly usage (%)** | Second most important metric after session | LOW | Metadata panel, accessory text | Show alongside session % |
| **Reset countdown timer** | Users need to know when limits reset | LOW | Metadata label, subtitle | "Resets in 3h 42m" or "Resets at 2:15 PM" |
| **Menu bar icon with usage** | ccusage and raycast-llm-usage both have this | LOW | MenuBarExtra with title showing % | Can show "72%" or gauge emoji |
| **Manual refresh action** | Users want to force-update | LOW | Action in ActionPanel | Standard Cmd+R shortcut |
| **Loading states** | Expected UX polish | LOW | isLoading prop on List/Detail | Show during OAuth fetch |
| **Error handling** | Auth failures, network issues | MEDIUM | Toast notifications, EmptyView | "Session expired - re-authenticate" |
| **Pace indicator** | Am I ahead/behind/on-track? | LOW | Color-coded accessory tag | Green/Yellow/Red based on burn rate |

### Competitive Parity Requirements

Based on analysis of ccusage, raycast-llm-usage, and ClaudeCast:

| Competitor Feature | Must Match? | Notes |
|-------------------|-------------|-------|
| Session/weekly/Sonnet usage breakdown | YES | All three competitors show this |
| Cost estimation | NICE-TO-HAVE | ClaudeCast and ccusage show costs, raycast-llm-usage does too |
| Model breakdown (Opus/Sonnet/Haiku) | NICE-TO-HAVE | ccusage shows this prominently |
| Menu bar integration | YES | raycast-llm-usage is menu-bar-first |
| Background auto-refresh | YES | All competitors do 5-minute intervals |
| Keyboard shortcut actions | YES | Raycast users expect keyboard-first UX |

---

## 3. Differentiators

Features that set Tokemon apart. Not expected, but valuable.

| Feature | Value Proposition | Complexity | Raycast Pattern | Notes |
|---------|-------------------|------------|-----------------|-------|
| **Multi-profile support** | Tokemon.app's key differentiator. Work/personal/client accounts | MEDIUM | List with profile switcher, Form for add | Unique vs. competitors (ccusage/raycast-llm-usage are single-profile) |
| **Profile quick-switch** | Change active profile without leaving current command | LOW | List.Dropdown as searchBarAccessory | Seamless UX for multi-account users |
| **Alert configuration from Raycast** | Set 50%/75%/90% thresholds without opening Tokemon.app | MEDIUM | Form with validation, stored in LocalStorage | None of the competitors have this |
| **Sync with Tokemon.app** | Use same profiles/settings as native app (optional) | HIGH | Read shared data via file/IPC | Could be deferred -- standalone is simpler |
| **Time-to-limit prediction** | "At current pace, you'll hit limit in 2.3 hours" | MEDIUM | Metadata label with calculation | ClaudeCast has "pace prediction", this is more specific |
| **Cost tracking** | Today's estimated cost, 30-day total | MEDIUM | Metadata section, List.Item subtitle | ccusage does this well, match or exceed |
| **Quick Actions** | Open Tokemon.app, open Claude.ai, copy stats to clipboard | LOW | ActionPanel with standard actions | Polish feature, low effort |
| **Notification integration** | macOS notifications when thresholds crossed | MEDIUM | showHUD, system notifications | Requires background refresh running |

### Unique Positioning vs. Competitors

| Tokemon Advantage | How to Leverage |
|-------------------|-----------------|
| Native Swift app companion | Offer "Open in Tokemon" action for detailed analytics |
| Multi-profile architecture | Prominently feature profile switching in all commands |
| Established Pro features | Tease Pro features with "Available in Tokemon Pro" |
| Brand recognition | Consistent design language with Tokemon.app |

---

## 4. Anti-Features

Features to explicitly NOT build. Learned from competitor patterns and Raycast best practices.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| **External CLI dependency** | ccusage requires npx/bunx runtime. Adds friction, version issues, PATH problems | Direct OAuth API calls. Tokemon extension works standalone |
| **Excessive commands** | ClaudeCast has 10+ commands (Ask Claude, Project Launcher, Session Browser...). Scope creep | 3-4 focused commands: Dashboard, Menu Bar, Configure Alerts, Switch Profile |
| **AI integration** | ClaudeCast "Ask Claude Code" duplicates Raycast AI. Not our domain | Focus on monitoring, not Claude interaction |
| **Project/session management** | ClaudeCast browses sessions, launches projects. Different product | Tokemon monitors usage, not manages sessions |
| **Cloud sync** | Privacy concern. Users trust local-only data | Keep all data local. Export if needed |
| **Real-time websocket updates** | Over-engineering. 5-minute intervals are fine | Background refresh at configurable interval |
| **Complex visualizations** | Raycast UI is text-focused. Charts don't render well | Use text + emoji + color for status. Link to Tokemon.app for charts |
| **Embedded web views** | Against Raycast design philosophy | Native Raycast components only |

### Lessons from Competitor Reviews

| Competitor | Known Issue | Avoid |
|------------|-------------|-------|
| ccusage | "ccusage CLI not found" errors | Don't depend on external CLI |
| raycast-llm-usage | "Session expired" with no clear fix | Clear re-auth flow with instructions |
| ClaudeCast | Feature bloat, slow to load | Keep command count low, fast load |

---

## 5. Competitive Analysis

### Competitor Feature Matrix

| Feature | ccusage | raycast-llm-usage | ClaudeCast | **Tokemon** (planned) |
|---------|---------|-------------------|------------|----------------------|
| **Session usage %** | Yes | Yes | Yes | **Yes** |
| **Weekly usage %** | Yes | Yes | Yes | **Yes** |
| **Menu bar command** | Yes | Yes (primary) | Yes | **Yes** |
| **Cost estimation** | Yes | Yes | Yes | **Yes** |
| **Model breakdown** | Yes | No | Partial | **Yes** |
| **Multi-profile** | No | No | No | **YES (unique)** |
| **Alert config** | No | No | No | **YES (unique)** |
| **Native app companion** | No | No | No | **YES (unique)** |
| **Standalone (no CLI)** | No (needs ccusage CLI) | Yes | Yes | **Yes** |
| **Background refresh** | Yes | Yes | Yes | **Yes** |
| **Installs** | 5,981 | Unknown | Unknown | N/A |

### Competitive Positioning

**ccusage (nyatinte)**
- Strengths: Mature, detailed model breakdown, cost tracking
- Weakness: Requires external CLI tool, single profile only
- Tokemon opportunity: No CLI dependency, multi-profile

**raycast-llm-usage (markhudsonn)**
- Strengths: Menu-bar-first, clean UX, direct OAuth
- Weakness: Single profile, no alert configuration
- Tokemon opportunity: Profile switching, configurable alerts

**ClaudeCast (qazi0)**
- Strengths: Feature-rich, project management, agentic workflows
- Weakness: Feature bloat, slow load, different focus (AI assistant vs. monitoring)
- Tokemon opportunity: Focused monitoring tool, fast and lightweight

**Tokemon Differentiation Summary:**
1. Multi-profile support (unique)
2. Alert configuration from Raycast (unique)
3. Native app companion with deeper analytics (unique)
4. No CLI dependency (matches raycast-llm-usage)
5. Focused on monitoring, not AI interaction (clarity vs. ClaudeCast)

---

## 6. Feature Dependencies

```
[OAuth Data Fetching]
    +-- required by --> [Dashboard Command]
    +-- required by --> [Menu Bar Command]
    +-- required by --> [Alert Checking]

[Profile Storage (LocalStorage)]
    +-- required by --> [Multi-Profile Support]
    +-- required by --> [Profile Quick-Switch]

[Alert Configuration (LocalStorage)]
    +-- required by --> [Alert Notifications]
    +-- requires --> [Form Command]

[Background Refresh (manifest interval)]
    +-- required by --> [Menu Bar Auto-Update]
    +-- required by --> [Alert Threshold Checking]
```

### Phase Ordering Implications

1. **Foundation**: OAuth fetching, single-profile display (List + Detail)
2. **Menu Bar**: MenuBarExtra command with background refresh
3. **Multi-Profile**: LocalStorage for profiles, profile switcher UI
4. **Alerts**: Form for configuration, notification on threshold breach

---

## 7. Command Structure Recommendation

### Core Commands (MVP)

| Command | Mode | Description | Complexity |
|---------|------|-------------|------------|
| **Usage Dashboard** | `view` | List with current session %, weekly %, reset timers | LOW |
| **Usage in Menu Bar** | `menu-bar` | Persistent usage % in menu bar with dropdown | MEDIUM |

### Extended Commands (v1.x)

| Command | Mode | Description | Complexity |
|---------|------|-------------|------------|
| **Configure Alerts** | `view` | Form to set threshold percentages | LOW |
| **Switch Profile** | `view` | List of profiles with quick-switch action | LOW |

### Deferred Commands (v2+)

| Command | Mode | Description | Rationale |
|---------|------|-------------|-----------|
| **Open Tokemon** | `no-view` | Opens Tokemon.app | Requires app detection |
| **Export Stats** | `no-view` | Copy current stats to clipboard | Nice-to-have |

---

## 8. Raycast Store Metadata

### Required Assets

| Asset | Specification | Notes |
|-------|---------------|-------|
| Extension icon | 512x512 PNG | Match Tokemon.app icon or complementary |
| Command icons | 64x64 PNG | One per command |
| Screenshots | 1660x1200 | Dashboard view, menu bar, alert config |

### Store Listing Strategy

**Title:** "Tokemon - Claude Usage Monitor"
**Subtitle:** "Track Claude Code usage with multi-profile support"
**Keywords:** claude, usage, monitoring, tokens, api, anthropic, llm, menu bar

**Description highlights:**
- "Works standalone - no CLI tools required"
- "Multi-profile support for work/personal accounts"
- "Configurable alerts before hitting limits"
- "Companion to Tokemon.app for deeper analytics"

---

## 9. MVP Feature Set

### Launch With (v1.0)

| Feature | Rationale | Effort |
|---------|-----------|--------|
| Usage Dashboard command | Core value prop | LOW |
| Menu Bar command | Expected feature, competitor parity | MEDIUM |
| Direct OAuth (no CLI) | Differentiation from ccusage | MEDIUM |
| Session/weekly/reset display | Table stakes | LOW |
| Pace indicator | Low effort, high value | LOW |
| Manual refresh action | Expected UX | LOW |

### Add After Launch (v1.x)

| Feature | Rationale | Effort |
|---------|-----------|--------|
| Multi-profile support | Key differentiator | MEDIUM |
| Alert configuration | Unique feature | MEDIUM |
| Cost tracking | Competitive parity | LOW |
| Model breakdown | Power user feature | LOW |

### Defer (v2+)

| Feature | Rationale | Effort |
|---------|-----------|--------|
| Tokemon.app sync | Complex IPC, not essential | HIGH |
| Notification Center alerts | Requires background infrastructure | MEDIUM |
| Usage forecasting | Can link to Tokemon.app for now | MEDIUM |

---

## Sources

### Raycast Official Documentation
- [List Component](https://developers.raycast.com/api-reference/user-interface/list) - List props, filtering, pagination, accessories
- [Detail Component](https://developers.raycast.com/api-reference/user-interface/detail) - Markdown rendering, metadata panel
- [MenuBarExtra](https://developers.raycast.com/api-reference/menu-bar-commands) - Menu bar command implementation
- [Form Component](https://developers.raycast.com/api-reference/user-interface/form) - Form fields, validation, drafts
- [Preferences API](https://developers.raycast.com/api-reference/preferences) - Extension and command preferences
- [LocalStorage API](https://developers.raycast.com/api-reference/storage) - Persistent key-value storage
- [OAuth API](https://developers.raycast.com/api-reference/oauth) - PKCE flow, token management
- [Background Refresh](https://developers.raycast.com/information/lifecycle/background-refresh) - Scheduled command execution
- [Best Practices](https://developers.raycast.com/information/best-practices) - Error handling, loading states, caching
- [useCachedPromise](https://developers.raycast.com/utilities/react-hooks/usecachedpromise) - Stale-while-revalidate data fetching

### Competitor Analysis
- [ccusage Raycast Extension](https://www.raycast.com/nyatinte/ccusage) - Feature set, user adoption (5,981 installs)
- [raycast-llm-usage GitHub](https://github.com/markhudsonn/raycast-llm-usage) - Implementation details, OAuth approach
- [ClaudeCast Raycast Extension](https://www.raycast.com/qazi0/claudecast) - Feature breadth, scope comparison

### Additional Resources
- [Actions API](https://developers.raycast.com/api-reference/user-interface/actions) - Built-in action types
- [Grid Component](https://developers.raycast.com/api-reference/user-interface/grid) - When to use Grid vs List
- [Toast API](https://developers.raycast.com/api-reference/feedback/toast) - User feedback patterns

---
*Feature research for: Tokemon v4.0 Raycast Extension*
*Researched: 2026-02-18*
