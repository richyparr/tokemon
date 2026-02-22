# Phase 19: Dashboard Command - Research

**Researched:** 2026-02-22
**Domain:** Raycast extension UI — @raycast/api Detail view, @raycast/utils hooks, TypeScript data typing
**Confidence:** HIGH

---

## Summary

Phase 19 completes the Raycast extension by building the real dashboard on top of the stub in `src/index.tsx`. The API response shape is already fully known from the Swift app's `OAuthUsageResponse.swift` — the response has `five_hour`, `seven_day`, `seven_day_oauth_apps`, `seven_day_opus`, `seven_day_sonnet`, and `extra_usage` fields, each with `utilization` (0-100) and `resets_at` (ISO-8601). Phase 19's job is to (1) type that response in TypeScript, (2) compute the display values, and (3) render them using Raycast's `Detail` + `Detail.Metadata` components.

The existing `fetchUsage` in `src/api.ts` already calls the endpoint and returns `Promise<unknown>`. Phase 19 adds a `UsageData` TypeScript interface matching the Swift model, then wraps `fetchUsage` with `useCachedPromise` from `@raycast/utils` for stale-while-revalidate caching and a `revalidate()` call wired to a Cmd+R action. The five pieces of required data (DASH-01 through DASH-05) all come from a single API call — no additional endpoints needed.

The pace indicator (DASH-04) requires a simple calculation: compare current session utilization against elapsed time in the 5-hour window. The Swift `BurnRateCalculator` uses historical points, but with a single API snapshot the Raycast extension can use a simpler heuristic: derive "expected utilization at this point in the window" from `(hoursElapsed / 5) * 100` and compare against `five_hour.utilization`. The reset countdown timer (DASH-03) requires a `useEffect` + `setInterval` to tick every second — this is standard React and well-supported in Raycast.

**Primary recommendation:** Use `useCachedPromise(fetchUsage, [token])` from `@raycast/utils` for data fetching, `Detail` + `Detail.Metadata` for layout, and `useEffect`/`setInterval` for the countdown timer. No new dependencies required.

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `@raycast/api` | 1.104.6 (installed) | Detail, Action, ActionPanel, Color, Icon, Toast | Only way to render Raycast UI |
| `@raycast/utils` | 1.19.1 (installed) | `useCachedPromise`, `useCachedState` | Official Raycast hooks for async state + persistence |
| TypeScript | ^5.0.0 (installed) | Type safety for API response | Already configured |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| React `useEffect` + `setInterval` | (built-in React) | Countdown timer that ticks every second | DASH-03 reset timer display |
| `useCachedState` from `@raycast/utils` | 1.19.1 | Persist last-known data across command re-launches | Optional: show stale data on first render |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `useCachedPromise` | `useEffect` + `useState` | useCachedPromise gives free stale-while-revalidate; useEffect requires manual state wiring |
| `useCachedPromise` | `useFetch` | useFetch is URL-based; useCachedPromise works with the existing `fetchUsage` function directly |
| `Detail.Metadata` panel | Markdown-only layout | Metadata renders structured key-value rows; markdown requires manual formatting and breaks on resizes |

**Installation:** No new packages. All dependencies already installed.

---

## Architecture Patterns

### Recommended File Structure
```
src/
├── index.tsx          # Dashboard command (main — replace stub)
├── api.ts             # fetchUsage, extractToken, TokenError (DONE)
├── constants.ts       # USAGE_URL, headers (DONE)
├── setup.tsx          # Setup wizard (DONE)
└── types.ts           # NEW: UsageData interface, computed display types
```

A `types.ts` file for the API response type keeps `api.ts` import-free from Raycast (per the existing decision that `api.ts` has zero Raycast imports).

### Pattern 1: useCachedPromise with Typed Response

**What:** Wrap `fetchUsage` in `useCachedPromise`, assert the response type, and extract display values.

**When to use:** Any time you call a custom async function and want stale-while-revalidate caching + a `revalidate()` handle.

