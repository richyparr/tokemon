# Phase 20: Menu Bar Command - Research

**Researched:** 2026-02-22
**Domain:** Raycast MenuBarExtra API, background refresh, icon color tinting
**Confidence:** HIGH

---

## Summary

Phase 20 adds a Raycast menu bar command that displays the Claude session usage percentage persistently in macOS's menu bar, updates automatically in the background, and changes icon color to reflect usage level (green/orange/red).

The Raycast API provides first-class support for this via `MenuBarExtra` component with `mode: "menu-bar"` in the manifest and an `interval` property for automatic background refresh. The primary color signal must be delivered via icon tinting (`tintColor`) because MenuBarExtra title text color is not programmable — it is fixed by macOS. All required infrastructure (fetchUsage, usageColor, getPreferenceValues) already exists in the codebase; this phase adds a new `src/menu-bar.tsx` file and a new entry in `package.json`'s `commands` array.

Background refresh is opt-in: after a Store install, the user must first open the command (or enable it in Raycast preferences) before automatic refresh begins. In development, refresh runs immediately.

**Primary recommendation:** Create `src/menu-bar.tsx` as a thin React component using `useCachedPromise` + `MenuBarExtra`, configure `"mode": "menu-bar"` and `"interval": "5m"` in `package.json`, and apply `tintColor` to the icon to convey usage level.

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `@raycast/api` | ^1.104.5 (already installed) | `MenuBarExtra`, `Color`, `Icon`, `getPreferenceValues`, `openExtensionPreferences`, `environment` | The only way to build Raycast extensions |
| `@raycast/utils` | ^1.0.0 (already installed) | `useCachedPromise` for stale-while-revalidate data fetching | Official Raycast utilities, reduces boilerplate |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Existing `src/api.ts` | — | `fetchUsage`, `extractToken`, `TokenError` | Reuse as-is; no changes needed |
| Existing `src/utils.ts` | — | `usageColor`, `formatPercentage`, `parseResetDate`, `formatCountdown`, `computePace` | Reuse as-is; all pure functions |
| Existing `src/types.ts` | — | `UsageData`, `UsageWindow` | Reuse as-is |
| Existing `src/constants.ts` | — | `USAGE_URL`, `ANTHROPIC_BETA_HEADER` | Reuse as-is |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `useCachedPromise` | `useState` + `useEffect` + `fetch` | useCachedPromise gives stale-while-revalidate for free, persists cache between command launches — strongly prefer |
| `tintColor` on icon | Title text color | Title text color is NOT supported by Raycast API (open issue #12610, no ETA). Icon tinting is the only official color mechanism. |
| `Icon.CircleFilled` with tintColor | Custom SVG asset | Built-in icons avoid asset management; tintColor works cleanly with enums |
| `Icon.CircleFilled` | `Icon.CircleProgress25/50/75/100` | CircleProgress variants communicate progress without color; tintColor + CircleFilled communicates health level. Both are valid; tintColor approach matches requirements exactly. |

**Installation:** No new packages needed. All dependencies are already in `package.json`.

---

## Architecture Patterns

### Recommended Project Structure

```
tokemon-raycast/src/
├── api.ts            # fetchUsage, extractToken, TokenError — no changes
├── constants.ts      # USAGE_URL, ANTHROPIC_BETA_HEADER — no changes
├── types.ts          # UsageData, UsageWindow — no changes
├── utils.ts          # usageColor, formatPercentage, etc. — no changes
├── index.tsx         # Dashboard command — no changes
├── setup.tsx         # Setup wizard command — no changes
└── menu-bar.tsx      # NEW: MenuBarExtra command (Phase 20)
```

### Pattern 1: MenuBarExtra with useCachedPromise

**What:** A menu-bar command exports a default function returning `<MenuBarExtra>`. `useCachedPromise` handles fetching, caching, and the `isLoading` lifecycle. The icon receives `tintColor` derived from utilization.

**When to use:** Any menu bar command that fetches async data and wants stale-while-revalidate behavior.

**Example:**
```typescript
// Source: https://developers.raycast.com/api-reference/menu-bar-commands
// Source: https://developers.raycast.com/utilities/react-hooks/usecachedpromise
import { MenuBarExtra, Icon, Color, getPreferenceValues, openExtensionPreferences } from "@raycast/api";
import { useCachedPromise } from "@raycast/utils";
import { extractToken, fetchUsage } from "./api";
import { usageColor, formatPercentage } from "./utils";

interface Preferences { oauthToken: string; }

const colorMap: Record<string, Color> = {
  green: Color.Green,
  orange: Color.Orange,
  red: Color.Red,
  yellow: Color.Yellow,
};

export default function MenuBarCommand() {
  const { oauthToken } = getPreferenceValues<Preferences>();
  const token = extractToken(oauthToken);

  const { isLoading, data } = useCachedPromise(
    async (t: string) => fetchUsage(t),
    [token],
    { execute: token.length > 0, keepPreviousData: true }
  );

  const utilization = data?.five_hour?.utilization ?? 0;
  const colorKey = usageColor(utilization);
  const tintColor = colorMap[colorKey] ?? Color.Green;
  const title = data ? formatPercentage(utilization) : undefined;

  return (
    <MenuBarExtra
      icon={{ source: Icon.CircleFilled, tintColor }}
      title={title}
      isLoading={isLoading}
      tooltip="Claude session usage"
    >
      <MenuBarExtra.Section title="Session">
        <MenuBarExtra.Item title={`Usage: ${formatPercentage(utilization)}`} />
      </MenuBarExtra.Section>
      <MenuBarExtra.Section>
        <MenuBarExtra.Item
          title="Open Dashboard"
          onAction={() => launchCommand({ name: "index", type: LaunchType.UserInitiated })}
        />
        <MenuBarExtra.Item
          title="Preferences"
          onAction={openExtensionPreferences}
        />
      </MenuBarExtra.Section>
    </MenuBarExtra>
  );
}
```

### Pattern 2: package.json Manifest Entry

**What:** Add a new command entry with `"mode": "menu-bar"` and `"interval"` for background refresh.

**Example:**
```json
// Source: https://developers.raycast.com/information/manifest
{
  "name": "menu-bar",
  "title": "Menu Bar",
  "subtitle": "tokemon",
  "description": "Claude usage in your menu bar",
  "mode": "menu-bar",
  "interval": "5m"
}
```

The command `name` must match the filename: `src/menu-bar.tsx` → `"name": "menu-bar"`.

### Pattern 3: isLoading Lifecycle (Critical)

**What:** `useCachedPromise` manages `isLoading` automatically — it is `true` during the fetch and `false` when resolved or rejected. Pass this directly to `MenuBarExtra`. Do NOT manually manage isLoading state.

**Why critical:** Raycast waits for `isLoading` to become `false` before unloading the command after a background refresh. If it stays `true`, Raycast eventually force-terminates the command.

**Example:**
```typescript
// useCachedPromise returns { isLoading, data, error, revalidate }
// Pass isLoading directly — it is false when done (success or error)
return <MenuBarExtra isLoading={isLoading} icon={...} title={...}>
```

### Pattern 4: Icon Color via tintColor

**What:** The ONLY supported way to add color to a menu bar item is via `tintColor` on the icon. Title text color is not programmable (macOS controls it).

**Source:** https://github.com/raycast/extensions/issues/12610 — open since May 2024, no resolution.

```typescript
// Source: https://developers.raycast.com/api-reference/user-interface/colors
icon={{ source: Icon.CircleFilled, tintColor: Color.Green }}
// OR: tintColor: Color.Orange, Color.Red, Color.Yellow
```

### Pattern 5: Background Refresh Opt-In UX

**What:** Raycast automatically adds "Enable/Disable Background Refresh" toggle to command preferences when `interval` is set. The user must open the command once (or enable in prefs) before automatic refresh begins.

**Impact:** On first install, the menu bar item shows but does NOT auto-refresh. This is Raycast's designed behavior — not a bug.

### Anti-Patterns to Avoid

- **Setting `isLoading` manually with `useState`:** useCachedPromise manages this. Wrapping its value in additional state causes double-render bugs.
- **Returning `null` from the command to hide the menu bar item when no token:** Return a `MenuBarExtra` with a warning icon instead. Returning null removes the item entirely, which is confusing.
- **Using `setInterval` for refresh:** The `interval` manifest property handles this via Raycast's scheduler. Custom timers inside the component only work while the menu is open.
- **Expecting exact interval timing:** Raycast docs note "the actual scheduling is not exact and might vary within a tolerance level" due to macOS optimization.
- **Attempting to color title text:** Not supported by Raycast API. Only `tintColor` on icons works.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Stale-while-revalidate data cache | Custom caching with LocalStorage | `useCachedPromise` from `@raycast/utils` | Handles cache key, persistence, deduplication, and isLoading lifecycle automatically |
| Background refresh scheduling | `setInterval` or background XPC | `interval` property in manifest | macOS-native scheduling, battery-aware, user-controllable via Raycast prefs |
| Color-coded status | Custom image generation | `tintColor: Color.Green/Orange/Red` on built-in Icon | Zero asset management, automatically adapts to light/dark menu bar |
| Token retrieval | Re-implementing preference reading | `getPreferenceValues<Preferences>()` (already in index.tsx) | One-liner, already proven in codebase |

**Key insight:** The codebase already has all business logic in pure, tested functions (`usageColor`, `formatPercentage`). The menu bar command is a thin UI shell that imports these.

---

## Common Pitfalls

### Pitfall 1: isLoading Not Properly Managed in Background Refresh

**What goes wrong:** Command hangs in background refresh, Raycast force-terminates it, error icon appears on the menu bar item.

**Why it happens:** If `isLoading` is stuck at `true` (e.g., unhandled promise rejection before setting state), the command never signals completion.

**How to avoid:** Use `useCachedPromise` — it sets `isLoading: false` on both success AND error. Do not add a parallel `setIsLoading(false)` call.

**Warning signs:** Menu bar item shows loading spinner indefinitely; Raycast shows warning icon with "command failed" tooltip.

### Pitfall 2: Background Refresh Disabled After Store Install

**What goes wrong:** Automated tests or user reports that "the menu bar doesn't update automatically."

**Why it happens:** By design, Raycast disables background refresh until the user activates it (opens command or enables in prefs).

**How to avoid:** Document this in the extension description. Users see a Raycast preference toggle ("Enable Background Refresh") — this is expected.

**Warning signs:** Works in development (`ray develop`) but not after `ray build` + manual install.

### Pitfall 3: Command Name Mismatch

**What goes wrong:** Build fails with "command not found" or the command doesn't appear in Raycast.

**Why it happens:** The `"name"` field in `package.json` commands array must exactly match the filename without extension: `menu-bar.tsx` → `"name": "menu-bar"`.

**How to avoid:** Name the file `src/menu-bar.tsx` and use `"name": "menu-bar"` in the manifest.

### Pitfall 4: Interval Below Minimum

**What goes wrong:** Build or publish validation rejects the extension.

**Why it happens:** Minimum interval is `10s` (10 seconds), though for polling an API `5m` is strongly recommended.

**How to avoid:** Use `"interval": "5m"` for production. Never go below `1m` unless there is a strong reason.

**Note:** There is a discrepancy between sources — one says `10s` minimum, another says `1m`. For safety and Store approval, use `5m` minimum.

### Pitfall 5: Rendering MenuBarExtra Without Children

**What goes wrong:** The menu bar item appears but clicking it does nothing or shows empty menu.

**Why it happens:** MenuBarExtra with no children renders the icon/title but shows no dropdown. This can confuse users.

**How to avoid:** Always include at least one `MenuBarExtra.Item` — e.g., a "Open Dashboard" action and "Preferences" action.

### Pitfall 6: Token Not Set — Poor UX

**What goes wrong:** Menu bar shows a generic icon with no data and user doesn't know why.

**Why it happens:** No token configured; `execute: false` means `useCachedPromise` doesn't run; `data` is undefined.

**How to avoid:** When `token.length === 0`, render a distinct icon (e.g., `Icon.Warning` with no tintColor) and a `MenuBarExtra.Item` titled "Setup Required — Open Preferences" with `onAction={openExtensionPreferences}`.

---

## Code Examples

Verified patterns from official sources:

### Complete Menu Bar Command with Background Refresh

```typescript
// Source: https://developers.raycast.com/api-reference/menu-bar-commands
// Source: https://developers.raycast.com/utilities/react-hooks/usecachedpromise
import {
  MenuBarExtra,
  Icon,
  Color,
  getPreferenceValues,
  openExtensionPreferences,
  launchCommand,
  LaunchType,
} from "@raycast/api";
import { useCachedPromise } from "@raycast/utils";
import { extractToken, fetchUsage, TokenError } from "./api";
import { usageColor, formatPercentage, parseResetDate, formatCountdown } from "./utils";
import type { UsageData } from "./types";

interface Preferences { oauthToken: string; }

const colorMap: Record<string, Color> = {
  green: Color.Green,
  yellow: Color.Yellow,
  orange: Color.Orange,
  red: Color.Red,
};

export default function MenuBarCommand() {
  const { oauthToken } = getPreferenceValues<Preferences>();
  const token = extractToken(oauthToken);

  const { isLoading, data, error } = useCachedPromise(
    async (t: string) => fetchUsage(t),
    [token],
    { execute: token.length > 0, keepPreviousData: true }
  );

  // No token — show setup prompt
  if (!token) {
    return (
      <MenuBarExtra icon={{ source: Icon.Warning }} tooltip="tokemon: Setup required" isLoading={false}>
        <MenuBarExtra.Item title="Setup Required" subtitle="Click to configure token" onAction={openExtensionPreferences} />
      </MenuBarExtra>
    );
  }

  const utilization = data?.five_hour?.utilization ?? 0;
  const colorKey = usageColor(utilization);
  const tintColor = colorMap[colorKey] ?? Color.Green;
  const title = data ? formatPercentage(utilization) : undefined;

  const resetAt = parseResetDate(data?.five_hour?.resets_at);
  const secondsRemaining = resetAt ? Math.floor((resetAt.getTime() - Date.now()) / 1000) : 0;

  return (
    <MenuBarExtra
      icon={{ source: Icon.CircleFilled, tintColor: error ? Color.SecondaryText : tintColor }}
      title={title}
      tooltip={`Claude usage: ${formatPercentage(utilization)}`}
      isLoading={isLoading}
    >
      <MenuBarExtra.Section title="Session (5h)">
        <MenuBarExtra.Item title={`Usage: ${formatPercentage(utilization)}`} />
        <MenuBarExtra.Item title={`Resets in: ${data ? formatCountdown(secondsRemaining) : "--"}`} />
      </MenuBarExtra.Section>
      <MenuBarExtra.Section title="Weekly (7d)">
        <MenuBarExtra.Item title={`Usage: ${formatPercentage(data?.seven_day?.utilization)}`} />
      </MenuBarExtra.Section>
      <MenuBarExtra.Section>
        <MenuBarExtra.Item
          title="Open Dashboard"
          icon={Icon.AppWindowSidebarLeft}
          onAction={() => launchCommand({ name: "index", type: LaunchType.UserInitiated })}
        />
        <MenuBarExtra.Item
          title="Preferences"
          icon={Icon.Gear}
          onAction={openExtensionPreferences}
        />
      </MenuBarExtra.Section>
    </MenuBarExtra>
  );
}
```

### package.json Command Entry

```json
// Source: https://developers.raycast.com/information/manifest
{
  "name": "menu-bar",
  "title": "Menu Bar",
  "subtitle": "tokemon",
  "description": "Claude usage percentage in your menu bar with automatic refresh",
  "mode": "menu-bar",
  "interval": "5m"
}
```

### Icon with tintColor (Color Signal Pattern)

```typescript
// Source: https://developers.raycast.com/api-reference/user-interface/colors
// Thresholds from existing usageColor() in utils.ts:
// >= 90 → "red", >= 70 → "orange", >= 40 → "yellow", else → "green"
const colorMap: Record<string, Color> = {
  green: Color.Green,
  yellow: Color.Yellow,
  orange: Color.Orange,
  red: Color.Red,
};
icon={{ source: Icon.CircleFilled, tintColor: colorMap[usageColor(utilization)] }}
```

### launchCommand to Open Dashboard from Menu Bar

```typescript
// Source: https://developers.raycast.com/api-reference/command
import { launchCommand, LaunchType } from "@raycast/api";

// Inside MenuBarExtra.Item onAction:
onAction={() => launchCommand({ name: "index", type: LaunchType.UserInitiated })}
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Script Commands for menu bar | `MenuBarExtra` React component | API v1.38.1 (2022-07) | Full React lifecycle, hooks, typed API |
| Manual state + useEffect for data fetch | `useCachedPromise` from `@raycast/utils` | API v1.38.1 (2022-07) | Stale-while-revalidate, persistent cache, automatic isLoading |
| No color support for icons | `tintColor` with `Color` enum on icon objects | API v1.41.0 (2022-10) | Color-coded status indicators work correctly |
| Icon colors based on Raycast theme | Icon colors based on macOS system appearance | API v1.62.0 (2023-11) | Menu bar icons now correctly adapt to macOS light/dark mode |
| `MenuBarExtra.Item.alternate` on all macOS | Alternates require macOS Sonoma+ | API v1.62.0 (2023-11) | Don't rely on alternate items for critical UX |

**Deprecated/outdated:**
- Manual `setInterval` inside command for refresh: replaced by `interval` manifest property.
- Script Commands for background tasks: fully replaced by `mode: "no-view"` and `mode: "menu-bar"` with `interval`.

---

## Open Questions

1. **What icon is most recognizable for usage in the menu bar?**
   - What we know: `Icon.CircleFilled` with tintColor works. The comparable `markhudsonn/raycast-llm-usage` extension uses `Icon.StackedBars1-4` for utilization levels plus title text showing percentage.
   - What's unclear: `Icon.CircleFilled` is a dot (compact); StackedBars communicates capacity but ignores tintColor color signal.
   - Recommendation: Use `Icon.CircleFilled` with tintColor for simplicity and clear color signal, plus `title` showing percentage string (e.g., "73%"). This matches MENU-01, MENU-03 requirements exactly.

2. **Should the menu bar show the percentage as title text?**
   - What we know: `MenuBarExtra.title` accepts a string shown alongside the icon in the menu bar. This adds horizontal space but gives instant numeric readout.
   - What's unclear: Space may be tight in crowded menu bars.
   - Recommendation: Show title text (e.g., "73%") — it directly fulfills MENU-01 ("usage percentage displayed") and the colored icon satisfies MENU-03.

3. **Exact minimum interval for Store submission**
   - What we know: Docs say `10s` is the minimum, but one source says `1m`. For safety and store approval, use `5m`.
   - What's unclear: Whether Raycast Store reviewers enforce a minimum above `10s`.
   - Recommendation: Use `"interval": "5m"` — appropriate for API polling, well above any documented minimum.

4. **Does `launchCommand` from a menu bar item require any special permission?**
   - What we know: Official docs say "presenting a permission alert if the command belongs to a different extension." Since `index` is in the same extension, no alert should appear.
   - What's unclear: Exact runtime behavior if the dashboard command is already open.
   - Recommendation: Use `launchCommand({ name: "index", type: LaunchType.UserInitiated })` — same-extension, no permission issue expected.

---

## Sources

### Primary (HIGH confidence)
- https://developers.raycast.com/api-reference/menu-bar-commands — MenuBarExtra component API, props, isLoading lifecycle, background refresh config
- https://developers.raycast.com/information/manifest — Command object schema, mode values, interval syntax
- https://developers.raycast.com/information/lifecycle/background-refresh — Background refresh mechanics, minimum interval (10s), opt-in behavior for Store installs
- https://developers.raycast.com/utilities/react-hooks/usecachedpromise — useCachedPromise options (keepPreviousData, execute), return shape
- https://developers.raycast.com/api-reference/user-interface/colors — Color enum constants (Green, Orange, Red, Yellow), tintColor usage
- https://developers.raycast.com/api-reference/command — launchCommand signature, LaunchType enum, updateCommandMetadata
- https://developers.raycast.com/misc/changelog — Version history for MenuBarExtra features

### Secondary (MEDIUM confidence)
- https://github.com/gabrieles02/raycast-docs/blob/main/docs/api-reference/menu-bar-commands.md — Complete MenuBarExtra code examples (GitHub mirror of official docs, validated against official content)
- https://github.com/markhudsonn/raycast-llm-usage — Reference implementation of a similar Claude usage menu bar extension (icon pattern: StackedBars + title text; confirms real-world viability)

### Tertiary (LOW confidence)
- https://github.com/raycast/extensions/issues/12610 — Open issue confirming title text color is NOT supported (open since May 2024, no resolution)
- WebSearch results about interval minimum discrepancy (`10s` vs `1m`) — contradictory; mitigated by using `5m` which is safe for both interpretations

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all APIs are official Raycast documentation, packages already installed
- Architecture: HIGH — MenuBarExtra + useCachedPromise + manifest interval is the canonical, documented pattern
- Pitfalls: HIGH for lifecycle/isLoading (documented); MEDIUM for interval minimum discrepancy (contradictory sources, mitigated by conservative choice); HIGH for tintColor-only color support (confirmed via open issue)

**Research date:** 2026-02-22
**Valid until:** 2026-03-22 (Raycast API is stable; 30-day validity reasonable)
