import SwiftUI

/// Badge indicating a Pro-only feature
struct ProBadge: View {
    var body: some View {
        Text("PRO")
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.orange.gradient)
            )
    }
}

/// Lock icon overlay for disabled Pro features
struct ProLockOverlay: View {
    let isLocked: Bool

    var body: some View {
        if isLocked {
            Image(systemName: "lock.fill")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(4)
                .background(.ultraThinMaterial, in: Circle())
        }
    }
}

/// View modifier to add Pro gating behavior.
/// Disables the view, shows a lock overlay, and prompts purchase on tap.
/// For use in Phases 7-9 when actual Pro features are implemented.
struct ProGatedModifier: ViewModifier {
    let feature: ProFeature
    @Environment(FeatureAccessManager.self) private var featureAccess
    @State private var showingPurchasePrompt = false

    func body(content: Content) -> some View {
        content
            .disabled(!featureAccess.canAccess(feature))
            .overlay(alignment: .topTrailing) {
                if !featureAccess.canAccess(feature) {
                    ProLockOverlay(isLocked: true)
                }
            }
            .onTapGesture {
                if !featureAccess.canAccess(feature) {
                    showingPurchasePrompt = true
                }
            }
            .sheet(isPresented: $showingPurchasePrompt) {
                PurchasePromptView()
            }
    }
}

extension View {
    /// Apply Pro feature gating to a view.
    /// Disables the view, shows a lock icon, and prompts purchase when tapped.
    func proGated(_ feature: ProFeature) -> some View {
        modifier(ProGatedModifier(feature: feature))
    }
}
