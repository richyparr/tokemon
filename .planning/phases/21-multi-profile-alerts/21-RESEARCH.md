# Phase 21: Multi-Profile & Alerts - Research

**Researched:** 2026-02-22
**Domain:** Raycast LocalStorage multi-profile storage, Form-based settings, background threshold notifications, useCachedState cross-command sharing
**Confidence:** HIGH (stack/APIs) / MEDIUM (alert delivery from background)

---

## Summary

Phase 21 adds two independent feature areas: (1) multi-profile management, where users can store multiple Claude OAuth tokens under named profiles and switch between them; and (2) threshold alerts, where the menu bar command can notify the user when usage crosses a configurable percentage.

**Multi-profile architecture:** Raycast's `LocalStorage` API stores per-extension data in an encrypted database shared across all commands in the extension. The extension currently reads its single token from a `password` Preference. Multi-profile requires storing a list of profiles as a JSON array in `LocalStorage` — the active profile's token is resolved at runtime rather than reading from Preferences. A dedicated "Profiles" command provides `List` + `ActionPanel` UI for add/switch/delete. A "Settings" command provides `Form` UI for threshold configuration. `useCachedState` (from `@raycast/utils`) synchronizes the active profile key across all commands without additional wiring.

**Alert delivery from background:** The menu bar command runs on a 5-minute `interval` in background. `showToast` is documented to fall back to `showHUD` when Raycast's window is closed, and verified community reports indicate that `Toast.Style.Success` and `Toast.Style.Failure` work in background/menu-bar context via this fallback. However, there is a confirmed limitation: `Toast API is not available when command is launched in background` can appear in no-view commands. The safest pattern is to guard alert delivery with `environment.launchType === LaunchType.Background` and use `showToast` — if it works (menu-bar context), it shows a HUD banner; if the environment blocks it, the error should be caught silently. No macOS Notification Center API exists in `@raycast/api` as of the current version.

**Primary recommendation:** Store profiles as `LocalStorage` JSON array with `useCachedState` for active profile key. Use `Form` + `useForm` for settings. Trigger alert by calling `showToast` in the menu-bar background refresh cycle when threshold is crossed, guarded by a `LocalStorage` flag to prevent repeated alerts per session window.

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `@raycast/api` | ^1.104.5 (installed) | `LocalStorage`, `List`, `Form`, `Action`, `ActionPanel`, `showToast`, `Toast`, `environment`, `LaunchType` | Only Raycast extension API; all required primitives are here |
| `@raycast/utils` | ^1.0.0 (installed) | `useCachedState`, `useLocalStorage`, `useForm` | Official Raycast utilities; cross-command state sharing via `useCachedState` |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `LocalStorage` (from `@raycast/api`) | — | Persistent, encrypted, cross-command storage | Primary store for profiles array and alert settings |
| `useCachedState` (from `@raycast/utils`) | — | Share active profile key between commands in real-time | Avoids re-reading `LocalStorage` on every render |
| `useLocalStorage` (from `@raycast/utils`) | — | React hook interface to LocalStorage for profiles list | Simplifies profiles CRUD with `isLoading`, `setValue` |
| `useForm` (from `@raycast/utils`) | — | Form validation, submit handling, error display | Threshold configuration form with 0-100 validation |
| `environment`, `LaunchType` (from `@raycast/api`) | — | Detect background vs user-initiated launch | Gate alert logic to background refresh cycles |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `LocalStorage` for profiles | Additional `password` Preferences in manifest | Preferences are static manifest entries — cannot be added/removed at runtime. LocalStorage is the only option for dynamic profile lists. |
| `useCachedState` for active profile | Re-reading `LocalStorage` directly | `useCachedState` with the same key auto-syncs across commands when one updates. Direct `LocalStorage.getItem` requires manual polling. |
| `showToast` for alert | macOS Notification Center | No `sendNotification` or system notification API exists in `@raycast/api`. `showToast` (falls back to `showHUD`) is the only available mechanism. |
| `useForm` for threshold form | Manual `useState` + validation | `useForm` handles `onBlur` error display and `onChange` error clearing automatically — recommended by Raycast best practices. |
| JSON array in single `LocalStorage` key | One key per profile | Single-key approach makes atomic reads/writes trivial. Per-profile keys require `LocalStorage.allItems()` and filtering by prefix. |

