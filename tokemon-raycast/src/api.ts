import { LocalStorage } from "@raycast/api";
import { ANTHROPIC_BETA_HEADER, OAUTH_CLIENT_ID, TOKEN_REFRESH_URL, USAGE_URL } from "./constants";
import type { OAuthCredentials, Profile, UsageData } from "./types";
import { PREF_CREDENTIALS_KEY, PROFILES_KEY } from "./types";

/** How far before expiry to proactively refresh (10 minutes, matching Swift app). */
const EXPIRY_BUFFER_MS = 10 * 60 * 1000;

/**
 * Typed error for OAuth token problems (401 / 403).
 * Callers can check `instanceof TokenError` to distinguish token issues from network failures.
 */
export class TokenError extends Error {
  constructor(
    message: string,
    public readonly statusCode: 401 | 403,
  ) {
    super(message);
    this.name = "TokenError";
  }
}

/**
 * Extract the access token from either a raw token string or a full Keychain JSON blob.
 * The macOS Keychain stores Claude credentials as JSON: { claudeAiOauth: { accessToken: "..." } }
 * Users may paste either format — this handles both transparently.
 */
export function extractToken(input: string): string {
  const trimmed = input.trim();
  if (!trimmed) return "";

  // Try parsing as JSON (full Keychain blob)
  try {
    const parsed = JSON.parse(trimmed);
    if (parsed?.claudeAiOauth?.accessToken) {
      return parsed.claudeAiOauth.accessToken;
    }
  } catch {
    // Not JSON — treat as raw token
  }

  return trimmed;
}

/**
 * Parse a full Keychain JSON blob into OAuthCredentials.
 * Returns null if the input isn't a valid blob or is missing required fields.
 */
export function parseCredentials(input: string): OAuthCredentials | null {
  const trimmed = input.trim();
  if (!trimmed) return null;

  try {
    const parsed = JSON.parse(trimmed);
    const oauth = parsed?.claudeAiOauth;
    if (oauth?.accessToken && oauth?.refreshToken && typeof oauth?.expiresAt === "number") {
      return {
        accessToken: oauth.accessToken,
        refreshToken: oauth.refreshToken,
        expiresAt: oauth.expiresAt,
      };
    }
  } catch {
    // Not JSON or missing fields
  }

  return null;
}

/**
 * Check whether credentials will expire within the proactive buffer window.
 */
export function isTokenExpiringSoon(creds: OAuthCredentials): boolean {
  return Date.now() + EXPIRY_BUFFER_MS >= creds.expiresAt;
}

// Singleton guard: only one refresh in flight at a time
let refreshInFlight: Promise<OAuthCredentials> | null = null;

/**
 * Refresh the access token using the refresh token.
 * Uses a singleton guard to prevent concurrent refresh requests.
 */
export async function refreshAccessToken(refreshToken: string): Promise<OAuthCredentials> {
  if (refreshInFlight) return refreshInFlight;

  refreshInFlight = (async () => {
    try {
      const response = await fetch(TOKEN_REFRESH_URL, {
        method: "POST",
        headers: { "Content-Type": "application/x-www-form-urlencoded" },
        body: new URLSearchParams({
          grant_type: "refresh_token",
          refresh_token: refreshToken,
          client_id: OAUTH_CLIENT_ID,
        }).toString(),
      });

      if (!response.ok) {
        throw new TokenError(
          `Token refresh failed: HTTP ${response.status}`,
          response.status === 403 ? 403 : 401,
        );
      }

      const data = (await response.json()) as {
        access_token: string;
        refresh_token: string;
        expires_in: number;
      };

      return {
        accessToken: data.access_token,
        refreshToken: data.refresh_token,
        expiresAt: Date.now() + data.expires_in * 1000,
      };
    } finally {
      refreshInFlight = null;
    }
  })();

  return refreshInFlight;
}

/**
 * Persist updated credentials back to storage.
 * @param credentials - The new credentials to store
 * @param origin - Either a profile ID or "preference" for the preference-token flow
 */
export async function persistCredentials(
  credentials: OAuthCredentials,
  origin: string,
): Promise<void> {
  if (origin === "preference") {
    await LocalStorage.setItem(PREF_CREDENTIALS_KEY, JSON.stringify(credentials));
  } else {
    // Update the profile's credentials and token
    const raw = await LocalStorage.getItem<string>(PROFILES_KEY);
    if (!raw) return;
    const profiles: Profile[] = JSON.parse(raw);
    const profile = profiles.find((p) => p.id === origin);
    if (!profile) return;
    profile.credentials = credentials;
    profile.token = credentials.accessToken;
    await LocalStorage.setItem(PROFILES_KEY, JSON.stringify(profiles));
  }
}

/** Token source passed to fetchUsageWithRefresh. */
export interface TokenSource {
  accessToken: string;
  credentials?: OAuthCredentials;
  origin: string; // profile ID or "preference"
}

/**
 * Fetch usage data with automatic token refresh.
 * - Proactively refreshes if token is expiring soon
 * - Retries once on 401 if credentials are available
 * - Persists updated credentials on successful refresh
 * - Falls back to plain fetchUsage for raw tokens (no credentials)
 */
export async function fetchUsageWithRefresh(source: TokenSource): Promise<UsageData> {
  let { accessToken, credentials } = source;

  // Proactive refresh if expiring soon
  if (credentials && isTokenExpiringSoon(credentials)) {
    try {
      credentials = await refreshAccessToken(credentials.refreshToken);
      accessToken = credentials.accessToken;
      await persistCredentials(credentials, source.origin);
    } catch {
      // Proactive refresh failed — try with current token anyway
    }
  }

  try {
    return await fetchUsage(accessToken);
  } catch (err) {
    // Retry on 401 if we have a refresh token
    if (err instanceof TokenError && err.statusCode === 401 && credentials) {
      credentials = await refreshAccessToken(credentials.refreshToken);
      accessToken = credentials.accessToken;
      await persistCredentials(credentials, source.origin);
      return await fetchUsage(accessToken);
    }
    throw err;
  }
}

/**
 * Fetch the Claude OAuth usage data.
 *
 * @param token - The user's raw OAuth access token.
 * @throws {TokenError} When the token is empty, expired (401), or missing required scope (403).
 * @throws {Error} For non-2xx HTTP responses or network failures.
 */
export async function fetchUsage(token: string): Promise<UsageData> {
  const trimmed = token.trim();

  if (!trimmed) {
    throw new TokenError("OAuth token is empty — enter your token in Preferences", 401);
  }

  let response: Response;
  try {
    response = await fetch(USAGE_URL, {
      method: "GET",
      headers: {
        Authorization: `Bearer ${trimmed}`,
        Accept: "application/json",
        "anthropic-beta": ANTHROPIC_BETA_HEADER,
        "User-Agent": "tokemon-raycast/1.0",
      },
    });
  } catch (err) {
    throw new Error(`Network error: ${err instanceof Error ? err.message : String(err)}`);
  }

  if (response.status === 401) {
    throw new TokenError("OAuth token is expired or invalid", 401);
  }

  if (response.status === 403) {
    throw new TokenError("OAuth token is missing the required scope for usage data", 403);
  }

  if (!response.ok) {
    throw new Error(`HTTP ${response.status}: ${response.statusText}`);
  }

  return response.json() as Promise<UsageData>;
}
