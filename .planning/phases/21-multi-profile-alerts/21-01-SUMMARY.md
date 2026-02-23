---
phase: 21-multi-profile-alerts
plan: 01
subsystem: tokemon-raycast
tags: [multi-profile, storage, token-resolution, raycast, typescript]
dependency_graph:
  requires: [phase-20-menu-bar-command]
  provides: [profile-management-command, active-profile-token-resolution]
  affects: [index.tsx, menu-bar.tsx, setup.tsx]
tech_stack:
  added: [useLocalStorage (profile CRUD), useCachedState (cross-command active profile sync)]
  patterns: [active-profile-with-preference-fallback, unconditional-hooks-before-returns]
key_files:
  created:
    - tokemon-raycast/src/profiles.tsx
  modified:
    - tokemon-raycast/src/types.ts
    - tokemon-raycast/src/index.tsx
    - tokemon-raycast/src/menu-bar.tsx
    - tokemon-raycast/src/setup.tsx
    - tokemon-raycast/package.json
key_decisions:
  - useCachedState for activeProfileId enables cross-command sync without LocalStorage polling
  - extractToken called at add-time so stored token is always a raw access token (never a JSON blob)
  - Preference oauthToken retained as backward-compatible fallback (existing users unaffected)
  - SetupCommand now uses hooks for profile resolution (isConfigured reflects active profile state)
metrics:
  duration: ~2 min
  completed: 2026-02-23
  tasks_completed: 2
  files_modified: 6
---

# Phase 21 Plan 01: Multi-Profile Management Summary

Multi-profile storage and token resolution via useCachedState + useLocalStorage with backward-compatible Preference fallback.

## Tasks Completed

| Task | Name | Commit | Files |
| ---- | ---- | ------ | ----- |
| 1 | Add types and create profiles command | 337929c | types.ts, profiles.tsx, package.json |
| 2 | Update token resolution in dashboard, menu bar, and setup | ae87bca | index.tsx, menu-bar.tsx, setup.tsx |

## What Was Built

### Task 1: Types + Profiles Command

**types.ts additions:**
- `Profile` interface: `{ id, name, token }` where token is a pre-extracted raw access token
- `AlertSettings` interface: `{ threshold, enabled, lastAlertedWindowId }` (used in Phase 21-02)
- Storage key constants: `PROFILES_KEY`, `ACTIVE_PROFILE_KEY`, `ALERT_SETTINGS_KEY`
- `DEFAULT_ALERT_SETTINGS` constant

**profiles.tsx (155 lines):**
- `ProfilesCommand`: List-based UI showing all saved profiles
- Per-item accessories: green checkmark icon on active profile
- Per-item subtitle: first 8 chars of token + "..."
- Actions: Switch to Profile, Add Profile (Cmd+N), Delete Profile (Ctrl+X, destructive)
- `AddProfileForm`: inline Form pushed via Action.Push — name field + password field
- On submit: calls `extractToken()` before storing, generates id via `Date.now()`, sets as active
- Empty state: `List.EmptyView` prompting Cmd+N
- CRUD via `useLocalStorage<Profile[]>`, active sync via `useCachedState<string | null>`

**package.json:**
- Added `"profiles"` command entry with `"mode": "view"`

### Task 2: Token Resolution in Existing Commands

Applied same resolution pattern to index.tsx, menu-bar.tsx, and setup.tsx:

```typescript
const [activeProfileId] = useCachedState<string | null>(ACTIVE_PROFILE_KEY, null);
const { value: profiles } = useLocalStorage<Profile[]>(PROFILES_KEY, []);
const activeProfile = profiles?.find((p) => p.id === activeProfileId);
const token = extractToken(activeProfile?.token ?? oauthToken);
```

All hooks placed unconditionally before early returns per React rules of hooks.
`setup.tsx` `isConfigured` now reflects active profile: a configured profile means "already configured" even without a Preference token.

## Verification Results

- `npm run build`: passed (4 entry points, no TypeScript errors)
- `npm test`: 30/30 tests passed (utils.test.ts)
- `activeProfileId` pattern confirmed in index.tsx, menu-bar.tsx, setup.tsx
- profiles.tsx: 155 lines (exceeds 80-line minimum)
- package.json: "profiles" command entry present

## Deviations from Plan

None - plan executed exactly as written.

## Self-Check: PASSED

Files exist:
- FOUND: tokemon-raycast/src/profiles.tsx
- FOUND: tokemon-raycast/src/types.ts (Profile, AlertSettings, keys confirmed)
- FOUND: tokemon-raycast/src/index.tsx (activeProfileId confirmed)
- FOUND: tokemon-raycast/src/menu-bar.tsx (activeProfileId confirmed)
- FOUND: tokemon-raycast/src/setup.tsx (activeProfileId confirmed)

Commits exist:
- FOUND: 337929c (Task 1)
- FOUND: ae87bca (Task 2)
