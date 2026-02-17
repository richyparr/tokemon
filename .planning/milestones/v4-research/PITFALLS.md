# Domain Pitfalls: v4.0 Raycast Extension

**Domain:** Building a standalone Raycast extension for Claude usage monitoring
**Researched:** 2026-02-18
**Confidence:** HIGH (verified against official Raycast developer documentation)

---

## Critical Pitfalls

Mistakes that cause store rejection, broken functionality, or rewrites.

### Pitfall 1: Keychain Access Request Causes Automatic Store Rejection

**What goes wrong:**
Developers coming from macOS/Swift backgrounds assume they can use Keychain APIs for secure credential storage. Raycast extensions requesting Keychain Access are automatically rejected from the store. This is a deliberate security policy.

**Why it happens:**
The native Tokemon macOS app uses Keychain extensively for OAuth tokens. Teams naturally assume the same pattern applies to Raycast. It doesn't.

**Consequences:**
- Extension rejected during review with no recourse
- Significant rework required to use Raycast's storage APIs
- Wasted development time on an incompatible approach

**Prevention:**
- Use Raycast's built-in secure storage mechanisms:
  - Password preferences (`type: "password"`) for API tokens entered by users
  - `LocalStorage` API for extension-specific data (encrypted, extension-isolated)
  - OAuth utilities with built-in `setTokens()`/`getTokens()` for OAuth flows
- Never import or reference macOS Keychain APIs

```typescript
// WRONG: Don't do this
import { exec } from "child_process";
exec("security add-generic-password ..."); // Will be rejected

// RIGHT: Use Raycast's OAuth token storage
import { OAuth } from "@raycast/api";
const client = new OAuth.PKCEClient({ ... });
await client.setTokens(tokenSet);
```

**Detection:**
- Any import of `child_process` with `security` commands
- References to Keychain in code
- Store reviewer feedback mentioning security policy

**Phase to address:** Phase 1 (Foundation) -- establish correct credential storage patterns from day one.