```typescript
// Source: https://developers.raycast.com/utilities/react-hooks/usecachedpromise
import { useCachedPromise } from "@raycast/utils";
import { fetchUsage } from "./api";
import type { UsageData } from "./types";

const { isLoading, data, error, revalidate } = useCachedPromise(
  async (token: string): Promise<UsageData> => {
    const raw = await fetchUsage(token);
    return raw as UsageData; // validated by structure at runtime if needed
  },
  [token],
  {
    execute: token.length > 0,   // don't fire if no token
    keepPreviousData: true,       // show last data while re-fetching
    onError: (err) => {
      // TokenError handled by showing openExtensionPreferences
    },
  }
);
```

### Pattern 2: Detail with Metadata Panel

**What:** Use `Detail.Metadata` subcomponents to render key-value data. The left pane gets a brief markdown summary; the right panel gets structured rows.

**When to use:** Any Detail screen that displays structured data (better than embedding all rows in markdown).

```typescript
// Source: https://developers.raycast.com/api-reference/user-interface/detail
<Detail
  isLoading={isLoading}
  markdown={summaryMarkdown}
  metadata={
    <Detail.Metadata>
      <Detail.Metadata.Label title="Session" text={sessionText} />
      <Detail.Metadata.Label title="Weekly" text={weeklyText} />
      <Detail.Metadata.Separator />
      <Detail.Metadata.Label title="Resets in" text={countdownText} icon={Icon.Clock} />
      <Detail.Metadata.TagList title="Pace">
        <Detail.Metadata.TagList.Item text={paceLabel} color={paceColor} />
      </Detail.Metadata.TagList>
    </Detail.Metadata>
  }
  actions={
    <ActionPanel>
      <Action
        title="Refresh"
        icon={Icon.ArrowClockwise}
        shortcut={{ modifiers: ["cmd"], key: "r" }}
        onAction={() => revalidate()}
      />
    </ActionPanel>
  }
/>
```

### Pattern 3: Countdown Timer via useEffect + setInterval

**What:** Track a live countdown to `resets_at` by ticking a local state variable every second.

**When to use:** Any time a date-diff must display as "3h 22m 14s" and update in real time.

```typescript
// Source: Standard React pattern, verified against Raycast lifecycle docs
const [now, setNow] = useState(new Date());

useEffect(() => {
  const id = setInterval(() => setNow(new Date()), 1000);
  return () => clearInterval(id);
}, []);

// Then derive countdown from `now` and `data.five_hour.resets_at`
const resetsAt = data?.five_hour?.resets_at ? new Date(data.five_hour.resets_at) : null;
const secondsRemaining = resetsAt ? Math.max(0, Math.floor((resetsAt.getTime() - now.getTime()) / 1000)) : null;
const countdown = secondsRemaining !== null ? formatCountdown(secondsRemaining) : "--";
```

Important: Raycast unloads commands from memory when the user returns to root search. The `setInterval` will be automatically cleaned up by the return function. No memory leak risk.

### Pattern 4: Pace Indicator Calculation

**What:** Determine if the user is "on track", "ahead of pace", or "behind pace" based on where they are in their 5-hour window.

**Context from Swift app:** The macOS app uses historical data points and burn rate. The Raycast extension only has one snapshot, so use this simpler approach:

```typescript
// Pace = actual utilization vs. expected utilization at this point in the window
// Expected: if window is 5 hours and resets_at is known, derive elapsed fraction
function computePace(utilization: number, resetsAt: Date | null): PaceStatus {
  if (resetsAt === null) return "unknown";

  const windowMs = 5 * 60 * 60 * 1000; // 5 hours in ms
  const elapsed = windowMs - (resetsAt.getTime() - Date.now());
  const elapsedFraction = Math.min(1, Math.max(0, elapsed / windowMs));
  const expectedUtilization = elapsedFraction * 100;

  const delta = utilization - expectedUtilization;
  if (delta > 10) return "behind";   // using faster than expected
  if (delta < -10) return "ahead";  // lots of headroom remaining
  return "on-track";
}

// Map to display
const paceConfig = {
  "on-track":  { label: "On Track",  color: Color.Green  },
  "ahead":     { label: "Ahead",     color: Color.Blue   },
  "behind":    { label: "Behind",    color: Color.Orange },
  "unknown":   { label: "Unknown",   color: Color.SecondaryText },
};
```

