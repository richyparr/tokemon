import SwiftUI

/// Compact account picker displayed in popover header.
/// Only visible for Pro users with multiple accounts.
struct AccountSwitcherView: View {
    @Environment(AccountManager.self) private var accountManager
    @Environment(FeatureAccessManager.self) private var featureAccess

    var body: some View {
        // Only show if Pro and has accounts
        if featureAccess.canAccess(.multiAccount) && !accountManager.accounts.isEmpty {
            Menu {
                ForEach(accountManager.accounts) { account in
                    Button {
                        Task {
                            try? await accountManager.setActiveAccount(account)
                        }
                    } label: {
                        HStack {
                            Text(account.displayName)
                            if account.id == accountManager.activeAccount?.id {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }

                if accountManager.accounts.count > 1 {
                    Divider()
                }

                Button("Manage Accounts...") {
                    SettingsWindowController.shared.showSettings()
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 14))
                    Text(accountManager.activeAccount?.displayName ?? "No Account")
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                }
                .foregroundStyle(.secondary)
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
    }
}
