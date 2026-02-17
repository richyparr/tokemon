import Foundation

/// Enumeration of Pro-only features for centralized access control.
/// Each feature maps to a v2 requirement and will be implemented in later phases.
enum ProFeature: String, CaseIterable, Sendable {
    // Phase 7: Multi-Account
    case multiAccount = "Multiple Claude accounts"
    case accountSwitcher = "Account switcher"
    case perAccountAlerts = "Per-account alert thresholds"
    case combinedUsage = "Combined usage view"

    // Phase 8: Analytics & Export
    case extendedHistory = "30/90-day usage history"
    case weeklySummary = "Weekly usage summary"
    case monthlySummary = "Monthly usage summary"
    case projectBreakdown = "Project token breakdown"
    case exportPDF = "Export PDF reports"
    case exportCSV = "Export CSV data"

    // Phase 9: Shareable Moments
    case usageCards = "Shareable usage cards"

    /// User-friendly description for UI
    var displayName: String {
        rawValue
    }

    /// Icon for feature in UI
    var icon: String {
        switch self {
        case .multiAccount, .accountSwitcher:
            return "person.2.fill"
        case .perAccountAlerts:
            return "bell.badge.fill"
        case .combinedUsage:
            return "chart.pie.fill"
        case .extendedHistory:
            return "calendar"
        case .weeklySummary, .monthlySummary:
            return "chart.bar.fill"
        case .projectBreakdown:
            return "folder.fill"
        case .exportPDF, .exportCSV:
            return "square.and.arrow.up.fill"
        case .usageCards:
            return "photo.fill"
        }
    }
}

/// Centralized manager for Pro feature access control.
/// Single source of truth for whether a feature should be enabled.
@Observable
@MainActor
final class FeatureAccessManager {

    // MARK: - Dependencies

    @ObservationIgnored
    private let licenseManager: LicenseManager

    // MARK: - Computed State

    /// Whether the user has Pro access
    var isPro: Bool {
        licenseManager.state.isProEnabled
    }

    /// Current license state (for UI display)
    var licenseState: LicenseState {
        licenseManager.state
    }

    // MARK: - Initialization

    init(licenseManager: LicenseManager) {
        self.licenseManager = licenseManager
    }

    // MARK: - Feature Access

    /// Check if a specific feature is accessible
    func canAccess(_ feature: ProFeature) -> Bool {
        isPro
    }

    /// Check if user should see an upgrade prompt for a feature
    func requiresPurchase(for feature: ProFeature) -> Bool {
        !isPro
    }

    /// Get all features that are currently locked
    var lockedFeatures: [ProFeature] {
        isPro ? [] : ProFeature.allCases
    }

    /// Get all features that are currently available
    var availableFeatures: [ProFeature] {
        isPro ? ProFeature.allCases : []
    }

    // MARK: - Actions

    /// Open purchase page (delegates to LicenseManager)
    func openPurchasePage() {
        licenseManager.openPurchasePage()
    }

    /// Open customer portal (delegates to LicenseManager)
    func openCustomerPortal() {
        licenseManager.openCustomerPortal()
    }
}
