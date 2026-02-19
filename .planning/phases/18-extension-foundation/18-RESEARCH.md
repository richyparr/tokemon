# Phase 18: Extension Foundation - Research

**Researched:** 2026-02-19
**Domain:** Raycast extension scaffolding, TypeScript/React, credential storage, branding
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Use Raycast preferences for the token field (password type) AND a dedicated setup command that guides users there
- Icon: Reuse the existing Tokemon macOS app icon (or close variant) for brand consistency
- Command naming: "tokemon" must be lowercase; Claude decides the rest based on Raycast store conventions
- Standalone with nod identity — works independently without the macOS app, but references "by tokemon" and links to the full app for power features
- Prettier + ESLint for code style

### Claude's Discretion
- First-run experience: whether to show a welcome screen or jump straight to setup
- Token validation: live validation vs save-then-check (pick best Raycast UX pattern)
- Error handling on invalid/expired token: inline error vs toast (use Raycast-native pattern)
- Guidance level for token acquisition: tailor for the Raycast developer audience
- Context/explanation: balance brevity with necessary context
- Token source: use whatever approach the macOS app already uses for OAuth token discovery
- Cross-app import: weigh complexity vs value of detecting Tokemon.app credentials
- Project location: pick based on development and Raycast publishing needs
- Code sharing with Swift app: pick based on maintainability
- Dependencies: use what the extension actually needs, no more

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope
</user_constraints>

---

## Summary

Raycast extensions are built with TypeScript, React, and `@raycast/api` scaffolded via `npm create @raycast/extension`. The project lives in a self-contained directory with a `package.json` that doubles as the Raycast manifest. Publishing works by running `npm run publish` which opens a PR in the `raycast/extensions` monorepo; the extension ships once Raycast merges the PR.

