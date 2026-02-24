import { getPreferenceValues, LocalStorage } from "@raycast/api";
import { useCachedState, useLocalStorage } from "@raycast/utils";
import { useEffect, useMemo, useState } from "react";
import { extractToken } from "./api";
import type { TokenSource } from "./api";
import type { OAuthCredentials, Profile } from "./types";
import { ACTIVE_PROFILE_KEY, PREF_CREDENTIALS_KEY, PROFILES_KEY } from "./types";

interface Preferences {
  oauthToken: string;
}

interface UseTokenSourceResult {
  tokenSource: TokenSource | null;
  isLoading: boolean;
}

/**
 * Shared hook that resolves the current token source.
 * Active profile > preference fallback. Includes credentials if available.
 * Returns a memoized TokenSource so useCachedPromise doesn't re-trigger on every render.
 */
export function useTokenSource(): UseTokenSourceResult {
  const { oauthToken } = getPreferenceValues<Preferences>();
  const [activeProfileId] = useCachedState<string | null>(ACTIVE_PROFILE_KEY, null);
  const { value: profiles, isLoading: profilesLoading } = useLocalStorage<Profile[]>(PROFILES_KEY, []);
  const [prefCredentials, setPrefCredentials] = useState<OAuthCredentials | undefined>(undefined);
  const [prefCredsLoaded, setPrefCredsLoaded] = useState(false);

  // Load preference-token credentials from LocalStorage
  useEffect(() => {
    LocalStorage.getItem<string>(PREF_CREDENTIALS_KEY).then((raw) => {
      if (raw) {
        try {
          setPrefCredentials(JSON.parse(raw));
        } catch {
          // ignore
        }
      }
      setPrefCredsLoaded(true);
    });
  }, []);

  const isLoading = profilesLoading || !prefCredsLoaded;

  // Derive stable primitives for the memo dependency array
  const activeProfile = profiles?.find((p) => p.id === activeProfileId);
  const resolvedToken = isLoading
    ? extractToken(oauthToken)
    : activeProfile
      ? activeProfile.token
      : extractToken(oauthToken);
  const resolvedOrigin = isLoading
    ? "preference"
    : activeProfile
      ? activeProfile.id
      : "preference";
  const resolvedCredentials = isLoading
    ? undefined
    : activeProfile
      ? activeProfile.credentials
      : prefCredentials;

  // Serialize credentials to a stable string for memo comparison
  const credentialsKey = resolvedCredentials
    ? `${resolvedCredentials.accessToken}:${resolvedCredentials.refreshToken}:${resolvedCredentials.expiresAt}`
    : "";

  const tokenSource = useMemo<TokenSource | null>(() => {
    if (!resolvedToken) return null;
    return {
      accessToken: resolvedToken,
      credentials: resolvedCredentials,
      origin: resolvedOrigin,
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [resolvedToken, resolvedOrigin, credentialsKey]);

  return { tokenSource, isLoading };
}
