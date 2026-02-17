---
phase: 16-webhook-alerts-pro
plan: 01
subsystem: services
tags: [webhook, slack, discord, block-kit, embed, http-post, alerts]

# Dependency graph
requires:
  - phase: 02-alerts-notifications
    provides: AlertManager threshold logic pattern (window reset detection, once-per-level firing)
  - phase: 06-licensing-foundation
    provides: ProFeature enum and FeatureAccessManager for gating
  - phase: 11-multi-profile
    provides: Profile model and activeProfileId for message context
provides:
  - WebhookConfig model with Slack/Discord URLs, enabled flags, and message template preferences
  - WebhookManager service with Slack Block Kit and Discord embed payload formatting
  - ProFeature.webhookAlerts case for UI gating
  - Constants.webhookConfigKey for UserDefaults persistence
affects: [16-02 webhook settings UI, alert integration wiring]

# Tech tracking
tech-stack:
  added: []
  patterns: [fire-and-forget webhook delivery, static method payload formatting for Sendable safety]

key-files:
  created:
    - Tokemon/Models/WebhookConfig.swift
    - Tokemon/Services/WebhookManager.swift
  modified:
    - Tokemon/Services/FeatureAccessManager.swift
    - Tokemon/Utilities/Constants.swift

key-decisions:
  - "Static payload methods for Sendable safety in Task.detached context"
  - "Profile name read from UserDefaults directly (no ProfileManager dependency) for loose coupling"
  - "WebhookError enum with LocalizedError conformance for UI-friendly test feedback"

patterns-established:
  - "Webhook fire-and-forget: sendWebhook dispatches Task.detached, only testWebhook throws"
  - "Static payload builders accept config parameter for safe cross-isolation transfer"

# Metrics
duration: 3min
completed: 2026-02-17
---

# Phase 16 Plan 01: Webhook Alerts Model & Service Summary

**WebhookConfig model with Slack/Discord template customization and WebhookManager with Block Kit and embed payload formatting**

## Performance

- **Duration:** 3 min
- **Started:** 2026-02-17T14:27:26Z
- **Completed:** 2026-02-17T14:30:33Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- WebhookConfig model with full Slack/Discord configuration, template field flags, and UserDefaults persistence
- WebhookManager service with threshold-based firing that mirrors AlertManager's once-per-level-per-window logic
- Slack Block Kit formatted payloads with header, section fields, and optional context blocks
- Discord embed payloads with color-coded severity, inline fields, footer, and ISO 8601 timestamps
- Test webhook capability for URL verification with throwing error handling
- ProFeature.webhookAlerts case ready for UI gating

## Task Commits

Each task was committed atomically:

1. **Task 1: WebhookConfig model and Constants** - `ffb7a5d` (feat)
2. **Task 2: WebhookManager service and ProFeature case** - `e3ed59b` (feat)

## Files Created/Modified
- `Tokemon/Models/WebhookConfig.swift` - Codable/Sendable config with URLs, enabled flags, template fields, computed helpers, save/load
- `Tokemon/Services/WebhookManager.swift` - Observable service with Slack Block Kit and Discord embed formatting, threshold logic, test webhook
- `Tokemon/Services/FeatureAccessManager.swift` - Added webhookAlerts ProFeature case with icon
- `Tokemon/Utilities/Constants.swift` - Added webhookConfigKey for UserDefaults storage

## Decisions Made
- Used static methods for Slack/Discord payload formatting to satisfy Swift 6 Sendable requirements in Task.detached context
- Read active profile name directly from UserDefaults (Profile JSON decode) rather than injecting ProfileManager dependency -- keeps WebhookManager loosely coupled
- WebhookError enum with LocalizedError conformance provides user-friendly messages for testWebhook UI feedback

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- WebhookConfig and WebhookManager ready for Plan 02 (Settings UI + AlertManager integration)
- ProFeature.webhookAlerts case available for feature gating in settings view
- testWebhook method ready for "Send Test" button integration

## Self-Check: PASSED

- [x] WebhookConfig.swift exists
- [x] WebhookManager.swift exists
- [x] 16-01-SUMMARY.md exists
- [x] Commit ffb7a5d found
- [x] Commit e3ed59b found

---
*Phase: 16-webhook-alerts-pro*
*Completed: 2026-02-17*
