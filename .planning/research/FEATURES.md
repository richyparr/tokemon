# Feature Landscape: Tokemon v2 Pro Features

**Domain:** macOS menu bar app monetization (licensing, analytics, export, sharing, multi-account)
**Researched:** 2026-02-14
**Confidence:** HIGH (LemonSqueezy docs verified, competitor patterns established)

**Context:** This research covers NEW features for v2 milestone. Existing v1 features (menu bar status, popover, floating window, OAuth/JSONL data sources, alerts, themes, settings) are already built.

---

## 1. Software Licensing & Trial Periods

### Table Stakes

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| License key entry dialog | Standard for paid desktop apps. Users expect a clean place to enter their key | LOW | Simple text field + "Activate" button. Show in Settings or on first launch |
| Online activation/validation | LemonSqueezy requires internet to validate license keys. Users expect this | LOW | POST to `https://api.lemonsqueezy.com/v1/licenses/activate`. Store `instance_id` for deactivation |
| Subscription status display | Users need to see "Pro" badge and expiration date. Builds confidence purchase worked | LOW | Show in Settings: "Tokemon Pro - Active until [date]" or "Free version" |
| Graceful degradation when expired | When subscription lapses, app should keep working in free mode, not crash or nag constantly | MEDIUM | Lock pro features, keep core monitoring. One tasteful "Renew" nudge per session max |
| License deactivation (for device transfer) | Users switch machines. Must be able to deactivate and reactivate elsewhere | LOW | Call LemonSqueezy deactivate endpoint with stored `instance_id` |

### Differentiators

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| 7-day full-featured trial | Industry research shows 7-day trials convert 20% better than 30-day trials due to urgency. Full features during trial lets users experience real value | MEDIUM | Store trial start date in UserDefaults (encrypted). After 7 days, lock pro features. Require no credit card upfront |
| Seamless upgrade from trial | "You have 3 days left" banner with one-click purchase link to LemonSqueezy checkout. No friction | LOW | Deep link: `https://[store].lemonsqueezy.com/buy/[product]?checkout[custom][instance_id]=...` |
| Offline grace period | 3-day offline grace before requiring revalidation. Power users work offline sometimes | MEDIUM | Cache last validation timestamp + status. Only require online validation every 72 hours |

### Anti-Features

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Aggressive nagware | Popups every launch, countdown timers, disabled features highlighted in red. Annoys users into refunds, not purchases | Subtle "Pro" badge, one banner per session max, features simply don't appear rather than being grayed out |
| Device limit enforcement with poor UX | "You have reached your device limit" with no way to manage devices. Leads to support tickets | Show list of activated devices in Settings with "Deactivate" buttons. Let users self-manage |
| Hardware fingerprinting | MAC address, serial number, etc. for license binding. Invasive, breaks on hardware changes | Use machine name + UUID as instance identifier (non-invasive). LemonSqueezy handles activation limits |

### Dependencies

- **Existing:** Settings window (built), Keychain storage (built for OAuth tokens)
- **New:** Internet connectivity check, LemonSqueezy API integration

---

## 2. Usage Analytics Dashboard

### Table Stakes

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Extended history view (30-90 days) | v1 has 7-day sparklines. Pro users want longer trends | MEDIUM | Expand HistoryStore to retain 90 days. Prune on app launch. Currently ~24 hours based on refresh interval |
| Daily usage breakdown | "Monday: 45%, Tuesday: 78%..." helps users understand patterns | LOW | Aggregate stored UsageDataPoint by date. SwiftUI chart with daily bars |
| Peak usage identification | "Your highest usage day was Thursday at 3pm". Helps users plan work | LOW | Calculate from stored history. Show in popover or dedicated analytics tab |

### Differentiators

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Usage heatmap (hour-of-day x day-of-week) | Visual pattern recognition. "I burn through limits on Monday mornings". GitHub contribution graph style | MEDIUM | 7x24 grid with color intensity. Requires hourly data bucketing |
| Model usage breakdown over time | "Last week: 60% Opus, 40% Sonnet. This week: 80% Opus". Shows model preference changes | LOW | Already have `sevenDayOpusUtilization` vs `sevenDayUtilization`. Track delta over time |
| Burn rate trends | "Your burn rate increased 15% this week". Early warning of limit pressure | MEDIUM | Store calculated burn rates. Show trend arrow (up/down) with percentage change |
| Comparative period view | "This week vs last week" or "This month vs last month". Common in analytics dashboards | MEDIUM | Requires enough history depth. Side-by-side or overlaid charts |