**Installation:** No new packages needed. All dependencies already installed.

---

## Architecture Patterns

### Recommended Project Structure

```
tokemon-raycast/src/
├── api.ts            # fetchUsage, extractToken, TokenError — no changes
├── constants.ts      # USAGE_URL, headers — no changes
├── types.ts          # UsageData, UsageWindow — extend with Profile, AlertSettings
├── utils.ts          # usageColor, formatPercentage, etc. — no changes
├── index.tsx         # Dashboard command — update to read active profile token
├── setup.tsx         # Setup wizard — update to target active profile
├── menu-bar.tsx      # Menu bar command — add threshold alert logic
├── profiles.tsx      # NEW: Profile management command (List + CRUD)
└── settings.tsx      # NEW: Settings command (Form for threshold + test alert)
```

### Pattern 1: Profile Storage Schema

**What:** All profiles stored as a JSON-serialized array under a single `LocalStorage` key. Active profile ID stored separately via `useCachedState`.

**When to use:** Any time multiple named configurations need to be stored dynamically at runtime.

**Type definitions to add to `src/types.ts`:**
```typescript
// Source: Raycast LocalStorage docs — values must be JSON-serializable strings
export interface Profile {
  id: string;       // UUID or timestamp-based; stable identifier
  name: string;     // Display name (e.g., "Personal", "Work")
  token: string;    // Raw OAuth token (already extracted from Keychain blob)
}

export interface AlertSettings {
  threshold: number;        // 0-100 integer — alert fires when utilization >= threshold
  enabled: boolean;         // Master enable/disable
  lastAlertedWindowId: string | null; // Track which window ID triggered last alert (prevent repeat)
}

export const PROFILES_KEY = "profiles";             // LocalStorage key for Profile[]
export const ACTIVE_PROFILE_KEY = "activeProfileId"; // useCachedState key
export const ALERT_SETTINGS_KEY = "alertSettings";   // LocalStorage key for AlertSettings
```

**Example (profiles CRUD):**
```typescript
// Source: https://developers.raycast.com/utilities/react-hooks/uselocalstorage
import { useLocalStorage } from "@raycast/utils";
import type { Profile } from "./types";

// In profiles.tsx — load profiles
const { value: profiles, setValue: setProfiles, isLoading } = useLocalStorage<Profile[]>(
  "profiles",
  []
);

// Add profile
const addProfile = async (name: string, token: string) => {
  const newProfile: Profile = {
    id: Date.now().toString(),
    name,
    token: extractToken(token), // normalize token same as current setup
  };
  await setProfiles([...(profiles ?? []), newProfile]);
};

// Delete profile
const deleteProfile = async (id: string) => {
  await setProfiles((profiles ?? []).filter((p) => p.id !== id));
};
```

### Pattern 2: Active Profile Key with Cross-Command Sharing

**What:** `useCachedState` with a shared key makes the active profile ID available in all commands simultaneously. When profiles.tsx updates it, index.tsx and menu-bar.tsx see the update immediately.

```typescript
// Source: https://developers.raycast.com/utilities/react-hooks/usecachedstate
import { useCachedState } from "@raycast/utils";

// Same key used in ALL commands that need to know the active profile
const [activeProfileId, setActiveProfileId] = useCachedState<string | null>(
  "activeProfileId",
  null
);

// Resolve active token
const activeProfile = (profiles ?? []).find((p) => p.id === activeProfileId);
const token = activeProfile?.token ?? ""; // Falls back to "" if no profile selected
```

**Critical:** When `activeProfileId` is null (no profile selected), fall back to the `oauthToken` Preference — this preserves backward compatibility for single-profile users who already have a token in Preferences.

### Pattern 3: Active Token Resolution (Backward Compatibility)

**What:** Resolution order that preserves existing single-token users.

```typescript
// In index.tsx, menu-bar.tsx — replaces direct getPreferenceValues usage
import { getPreferenceValues } from "@raycast/api";
import { useCachedState } from "@raycast/utils";
import { useLocalStorage } from "@raycast/utils";

interface Preferences { oauthToken: string; }

const { oauthToken } = getPreferenceValues<Preferences>();
const [activeProfileId] = useCachedState<string | null>("activeProfileId", null);
const { value: profiles } = useLocalStorage<Profile[]>("profiles", []);

// Resolution: active profile token > preference token
const activeProfile = profiles?.find((p) => p.id === activeProfileId);
const token = extractToken(activeProfile?.token ?? oauthToken);
```