For credential handling, the locked decision combines two mechanisms: a `password`-type preference (stored in Raycast's encrypted local database — NOT macOS Keychain, which causes Store rejection) AND a dedicated setup command that guides users to that preference panel. When `required: true` is set on a preference, Raycast gates the extension on that preference being filled. The best UX pattern is: check preference on command load, if empty show a `Detail` view with instructions + an `openExtensionPreferences()` action; if filled, validate against the API on first use and show `showToast` failure with an "Open Preferences" action on error.

The existing Tokemon app's OAuth endpoint (`https://api.anthropic.com/api/oauth/usage`), token refresh endpoint (`https://console.anthropic.com/v1/oauth/token`), and client ID (`9d1c250a-e61b-44d9-88ed-5944d1962f5e`) are directly reusable in the TypeScript extension — no code sharing infrastructure needed, just copy the constants and reimplement the `fetch` calls in TypeScript.

**Primary recommendation:** Scaffold with `npm create @raycast/extension`, place in a sibling `tokemon-raycast/` directory, use `password` preference + `Detail` setup command pattern, and export the existing `AppIcon.icns` as a 512×512 PNG for the `assets/icon.png`.

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `@raycast/api` | 1.104.5 (latest) | UI components, preferences, storage, toasts | Required by Raycast; zero alternatives |
| `@raycast/utils` | latest | `useLocalStorage`, `useCachedState`, `useCachedPromise`, `useForm`, `showFailureToast` | Official companion, ships with scaffolding |
| TypeScript | bundled via tsconfig | Type safety, `Preferences` namespace auto-generation | Required; `raycast-env.d.ts` auto-generates preference types |
| React | bundled via @raycast/api | JSX for command views | Required; Raycast renders React trees |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `@raycast/eslint-config` | bundled via scaffold | Opinionated linting with Raycast plugin | Scaffolded automatically; includes `@raycast/prefer-placeholders` rule |
| Prettier | bundled via scaffold | Code formatting via `.prettierrc` | Scaffolded automatically |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `password` preference | `LocalStorage.setItem` for token | Preference shows in Raycast Preferences UI, which users expect for credentials; LocalStorage is invisible to users — worse UX |
| `useLocalStorage` for token | `useCachedState` | `useLocalStorage` persists across restarts; `useCachedState` is session-only. For a token, `useLocalStorage` wins |
| `Detail` setup screen | `no-view` command that opens preferences | `Detail` gives richer guidance (markdown instructions, link to claude.ai, copy token steps); better for developer audience |

**Installation (at scaffold time, no manual install needed):**
```bash
npm create @raycast/extension@latest
# Follow prompts: TypeScript template, extension name "tokemon"
cd tokemon-raycast
npm install
npm run dev
```

---

## Architecture Patterns

### Recommended Project Structure
```
tokemon-raycast/               # Sibling to Tokemon/ Swift project
├── assets/
│   ├── icon.png               # 512x512px — exported from AppIcon.icns
│   └── icon@dark.png          # Optional dark variant (same icon works for both)
├── src/
│   ├── index.tsx              # Main "tokemon" command (dashboard, Phase 19)
│   └── setup.tsx              # Setup command (Phase 18 deliverable)
├── .prettierrc                # Scaffolded; Raycast defaults
├── eslint.config.js           # Uses @raycast/eslint-config
├── package.json               # Manifest + dependencies
├── package-lock.json
├── tsconfig.json              # Scaffolded; do not edit
├── raycast-env.d.ts           # Auto-generated; do not edit
└── README.md                  # Required if setup instructions are non-trivial
```

**Note on project location:** Place `tokemon-raycast/` as a sibling to the Swift project root (`Tokemon/`), not inside it. Keeps Swift and Node entirely separate. When publishing to the Store, `npm run publish` handles the fork+PR automatically.

**Note on `index.tsx`:** Raycast requires the main command file to be named `index`. The `setup` command can be named freely. Phase 18 only ships `setup.tsx` with a stub `index.tsx` (to satisfy the manifest) — the full dashboard lands in Phase 19.

### Pattern 1: Password Preference Declaration (package.json)
**What:** Declare a `password`-type preference at the extension level so it appears in Raycast Preferences for all commands.
**When to use:** Any secret that users need to enter once and reuse across commands.

```json
// Source: https://developers.raycast.com/information/manifest
{
  "name": "tokemon",
  "title": "tokemon",
  "description": "Monitor your Claude usage at a glance",
  "icon": "icon.png",
  "author": "YOUR_RAYCAST_USERNAME",
  "platforms": ["macOS"],
  "categories": ["Developer Tools"],
  "license": "MIT",
  "preferences": [
    {
      "name": "oauthToken",
      "type": "password",
      "title": "Claude OAuth Token",
      "description": "Your Claude OAuth access token. Get it from claude.ai → Settings → API Keys.",
      "required": true
    }
  ],
  "commands": [
    {
      "name": "index",
      "title": "Dashboard",
      "subtitle": "tokemon",
      "description": "View your Claude usage",
      "mode": "view"
    },
    {
      "name": "setup",
      "title": "Setup",
      "subtitle": "tokemon",
      "description": "Configure your Claude OAuth token",
      "mode": "view"
    }
  ]
}
```

### Pattern 2: Reading the Preference Token in a Command
**What:** Use `getPreferenceValues` with auto-generated type for type-safe access.
**When to use:** Every command that calls the Claude API.

```typescript
// Source: https://developers.raycast.com/api-reference/preferences
import { getPreferenceValues, openExtensionPreferences, Detail, ActionPanel, Action } from "@raycast/api";

interface Preferences {
  oauthToken: string;
}

export default function Command() {
  const { oauthToken } = getPreferenceValues<Preferences>();

  if (!oauthToken) {
    return (
      <Detail
        markdown="## Setup Required\n\nEnter your Claude OAuth token to get started."
        actions={
          <ActionPanel>
            <Action title="Open Preferences" onAction={openExtensionPreferences} />
          </ActionPanel>
        }
      />
    );
  }

  // Proceed with API call...
}
```

### Pattern 3: Token Validation (save-then-check, Raycast-native)
**What:** Validate the token by making a real API call on first use rather than at preference-entry time. Show `Toast.Style.Failure` on error with an "Open Preferences" action.
**When to use:** Any command that first loads with a stored token.

This is the correct Raycast UX pattern: Raycast preferences have no built-in "validate on save" hook, so validation happens when the command runs. Users follow the error toast to fix the token.

```typescript
// Source: https://developers.raycast.com/utilities/functions/showfailuretoast
import { showToast, Toast, openExtensionPreferences } from "@raycast/api";

async function fetchUsage(token: string): Promise<UsageData> {
  const response = await fetch("https://api.anthropic.com/api/oauth/usage", {
    headers: {
      Authorization: `Bearer ${token}`,
      Accept: "application/json",
      "anthropic-beta": "oauth-2025-04-20",
    },
  });

  if (response.status === 401) {
    await showToast({
      style: Toast.Style.Failure,
      title: "Invalid token",
      message: "Update your Claude OAuth token in preferences.",
      primaryAction: {
        title: "Open Preferences",
        onAction: openExtensionPreferences,
      },
    });
    throw new Error("TOKEN_INVALID");
  }

  if (!response.ok) {
    throw new Error(`HTTP ${response.status}`);
  }

  return response.json();
}
```

### Pattern 4: Setup Command (Detail-based Guide)
**What:** A `view`-mode command that renders a markdown guide for how to get the OAuth token, with a direct action to open preferences.
**When to use:** First-run experience and whenever user needs token refresh guidance.

```typescript
// Source: https://developers.raycast.com/api-reference/user-interface/detail
import { Detail, ActionPanel, Action, openExtensionPreferences } from "@raycast/api";

const SETUP_GUIDE = `
# Welcome to tokemon

Monitor your Claude usage directly from Raycast — no app required.

## Get Your OAuth Token

1. Open [claude.ai](https://claude.ai) in your browser
2. Go to **Settings → API Keys**
3. Create or copy your OAuth access token
4. Paste it in the preferences panel below

---

*by [tokemon](https://tokemon.app) — also available as a macOS menu bar app*
`;

export default function SetupCommand() {
  return (
    <Detail
      markdown={SETUP_GUIDE}
      actions={
        <ActionPanel>
          <Action
            title="Enter Token in Preferences"
            onAction={openExtensionPreferences}
          />
        </ActionPanel>
      }
    />
  );
}
```

### Pattern 5: Icon Preparation
**What:** Export the existing macOS `AppIcon.icns` to a 512×512 PNG.
**When to use:** One-time preparation before building the extension.

```bash
# Export from .icns to PNG using sips (built into macOS)
sips -s format png \
  /path/to/Tokemon/Tokemon/Resources/AppIcon.icns \
  --out /path/to/tokemon-raycast/assets/icon.png \
  --resampleHeightWidth 512 512
```

Alternatively, use the Raycast Icon Maker at https://ray.so/icon as a design aid.

### Anti-Patterns to Avoid
- **Using macOS Keychain directly:** Raycast Store rejects extensions that request Keychain access. This is already locked: use password preferences only.
- **Setting `required: true` on the command-level setup preference:** Extension-level preferences apply to all commands. Command-level preferred for per-command settings only.
- **Building a Form-based token entry screen:** The Raycast-native pattern is preferences, not a custom form. A `Detail` that points to preferences is correct; a `Form.PasswordField` that writes to `LocalStorage` bypasses Raycast's built-in credential UI.
- **Calling Keychain-reading code from Claude Code:** The macOS app reads Claude Code's Keychain. The Raycast extension cannot do this — store rejection is confirmed. Manual token entry is the only approved path.
- **Not including `package-lock.json`:** Store submission requires it. Always commit it.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Encrypted credential storage | Custom encryption or file-based storage | `password`-type preference | Raycast stores it in its own encrypted local database; isolation per extension |
| Token persistence across commands | `LocalStorage.setItem("token", ...)` | `password` preference | Preferences appear in UI; LocalStorage is invisible to users |
| Loading/caching state | Manual `useState` + `useEffect` for async | `useCachedPromise` or `useLocalStorage` | Handles loading flags, error states, and re-validation automatically |
| Form validation | Manual error state tracking | `useForm` from `@raycast/utils` | Handles blur/change lifecycle, prevents invalid submit |
| Error toasts | Custom error UI | `showToast` / `showFailureToast` | Raycast-native; integrates with HUD fallback when window is closed |

**Key insight:** The Raycast API handles security, storage, and UI feedback through its own primitives. Reimplementing any of these with custom code introduces bugs, reduces consistency, and may cause Store rejection.

---

## Common Pitfalls

### Pitfall 1: Token Not in Preferences vs. Empty String
**What goes wrong:** `required: true` gates the extension on the field being non-empty, but the field can still contain whitespace. `getPreferenceValues` returns the raw string.
**Why it happens:** Raycast validates presence, not validity.
**How to avoid:** Always `trim()` the token and check truthiness before using it. Show the setup guide if trimmed value is empty.
**Warning signs:** Extension appears to work (preferences screen passes) but API calls return 401.

### Pitfall 2: Main Command Must Be Named `index`
**What goes wrong:** If the primary command file is named `dashboard.tsx` or anything other than `index.tsx`, Raycast does not recognize it as the default.
**Why it happens:** Raycast convention, not documented prominently.
**How to avoid:** Always create `src/index.tsx` as the primary command entry point, even if it's a stub in Phase 18.
**Warning signs:** Extension loads but primary command is missing from Raycast root search.

### Pitfall 3: Icon Size and Format
**What goes wrong:** Using an icon smaller than 512×512 or in a format other than PNG causes Store rejection. `.icns` files are not valid.
**Why it happens:** Store validation checks asset specifications.
**How to avoid:** Export `AppIcon.icns` → `assets/icon.png` at exactly 512×512 using `sips` before first `npm run dev`.
**Warning signs:** `npm run build` or Store submission fails with asset validation error.

### Pitfall 4: Missing `package-lock.json`
**What goes wrong:** Store submission is rejected if `package-lock.json` is absent.
**Why it happens:** Raycast requires reproducible installs for security review.
**How to avoid:** Always `npm install` (not `yarn` or `pnpm`) and commit `package-lock.json`.
**Warning signs:** `npm run publish` PR fails automated checks.

### Pitfall 5: Subtitle Duplication
**What goes wrong:** Setting subtitle to "tokemon" on a command titled "tokemon Dashboard" makes search results look redundant.
**Why it happens:** Guidelines say subtitles should add context, not repeat the title.
**How to avoid:** Use subtitle `"by tokemon"` on commands (adds ecosystem identity without duplication). Or omit subtitle on commands where the extension title is already "tokemon".
**Warning signs:** Raycast reviewer requests change during PR review.

### Pitfall 6: Node Version
**What goes wrong:** Raycast requires Node.js 22.14+. Using an older Node version produces cryptic build errors.
**Why it happens:** `@raycast/api` uses modern Node APIs.
**How to avoid:** Verify `node --version` >= 22.14 before scaffolding. Current environment has v24.12.0 — this is fine.
**Warning signs:** `npm run dev` fails immediately with `SyntaxError` or `ERR_UNSUPPORTED_FEATURE`.

---

## Code Examples

Verified patterns from official sources:

### Complete package.json Manifest
```json
// Source: https://developers.raycast.com/information/manifest
{
  "name": "tokemon",
  "title": "tokemon",
  "description": "Monitor your Claude AI usage at a glance — session and weekly limits, reset timers, and more.",
  "icon": "icon.png",
  "author": "YOUR_RAYCAST_USERNAME",
  "platforms": ["macOS"],
  "categories": ["Developer Tools"],
  "license": "MIT",
  "preferences": [
    {
      "name": "oauthToken",
      "type": "password",
      "title": "Claude OAuth Token",
      "description": "Your Claude OAuth access token. Run the Setup command for instructions.",
      "required": true
    }
  ],
  "commands": [
    {
      "name": "index",
      "title": "Dashboard",
      "subtitle": "tokemon",
      "description": "View your Claude session and weekly usage",
      "mode": "view"
    },
    {
      "name": "setup",
      "title": "Setup",
      "subtitle": "tokemon",
      "description": "Configure your Claude OAuth token",
      "mode": "view"
    }
  ],
  "dependencies": {
    "@raycast/api": "^1.104.5",
    "@raycast/utils": "^1.0.0"
  },
  "devDependencies": {
    "@raycast/eslint-config": "^1.0.0",
    "typescript": "^5.0.0"
  },
  "scripts": {
    "build": "ray build -e dist",
    "dev": "ray develop",
    "fix-lint": "ray lint --fix",
    "lint": "ray lint",
    "publish": "npx @raycast/api@latest publish"
  }
}
```

### useCachedState for Fast UI
```typescript
// Source: https://developers.raycast.com/utilities/react-hooks/usecachedstate
import { useCachedState } from "@raycast/utils";

// Persists the last known usage value so the UI is instant on reopen
const [cachedUsage, setCachedUsage] = useCachedState<UsageData | null>("usage-data", null);
```

### useLocalStorage for Persistent Token Metadata
```typescript
// Source: https://developers.raycast.com/utilities/react-hooks/uselocalstorage
import { useLocalStorage } from "@raycast/utils";

// Track when token was last validated (not the token itself — that's in preferences)
const { value: lastValidated, setValue: setLastValidated } = useLocalStorage<string>("last-validated", "");
```

### API Fetch with anthropic-beta Header
```typescript
// Derived from existing OAuthClient.swift — same endpoint, TypeScript equivalent
const USAGE_URL = "https://api.anthropic.com/api/oauth/usage";

async function fetchUsage(token: string) {
  const response = await fetch(USAGE_URL, {
    method: "GET",
    headers: {
      Authorization: `Bearer ${token.trim()}`,
      Accept: "application/json",
      "anthropic-beta": "oauth-2025-04-20",
      "User-Agent": "tokemon-raycast/1.0",
    },
  });

  if (response.status === 401) throw new Error("TOKEN_EXPIRED");
  if (response.status === 403) throw new Error("INSUFFICIENT_SCOPE");
  if (!response.ok) throw new Error(`HTTP_${response.status}`);

  return response.json();
}
```

### ESLint Config (extends Raycast default)
```javascript
// Source: https://developers.raycast.com/information/developer-tools/eslint
const { defineConfig } = require("eslint/config");
const raycastConfig = require("@raycast/eslint-config");

module.exports = defineConfig([
  ...raycastConfig,
  {
    rules: {
      "@raycast/prefer-placeholders": "warn",
    },
  },
]);
```

---

## API Reference: Key Endpoints (from existing Swift app)

These are already proven in the macOS app and directly portable to TypeScript:

| Constant | Value |
|----------|-------|
| Usage endpoint | `https://api.anthropic.com/api/oauth/usage` |
| Token refresh endpoint | `https://console.anthropic.com/v1/oauth/token` |
| OAuth client ID | `9d1c250a-e61b-44d9-88ed-5944d1962f5e` |
| Required header | `anthropic-beta: oauth-2025-04-20` |
| Required scope | `user:profile` |
| Token expiry field | `expiresAt` (milliseconds since epoch) |
| Token structure | `{ claudeAiOauth: { accessToken, refreshToken, expiresAt, scopes } }` |

**Note on token refresh:** The macOS app uses the refresh token to get a new access token. For Phase 18 (foundation only), the extension accepts a manually-entered token. Token refresh logic is deferred to a later phase — Phase 18 only needs to call the usage endpoint with the stored token and show an error toast if it fails.

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `.eslintrc.js` with `extends` | `eslint.config.js` with flat config + `defineConfig` | ESLint 9+ / Raycast v1.48.8+ | New scaffold uses flat config; existing tutorials using `extends` are outdated |
| Manual `useState` + `useEffect` for async | `useCachedPromise` from `@raycast/utils` | 2023 | Reduces boilerplate significantly |
| `useLocalStorage` as custom hook | `useLocalStorage` in `@raycast/utils` | 2024 | Official hook, no need to implement |
| `platforms: ["macOS"]` only | Can specify `["macOS", "Windows"]` | v1.103.0 (Sept 2025) | Phase 18 targets macOS only — omit Windows |

**Deprecated/outdated:**
- `@typescript-eslint/eslint-plugin` configured manually: Bundled in `@raycast/eslint-config`, do not add separately
- `OAuthService` from `@raycast/utils`: Built for full OAuth PKCE flows. Not appropriate here — we store a pre-obtained token, not implement OAuth authorization. Ignore OAuth utilities.

---

## Recommendations (Claude's Discretion Areas)

### Project location
Place in `tokemon-raycast/` at the same level as `Tokemon/` (Swift project). This keeps the Node project completely independent from the Swift project, avoids Xcode picking up JS files, and matches the layout expected when submitting to `raycast/extensions`.

### First-run experience
Skip the welcome screen. When `required: true` is on the preference, Raycast's own preference gate shows before any command runs. The `setup` command serves as an explicit guide for users who want instructions. No additional welcome screen needed.

### Token validation approach
Use **save-then-check** (validate on first API call). Raycast preferences have no "validate on save" hook. The correct pattern is: try the API call, show `Toast.Style.Failure` with "Open Preferences" action on 401/403. This is what every well-reviewed extension on the Store does.

### Error handling
Use `showToast` with `Toast.Style.Failure` for API errors, not inline UI error states. On 401: title "Token expired", message "Update your Claude OAuth token in preferences", primaryAction opens preferences. This is the Raycast-native pattern documented in best practices.

### Token acquisition guidance
In the setup command markdown, direct users to `claude.ai → Settings → API Keys`. Keep the guide brief — Raycast's developer audience doesn't need hand-holding, but a direct link and three clear steps is the right level.

### Cross-app import
Do NOT implement Claude Code Keychain reading. It causes Store rejection (confirmed in requirements, validated against Raycast security docs). Manual token entry only.

### Code sharing with Swift app
No code sharing. Swift and TypeScript cannot share code directly. Copy the API constants (`USAGE_URL`, `anthropic-beta` header, OAuth client ID) into a TypeScript `constants.ts` file. This is the right maintainability choice — the Swift and TypeScript implementations are independent.

### Subtitle for discoverability
Use `"tokemon"` as the extension title (lowercase per locked decision). Commands should have subtitle `"tokemon"` to match the extension identity in Raycast search results. This matches the GitLab extension pattern (commands have subtitle "GitLab") which is the established Store convention.

### Dependencies
Only `@raycast/api` and `@raycast/utils` needed for this phase. No additional packages.

---

## Open Questions

1. **Raycast Store username**
   - What we know: The `author` field in `package.json` must match the developer's Raycast Store account username.
   - What's unclear: The developer's Raycast username is not known from this research.
   - Recommendation: Planner should note this as a one-time manual step during scaffold (`npm create @raycast/extension` prompts for it).

2. **`icon@dark.png` necessity**
   - What we know: Raycast supports `icon@dark.png` for dark-mode variants. The Tokemon icon is designed to work on dark backgrounds (macOS menu bar uses it that way).
   - What's unclear: Whether the single exported `icon.png` will look acceptable on Raycast's light-mode background.
   - Recommendation: Export a single `icon.png` first; test in both Raycast themes via Preferences → Appearance. Add `icon@dark.png` only if the light-mode rendering looks wrong.

3. **Token refresh in Phase 18 scope**
   - What we know: The context says "OAuth token refresh handled automatically after initial entry" in prior decisions.
   - What's unclear: Whether Phase 18 should implement refresh logic or just validate.
   - Recommendation: Phase 18 should NOT implement token refresh — that's API behavior needed for Dashboard (Phase 19). Phase 18 only stores and validates the initial token. The planner should confirm this scope boundary.

---

## Sources

### Primary (HIGH confidence)
- `https://developers.raycast.com/information/manifest` — manifest fields, preference types, command modes verified
- `https://developers.raycast.com/information/file-structure` — project structure verified
- `https://developers.raycast.com/api-reference/preferences` — `getPreferenceValues`, preference types, `openExtensionPreferences` verified
- `https://developers.raycast.com/api-reference/storage` — `LocalStorage` API verified
- `https://developers.raycast.com/utilities/react-hooks/uselocalstorage` — `useLocalStorage` hook signature verified
- `https://developers.raycast.com/utilities/react-hooks/usecachedstate` — `useCachedState` hook signature verified
- `https://developers.raycast.com/utilities/getting-started` — `@raycast/utils` package and utilities verified
- `https://developers.raycast.com/information/security` — encryption model, password preference storage verified
- `https://developers.raycast.com/basics/prepare-an-extension-for-store` — icon 512×512 PNG, MIT license, naming conventions verified
- `https://developers.raycast.com/basics/publish-an-extension` — `npm run publish` → PR workflow verified
- `https://developers.raycast.com/information/developer-tools/eslint` — `@raycast/eslint-config` verified
- `https://developers.raycast.com/information/best-practices` — Toast failure pattern, loading state patterns verified
- `https://developers.raycast.com/misc/changelog` — v1.103.0 (Sept 2025) cross-platform changes verified
- `/Users/richardparr/Tokemon/Tokemon/Utilities/Constants.swift` — API endpoints, client ID, keychain service from existing app
- `/Users/richardparr/Tokemon/Tokemon/Services/OAuthClient.swift` — fetch pattern, header requirements from existing app
- `/Users/richardparr/Tokemon/Tokemon/Models/OAuthUsageResponse.swift` — response structure from existing app

### Secondary (MEDIUM confidence)
- WebSearch results on Raycast Store convention for subtitles and naming — confirmed against official "prepare for store" docs
- GitLab extension `package.json` as a real-world reference for categories, command structure pattern

### Tertiary (LOW confidence)
- None — all critical claims verified against official documentation

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — verified against official Raycast docs and npm registry
- Architecture: HIGH — verified against official file structure docs and real extensions
- Pitfalls: HIGH — derived from official guidelines, Store submission docs, and confirmed requirements (`REQUIREMENTS.md` confirms Keychain rejection)
- API endpoints: HIGH — read directly from existing working Swift implementation

**Research date:** 2026-02-19
**Valid until:** 2026-04-19 (stable API; Raycast releases frequently but the extension model is stable)
