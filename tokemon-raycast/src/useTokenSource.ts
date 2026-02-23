import { getPreferenceValues, LocalStorage } from "@raycast/api";
import { useCachedState, useLocalStorage } from "@raycast/utils";
import { useEffect, useState } from "react";
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

  if (profilesLoading || !prefCredsLoaded) {
    // Still loading — return a temporary source using preference token to avoid flicker
    const fallbackToken = extractToken(oauthToken);
    if (!fallbackToken) return { tokenSource: null, isLoading: true };
    return {
      tokenSource: { accessToken: fallbackToken, origin: "preference" },
      isLoading: true,
    };
  }

  const activeProfile = profiles?.find((p) => p.id === activeProfileId);

  if (activeProfile) {
    return {
      tokenSource: {
        accessToken: activeProfile.token,
        credentials: activeProfile.credentials,
        origin: activeProfile.id,
      },
      isLoading: false,
    };
  }

  // Preference fallback
  const token = extractToken(oauthToken);
  if (!token) return { tokenSource: null, isLoading: false };

  return {
    tokenSource: {
      accessToken: token,
      credentials: prefCredentials,
      origin: "preference",
    },
    isLoading: false,
  };
}