### Anti-Features

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Cloud sync of usage data | Privacy concern. Users chose local-only app for a reason | Keep all analytics local. Export if user wants backup |
| Gamification (achievements, badges) | Not appropriate for a utility app. Feels forced | Let the data speak. Users want insights, not badges |
| AI-powered insights | "We analyzed your usage and recommend..." Scope creep, maintenance burden, accuracy concerns | Show clear data. Let users draw conclusions |

### Dependencies

- **Existing:** HistoryStore (built), UsageDataPoint model (built), Charts (SwiftUI Charts used in v1)
- **New:** Extended retention period, date aggregation logic

---

## 3. PDF/CSV Report Export

### Table Stakes

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| CSV export of usage history | Universal format. Opens in Excel, Numbers, any spreadsheet. Power users expect this | LOW | Use SwiftCSVExport or write simple CSV manually. Columns: timestamp, percentage, source, model, tokens |
| Date range selection | "Export last 7 days" or "Export Jan 1 - Jan 31". Users need control over what to export | LOW | Date pickers in export dialog |
| File save dialog | Standard macOS NSSavePanel. Users choose where to save | LOW | Native macOS API |

### Differentiators

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| PDF report with charts | Professional-looking summary. "January Usage Report" with embedded sparklines | HIGH | Use TPPDF or Core Graphics + PDFKit. Include: summary stats, trend chart, model breakdown |
| Scheduled automatic export | "Export weekly summary every Monday at 8am". For users who track in spreadsheets | HIGH | Requires background execution, file path persistence. May conflict with sandboxing |
| Multiple format options | CSV, JSON, PDF. Let user choose | MEDIUM | JSON is trivial (Codable). PDF is the complex one |

### Anti-Features

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Cloud export (Google Sheets, Dropbox) | Scope creep. Each integration is a maintenance burden. Privacy concerns | Export to local file. User can upload wherever they want |
| Email reports | Requires email configuration, SMTP handling, potential privacy issues | Export PDF, user can email it themselves |
| Real-time streaming export | Continuous CSV append. Complex, edge cases, file locking issues | On-demand export. User clicks button, gets file |

### Dependencies

- **Existing:** HistoryStore with usage data, Charts for visualization
- **New:** CSV/PDF generation libraries, NSSavePanel integration

---

## 4. Shareable Social Cards/Badges

### Table Stakes

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Copy image to clipboard | One click, paste anywhere. Most common sharing workflow | LOW | NSPasteboard with NSImage. SwiftUI view rendered to image |
| Basic share sheet | Native macOS sharing (Twitter, Messages, Mail, AirDrop) | LOW | NSSharingServicePicker with rendered image |

### Differentiators

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| "Weekly Wrap" card | "This week I used 847,000 tokens with Claude". GitHub Wrapped/Spotify Wrapped style. Perfect for Twitter/LinkedIn | MEDIUM | Template-based image generation. Show: total tokens, primary model, streak days, hours saved estimate |
| Customizable card styles | Multiple visual templates (minimal, colorful, dark mode). User picks their aesthetic | MEDIUM | 3-4 SwiftUI templates. Render to image with ImageRenderer |
| Usage milestones | "1M tokens milestone" badge. Automatically generated when milestones hit | LOW | Track cumulative tokens. Generate badge image when thresholds crossed (100k, 500k, 1M, 5M) |
| "Powered by Claude" badge | Static badge user can add to their GitHub README or website. Links back to Claude | LOW | Pre-rendered image with download button |

### Anti-Features

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Auto-posting to social | Never post on user's behalf without explicit action. Privacy nightmare | Generate image + copy to clipboard. User posts manually |
| Leaderboards | "You're in the top 5% of Claude users". No data to support this claim. Feels competitive in a bad way | Focus on personal stats, not comparisons |
| Live/embedded widgets | "Embed this in your website". Requires server, API, ongoing maintenance | Static images. User regenerates when they want fresh stats |

### Dependencies

- **Existing:** UsageSnapshot with all relevant data, Theme system
- **New:** SwiftUI ImageRenderer, card template designs, clipboard integration

---

## 5. Multi-Account Management