Note: "behind" means burning faster than the window allows (higher utilization than expected for the time elapsed), which is the warning state.

### Anti-Patterns to Avoid

- **Calling `fetchUsage` directly in `useEffect`:** Bypasses caching; use `useCachedPromise` instead for stale-while-revalidate.
- **Rendering countdown in markdown string:** Requires re-computing markdown on every tick; use `Detail.Metadata.Label` with a state value and only re-render the metadata.
- **Polling with `setInterval` for API data:** API should only be called when user manually refreshes (DASH-05) or on mount. The 1-second interval is only for the countdown clock, not for `fetchUsage`.
- **Putting all display logic in the component body:** Extract `formatCountdown`, `computePace`, `formatPercentage` as pure functions in `types.ts` or a `utils.ts` so they're testable without Raycast.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Stale-while-revalidate caching | Custom cache in LocalStorage | `useCachedPromise` from `@raycast/utils` | Built-in, key-scoped, handles race conditions |
| Manual refresh with loading state | `isRefreshing` boolean + manual fetch | `revalidate()` from `useCachedPromise` | Automatically resets `isLoading`, handles errors |
| Toast on error | Custom error display in markdown | Default `useCachedPromise` error toast | Shows retry action automatically |
| Token absence guard | `if (!token) return null` before hook | `execute: token.length > 0` in useCachedPromise options | Hooks cannot be called conditionally; use `execute` option |

**Key insight:** `useCachedPromise` with `execute: false` is the correct way to conditionally skip a fetch — the hook still mounts but doesn't fire until `execute` becomes true. Never call hooks conditionally.

---

## Common Pitfalls

### Pitfall 1: Calling Hooks Conditionally for Token Guard

**What goes wrong:** Developer writes `if (!token) return <NoTokenView />;` before calling `useCachedPromise`, causing React's "fewer hooks than expected" error.

**Why it happens:** Natural instinct to early-return before hooks if token is missing.

**How to avoid:** Always call `useCachedPromise` unconditionally, with `execute: token.length > 0`. Then conditionally render based on `!token` after the hook call.

**Warning signs:** Console error "React has detected a change in the order of Hooks."

### Pitfall 2: JSON Parsing of `resets_at` Without Error Handling

**What goes wrong:** `new Date(data.five_hour.resets_at)` returns `Invalid Date` if Anthropic changes the ISO-8601 format or adds fractional seconds without "Z" suffix.

**Why it happens:** The Swift app handles this explicitly with `ISO8601DateFormatter` with `withFractionalSeconds` option.

**How to avoid:** Wrap in a helper that returns `null` on invalid date:
```typescript
function parseResetDate(iso: string | undefined | null): Date | null {
  if (!iso) return null;
  const d = new Date(iso);
  return isNaN(d.getTime()) ? null : d;
}
```

**Warning signs:** Countdown shows "NaN" or "Invalid Date" in UI.

### Pitfall 3: setInterval Not Cleared on Component Unmount

**What goes wrong:** If the cleanup function is omitted from `useEffect`, a stale interval continues firing after the command is unmounted, potentially causing state updates on an unmounted component.

**Why it happens:** Easy to forget `return () => clearInterval(id)`.

**How to avoid:** Always return the cleanup. ESLint/TypeScript will not catch this — it's a runtime issue only.

**Warning signs:** Console warning "Can't perform a React state update on an unmounted component."

### Pitfall 4: Metadata Panel Not Rendering

**What goes wrong:** `Detail.Metadata` renders nothing or shows an empty panel.

**Why it happens:** `Detail.Metadata` must be passed as the `metadata` prop (not a child), and must contain at least one subcomponent. Passing `undefined` when data is loading causes the panel to disappear.

**How to avoid:** Always render the metadata panel; use placeholder strings ("--") when data is loading rather than omitting rows.

```typescript
metadata={
  <Detail.Metadata>
    <Detail.Metadata.Label title="Session" text={data ? formatPct(data.five_hour?.utilization) : "--"} />
  </Detail.Metadata>
}
```

### Pitfall 5: useCachedPromise Cache Scoping Confusion

**What goes wrong:** Two different commands sharing the same cache key accidentally share state — or conversely, the developer wants to share a cache key between Dashboard and other future commands but doesn't.