### Pattern 4: Profiles Command (List + CRUD Actions)

**What:** A `List` command showing all profiles with active indicator, add/switch/delete actions.

```typescript
// Source: https://developers.raycast.com/api-reference/user-interface/list
import { List, ActionPanel, Action, Icon, Color } from "@raycast/api";

// Mark active profile with checkmark accessory
<List.Item
  key={profile.id}
  title={profile.name}
  accessories={[
    profile.id === activeProfileId
      ? { icon: { source: Icon.Checkmark, tintColor: Color.Green }, tooltip: "Active" }
      : {}
  ]}
  actions={
    <ActionPanel>
      <Action title="Switch to Profile" onAction={() => setActiveProfileId(profile.id)} />
      <Action title="Delete Profile" style={Action.Style.Destructive} onAction={() => deleteProfile(profile.id)} />
    </ActionPanel>
  }
/>
```

### Pattern 5: Settings Command (Form for Threshold)

**What:** A `Form` command using `useForm` hook for validated threshold input.

```typescript
// Source: https://developers.raycast.com/utilities/react-hooks/useform
// Source: https://developers.raycast.com/api-reference/user-interface/form
import { Form, ActionPanel, Action, showToast, Toast } from "@raycast/api";
import { useForm } from "@raycast/utils";

interface ThresholdValues {
  threshold: string; // Form.TextField always yields string
  enabled: string;   // Form.Checkbox yields boolean (cast)
}

const { handleSubmit, itemProps } = useForm<ThresholdValues>({
  onSubmit: async (values) => {
    const threshold = parseInt(values.threshold, 10);
    await LocalStorage.setItem("alertSettings", JSON.stringify({
      threshold,
      enabled: values.enabled === "true",
      lastAlertedWindowId: null,
    }));
    await showToast({ style: Toast.Style.Success, title: "Settings saved" });
  },
  initialValues: { threshold: "80", enabled: "true" },
  validation: {
    threshold: (value) => {
      const num = parseInt(value ?? "", 10);
      if (!value || isNaN(num)) return "Enter a number";
      if (num < 1 || num > 100) return "Must be between 1 and 100";
    },
  },
});

return (
  <Form actions={<ActionPanel><Action.SubmitForm title="Save Settings" onSubmit={handleSubmit} /></ActionPanel>}>
    <Form.TextField title="Alert Threshold (%)" placeholder="e.g. 80" {...itemProps.threshold} />
    <Form.Checkbox label="Enable Alerts" {...itemProps.enabled} />
    <Form.Separator />
    {/* Test alert button via Action in ActionPanel */}
  </Form>
);
```

### Pattern 6: Alert Trigger in Menu Bar Background Refresh

**What:** During background refresh, after fetching usage, compare utilization to threshold. If crossed AND window has changed since last alert, call `showToast`. Guard against repeated alerts.

```typescript
// Source: https://developers.raycast.com/api-reference/environment
// Source: https://developers.raycast.com/api-reference/feedback/toast
import { environment, LaunchType, showToast, Toast, LocalStorage } from "@raycast/api";

// Inside menu-bar.tsx useEffect (runs after data fetches)
useEffect(() => {
  if (!data || environment.launchType !== LaunchType.Background) return;

  const checkAlert = async () => {
    const raw = await LocalStorage.getItem<string>("alertSettings");
    if (!raw) return;
    const settings: AlertSettings = JSON.parse(raw);
    if (!settings.enabled) return;

    const utilization = data.five_hour?.utilization ?? 0;
    const windowId = data.five_hour?.resets_at ?? "unknown";

    if (utilization >= settings.threshold && settings.lastAlertedWindowId !== windowId) {
      // Update last alerted window before showing (prevent race conditions)
      await LocalStorage.setItem("alertSettings", JSON.stringify({
        ...settings,
        lastAlertedWindowId: windowId,
      }));
      // showToast falls back to showHUD when Raycast window is closed
      await showToast({
        style: Toast.Style.Failure,
        title: "Claude usage alert",
        message: `Session usage is at ${Math.round(utilization)}% (threshold: ${settings.threshold}%)`,
      });
    }
  };

  checkAlert().catch(() => {
    // Swallow errors — alert failure must not break the menu bar command
  });
}, [data]);
```

