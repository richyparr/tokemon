import {
  Action,
  ActionPanel,
  Form,
  Icon,
  List,
  showToast,
  Toast,
  useNavigation,
} from "@raycast/api";
import { useLocalStorage } from "@raycast/utils";
import { useCachedState } from "@raycast/utils";
import { extractToken, parseCredentials } from "./api";
import type { Profile } from "./types";
import { PROFILES_KEY, ACTIVE_PROFILE_KEY } from "./types";

function AddProfileForm({ onAdd }: { onAdd: (profile: Profile) => void }) {
  const { pop } = useNavigation();

  function handleSubmit(values: { name: string; token: string }) {
    const name = values.name.trim();
    const rawToken = values.token.trim();

    if (!name) {
      showToast({ style: Toast.Style.Failure, title: "Name is required" });
      return;
    }
    if (!rawToken) {
      showToast({ style: Toast.Style.Failure, title: "Token is required" });
      return;
    }

    const extracted = extractToken(rawToken);
    if (!extracted) {
      showToast({ style: Toast.Style.Failure, title: "Could not extract a valid token from the value provided" });
      return;
    }

    const credentials = parseCredentials(rawToken) ?? undefined;

    const newProfile: Profile = {
      id: Date.now().toString(),
      name,
      token: extracted,
      credentials,
    };

    onAdd(newProfile);
    showToast({ style: Toast.Style.Success, title: `Profile "${name}" added` });
    pop();
  }

  return (
    <Form
      navigationTitle="Add Profile"
      actions={
        <ActionPanel>
          <Action.SubmitForm title="Add Profile" onSubmit={handleSubmit} />
        </ActionPanel>
      }
    >
      <Form.TextField id="name" title="Profile Name" placeholder="Personal, Work, etc." />
      <Form.PasswordField id="token" title="Claude OAuth Token" placeholder="Paste token or Keychain JSON blob" />
    </Form>
  );
}

export default function ProfilesCommand() {
  const { value: profiles = [], setValue: setProfiles } = useLocalStorage<Profile[]>(PROFILES_KEY, []);
  const [activeProfileId, setActiveProfileId] = useCachedState<string | null>(ACTIVE_PROFILE_KEY, null);

  async function handleAdd(newProfile: Profile) {
    const updated = [...(profiles ?? []), newProfile];
    await setProfiles(updated);
    setActiveProfileId(newProfile.id);
  }

  async function handleDelete(profile: Profile) {
    const remaining = (profiles ?? []).filter((p) => p.id !== profile.id);
    await setProfiles(remaining);

    if (activeProfileId === profile.id) {
      const nextActiveId = remaining.length > 0 ? remaining[0].id : null;
      setActiveProfileId(nextActiveId);
    }

    showToast({ style: Toast.Style.Success, title: `Profile "${profile.name}" deleted` });
  }

  function handleSwitch(profile: Profile) {
    setActiveProfileId(profile.id);
    showToast({ style: Toast.Style.Success, title: `Switched to "${profile.name}"` });
  }

  const profileList = profiles ?? [];

  return (
    <List
      navigationTitle="Manage Profiles"
      actions={
        <ActionPanel>
          <Action.Push
            title="Add Profile"
            icon={Icon.Plus}
            shortcut={{ modifiers: ["cmd"], key: "n" }}
            target={<AddProfileForm onAdd={handleAdd} />}
          />
        </ActionPanel>
      }
    >
      {profileList.length === 0 ? (
        <List.EmptyView
          title="No Profiles"
          description="Press Cmd+N to add your first profile"
          icon={Icon.Person}
        />
      ) : (
        profileList.map((profile) => {
          const isActive = profile.id === activeProfileId;
          return (
            <List.Item
              key={profile.id}
              title={profile.name}
              subtitle={`${profile.token.slice(0, 8)}...`}
              accessories={
                isActive
                  ? [{ icon: { source: Icon.CheckCircle, tintColor: { light: "#00CC00", dark: "#00CC00", adjustContrast: false } }, tooltip: "Active" }]
                  : []
              }
              actions={
                <ActionPanel>
                  <Action
                    title="Switch to Profile"
                    icon={Icon.Person}
                    onAction={() => handleSwitch(profile)}
                  />
                  <Action.Push
                    title="Add Profile"
                    icon={Icon.Plus}
                    shortcut={{ modifiers: ["cmd"], key: "n" }}
                    target={<AddProfileForm onAdd={handleAdd} />}
                  />
                  <Action
                    title="Delete Profile"
                    icon={Icon.Trash}
                    style={Action.Style.Destructive}
                    shortcut={{ modifiers: ["ctrl"], key: "x" }}
                    onAction={() => handleDelete(profile)}
                  />
                </ActionPanel>
              }
            />
          );
        })
      )}
    </List>
  );
}
