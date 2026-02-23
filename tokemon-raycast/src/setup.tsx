import { Action, ActionPanel, Detail, getPreferenceValues, openExtensionPreferences } from "@raycast/api";
import { useCachedState, useLocalStorage } from "@raycast/utils";
import { extractToken } from "./api";
import type { Profile } from "./types";
import { PROFILES_KEY, ACTIVE_PROFILE_KEY } from "./types";

interface Preferences {
  oauthToken: string;
}

const SETUP_GUIDE = `# Welcome to tokemon

Monitor your Claude usage directly from Raycast.

## How to get your OAuth token

**Option A — Copy from macOS Keychain (recommended):**

1. Open **Keychain Access** (search in Spotlight)
2. Search for \`Claude Code-credentials\`
3. Double-click the entry → click **Show Password**
4. Copy the entire value and paste it into preferences — tokemon will extract the token automatically

**Option B — Copy from browser:**

1. Open [claude.ai](https://claude.ai) in your browser and sign in
2. Open Developer Tools (F12 or ⌥⌘I)
3. Go to the **Network** tab, then trigger any page load
4. Filter requests by \`api.anthropic.com\`
5. Click any request → **Headers** → copy the value after \`Bearer \`

---

Press **Enter Token in Preferences** below to paste your token.

---

*by [tokemon](https://tokemon.app) — also available as a macOS menu bar app*
`;

const ALREADY_CONFIGURED_GUIDE = `# tokemon — Token Configured

Your OAuth token is already set. Use the **Dashboard** command to view your Claude usage.

If your token has expired, press **Update Token** below to enter a new one.

---

*by [tokemon](https://tokemon.app) — also available as a macOS menu bar app*
`;

export default function SetupCommand() {
  const { oauthToken } = getPreferenceValues<Preferences>();

  // All hooks called unconditionally before early returns
  const [activeProfileId] = useCachedState<string | null>(ACTIVE_PROFILE_KEY, null);
  const { value: profiles } = useLocalStorage<Profile[]>(PROFILES_KEY, []);

  // Resolve token: active profile > preference fallback
  const activeProfile = profiles?.find((p) => p.id === activeProfileId);
  const isConfigured = extractToken(activeProfile?.token ?? oauthToken).length > 0;

  if (isConfigured) {
    return (
      <Detail
        markdown={ALREADY_CONFIGURED_GUIDE}
        actions={
          <ActionPanel>
            <Action title="Update Token" onAction={openExtensionPreferences} />
          </ActionPanel>
        }
      />
    );
  }

  return (
    <Detail
      markdown={SETUP_GUIDE}
      actions={
        <ActionPanel>
          <Action title="Enter Token in Preferences" onAction={openExtensionPreferences} />
        </ActionPanel>
      }
    />
  );
}
