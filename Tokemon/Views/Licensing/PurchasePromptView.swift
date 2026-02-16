import SwiftUI

/// Modal prompt shown when trial expires or user clicks Upgrade.
/// Provides purchase button and license key entry.
struct PurchasePromptView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(LicenseManager.self) private var licenseManager

    @State private var licenseKeyInput: String = ""
    @State private var isActivating: Bool = false
    @State private var activationError: String?
    @State private var showingLicenseEntry: Bool = false

    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "star.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.yellow)

                Text("Unlock Tokemon Pro")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Get access to all features")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Features list
            VStack(alignment: .leading, spacing: 12) {
                FeatureRow(icon: "person.2.fill", text: "Multiple Claude accounts")
                FeatureRow(icon: "chart.bar.fill", text: "Extended analytics & history")
                FeatureRow(icon: "square.and.arrow.up.fill", text: "Export reports (PDF/CSV)")
                FeatureRow(icon: "photo.fill", text: "Shareable usage cards")
            }
            .padding(.vertical, 8)

            // Pricing
            VStack(spacing: 4) {
                Text("$3/month or $29/year")
                    .font(.headline)
                Text("Cancel anytime")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Actions
            VStack(spacing: 12) {
                Button {
                    licenseManager.openPurchasePage()
                } label: {
                    Text("Purchase License")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button {
                    withAnimation {
                        showingLicenseEntry.toggle()
                    }
                } label: {
                    Text(showingLicenseEntry ? "Hide License Entry" : "I have a license key")
                        .font(.callout)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.blue)
            }

            // License key entry (expandable)
            if showingLicenseEntry {
                VStack(spacing: 8) {
                    TextField("Enter license key", text: $licenseKeyInput)
                        .textFieldStyle(.roundedBorder)

                    if let error = activationError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    Button {
                        Task { await activateLicense() }
                    } label: {
                        if isActivating {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Text("Activate")
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(licenseKeyInput.isEmpty || isActivating)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // Dismiss button
            Button("Maybe Later") {
                dismiss()
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .font(.callout)
        }
        .padding(24)
        .frame(width: 320)
    }

    private func activateLicense() async {
        isActivating = true
        activationError = nil
        defer { isActivating = false }

        do {
            try await licenseManager.activateLicense(key: licenseKeyInput)
            dismiss()
        } catch {
            activationError = error.localizedDescription
        }
    }
}

private struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundStyle(.blue)
            Text(text)
                .font(.callout)
        }
    }
}