**Critical detail:** The `lastAlertedWindowId` uses `resets_at` as the window identifier. When the 5-hour window resets, `resets_at` changes → a new alert can fire for the new window. This prevents repeated alerts within the same 5-hour window while allowing alerts in future windows.

### Pattern 7: Test Alert Action (ALRT-03)

**What:** An action in the Settings command that immediately fires the alert toast regardless of current utilization.

```typescript
// In settings.tsx ActionPanel
<Action
  title="Test Alert"
  icon={Icon.Bell}
  onAction={async () => {
    await showToast({
      style: Toast.Style.Failure,
      title: "Claude usage alert (test)",
      message: "This is what your alert will look like",
    });
  }}
/>
```

### Pattern 8: New Commands in package.json

Add two new command entries:

```json
{
  "name": "profiles",
  "title": "Manage Profiles",
  "subtitle": "tokemon",
  "description": "Add, switch, and delete Claude OAuth profiles",
  "mode": "view"
},
{
  "name": "settings",
  "title": "Settings",
  "subtitle": "tokemon",
  "description": "Configure usage alerts and extension settings",
  "mode": "view"
}
```

### Anti-Patterns to Avoid

- **Storing tokens in separate `password` Preferences per profile:** Preferences are manifest-static. Cannot add/remove at runtime. Must use `LocalStorage`.
- **Using `LocalStorage.clear()` for profile delete:** This clears ALL extension data. Use `setProfiles(profiles.filter(...))`.
- **Firing alert every background refresh when threshold is crossed:** Without `lastAlertedWindowId` guard, user gets a HUD notification every 5 minutes once threshold is crossed. Track the window ID.
- **Calling `showToast` without try/catch in background context:** Toast API MAY be unavailable in some background contexts. Wrap in try/catch and swallow errors silently.
- **Breaking single-token backward compatibility:** Existing users with `oauthToken` Preference must continue to work without migrating to the profile system. Always fall back to Preference token.
- **Allowing empty profile name:** Enforce non-empty name validation in the add-profile form — empty names create an unusable list UI.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Cross-command state sync | Custom pub/sub or polling | `useCachedState` with shared key | Built-in sync; same key in any command sees updates immediately |
| Form validation for threshold | Manual `useState` + `if` checks | `useForm` from `@raycast/utils` | Handles `onBlur` error display, `onChange` error clearing — documented best practice |
| Profile list storage | File-based JSON in support directory | `useLocalStorage` + `LocalStorage` API | Raycast's API is encrypted, extension-scoped, simpler. File API needed only for large data (>100KB). |
| Alert deduplication | Timestamp-based cooldown | `lastAlertedWindowId` using `resets_at` | Using the window's own reset time as ID is semantically correct — alert fires once per 5-hour window, resets naturally. |
| macOS system notification | `NSUserNotification` / `osascript` | `showToast` (falls back to `showHUD`) | No system notification API in `@raycast/api`. `showToast` → HUD is the official mechanism. Don't shell out to `osascript`. |

**Key insight:** The Raycast API provides exactly the right level of abstraction for this feature set. Every custom solution would be worse: harder to maintain, not encrypted, and potentially subject to Store rejection for using unsupported APIs.

---

## Common Pitfalls

### Pitfall 1: Toast API Unavailable in Some Background Contexts

**What goes wrong:** In no-view background commands, calling `showToast` throws `"Toast API is not available when command is launched in background"`.

**Why it happens:** No-view commands (mode: `no-view`) may not have a UI context. Menu-bar commands are slightly different and `showToast` appears to work via HUD fallback, but this is not definitively documented for all versions.

**How to avoid:** Always wrap `showToast` calls in the background alert path in `try/catch`. If the toast fails, consider falling back to `updateCommandMetadata({ subtitle: "!" })` as a secondary signal.

**Warning signs:** Menu bar command logs error but continues running; alert never shows.

