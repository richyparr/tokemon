import SwiftUI

/// Compact profile switcher displayed at the top of the popover.
/// Shows a dropdown menu for quick profile switching when 2+ profiles exist.
/// When only 1 profile exists, this view should not be shown (handled by parent).
struct ProfileSwitcherView: View {
    @Environment(ProfileManager.self) private var profileManager

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "person.crop.circle")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)

            Menu {
                ForEach(profileManager.profiles) { profile in
                    Button {
                        if profile.id != profileManager.activeProfileId {
                            profileManager.setActiveProfile(id: profile.id)
                        }
                    } label: {
                        HStack {
                            Text(profile.name)
                            if profile.id == profileManager.activeProfileId {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 3) {
                    Text(profileManager.activeProfile?.name ?? "Default")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundStyle(.tertiary)
                }
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()

            Spacer()
        }
    }
}
