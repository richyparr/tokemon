import { Form, ActionPanel, Action, Icon, showToast, Toast, LocalStorage } from "@raycast/api";
import { useForm } from "@raycast/utils";
import { useEffect, useState } from "react";
import type { AlertSettings } from "./types";
import { ALERT_SETTINGS_KEY, DEFAULT_ALERT_SETTINGS } from "./types";

interface FormValues {
  threshold: string;
  enabled: boolean;
}

// Inner form — rendered only after settings have loaded, so useForm gets stable initialValues
function AlertSettingsForm({ initialValues }: { initialValues: FormValues }) {
  const { handleSubmit, itemProps } = useForm<FormValues>({
    initialValues,
    validation: {
      threshold: (value) => {
        const n = parseInt(value ?? "", 10);
        if (isNaN(n) || n < 1 || n > 100) {
          return "Threshold must be a whole number between 1 and 100";
        }
      },
    },
    onSubmit: async (values) => {
      try {
        // Read current settings to preserve lastAlertedWindowId
        const raw = await LocalStorage.getItem<string>(ALERT_SETTINGS_KEY);
        let current: AlertSettings = DEFAULT_ALERT_SETTINGS;
        try {
          if (raw) current = JSON.parse(raw);
        } catch {
          // ignore parse errors
        }

        const newThreshold = parseInt(values.threshold, 10);
        const settings: AlertSettings = {
          threshold: newThreshold,
          enabled: values.enabled,
          // Reset window deduplication when threshold changes so alert re-fires at new level
          lastAlertedWindowId: newThreshold !== current.threshold ? null : current.lastAlertedWindowId,
        };

        await LocalStorage.setItem(ALERT_SETTINGS_KEY, JSON.stringify(settings));
        await showToast({ style: Toast.Style.Success, title: "Settings saved" });
      } catch {
        await showToast({ style: Toast.Style.Failure, title: "Failed to save settings" });
      }
    },
  });

  return (
    <Form
      actions={
        <ActionPanel>
          <Action.SubmitForm title="Save Settings" onSubmit={handleSubmit} />
          <Action
            title="Test Alert"
            icon={Icon.Bell}
            onAction={async () => {
              await showToast({
                style: Toast.Style.Failure,
                title: "Claude usage alert (test)",
                message: "This is what your alert will look like",
              });
            }}
          />
        </ActionPanel>
      }
    >
      <Form.TextField
        {...itemProps.threshold}
        title="Alert Threshold (%)"
        placeholder="e.g. 80"
      />
      <Form.Checkbox {...itemProps.enabled} label="Enable Alerts" />
      <Form.Description text="You'll receive a notification when your 5-hour session usage crosses this threshold. Alerts fire once per session window." />
    </Form>
  );
}

export default function SettingsCommand() {
  const [isLoading, setIsLoading] = useState(true);
  const [loadedValues, setLoadedValues] = useState<FormValues | null>(null);

  useEffect(() => {
    async function loadSettings() {
      try {
        const raw = await LocalStorage.getItem<string>(ALERT_SETTINGS_KEY);
        if (raw) {
          const parsed: AlertSettings = JSON.parse(raw);
          setLoadedValues({
            threshold: String(parsed.threshold),
            enabled: parsed.enabled,
          });
        } else {
          setLoadedValues({
            threshold: String(DEFAULT_ALERT_SETTINGS.threshold),
            enabled: DEFAULT_ALERT_SETTINGS.enabled,
          });
        }
      } catch {
        setLoadedValues({
          threshold: String(DEFAULT_ALERT_SETTINGS.threshold),
          enabled: DEFAULT_ALERT_SETTINGS.enabled,
        });
      } finally {
        setIsLoading(false);
      }
    }
    loadSettings();
  }, []);

  if (isLoading || !loadedValues) {
    return <Form isLoading={true} />;
  }

  return <AlertSettingsForm initialValues={loadedValues} />;
}