**Mitigation pattern:**
```typescript
try {
  await showToast({ style: Toast.Style.Failure, title: "Claude usage alert", message: `...` });
} catch {
  // Silently ignore — alert failure must not crash the menu bar command
}
```

### Pitfall 2: Active Profile ID Points to Deleted Profile

**What goes wrong:** User deletes the active profile. `activeProfileId` still holds the deleted ID. All commands get an empty token and silently fail.

**Why it happens:** `useCachedState` persists independently from the profiles array. Deleting a profile from the array doesn't automatically clear the active ID.

**How to avoid:** In the delete action, check if the deleted profile is active. If so, reset `activeProfileId` to the first remaining profile or `null`.

```typescript
const deleteProfile = async (id: string) => {
  const remaining = (profiles ?? []).filter((p) => p.id !== id);
  await setProfiles(remaining);
  if (activeProfileId === id) {
    setActiveProfileId(remaining[0]?.id ?? null);
  }
};
```

**Warning signs:** Dashboard shows "No token configured" after deleting a profile.

### Pitfall 3: JSON Parse Error on AlertSettings

**What goes wrong:** `LocalStorage.getItem("alertSettings")` returns an old/malformed string. `JSON.parse` throws. Alert logic crashes.

**Why it happens:** LocalStorage migrated from a different schema, or user had a partially written value.

**How to avoid:** Wrap JSON.parse in try/catch with a default fallback:
```typescript
const parseAlertSettings = (raw: string | undefined): AlertSettings => {
  try {
    return raw ? JSON.parse(raw) : defaultAlertSettings;
  } catch {
    return defaultAlertSettings;
  }
};
```

### Pitfall 4: Adding Profile with Raw Keychain Blob Token

**What goes wrong:** User pastes full Keychain JSON blob into the add-profile form. The token stored is the blob, not the extracted access token.

**Why it happens:** The existing `extractToken()` in `api.ts` handles this — but only if called at add-time.

**How to avoid:** Call `extractToken()` on the token value before storing in the profile. The existing `extractToken` in `api.ts` already handles both formats. This is consistent with how `setup.tsx` works.

### Pitfall 5: Alert Fires Every 5 Minutes Once Threshold is Crossed

**What goes wrong:** User sees a HUD notification every time the menu bar refreshes (every 5 minutes) once usage goes over threshold.

**Why it happens:** No deduplication. Each background refresh checks threshold and always fires.

**How to avoid:** Store `lastAlertedWindowId` (the `resets_at` value of the window that triggered the alert). Only fire again when `resets_at` changes (i.e., a new 5-hour window started). Reset `lastAlertedWindowId` to `null` when user explicitly dismisses or when the window resets.

### Pitfall 6: LocalStorage key collision

**What goes wrong:** `useCachedState` and `LocalStorage` both use the same string keys. If the key names overlap between them, one can clobber the other.

**Why it happens:** `useCachedState` stores values in a different namespace from `LocalStorage`. They do NOT share keys. However, confusion can arise within the team.

**How to avoid:** Use clear, distinct key naming: `"profiles"` for LocalStorage profile array, `"alertSettings"` for LocalStorage alert config, `"activeProfileId"` for useCachedState. Never use the same key in both APIs.

---

## Code Examples

Verified patterns from official sources:

### LocalStorage CRUD for Profile List

```typescript
// Source: https://developers.raycast.com/api-reference/storage
// Source: https://developers.raycast.com/utilities/react-hooks/uselocalstorage
import { LocalStorage } from "@raycast/api";
import { useLocalStorage } from "@raycast/utils";
import type { Profile } from "./types";

// Hook-based (preferred in React components)
const { value: profiles, setValue: setProfiles, isLoading } = useLocalStorage<Profile[]>("profiles", []);

// Imperative (for use outside React — e.g., in background refresh)
const rawProfiles = await LocalStorage.getItem<string>("profiles");
const profiles: Profile[] = rawProfiles ? JSON.parse(rawProfiles) : [];
```

### useCachedState for Active Profile (Cross-Command)

```typescript
// Source: https://developers.raycast.com/utilities/react-hooks/usecachedstate
import { useCachedState } from "@raycast/utils";

// Use the SAME key in every command to get synchronized state
const [activeProfileId, setActiveProfileId] = useCachedState<string | null>("activeProfileId", null);
```