**Confidence:** HIGH -- verified via [Raycast Store Submission Guidelines](https://developers.raycast.com/basics/prepare-an-extension-for-store) and [Raycast Security Documentation](https://developers.raycast.com/information/security)

---

### Pitfall 2: OAuth State Mismatch During Development Hot Reload

**What goes wrong:**
While developing OAuth flows, developers save a file during an active authorization redirect. This triggers Raycast's hot reload, which reinitializes the OAuth client with a new state. When the redirect returns, the state doesn't match, causing authorization to fail silently or with cryptic errors.

**Why it happens:**
Raycast's development mode (`npm run dev`) watches for file changes and reloads the extension. OAuth flows rely on state parameters that are generated on the client. Reload = new client = new state = mismatch.

**Consequences:**
- OAuth appears randomly broken during development
- Developers blame the OAuth provider or their code
- Hours lost debugging a development environment issue

**Prevention:**
- **Never save files during an active OAuth redirect flow**
- Complete the OAuth flow fully before making code changes
- When testing OAuth, use `npm run build` and load the built extension for more stable testing
- Add development notes warning team members about this behavior

**Detection:**
- OAuth works sometimes but not others during development
- Errors mentioning "state mismatch" or "invalid state"
- OAuth works in production but fails during dev mode

**Phase to address:** Phase 1 (Foundation) -- document this in development setup guide.

**Confidence:** HIGH -- explicitly documented in [Raycast OAuth API Reference](https://developers.raycast.com/api-reference/oauth)

---

### Pitfall 3: PKCE Required But Provider Gives Client Secret

**What goes wrong:**
Raycast mandates PKCE (Proof Key for Code Exchange) flow for all OAuth. Some providers (including some enterprise setups) still return a client secret during app registration. Developers hardcode this secret in the extension, which:
1. Is a security vulnerability (secrets visible in open-source code)
2. May cause the OAuth flow to fail (PKCE doesn't use secrets)
3. Will cause store rejection

**Why it happens:**
Legacy OAuth patterns used client secrets. Many tutorials still reference them. Providers return secrets even when they're not needed for PKCE.

**Consequences:**
- Security vulnerability if secret is committed
- Store rejection for hardcoded secrets
- OAuth failures if provider expects different flow

**Prevention:**
- Use PKCE-only flow (client secret not needed)
- When registering OAuth app, select "desktop", "native", or "mobile" app type
- If provider doesn't support PKCE, use Raycast's PKCE proxy: `oauth.raycast.com`
- Never commit client secrets; if accidentally committed, rotate immediately

```typescript
// PKCE client setup - no secret needed
const client = new OAuth.PKCEClient({
  redirectMethod: OAuth.RedirectMethod.Web,
  providerName: "Claude",
  providerIcon: Icon.PersonCircle,
  description: "Connect your Claude account",
});
```

**Detection:**
- `clientSecret` appearing anywhere in code
- OAuth app registered as "web" or "server" type
- OAuth failures with PKCE-supporting providers

**Phase to address:** Phase 1 (Foundation) -- use PKCE-only from the start with Claude's OAuth.

**Confidence:** HIGH -- verified via [Raycast OAuth Documentation](https://developers.raycast.com/api-reference/oauth)

---

### Pitfall 4: Menu Bar Command Never Unloads Due to isLoading Stuck True

**What goes wrong:**
Menu bar commands must set `isLoading={false}` when execution completes. If the async operation fails or the developer forgets to set it false on all code paths, the command remains in memory indefinitely, draining battery and potentially causing memory leaks.

**Why it happens:**
Unlike regular commands, menu bar commands' lifecycle is tied to `isLoading`. Developers set it true at the start but forget to handle all exit paths (success, error, timeout).

**Consequences:**
- Battery drain from perpetually running command
- Memory leaks over time
- Poor user experience
- Potential store rejection for performance issues

**Prevention:**
- Always wrap async operations in try/finally that sets `isLoading={false}`
- Use `useCachedPromise` or `usePromise` hooks which manage loading state automatically
- Test error paths, not just happy paths

```typescript
// WRONG: Loading state can get stuck
const [isLoading, setIsLoading] = useState(true);
useEffect(() => {
  fetchData().then(data => {
    setData(data);
    setIsLoading(false); // What if fetchData() throws?
  });
}, []);

// RIGHT: Always complete loading state
const [isLoading, setIsLoading] = useState(true);
useEffect(() => {
  fetchData()
    .then(setData)
    .catch(handleError)
    .finally(() => setIsLoading(false)); // Always executes
}, []);

// BEST: Use Raycast hooks that handle this
const { data, isLoading } = usePromise(fetchData);
```

**Detection:**
- Menu bar icon shows loading spinner indefinitely
- Activity Monitor shows extension process persisting
- Extension not responding to background refresh cycles

**Phase to address:** Phase 2 (Menu Bar) -- establish loading state patterns before building menu bar UI.

**Confidence:** HIGH -- verified via [Raycast Menu Bar Commands Documentation](https://developers.raycast.com/api-reference/menu-bar-commands)

---

### Pitfall 5: Duplicate MenuBarExtra.Items Silently Break onAction Handlers

**What goes wrong:**
Placing identical `MenuBarExtra.Item` components at the same level (siblings directly under `MenuBarExtra` or within the same `Submenu`) causes their `onAction` handlers to malfunction. No error is thrown; actions simply don't execute.

**Why it happens:**
Raycast uses item identity for action routing. Duplicate items at the same level create ambiguous identity. This is a silent failure -- the UI renders correctly but actions break.

**Consequences:**
- Menu items appear to work but clicking does nothing
- Intermittent failures (sometimes one works, sometimes the other)
- Hours debugging "why doesn't this click work"

**Prevention:**
- Ensure unique titles for sibling items
- Use keys if generating items dynamically
- If you need repeated labels, add unique suffixes or use different levels (submenus)

```typescript
// WRONG: Duplicate items at same level
<MenuBarExtra>
  <MenuBarExtra.Item title="Refresh" onAction={refreshA} />
  <MenuBarExtra.Item title="Refresh" onAction={refreshB} />  {/* Won't work! */}
</MenuBarExtra>

// RIGHT: Unique titles
<MenuBarExtra>
  <MenuBarExtra.Item title="Refresh Usage" onAction={refreshUsage} />
  <MenuBarExtra.Item title="Refresh Accounts" onAction={refreshAccounts} />
</MenuBarExtra>

// RIGHT: Or use submenu for grouping
<MenuBarExtra>
  <MenuBarExtra.Submenu title="Refresh">
    <MenuBarExtra.Item title="Usage" onAction={refreshUsage} />
    <MenuBarExtra.Item title="Accounts" onAction={refreshAccounts} />
  </MenuBarExtra.Submenu>
</MenuBarExtra>
```

**Detection:**
- Menu items don't respond to clicks (no error, just nothing happens)
- Some duplicate items work, others don't
- onAction callbacks not being called (add console.log to verify)

**Phase to address:** Phase 2 (Menu Bar) -- establish unique naming convention for menu items.

**Confidence:** HIGH -- explicitly documented in [Raycast Menu Bar Commands](https://developers.raycast.com/api-reference/menu-bar-commands)

---

### Pitfall 6: Flickering Empty State View on Initial Load

**What goes wrong:**
When the command launches, it briefly shows an empty list before data arrives, causing a jarring flicker. This is a known store rejection reason for poor UX.

**Why it happens:**
Developers return an empty `<List>` or `<Grid>` before async data fetch completes. The component renders immediately with no items, then re-renders with data.

**Consequences:**
- Poor user experience
- Potential store rejection
- Users think the extension is broken

**Prevention:**
- Show loading indicator until data arrives (don't render empty list)
- Use `isLoading` prop on top-level components
- Check for undefined data before rendering items

```typescript
// WRONG: Causes flicker
function Command() {
  const [items, setItems] = useState([]);  // Starts empty
  useEffect(() => { fetchItems().then(setItems); }, []);
  return <List>{items.map(i => <List.Item key={i.id} title={i.name} />)}</List>;
}

// RIGHT: Show loading until data ready
function Command() {
  const { data, isLoading } = usePromise(fetchItems);
  return (
    <List isLoading={isLoading}>
      {data?.map(i => <List.Item key={i.id} title={i.name} />)}
    </List>
  );
}
```

**Detection:**
- Brief flash of "No items" before data appears
- Store reviewer feedback about loading states
- User reports of "blank screen" on launch

**Phase to address:** Phase 1 (Foundation) -- establish data loading patterns before building any views.

**Confidence:** HIGH -- verified via [Raycast Best Practices](https://developers.raycast.com/information/best-practices)

---

### Pitfall 7: API Rate Limits Interpreted as Authentication Failure

**What goes wrong:**
When Claude's API returns 429 (rate limited), the extension interprets this as invalid credentials and logs the user out, clears tokens, or shows "authentication failed" errors.

**Why it happens:**
Generic error handling treats all 4xx responses as client errors. Rate limits are transient server-side throttling, not authentication issues.

**Consequences:**
- Users logged out during heavy usage
- Need to re-authenticate repeatedly
- Lost trust in extension reliability

**Prevention:**
- Explicitly check for 429 status before generic error handling
- On 429: retain current auth, show "rate limited" message, implement exponential backoff
- Never clear credentials on rate limit errors

```typescript
async function fetchUsage() {
  try {
    const response = await fetch(USAGE_API, { headers });
    if (response.status === 429) {
      // Rate limited - DON'T clear auth
      const retryAfter = response.headers.get('Retry-After') || '60';
      showToast(Toast.Style.Failure, "Rate limited", `Try again in ${retryAfter}s`);
      return cachedData; // Return cached data
    }
    if (response.status === 401) {
      // Actually unauthorized - clear tokens
      await clearTokens();
      throw new Error("Please re-authenticate");
    }
    return response.json();
  } catch (error) {
    // Handle network errors without clearing auth
  }
}
```

**Detection:**
- Users report being logged out during normal use
- "Authentication failed" errors that resolve on retry
- Usage spikes correlate with logout reports

**Phase to address:** Phase 1 (Foundation) -- implement proper HTTP status handling in API client.

**Confidence:** HIGH -- verified via [GitHub Extension Rate Limit Issue](https://github.com/raycast/extensions/issues/12664)

---

### Pitfall 8: Background Refresh Corrupts Shared State

**What goes wrong:**
Menu bar commands use background refresh (`interval` property). If the background execution writes to shared state while a user-triggered execution is also running, race conditions corrupt data. Results: garbled UI, missing data, crashes.

**Why it happens:**
Background refresh runs on a schedule, independent of user actions. Without synchronization, concurrent writes conflict.

**Consequences:**
- Data appears randomly corrupted
- Intermittent crashes that are hard to reproduce
- User complaints about "weird numbers" appearing

**Prevention:**
- Use `environment.launchType` to distinguish background vs user-triggered
- Implement optimistic locking or mutex patterns for shared state
- Use atomic writes to LocalStorage
- Consider separate cache keys for background vs foreground data

```typescript
import { environment, LaunchType } from "@raycast/api";

export default function Command() {
  const isBackground = environment.launchType === LaunchType.Background;

  // Background refresh: update cache silently
  if (isBackground) {
    return updateCacheQuietly();
  }

  // User launch: show UI with cached data, then refresh
  return <MenuBarExtra>...</MenuBarExtra>;
}
```

**Detection:**
- Data inconsistencies that appear randomly
- Issues more common with lower refresh intervals
- Console shows overlapping fetch operations

**Phase to address:** Phase 2 (Menu Bar) -- design cache/refresh strategy before implementing background refresh.

**Confidence:** HIGH -- verified via [Raycast Background Refresh Documentation](https://developers.raycast.com/information/lifecycle/background-refresh)

---

### Pitfall 9: Using Default Raycast Icon Causes Store Rejection

**What goes wrong:**
Developers use the default Raycast icon during development and forget to replace it before submission. Extensions using the default icon are rejected.

**Why it happens:**
The default icon works fine during development. It's easy to forget to create a custom icon before submission.

**Consequences:**
- Store rejection
- Delay in publishing
- Scrambling to create an icon at the last minute

**Prevention:**
- Create custom icon early in development (512x512 PNG)
- Ensure icon works in both light and dark modes
- Test icon appearance in Raycast before submission
- Add to pre-submission checklist

**Detection:**
- Store rejection feedback mentioning icon
- Extension using `icon-512.png` that looks like default
- `npm run build` warnings about icon

**Phase to address:** Phase 1 (Foundation) -- create Tokemon-branded icon for Raycast extension.

**Confidence:** HIGH -- verified via [Raycast Store Submission Guidelines](https://developers.raycast.com/basics/prepare-an-extension-for-store)

---

### Pitfall 10: LocalStorage Used for Large Data Sets

**What goes wrong:**
Developers store large amounts of usage history or analytics data in Raycast's LocalStorage API. The API is not designed for large data and performance degrades.

**Why it happens:**
LocalStorage is convenient and secure. Developers assume it scales like browser localStorage or filesystem storage.

**Consequences:**
- Slow extension startup
- UI lag when reading/writing data
- Potential data loss if limits exceeded

**Prevention:**
- Use LocalStorage only for small config/preferences
- For large data: use filesystem APIs (Node's `fs`) writing to extension support directory
- Implement data pagination/rolling windows for history
- Cache only recent/relevant data in LocalStorage

```typescript
import { environment } from "@raycast/api";
import fs from "fs";
import path from "path";

// For large data, use filesystem
const dataPath = path.join(environment.supportPath, "usage-history.json");

async function saveHistory(history: UsageData[]) {
  await fs.promises.writeFile(dataPath, JSON.stringify(history));
}

async function loadHistory(): Promise<UsageData[]> {
  try {
    const data = await fs.promises.readFile(dataPath, "utf-8");
    return JSON.parse(data);
  } catch {
    return [];
  }
}
```

**Detection:**
- Extension launch noticeably slow
- LocalStorage operations timing out
- Console warnings about storage limits

**Phase to address:** Phase 3 (Data/History) -- design storage strategy before implementing history features.

**Confidence:** HIGH -- verified via [Raycast Storage Documentation](https://developers.raycast.com/api-reference/storage)

---

## OAuth/Credentials Pitfalls

Issues specific to authentication and token management.

### Pitfall 11: Refresh Token Not Stored, Users Re-authenticate Daily

**What goes wrong:**
OAuth token storage saves only the access token, not the refresh token. When the access token expires (often 1 hour), users must re-authenticate manually.

**Why it happens:**
Quick implementations only handle the access token. Refresh token logic is "added later" but often forgotten.

**Consequences:**
- Users prompted to authenticate daily or more often
- Poor user experience
- Complaints about "always logging me out"

**Prevention:**
- Always store the complete token set: accessToken, refreshToken, expiresIn, scope
- Implement proactive token refresh before expiration
- Use `tokenSet.isExpired()` which includes a buffer

```typescript
// Store complete token set
await client.setTokens({
  accessToken: tokens.access_token,
  refreshToken: tokens.refresh_token,
  expiresIn: tokens.expires_in,
  scope: tokens.scope,
});

// Before API calls, check and refresh if needed
const tokenSet = await client.getTokens();
if (tokenSet?.isExpired()) {
  const newTokens = await refreshAccessToken(tokenSet.refreshToken);
  await client.setTokens(newTokens);
}
```

**Detection:**
- Users report frequent re-authentication prompts
- Access token present but refresh token undefined
- Token expiration equals re-login frequency

**Phase to address:** Phase 1 (Foundation) -- implement complete OAuth flow with refresh from the start.

**Confidence:** HIGH -- verified via [Raycast OAuth API](https://developers.raycast.com/api-reference/oauth)

---

### Pitfall 12: Missing offline.access Scope Prevents Token Refresh

**What goes wrong:**
Some OAuth providers (Twitter is explicitly documented) require specific scopes like `offline.access` to return refresh tokens. Without this scope, you get access token only, and it cannot be refreshed.

**Why it happens:**
Developers copy minimal scope lists without understanding refresh token requirements vary by provider.

**Consequences:**
- No refresh token returned
- Users must re-authenticate when access token expires
- Can't implement silent token refresh

**Prevention:**
- Research provider's refresh token requirements
- Include offline/refresh scopes in authorization request
- Test that refresh token is actually returned

```typescript
// Check your provider's requirements for refresh tokens
const authRequest = await client.authorizationRequest({
  endpoint: "https://auth.example.com/oauth/authorize",
  clientId: "your-client-id",
  scope: "read write offline.access",  // Include offline scope!
});
```

**Detection:**
- Token response has no refresh_token field
- Provider documentation mentions offline scope requirement
- Token refresh attempts fail with "invalid_grant"

**Phase to address:** Phase 1 (Foundation) -- verify Claude OAuth scope requirements.

**Confidence:** HIGH -- verified via [Raycast OAuth Documentation](https://developers.raycast.com/api-reference/oauth)

---

## Menu Bar Pitfalls

Issues specific to menu bar extra commands.

### Pitfall 13: Menu Bar Disappears Due to macOS Space Constraints

**What goes wrong:**
Users have many menu bar items. macOS hides items that don't fit. The Raycast extension's menu bar icon isn't visible, and users think the extension is broken.

**Why it happens:**
Menu bar real estate is limited. macOS silently hides overflow items. This isn't a bug in the extension.

**Consequences:**
- Users report "extension doesn't show in menu bar"
- Support requests for a non-issue
- Confusion about whether extension is running

**Prevention:**
- Document this limitation in README
- Suggest tools like Bartender or HiddenBar
- Keep menu bar title short to minimize space usage
- Consider tooltip noting the extension is running

```typescript
// Keep title minimal to fit in menu bar
<MenuBarExtra
  icon={Icon.BarChart}
  title="45%"  // Short! Not "Claude Usage: 45% remaining"
  tooltip="Claude Usage Monitor - Click for details"
>
```

**Detection:**
- Support requests about missing menu bar icon
- Users with many menu bar items
- Works on some machines, not others

**Phase to address:** Phase 2 (Menu Bar) -- document limitation and design compact title.

**Confidence:** HIGH -- verified via [Raycast Menu Bar Documentation](https://developers.raycast.com/api-reference/menu-bar-commands)

---

### Pitfall 14: Background Refresh Interval Too Aggressive Drains Battery

**What goes wrong:**
Setting a short refresh interval (e.g., 10 seconds minimum) causes frequent network requests and code execution, draining laptop battery and potentially hitting API rate limits.

**Why it happens:**
Developers want "real-time" updates. The minimum interval feels like a safe default.

**Consequences:**
- Battery drain complaints
- API rate limit issues (see Pitfall 7)
- Users disable the extension to save battery

**Prevention:**
- Use the longest interval that still provides useful updates
- For usage monitoring, 5-15 minutes is usually sufficient
- Provide user preference to control refresh frequency
- Complete background execution as quickly as possible

```typescript
// In package.json, use reasonable interval
{
  "commands": [{
    "name": "menu-bar",
    "mode": "menu-bar",
    "interval": "15m"  // Not "10s"!
  }]
}
```

**Detection:**
- Activity Monitor shows frequent extension activity
- Battery usage complaints
- API rate limit errors

**Phase to address:** Phase 2 (Menu Bar) -- choose appropriate refresh interval based on use case.

**Confidence:** HIGH -- verified via [Raycast Background Refresh Documentation](https://developers.raycast.com/information/lifecycle/background-refresh)

---

### Pitfall 15: Platform Check Missing for macOS-Only Features

**What goes wrong:**
Menu bar commands are macOS-only. If the extension includes both regular commands and menu bar commands, and doesn't properly configure the `platforms` field, Windows users get broken functionality or errors.

**Why it happens:**
Development happens on macOS where everything works. Windows compatibility isn't tested.

**Consequences:**
- Errors for Windows Raycast users
- Store rejection for platform issues
- Bad reviews from Windows users

**Prevention:**
- Set `platforms` field correctly in package.json
- If extension has macOS-only features, either:
  - Mark entire extension as macOS-only
  - Separate menu bar command into macOS-only command
- Test on both platforms if supporting both

```json
{
  "platforms": ["macos"],  // If using menu bar
  // OR for mixed:
  "commands": [
    {
      "name": "search",
      "mode": "view",
      "platforms": ["macos", "windows"]
    },
    {
      "name": "menu-bar",
      "mode": "menu-bar",
      "platforms": ["macos"]  // Menu bar is macOS only
    }
  ]
}
```

**Detection:**
- Windows user complaints
- Store review feedback about platform
- Errors mentioning unavailable APIs on Windows

**Phase to address:** Phase 1 (Foundation) -- configure platforms correctly in manifest.

**Confidence:** HIGH -- verified via [Raycast Store Submission Guidelines](https://developers.raycast.com/basics/prepare-an-extension-for-store)

---

## Review Process Pitfalls

Issues specific to Raycast Store submission and review.

### Pitfall 16: MIT License Not Used, Causes Rejection

**What goes wrong:**
Extension uses a different license (Apache 2.0, GPL, proprietary) in package.json. Store requires MIT license for all public extensions.

**Why it happens:**
Developers use their preferred license or copy from other projects without checking Raycast's requirements.

**Consequences:**
- Store rejection
- Need to relicense (may have implications for contributors)
- Delay in publishing

**Prevention:**
- Set `"license": "MIT"` in package.json
- Include MIT LICENSE file in extension
- Verify before submission

**Detection:**
- Store rejection feedback
- package.json has non-MIT license
- npm run lint may warn

**Phase to address:** Phase 1 (Foundation) -- set correct license from project start.

**Confidence:** HIGH -- verified via [Raycast Store Submission Guidelines](https://developers.raycast.com/basics/prepare-an-extension-for-store)

---

### Pitfall 17: Extension Duplicates Existing Raycast Functionality

**What goes wrong:**
The extension provides features already available in Raycast or existing extensions. Review team rejects to keep store tidy.

**Why it happens:**
Developers don't thoroughly search existing extensions before building.

**Consequences:**
- Store rejection
- Wasted development effort
- May need to find unique angle or enhancement

**Prevention:**
- Search Raycast Store for similar extensions before starting
- Ensure clear differentiation from existing solutions
- Focus on unique value: Tokemon's specific Claude integration is differentiating
- Consider contributing to existing extension if overlap is significant

**Detection:**
- Store rejection mentioning existing extension
- Search results show similar functionality

**Phase to address:** Before Phase 1 -- validate extension concept against existing store offerings.

**Confidence:** HIGH -- verified via [Raycast Store Guidelines](https://manual.raycast.com/extensions)

---

### Pitfall 18: README Missing Required Setup Instructions

**What goes wrong:**
Extension requires API tokens, OAuth setup, or specific configuration but README doesn't explain how to set these up. Users can't use the extension; reviewers may reject.

**Why it happens:**
Developers know how to set things up and forget to document it.

**Consequences:**
- Poor user experience
- Bad reviews from confused users
- Potential store rejection

**Prevention:**
- Document all required setup steps in README
- Include screenshots for complex setup flows
- Test fresh install experience (or have someone else test)
- Cover: what credentials are needed, how to get them, where to enter them

**Detection:**
- User confusion in reviews/issues
- Store reviewer feedback
- Fresh install doesn't work without insider knowledge

**Phase to address:** Pre-submission -- complete README before store submission.

**Confidence:** HIGH -- verified via [Raycast Store Submission Guidelines](https://developers.raycast.com/basics/prepare-an-extension-for-store)

---

## Async Data Handling Pitfalls

Issues specific to React/async patterns in Raycast.

### Pitfall 19: usePromise Function Recreated on Every Render

**What goes wrong:**
The async function passed to `usePromise` is recreated on every render, but the hook assumes the function is constant. This causes unexpected re-executions or stale closure bugs.

**Why it happens:**
Standard React pattern is to define functions inline. `usePromise` has different assumptions than typical React hooks.

**Consequences:**
- Unexpected API calls on every render
- Stale data due to closure over old values
- Performance issues from excessive fetching

**Prevention:**
- Define fetch function outside component or use useCallback
- Use the `execute` flag for conditional execution
- Pass dependencies through the second argument array

```typescript
// WRONG: Function recreated every render
function Command() {
  const { data } = usePromise(async () => {
    return fetchData(someValue);  // someValue captured in closure
  });
}

// RIGHT: Stable function reference
const fetchData = async (value: string) => { /* ... */ };

function Command() {
  const { data } = usePromise(
    fetchData,
    [someValue]  // Dependencies passed properly
  );
}
```

**Detection:**
- Network tab shows excessive API calls
- Data appears stale despite recent fetch
- Performance degradation over time

**Phase to address:** Phase 1 (Foundation) -- establish correct usePromise patterns in base components.

**Confidence:** HIGH -- verified via [Raycast usePromise Documentation](https://developers.raycast.com/utilities/react-hooks/usepromise)

---

### Pitfall 20: No Graceful Degradation When Network Fails

**What goes wrong:**
Network request fails (offline, API down, timeout). Extension shows error and becomes unusable instead of showing cached data.

**Why it happens:**
Happy path development. Error handling shows toast but doesn't provide fallback UX.

**Consequences:**
- Extension unusable when offline
- Users can't see their last-known usage stats
- Poor perception of reliability

**Prevention:**
- Cache last successful data
- On error, show cached data with "last updated" indicator
- Provide manual refresh action
- Toast the error but don't block UI

```typescript
const { data, error, isLoading, revalidate } = useCachedPromise(
  fetchUsage,
  [],
  {
    initialData: getCachedUsage(),  // Start with cached data
    keepPreviousData: true,  // Don't clear on refetch
  }
);

useEffect(() => {
  if (error) {
    showToast(Toast.Style.Failure, "Offline", "Showing cached data");
  }
}, [error]);

// UI shows data (cached or fresh) regardless of error state
return <List>
  {data?.map(item => <List.Item ... />)}
</List>;
```

**Detection:**
- Extension blank/broken when offline
- No indication of cached vs fresh data
- Users report extension doesn't work on planes/subways

**Phase to address:** Phase 1 (Foundation) -- implement caching strategy before building UI.

**Confidence:** HIGH -- verified via [Raycast Best Practices](https://developers.raycast.com/information/best-practices)

---

## Minor Pitfalls

Issues that are annoying but have straightforward fixes.

### Pitfall 21: dotenv Package Included Unnecessarily

**What goes wrong:**
Developers install dotenv for environment variables. Raycast has its own preference system and doesn't use .env files. The dependency bloats the extension and may cause confusion.

**Prevention:**
- Use Raycast preferences for configuration
- Remove dotenv from dependencies
- Use environment variables only for build-time config, not runtime

---

### Pitfall 22: Manually Defining Preferences Interface

**What goes wrong:**
Developers manually create TypeScript interfaces for preferences. Raycast auto-generates these in `raycast-env.d.ts` and manual definitions can drift out of sync.

**Prevention:**
- Use auto-generated types from `raycast-env.d.ts`
- Don't duplicate interface definitions
- Run `npm run dev` to regenerate types when preferences change

---

### Pitfall 23: Long Titles Truncated in Menu Bar

**What goes wrong:**
Menu bar title is too long and gets truncated, making it unreadable or ugly.

**Prevention:**
- Keep menu bar titles very short (ideally just numbers or icons)
- Use tooltip for full context
- Test on real menu bar with other items

---

### Pitfall 24: Navigation Title Changed in Root Command

**What goes wrong:**
Developers set `navigationTitle` in the root command view. This is meant for nested screens only and causes confusion in the root.

**Prevention:**
- Only use `navigationTitle` in pushed/nested screens
- Root command uses the title from package.json manifest

---

### Pitfall 25: Action Panel Inconsistent Case or Missing Icons

**What goes wrong:**
Action items use inconsistent casing (sentence case vs title case) or some have icons while others don't. This causes a messy, unprofessional appearance.

**Prevention:**
- Use Title Case for all action panel items
- Either all actions have icons or none do
- Follow Apple Human Interface Guidelines for consistency

---

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| Foundation/Setup | Keychain access attempted | Use Raycast OAuth utils, LocalStorage |
| Foundation/Setup | Wrong license (not MIT) | Set MIT in package.json from start |
| Foundation/Setup | Default Raycast icon used | Create custom 512x512 icon early |
| OAuth Integration | PKCE not used correctly | Never hardcode secrets, use PKCE only |
| OAuth Integration | Dev hot reload breaks auth | Don't save files during OAuth flow |
| OAuth Integration | Missing refresh token | Include offline.access scope, store full token set |
| Menu Bar Command | isLoading stuck true | Use try/finally, prefer usePromise hook |
| Menu Bar Command | Duplicate items break actions | Ensure unique titles for sibling items |
| Menu Bar Command | Too aggressive refresh | Use 15m+ interval, complete quickly |
| Menu Bar Command | Windows users get errors | Set platforms: ["macos"] in manifest |
| Data Handling | Rate limit treated as auth error | Explicit 429 handling, retain auth |
| Data Handling | Large data in LocalStorage | Use filesystem for large datasets |
| Data Handling | No offline fallback | Cache last successful data |
| Store Submission | Missing README setup docs | Document all configuration steps |
| Store Submission | Duplicates existing extension | Search store before building |

---

## "Looks Done But Isn't" Checklist: Raycast Extension

- [ ] **Credentials:** Using Raycast OAuth utils, NOT Keychain APIs
- [ ] **OAuth:** PKCE flow only, no client secret in code
- [ ] **OAuth:** Refresh token stored with access token
- [ ] **OAuth:** Offline/refresh scope included in authorization request
- [ ] **Menu Bar:** isLoading set to false on ALL code paths (success, error, timeout)
- [ ] **Menu Bar:** No duplicate items at same level
- [ ] **Menu Bar:** Reasonable refresh interval (5m+)
- [ ] **Menu Bar:** platforms set to ["macos"] in manifest
- [ ] **Loading:** No flickering empty state on initial load
- [ ] **Error Handling:** 429 rate limits don't clear auth
- [ ] **Error Handling:** Network errors show cached data, not blank screen
- [ ] **Storage:** Large data uses filesystem, not LocalStorage
- [ ] **Store:** Custom icon created (512x512 PNG)
- [ ] **Store:** MIT license set in package.json
- [ ] **Store:** README includes all setup instructions
- [ ] **Store:** No existing extension with same functionality
- [ ] **React:** usePromise functions stable (not recreated per render)
- [ ] **UX:** Action panel uses consistent Title Case and icons

---

## Prevention Checklist by Development Stage

### Before Writing Code
- [ ] Search Raycast Store for similar extensions
- [ ] Verify Claude's OAuth supports PKCE
- [ ] Research Claude OAuth scope requirements for refresh tokens
- [ ] Create custom extension icon

### During Development
- [ ] Don't save files during active OAuth testing
- [ ] Use npm run dev for iteration
- [ ] Test error paths, not just happy paths
- [ ] Check network tab for excessive API calls

### Before Store Submission
- [ ] MIT license in package.json
- [ ] Custom icon (not default)
- [ ] README with setup instructions
- [ ] npm run build passes
- [ ] npm run lint passes
- [ ] Test fresh install flow
- [ ] Test offline behavior
- [ ] Test on both light/dark themes

---

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Keychain access used | HIGH | Complete rewrite of credential storage |
| Client secret hardcoded | MEDIUM | Rotate secret, remove from code, use PKCE |
| isLoading never false | LOW | Add finally blocks, use usePromise |
| Duplicate menu items | LOW | Rename items to be unique |
| No refresh token | MEDIUM | Add scope, re-test auth flow, may need re-auth |
| Rate limit causes logout | LOW | Add 429 handling, retain auth state |
| Wrong license | LOW | Change package.json, add LICENSE file |
| Default icon | LOW | Create and add custom icon |
| Large data in LocalStorage | MEDIUM | Migrate to filesystem storage |
| Missing README | LOW | Write documentation |

---

## Sources

### Official Raycast Documentation (HIGH confidence)
- [Raycast Store Submission Guidelines](https://developers.raycast.com/basics/prepare-an-extension-for-store)
- [Raycast OAuth API Reference](https://developers.raycast.com/api-reference/oauth)
- [Raycast OAuth Utilities](https://developers.raycast.com/utilities/oauth)
- [Raycast Menu Bar Commands](https://developers.raycast.com/api-reference/menu-bar-commands)
- [Raycast Background Refresh](https://developers.raycast.com/information/lifecycle/background-refresh)
- [Raycast Best Practices](https://developers.raycast.com/information/best-practices)
- [Raycast Security](https://developers.raycast.com/information/security)
- [Raycast Storage API](https://developers.raycast.com/api-reference/storage)
- [Raycast usePromise Hook](https://developers.raycast.com/utilities/react-hooks/usepromise)
- [Raycast Extensions Guidelines](https://manual.raycast.com/extensions)

### Community/Real-World Issues (MEDIUM confidence)
- [GitHub Extension Rate Limit Issue #12664](https://github.com/raycast/extensions/issues/12664)
- [Raycast Extension Building Guide - David Alecrim](https://www.davidalecrim.dev/articles/raycast-extension-building-guide/)
- [My First Raycast Extension Journey](https://www.ypplog.cn/en/raycast-extension-development-experience/)

---

*Pitfalls research for: Tokemon v4.0 Raycast Extension*
*Domain: Building a standalone Raycast extension for Claude usage monitoring*
*Researched: 2026-02-18*
