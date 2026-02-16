import SwiftUI
import AppKit

/// Main popover layout displayed when clicking the menu bar icon.
/// Composes UsageHeaderView, UsageDetailView, ErrorBannerView, and RefreshStatusView
/// into a cohesive popover with comfortable density.
struct PopoverContentView: View {
    @Environment(UsageMonitor.self) private var monitor
    @Environment(AlertManager.self) private var alertManager
    @Environment(ThemeManager.self) private var themeManager
    @Environment(LicenseManager.self) private var licenseManager
    @Environment(FeatureAccessManager.self) private var featureAccess
    @Environment(AccountManager.self) private var accountManager
    @Environment(\.colorScheme) private var colorScheme

    // Setting for showing usage trend (stored in UserDefaults)
    @AppStorage("showUsageTrend") private var showUsageTrend: Bool = false

    @State private var showingPurchasePrompt = false

    /// Computed theme colors based on current theme and color scheme
    private var themeColors: ThemeColors {
        themeManager.colors(for: colorScheme)
    }

    var body: some View {
        popoverContent
            .preferredColorScheme(themeColors.colorSchemeOverride)
            .onAppear {
                // Set window appearance for Light/Dark themes
                if let window = NSApp.windows.first(where: { $0.className.contains("StatusBarWindow") || $0.className.contains("MenuBarExtra") }) {
                    if let override = themeColors.colorSchemeOverride {
                        window.appearance = NSAppearance(named: override == .light ? .aqua : .darkAqua)
                    } else {
                        window.appearance = nil  // Follow system
                    }
                }
            }
    }

    private var popoverContent: some View {
        VStack(spacing: 16) {
            // Account switcher (Pro only, multiple accounts - view handles own visibility)
            HStack {
                AccountSwitcherView()
                Spacer()
            }

            // Big percentage number (dominant, first thing user sees)
            UsageHeaderView(usage: monitor.currentUsage, alertLevel: alertManager.currentAlertLevel)

            Divider()

            // Detail breakdown: reset time, usage windows (OAuth) or token counts (JSONL)
            UsageDetailView(usage: monitor.currentUsage, showExtraUsage: monitor.showExtraUsage)

            // Usage trends section (only show if enabled in settings AND we have OAuth data)
            if showUsageTrend && monitor.currentUsage.hasPercentage {
                Divider()

                // Chart - pass theme environment for chart colors
                UsageChartView(dataPoints: monitor.usageHistory)
                    .environment(themeManager)

                // Burn rate
                BurnRateView(
                    currentUsage: monitor.currentUsage.primaryPercentage,
                    dataPoints: monitor.usageHistory
                )
            }

            // Trial/License banner
            if shouldShowTrialBanner {
                TrialBannerView(state: licenseManager.state) {
                    showingPurchasePrompt = true
                }
            }

            // Error banner (if error exists)
            if let error = monitor.error {
                ErrorBannerView(
                    error: error,
                    onRetry: { monitor.manualRefresh() },
                    requiresManualRetry: monitor.requiresManualRetry
                )
            }

            Divider()

            // Footer: refresh status + actions
            HStack {
                RefreshStatusView(
                    isRefreshing: monitor.isRefreshing,
                    lastUpdated: monitor.lastUpdated
                )

                Spacer()

                // Pro badge (shown when licensed)
                if case .licensed = featureAccess.licenseState {
                    ProBadge()
                }

                // Refresh button
                Button {
                    Task { await monitor.refresh() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Refresh Now")

                // Settings/More menu - combines settings and quit
                Menu {
                    Button(FloatingWindowController.shared.isVisible ? "Hide Floating Window" : "Show Floating Window") {
                        FloatingWindowController.shared.toggleFloatingWindow()
                    }
                    .keyboardShortcut("f", modifiers: .command)

                    Divider()

                    Button("Settings...") {
                        openSettingsWindow()
                    }
                    .keyboardShortcut(",", modifiers: .command)

                    Divider()

                    Button("Quit tokemon") {
                        NSApplication.shared.terminate(nil)
                    }
                    .keyboardShortcut("q", modifiers: .command)
                } label: {
                    Image(systemName: "gear")
                        .foregroundStyle(.secondary)
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .tint(.secondary)
                .frame(width: 20)
                .help("Settings & Options")
            }
        }
        .padding(16)
        .frame(width: 320)
        .background(themeColors.primaryBackground.ignoresSafeArea())
        .tint(themeColors.primaryAccent)
        .sheet(isPresented: $showingPurchasePrompt) {
            PurchasePromptView()
                .environment(licenseManager)
        }
    }

    /// Whether to show the trial/license banner in the popover
    private var shouldShowTrialBanner: Bool {
        switch licenseManager.state {
        case .onTrial, .trialExpired, .gracePeriod:
            return true
        default:
            return false
        }
    }

    /// Open settings window using our custom controller
    private func openSettingsWindow() {
        SettingsWindowController.shared.showSettings()
    }
}