**Why it happens:** `useCachedPromise` automatically generates a cache key from the function reference + args. Developers assume the key is manually set (like `useCachedState`).

**How to avoid:** Know that `useCachedPromise` uses the function identity + serialized args as the cache key automatically. The Dashboard command's `useCachedPromise(fetchUsage, [token])` is already correctly scoped.

### Pitfall 6: Token Error Not Distinguished from Network Error

**What goes wrong:** A `TokenError` (401/403) shows the same generic "network error" toast as a real network failure.

**Why it happens:** `useCachedPromise`'s default `onError` doesn't know about `TokenError`.

**How to avoid:** Use the `onError` callback to handle `TokenError` specifically:
```typescript
onError: async (err) => {
  if (err instanceof TokenError) {
    await showToast({
      style: Toast.Style.Failure,
      title: "Token expired",
      primaryAction: { title: "Open Preferences", onAction: openExtensionPreferences },
    });
  }
  // Let useCachedPromise handle generic errors
}
```

---

## Code Examples

Verified patterns from official sources:

### Full Response Type (mirrors Swift OAuthUsageResponse)
```typescript
// Source: Derived from /Tokemon/Tokemon/Models/OAuthUsageResponse.swift (verified against API)
export interface UsageWindow {
  utilization: number;     // 0-100
  resets_at: string | null; // ISO-8601 or null
}

export interface ExtraUsage {
  is_enabled: boolean;
  monthly_limit: number | null;   // cents
  used_credits: number | null;    // cents
  utilization: number | null;     // 0-100
}

export interface UsageData {
  five_hour: UsageWindow | null;
  seven_day: UsageWindow | null;
  seven_day_oauth_apps: UsageWindow | null;
  seven_day_opus: UsageWindow | null;
  seven_day_sonnet: UsageWindow | null;
  extra_usage: ExtraUsage | null;
}
```

### Cmd+R Shortcut
```typescript
// Source: https://developers.raycast.com/api-reference/keyboard
<Action
  title="Refresh"
  icon={Icon.ArrowClockwise}
  shortcut={{ modifiers: ["cmd"], key: "r" }}
  onAction={revalidate}
/>
```

### Color Mapping for Percentage
```typescript
// Source: https://developers.raycast.com/api-reference/user-interface/colors
import { Color } from "@raycast/api";

function usageColor(pct: number): string {
  if (pct >= 90) return Color.Red;
  if (pct >= 70) return Color.Orange;
  if (pct >= 40) return Color.Yellow;
  return Color.Green;
}
```

### Countdown Formatter
```typescript
// Pure utility — no Raycast imports (safe for testing)
export function formatCountdown(seconds: number): string {
  if (seconds <= 0) return "resetting";
  const h = Math.floor(seconds / 3600);
  const m = Math.floor((seconds % 3600) / 60);
  const s = seconds % 60;
  if (h > 0) return `${h}h ${m}m ${s}s`;
  if (m > 0) return `${m}m ${s}s`;
  return `${s}s`;
}
```

### Toast on Manual Refresh
```typescript
// Source: https://developers.raycast.com/api-reference/feedback/toast
const handleRefresh = async () => {
  const toast = await showToast({ style: Toast.Style.Animated, title: "Refreshing..." });
  try {
    await revalidate();
    toast.style = Toast.Style.Success;
    toast.title = "Updated";
  } catch {
    toast.style = Toast.Style.Failure;
    toast.title = "Refresh failed";
  }
};
```

Note: `revalidate()` from `useCachedPromise` does not return a promise that resolves when fetch completes — it fires-and-forgets. A simpler pattern is just `onAction: revalidate` without the toast, letting `isLoading` drive the UI state.

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `useEffect` + manual `useState` for async | `useCachedPromise` from `@raycast/utils` | @raycast/utils v1.x | Eliminates boilerplate, adds free caching |
| `useFetch` for all data fetching | `useFetch` for URLs, `useCachedPromise` for custom functions | @raycast/utils v1.x | Better fit for `fetchUsage` which is a function, not a URL |
| Markdown-only Detail views | `Detail.Metadata` panel for structured data | @raycast/api early versions | Separates prose (left) from data (right), cleaner UX |

