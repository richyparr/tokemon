import {
  MenuBarExtra,
  Icon,
  Color,
  openExtensionPreferences,
  launchCommand,
  LaunchType,
  LocalStorage,
  showToast,
  Toast,
  environment,
} from "@raycast/api";
import { useCachedPromise } from "@raycast/utils";
import { useEffect } from "react";
import { fetchUsageWithRefresh, TokenError } from "./api";
import { usageColor, formatPercentage, parseResetDate, formatCountdown } from "./utils";
import type { AlertSettings } from "./types";
import { ALERT_SETTINGS_KEY, DEFAULT_ALERT_SETTINGS } from "./types";
import { useTokenSource } from "./useTokenSource";

function parseAlertSettings(raw: string | undefined): AlertSettings {
  try {
    return raw ? JSON.parse(raw) : DEFAULT_ALERT_SETTINGS;
  } catch {
    return DEFAULT_ALERT_SETTINGS;
  }
}

const colorMap: Record<string, Color> = {
  green: Color.Green,
  yellow: Color.Yellow,
  orange: Color.Orange,
  red: Color.Red,
};

export default function MenuBarCommand() {
  const { tokenSource, isLoading: tokenLoading } = useTokenSource();
  const token = tokenSource?.accessToken ?? "";

  const { isLoading, data, error } = useCachedPromise(
    async (src: typeof tokenSource) => {
      if (!src) throw new TokenError("OAuth token is empty — enter your token in Preferences", 401);
      return fetchUsageWithRefresh(src);
    },
    [tokenSource],
    {
      execute: token.length > 0 && !tokenLoading,
      keepPreviousData: true,
    },
  );

  // Alert checking — only fires on background refresh, deduplicated by window ID
  useEffect(() => {
    if (!data) return;
    if (environment.launchType !== LaunchType.Background) return;

    async function checkAlert() {
      const raw = await LocalStorage.getItem<string>(ALERT_SETTINGS_KEY);
      const settings = parseAlertSettings(raw);

      if (!settings.enabled) return;

      const utilization = data?.five_hour?.utilization ?? 0;
      const windowId = data?.five_hour?.resets_at ?? "unknown";

      if (utilization >= settings.threshold && settings.lastAlertedWindowId !== windowId) {
        // Update deduplication key FIRST to prevent race conditions
        const updated: AlertSettings = { ...settings, lastAlertedWindowId: windowId };
        await LocalStorage.setItem(ALERT_SETTINGS_KEY, JSON.stringify(updated));

        try {
          await showToast({
            style: Toast.Style.Failure,
            title: "Claude usage alert",
            message: `Session at ${Math.round(utilization)}% — threshold: ${settings.threshold}%`,
          });
        } catch {
          // Swallow toast errors silently — never crash the menu bar
        }
      }
    }

    checkAlert().catch(() => {});
  }, [data]);

  // No token — show warning icon with setup prompt
  if (!token && !tokenLoading) {
    return (
      <MenuBarExtra icon={{ source: Icon.Warning }} tooltip="tokemon: Setup required" isLoading={false}>
        <MenuBarExtra.Item
          title="Setup Required"
          subtitle="Click to configure token"
          onAction={openExtensionPreferences}
        />
      </MenuBarExtra>
    );
  }

  // Derive display values
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
      isLoading={isLoading || tokenLoading}
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
        <MenuBarExtra.Item title="Preferences" icon={Icon.Gear} onAction={openExtensionPreferences} />
      </MenuBarExtra.Section>
    </MenuBarExtra>
  );
}
