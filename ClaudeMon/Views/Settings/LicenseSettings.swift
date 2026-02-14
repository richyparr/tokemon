import SwiftUI

/// License settings tab for viewing status, activating keys, and managing subscription.
struct LicenseSettings: View {
    @Environment(LicenseManager.self) private var licenseManager

    @State private var licenseKeyInput: String = ""
    @State private var isActivating: Bool = false
    @State private var activationError: String?
    @State private var showingDeactivateConfirm: Bool = false

    var body: some View {
        Form {
            // Status section
            Section("License Status") {
                LabeledContent("Status") {
                    HStack(spacing: 6) {
                        statusIcon
                        Text(licenseManager.state.displayText)
                    }
                }

                if case .licensed(_, _, let expires) = licenseManager.state,
                   let expiresAt = expires {
                    LabeledContent("Renews") {
                        Text(expiresAt.formatted(date: .abbreviated, time: .omitted))
                    }
                }

                if let lastValidated = licenseManager.lastValidated {
                    LabeledContent("Last verified") {
                        Text(lastValidated.formatted(date: .abbreviated, time: .shortened))
                    }
                }

                if licenseManager.isValidating {
                    HStack {
                        ProgressView()
                            .controlSize(.small)
                        Text("Validating...")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Activation section (only for non-licensed states)
            if !isLicensed {
                Section("Activate License") {
                    TextField("License Key", text: $licenseKeyInput)
                        .textFieldStyle(.roundedBorder)

                    if let error = activationError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    HStack {
                        Button("Activate") {
                            Task { await activateLicense() }
                        }
                        .disabled(licenseKeyInput.isEmpty || isActivating)

                        if isActivating {
                            ProgressView()
                                .controlSize(.small)
                        }

                        Spacer()

                        Button("Purchase License") {
                            licenseManager.openPurchasePage()
                        }
                    }
                }
            }

            // Subscription management section
            Section("Subscription") {
                Button("Manage Subscription") {
                    licenseManager.openCustomerPortal()
                }
                .help("Opens LemonSqueezy customer portal in browser")

                if isLicensed {
                    Button("Deactivate License", role: .destructive) {
                        showingDeactivateConfirm = true
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 400)
        .confirmationDialog(
            "Deactivate License?",
            isPresented: $showingDeactivateConfirm,
            titleVisibility: .visible
        ) {
            Button("Deactivate", role: .destructive) {
                Task { try? await licenseManager.deactivateLicense() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove the license from this device. You can reactivate later with the same key.")
        }
    }

    private var isLicensed: Bool {
        if case .licensed = licenseManager.state { return true }
        return false
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch licenseManager.state {
        case .licensed:
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(.green)
        case .onTrial:
            Image(systemName: "clock")
                .foregroundStyle(.blue)
        case .trialExpired:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
        case .gracePeriod:
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(.yellow)
        case .unlicensed:
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.secondary)
        }
    }

    private func activateLicense() async {
        isActivating = true
        activationError = nil
        defer { isActivating = false }

        do {
            try await licenseManager.activateLicense(key: licenseKeyInput)
            licenseKeyInput = ""
        } catch {
            activationError = error.localizedDescription
        }
    }
}