**Deprecated/outdated:**
- Direct `fetch()` in `useEffect`: Still works but loses caching; use `useCachedPromise` instead.
- `LocalStorage` for caching API responses: Redundant when `useCachedPromise` is available; `useCachedPromise` uses the same underlying LocalStorage but manages lifecycle automatically.

---

## Open Questions

1. **Does `revalidate()` from `useCachedPromise` return a Promise?**
   - What we know: The docs show it as `revalidate: () => void` return type in the hook signature.
   - What's unclear: Whether `await revalidate()` works for the toast pattern above.
   - Recommendation: Use the simpler `onAction: revalidate` (no toast), and let `isLoading: true` on the Detail indicate the refresh is in progress. This is safer.

2. **What value does `seven_day.utilization` map to for "weekly usage" (DASH-02)?**
   - What we know: The API has both `seven_day` (all models) and `seven_day_sonnet`, `seven_day_opus`. The Swift app shows `seven_day.utilization` as "7-day usage" (the primary weekly metric).
   - What's unclear: Whether Raycast extension should show all three or just the aggregate.
   - Recommendation: Show `seven_day.utilization` as "Weekly Usage" (DASH-02). Optionally show Sonnet/Opus breakdowns as secondary metadata rows if non-null.

3. **Does the Anthropic API `resets_at` field always reflect the start of the current window?**
   - What we know: Swift app parses it as ISO-8601 with fractional seconds. The pace calculation depends on this being accurate.
   - What's unclear: If the API sometimes returns a `null` for `resets_at` (e.g., first-ever usage, or at exact reset moment).
   - Recommendation: Treat `null` as "unknown" and show "--" for pace and countdown. Verified `parseResetDate()` helper handles this.

---

## Sources

### Primary (HIGH confidence)
- `/Users/richardparr/Tokemon/Tokemon/Models/OAuthUsageResponse.swift` — exact API response shape, field names, types
- `/Users/richardparr/Tokemon/Tokemon/Models/UsageSnapshot.swift` — derived display model, pace logic reference
- `/Users/richardparr/tokemon-raycast/src/api.ts` — `fetchUsage`, `TokenError`, `extractToken` (what Phase 19 builds on)
- `/Users/richardparr/tokemon-raycast/package.json` — confirms @raycast/api 1.104.6, @raycast/utils 1.19.1
- https://developers.raycast.com/api-reference/user-interface/detail — Detail component, Detail.Metadata subcomponents
- https://developers.raycast.com/utilities/react-hooks/usecachedpromise — useCachedPromise API, revalidate(), keepPreviousData
- https://developers.raycast.com/utilities/react-hooks/usecachedstate — useCachedState API
- https://developers.raycast.com/api-reference/keyboard — Keyboard.Shortcut type, Cmd+R pattern
- https://developers.raycast.com/api-reference/user-interface/colors — Color enum constants
- https://developers.raycast.com/api-reference/feedback/toast — Toast.Style, showToast animated pattern
- https://developers.raycast.com/information/lifecycle — command unmount behavior, setInterval cleanup importance

### Secondary (MEDIUM confidence)
- https://developers.raycast.com/utilities/react-hooks/usefetch — verified useFetch supports custom headers; confirms useCachedPromise is better for function-based fetching
- https://developers.raycast.com/api-reference/user-interface/actions — Action component, built-in shortcut pattern

### Tertiary (LOW confidence)
- WebSearch: Raycast timer extension patterns (unverified implementation details — confirmed setInterval/useEffect is the standard approach via lifecycle docs)

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all packages are already installed and versions confirmed from package.json
- API response typing: HIGH — exact shape confirmed from production Swift code that already works
- Architecture (useCachedPromise): HIGH — verified directly from official Raycast docs
- Pace calculation: MEDIUM — logic is derived; no official Anthropic documentation on window timing semantics
- Countdown timer pattern: HIGH — standard React useEffect/setInterval, confirmed compatible with Raycast lifecycle

**Research date:** 2026-02-22
**Valid until:** 2026-03-24 (30 days — @raycast/api is stable; @raycast/utils minor versions release frequently but APIs are backward-compatible)