### Table Stakes

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Account list in Settings | Show all connected accounts with status (active, needs auth, error) | LOW | List view with account name, auth status, last sync time |
| Add/remove accounts | Users have work + personal Claude accounts | MEDIUM | Re-use existing OAuth flow. Store multiple tokens in Keychain with account identifier |
| Account switcher in popover | Quick way to see different account's usage without going to Settings | LOW | Dropdown or segmented control at top of popover |

### Differentiators

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Aggregate view | "Total across all accounts: 73%". Single number when you have multiple accounts | MEDIUM | Weight by plan type? Or just show highest? Need UX research |
| Per-account alerts | "Work account at 80%" separate from "Personal account at 40%" | MEDIUM | AlertManager needs account context. Each account can have different thresholds |
| Account naming/nicknames | "Work" and "Personal" instead of email addresses. Cleaner UI | LOW | Store nickname alongside credentials in Keychain |
| Account color coding | Each account gets a color. Visual differentiation in charts/menu bar | LOW | 5-6 predefined colors. User selects per account |

### Anti-Features

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Unlimited accounts | Supporting 10+ accounts adds complexity for marginal use case | Limit to 5 accounts. Covers 99% of use cases (work, personal, client1, client2, client3) |
| Team account sharing | "Share this account with your team". Security nightmare, credential sharing | Each user has their own Tokemon + credentials. This is a personal tool |
| Account sync across devices | "Your accounts sync via iCloud". Syncing credentials is risky, iCloud Keychain issues | Each device configured independently. Simple, safe |

### Dependencies

- **Existing:** OAuth flow, TokenManager, Keychain storage
- **New:** Multi-credential Keychain storage, account-aware UsageMonitor, account switcher UI

---

## Feature Dependencies Map

```
[Licensing System]
    |
    +-- enables --> [Pro-only Features]
    |                   +-- unlocks --> [Extended Analytics (30-90 day)]
    |                   +-- unlocks --> [PDF Export]
    |                   +-- unlocks --> [Social Cards]
    |                   +-- unlocks --> [Multi-Account (3+ accounts)]
    |
    +-- requires --> [Settings Window] (already built)
    +-- requires --> [Internet Connectivity Check] (new)
    +-- requires --> [LemonSqueezy API Client] (new)

[Extended Analytics]
    +-- requires --> [HistoryStore expansion] (modify existing)
    +-- requires --> [New chart views] (new)

[PDF Export]
    +-- requires --> [PDF generation library] (TPPDF or PDFKit)
    +-- requires --> [Chart rendering to image] (ImageRenderer)
    +-- requires --> [NSSavePanel integration] (new)

[CSV Export]
    +-- requires --> [CSV serialization] (trivial)
    +-- requires --> [NSSavePanel integration] (shared with PDF)

[Social Cards]
    +-- requires --> [SwiftUI ImageRenderer] (macOS 13+)
    +-- requires --> [NSSharingServicePicker] (existing macOS API)
    +-- requires --> [Card template designs] (new)

[Multi-Account]
    +-- requires --> [Keychain multi-credential storage] (extend existing)
    +-- requires --> [Account-aware UsageMonitor] (modify existing)
    +-- requires --> [Account switcher UI] (new)
    +-- requires --> [Per-account alerts] (extend AlertManager)
```

---

## MVP Recommendation for v2

### Launch With (v2.0)

| Feature | Rationale | Effort |
|---------|-----------|--------|
| LemonSqueezy license activation | Required for monetization. Blocking for any paid features | MEDIUM |
| 7-day trial | Lets users experience Pro before buying. Standard practice | LOW |
| CSV export | Low effort, high perceived value. Power users expect data portability | LOW |
| Extended history (30 days) | Differentiates Pro from Free. Visible upgrade value | LOW |
| Multi-account (2 accounts) | Work + personal is the minimum viable use case | MEDIUM |
| Basic social card | One "weekly wrap" template. Copy to clipboard. Ship fast | LOW |

### Add After Validation (v2.x)

| Feature | Rationale | Effort |
|---------|-----------|--------|
| PDF export | Higher effort than CSV. Wait for user demand signal | HIGH |
| Usage heatmap | Cool visualization but not critical for launch | MEDIUM |
| More social card templates | Add based on user feedback on which styles they want | LOW |
| Multi-account (5 accounts) | Only if 2-account limit causes complaints | LOW |
| Account color coding | Polish feature. Add after core multi-account is stable | LOW |