### useForm for Threshold Settings

```typescript
// Source: https://developers.raycast.com/utilities/react-hooks/useform
import { useForm } from "@raycast/utils";

const { handleSubmit, itemProps } = useForm<{ threshold: string; enabled: boolean }>({
  onSubmit: async (values) => {
    // Save to LocalStorage
  },
  initialValues: { threshold: "80", enabled: true },
  validation: {
    threshold: (v) => {
      const n = parseInt(v ?? "");
      if (isNaN(n) || n < 1 || n > 100) return "Enter a number between 1 and 100";
    },
  },
});
```

### Background Alert with Window Deduplication

```typescript
// Source: https://developers.raycast.com/api-reference/environment
// Source: https://developers.raycast.com/api-reference/feedback/toast
import { environment, LaunchType, showToast, Toast, LocalStorage } from "@raycast/api";

// Called inside useEffect after data loads in menu-bar.tsx
if (environment.launchType === LaunchType.Background && data) {
  const raw = await LocalStorage.getItem<string>("alertSettings");
  const settings = parseAlertSettings(raw);
  const utilization = data.five_hour?.utilization ?? 0;
  const windowId = data.five_hour?.resets_at ?? null;

  if (settings.enabled && windowId && utilization >= settings.threshold && settings.lastAlertedWindowId !== windowId) {
    await LocalStorage.setItem("alertSettings", JSON.stringify({ ...settings, lastAlertedWindowId: windowId }));
    try {
      await showToast({
        style: Toast.Style.Failure,
        title: "Claude usage alert",
        message: `Session at ${Math.round(utilization)}% — threshold: ${settings.threshold}%`,
      });
    } catch { /* ignore — must not break menu bar */ }
  }
}
```

### List with Active Profile Checkmark

