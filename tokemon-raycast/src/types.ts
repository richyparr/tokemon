export interface UsageWindow {
  utilization: number; // 0-100
  resets_at: string | null; // ISO-8601
}

export interface ExtraUsage {
  is_enabled: boolean;
  monthly_limit: number | null; // cents
  used_credits: number | null; // cents
  utilization: number | null; // 0-100
}

export interface UsageData {
  five_hour: UsageWindow | null;
  seven_day: UsageWindow | null;
  seven_day_oauth_apps: UsageWindow | null;
  seven_day_opus: UsageWindow | null;
  seven_day_sonnet: UsageWindow | null;
  extra_usage: ExtraUsage | null;
}

export type PaceStatus = "on-track" | "ahead" | "behind" | "unknown";

export interface OAuthCredentials {
  accessToken: string;
  refreshToken: string;
  expiresAt: number; // milliseconds since epoch
}

export interface Profile {
  id: string;
  name: string;
  token: string; // Raw OAuth token (already extracted via extractToken at add-time)
  credentials?: OAuthCredentials;
}

export interface AlertSettings {
  threshold: number;          // 1-100 integer
  enabled: boolean;
  lastAlertedWindowId: string | null;
}

export const PROFILES_KEY = "profiles";
export const ACTIVE_PROFILE_KEY = "activeProfileId";
export const ALERT_SETTINGS_KEY = "alertSettings";
export const PREF_CREDENTIALS_KEY = "prefCredentials";

export const DEFAULT_ALERT_SETTINGS: AlertSettings = {
  threshold: 80,
  enabled: true,
  lastAlertedWindowId: null,
};