### Defer (v3+)

| Feature | Rationale | Effort |
|---------|-----------|--------|
| Scheduled automatic export | Complex, sandboxing issues, edge cases | HIGH |
| Aggregate multi-account view | UX unclear (how to weight different plans?) | MEDIUM |
| Usage milestones/badges | Gamification is polarizing. Test user appetite first | MEDIUM |

---

## Free vs Pro Feature Matrix

| Feature | Free | Pro |
|---------|------|-----|
| Menu bar usage display | Yes | Yes |
| Popover with details | Yes | Yes |
| Floating window | Yes | Yes |
| 5-hour + 7-day usage | Yes | Yes |
| Reset countdown timers | Yes | Yes |
| Basic alerts (50/75/90%) | Yes | Yes |
| 7-day usage history | Yes | Yes |
| Themes (3) | Yes | Yes |
| **Extended history (30-90 days)** | No | Yes |
| **Usage heatmap** | No | Yes |
| **CSV export** | No | Yes |
| **PDF export** | No | Yes |
| **Social cards** | No | Yes |
| **Multi-account (2+)** | 1 account | 5 accounts |
| **Per-account alerts** | No | Yes |

**Free version remains fully functional** for single-account usage monitoring. Pro adds analytics depth, export, sharing, and multi-account -- features that power users and professionals value.

---

## Complexity Assessment Summary

| Feature Area | Overall Complexity | Key Challenge |
|--------------|-------------------|---------------|
| Licensing | MEDIUM | LemonSqueezy API integration, offline handling, graceful degradation |
| Extended Analytics | LOW-MEDIUM | Storage expansion, chart views, performance with more data |
| CSV Export | LOW | Trivial serialization |
| PDF Export | HIGH | PDF library integration, chart rendering, layout |
| Social Cards | MEDIUM | Image rendering, template design, share sheet integration |
| Multi-Account | MEDIUM | Keychain multi-credential, account-aware state, UI for switching |

---

## Sources

### Licensing & Trials
- [Lemon Squeezy Licensing Docs](https://docs.lemonsqueezy.com/help/licensing) - Official documentation, HIGH confidence
- [Lemon Squeezy License API Guide](https://docs.lemonsqueezy.com/guides/tutorials/license-keys) - API implementation details, HIGH confidence
- [TrialLicensing Swift Framework (GitHub)](https://github.com/CleanCocoa/TrialLicensing) - Swift trial period implementation patterns, MEDIUM confidence
- [SaaS Free Trial Length Research (Ordway)](https://ordwaylabs.com/blog/saas-free-trial-length-conversion/) - 7-day vs 14-day conversion data, MEDIUM confidence
- [Perfect Trial Length (Encharge)](https://encharge.io/perfect-saas-trial-length/) - Industry best practices, MEDIUM confidence

### Export & Analytics
- [PDFKit Apple Docs](https://developer.apple.com/documentation/pdfkit) - Native PDF framework, HIGH confidence
- [TPPDF GitHub](https://github.com/techprimate/TPPDF) - Swift PDF builder for macOS, HIGH confidence
- [SwiftCSVExport GitHub](https://github.com/vigneshuvi/SwiftCSVExport) - CSV export library, MEDIUM confidence

### Social Sharing
- [NSSharingServicePicker Apple Docs](https://developer.apple.com/documentation/appkit/nssharingservicepicker) - Native share sheet, HIGH confidence
- [GitHub Readme Streak Stats](https://github.com/DenverCoder1/github-readme-streak-stats) - Developer stats card patterns, HIGH confidence
- [SwiftUI ShareLink (Hacking with Swift)](https://www.hackingwithswift.com/books/ios-swiftui/sharing-an-image-using-sharelink) - SwiftUI sharing patterns, HIGH confidence

### Multi-Account UX
- [Account Switcher Design Patterns (UX Power Tools)](https://medium.com/ux-power-tools/ways-to-design-account-switchers-app-switchers-743e05372ede) - UI/UX patterns, MEDIUM confidence
- [Account Switching UX (UX Power Tools)](https://medium.com/ux-power-tools/breaking-down-the-ux-of-switching-accounts-in-web-apps-501813a5908b) - Detailed UX analysis, MEDIUM confidence

---
*Feature research for: Tokemon v2 Pro Features*
*Researched: 2026-02-14*