```typescript
// Source: https://developers.raycast.com/api-reference/user-interface/list
import { List, ActionPanel, Action, Icon, Color } from "@raycast/api";

{profiles?.map((profile) => (
  <List.Item
    key={profile.id}
    title={profile.name}
    subtitle={`${profile.token.slice(0, 8)}...`}
    accessories={
      profile.id === activeProfileId
        ? [{ icon: { source: Icon.Checkmark, tintColor: Color.Green }, tooltip: "Active profile" }]
        : []
    }
    actions={
      <ActionPanel>
        <Action title="Switch to This Profile" onAction={() => setActiveProfileId(profile.id)} />
        <Action
          title="Delete Profile"
          style={Action.Style.Destructive}
          onAction={() => deleteProfile(profile.id)}
        />
      </ActionPanel>
    }
  />
))}
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manual `LocalStorage.getItem/setItem` in components | `useLocalStorage` React hook from `@raycast/utils` | Added in @raycast/utils ~1.17 | Simpler: isLoading, setValue, removeValue in one hook |
| `useState` + manual persistence | `useCachedState` for cross-command sync | Available since @raycast/utils v1.0 | Auto-sync across commands; no manual pub/sub |
| Manual form validation with `useState` | `useForm` hook with validation config | Available in @raycast/utils | Built-in onBlur/onChange lifecycle, error display, FormValidation.Required |
| Alert via `osascript` or shell notification | `showToast` (falls back to `showHUD`) | API v1.0+ | Fully integrated, no shell escape, Store-safe |

**Deprecated/outdated:**
- Using macOS `osascript` / `terminal-notifier` for notifications: Store-rejectable, security risk. Never do this.
- Storing profiles in Raycast extension Preferences manifest: Preferences are static — cannot be added/removed at runtime.

---

## Open Questions

1. **Can `showToast` reliably fire from the menu-bar background refresh context?**
   - What we know: `showToast` is documented to fall back to `showHUD` when the Raycast window is closed. Community reports say this works in menu-bar background refresh. The Apple Mail extension issue about "Toast API not available in background" appears to apply specifically to no-view commands, not menu-bar commands.
   - What's unclear: Official docs do not explicitly state that `showToast` works in `LaunchType.Background` for menu-bar commands. Tested behavior in community but not officially confirmed.
   - Recommendation: Implement with `showToast` wrapped in `try/catch`. If it works (expected), great. If it doesn't, fall back to `updateCommandMetadata({ subtitle: "!" })` as a secondary signal. Test in `ray develop` mode with `environment.launchType` check.
   - Confidence: MEDIUM

2. **Should the profile system completely replace the Preferences `oauthToken` field?**
   - What we know: Removing a preference field that existing users have set causes data loss and potentially breaks existing installations.
   - What's unclear: Whether Raycast Store allows keeping a preference field that is optionally overridden by app logic.
   - Recommendation: Keep `oauthToken` Preference as a fallback. When no active profile is set (empty `activeProfileId`), fall back to Preference token. Document this in Setup command.
   - Confidence: HIGH

3. **What is the UX for "Add Profile" — separate command or inline form?**
   - What we know: Raycast supports `push` navigation (`Action.Push` with a Form component) or a dedicated `view` command. Both work.
   - What's unclear: User preference — are they launching "Manage Profiles" to add, or using a separate "Add Profile" command?
   - Recommendation: Use `Action.Push` to push an inline Form within the profiles List command. Fewer commands in Raycast root search is cleaner UX. Single `profiles.tsx` handles list + add.
   - Confidence: HIGH

4. **How to handle the threshold alert when usage data is stale?**
   - What we know: `useCachedPromise` with `keepPreviousData: true` will serve cached data on background refresh until fresh data arrives.
   - What's unclear: Should the alert fire on stale data?
   - Recommendation: Only fire alert after fresh data is fetched (i.e., inside the `useEffect` that depends on `data`, not on cached stale data). The `revalidate` behavior of `useCachedPromise` means `data` updates after a successful fetch — the effect fires at that point.
   - Confidence: HIGH

---

## Sources

### Primary (HIGH confidence)

- https://developers.raycast.com/api-reference/storage — LocalStorage.getItem, setItem, removeItem, allItems, clear; value types; encryption; scope
- https://developers.raycast.com/utilities/react-hooks/uselocalstorage — useLocalStorage hook signature, setValue, removeValue, isLoading
- https://developers.raycast.com/utilities/react-hooks/usecachedstate — useCachedState signature, cross-command sharing with same key, JSON serialization requirement
- https://developers.raycast.com/utilities/react-hooks/useform — useForm signature, validation, onSubmit, initialValues, itemProps spread pattern
- https://developers.raycast.com/api-reference/user-interface/form — Form.TextField, Form.Checkbox, Form.Dropdown, Form.PasswordField, storeValue, error prop
- https://developers.raycast.com/api-reference/user-interface/list — List.Item accessories (icon, text, tag, tooltip), ActionPanel, Action.Style.Destructive
- https://developers.raycast.com/api-reference/feedback/toast — showToast signature, Toast.Style options, HUD fallback when window closed
- https://developers.raycast.com/api-reference/feedback/hud — showHUD signature
- https://developers.raycast.com/api-reference/environment — environment.launchType, LaunchType.UserInitiated, LaunchType.Background
- https://developers.raycast.com/information/manifest — preference types (password, textfield, checkbox, dropdown), command modes

### Secondary (MEDIUM confidence)

- WebSearch result: "Toast API is not available when command is launched in background" — confirmed limitation for no-view commands; menu-bar appears to be exempt via HUD fallback; mitigated by try/catch
- WebSearch result: useCachedState "hooks using the same key will share the same state" — verified against official docs URL
- WebSearch result: useLocalStorage added to @raycast/utils — confirmed via official changelog URL

### Tertiary (LOW confidence)

- Community reports that `showToast` works in menu-bar background context via HUD fallback — multiple sources agree but no official documentation explicitly confirms menu-bar background context. Flag for manual testing during implementation.

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all APIs verified against official Raycast docs (LocalStorage, useCachedState, useForm, List, Form, showToast)
- Architecture (profile storage): HIGH — JSON array in LocalStorage is the only viable option; Preference limitations confirmed officially
- Architecture (alert delivery): MEDIUM — showToast falls back to HUD (officially documented), but menu-bar background context not explicitly confirmed
- Pitfalls: HIGH — active profile deletion race condition and JSON parse errors are deterministic; alert deduplication pattern is solid; Toast-in-background limitation confirmed with workaround

**Research date:** 2026-02-22
**Valid until:** 2026-03-22 (Raycast API is stable; 30-day validity reasonable)
