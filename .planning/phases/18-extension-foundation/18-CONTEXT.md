# Phase 18: Extension Foundation - Context

**Gathered:** 2026-02-19
**Status:** Ready for planning

<domain>
## Phase Boundary

Scaffold a working Raycast extension with credential handling and custom branding. Covers project setup, dev tooling, token entry/validation, branding assets, and the initial command structure. Dashboard UI, menu bar, profiles, and alerts are separate phases (19-21).

</domain>

<decisions>
## Implementation Decisions

### Setup wizard flow
- Use Raycast preferences for the token field (password type) AND a dedicated setup command that guides users there
- First-run experience: Claude's discretion on whether to show a welcome screen or jump straight to setup
- Token validation: Claude's discretion on live validation vs save-then-check (pick best Raycast UX pattern)
- Error handling on invalid/expired token: Claude's discretion on inline error vs toast (use Raycast-native pattern)

### Extension branding
- Icon: Reuse the existing Tokemon macOS app icon (or close variant) for brand consistency
- Command naming: "tokemon" must be lowercase; Claude decides the rest based on Raycast store conventions
- Subtitle: Claude's discretion — pick most effective subtitle for discoverability
- Identity: Standalone with nod — works independently without the macOS app, but references "by tokemon" and links to the full app for power features

### Token acquisition
- Guidance level: Claude's discretion — tailor for the Raycast developer audience
- Context/explanation: Claude's discretion — balance brevity with necessary context
- Token source: Claude's discretion — use whatever approach the macOS app already uses for OAuth token discovery
- Cross-app import: Claude's discretion — weigh complexity vs value of detecting Tokemon.app credentials

### Dev experience
- Project location: Claude's discretion — pick based on development and Raycast publishing needs
- Code style: Prettier + ESLint with strict TypeScript rules
- Code sharing with Swift app: Claude's discretion — pick based on maintainability
- Dependencies: Claude's discretion — use what the extension actually needs, no more

### Claude's Discretion
Broad discretion granted across most implementation details. Key locked decisions are:
- Raycast preferences + setup command (both)
- Tokemon app icon for branding
- Lowercase "tokemon" in command names
- Standalone with nod identity
- Prettier + ESLint for code style

</decisions>

<specifics>
## Specific Ideas

- "tokemon" must always be lowercase in command names and branding
- The extension should feel like a standalone product that happens to be from the tokemon ecosystem
- Existing Tokemon app icon should carry over for visual consistency in the Raycast grid

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 18-extension-foundation*
*Context gathered: 2026-02-19*
