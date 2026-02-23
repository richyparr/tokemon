import {
  Action,
  ActionPanel,
  Color,
  Detail,
  Icon,
  openExtensionPreferences,
  showToast,
  Toast,
} from "@raycast/api";
import { useCachedPromise } from "@raycast/utils";
import { useEffect, useState } from "react";
import { fetchUsageWithRefresh, TokenError } from "./api";
import { computePace, formatCountdown, formatPercentage, parseResetDate, usageColor } from "./utils";
import { useTokenSource } from "./useTokenSource";

const NO_TOKEN_GUIDE = `# Setup Required

No OAuth token is configured. Run the **Setup** command to get your token and enter it in Preferences.
`;

const colorMap: Record<string, Color> = {
  green: Color.Green,
  yellow: Color.Yellow,
  orange: Color.Orange,
  red: Color.Red,
};

const paceConfig: Record<string, { label: string; color: Color }> = {
  "on-track": { label: "On Track", color: Color.Green },
  ahead: { label: "Ahead", color: Color.Blue },
  behind: { label: "Behind", color: Color.Orange },
  unknown: { label: "Unknown", color: Color.SecondaryText },
};

export default function Command() {
  const { tokenSource, isLoading: tokenLoading } = useTokenSource();
  const token = tokenSource?.accessToken ?? "";

  const { isLoading, data, error, revalidate } = useCachedPromise(
    async (src: typeof tokenSource) => {
      if (!src) throw new TokenError("OAuth token is empty — enter your token in Preferences", 401);
      return fetchUsageWithRefresh(src);
    },
    [tokenSource],
    { execute: token.length > 0 && !tokenLoading, keepPreviousData: true },
  );

  const [now, setNow] = useState<Date>(new Date());

  useEffect(() => {
    const id = setInterval(() => setNow(new Date()), 1000);
    return () => clearInterval(id);
  }, []);

  // Show toast on error
  useEffect(() => {
    if (!error) return;
    if (error instanceof TokenError) {
      const hasCredentials = !!tokenSource?.credentials;
      showToast({
        style: Toast.Style.Failure,
        title: hasCredentials ? "Auto-refresh failed" : "Invalid or expired token",
        message: "Update your token in preferences",
        primaryAction: {
          title: "Open Preferences",
          onAction: openExtensionPreferences,
        },
      });
    } else {
      showToast({
        style: Toast.Style.Failure,
        title: "Connection failed",
        message: error instanceof Error ? error.message : String(error),
      });
    }
  }, [error]);

  // No token configured — show setup prompt (after all hooks)
  if (!token && !tokenLoading) {
    return (
      <Detail
        markdown={NO_TOKEN_GUIDE}
        actions={
          <ActionPanel>
            <Action title="Open Preferences" icon={Icon.Gear} onAction={openExtensionPreferences} />
          </ActionPanel>
        }
      />
    );
  }

  // Derive display values
  const sessionText = formatPercentage(data?.five_hour?.utilization);
  const weeklyText = formatPercentage(data?.seven_day?.utilization);

  const sessionResetsAt = parseResetDate(data?.five_hour?.resets_at);
  const secondsRemaining = sessionResetsAt ? Math.floor((sessionResetsAt.getTime() - now.getTime()) / 1000) : 0;
  const countdownText = data ? formatCountdown(secondsRemaining) : "--";

  const pace = computePace(data?.five_hour?.utilization ?? 0, sessionResetsAt);
  const { label: paceLabel, color: paceColor } = paceConfig[pace] ?? paceConfig["unknown"];

  const sessionUtilization = data?.five_hour?.utilization ?? 0;
  const sessionColor = colorMap[usageColor(sessionUtilization)] ?? Color.Green;

  const markdown = data
    ? `# Claude Usage\n\nSession: **${sessionText}** | Weekly: **${weeklyText}**`
    : "# Claude Usage\n\nLoading...";

  const hasSonnet = data?.seven_day_sonnet?.utilization != null;
  const hasOpus = data?.seven_day_opus?.utilization != null;

  return (
    <Detail
      isLoading={isLoading || tokenLoading}
      markdown={markdown}
      metadata={
        <Detail.Metadata>
          <Detail.Metadata.Label
            title="Session (5h)"
            text={{ value: sessionText, color: data ? sessionColor : Color.SecondaryText }}
            icon={Icon.Gauge}
          />
          <Detail.Metadata.Label title="Weekly (7d)" text={weeklyText} icon={Icon.Calendar} />
          <Detail.Metadata.Separator />
          <Detail.Metadata.Label title="Resets in" text={countdownText} icon={Icon.Clock} />
          <Detail.Metadata.TagList title="Pace">
            <Detail.Metadata.TagList.Item text={paceLabel} color={paceColor} />
          </Detail.Metadata.TagList>
          {(hasSonnet || hasOpus) && <Detail.Metadata.Separator />}
          {hasSonnet && (
            <Detail.Metadata.Label title="Sonnet (7d)" text={formatPercentage(data?.seven_day_sonnet?.utilization)} />
          )}
          {hasOpus && (
            <Detail.Metadata.Label title="Opus (7d)" text={formatPercentage(data?.seven_day_opus?.utilization)} />
          )}
        </Detail.Metadata>
      }
      actions={
        <ActionPanel>
          <Action
            title="Refresh"
            icon={Icon.ArrowClockwise}
            shortcut={{ modifiers: ["cmd"], key: "r" }}
            onAction={revalidate}
          />
          <Action title="Open Preferences" icon={Icon.Gear} onAction={openExtensionPreferences} />
        </ActionPanel>
      }
    />
  );
}
