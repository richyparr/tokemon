import SwiftUI
import AppKit
import ObjectiveC

/// Main popover layout displayed when clicking the menu bar icon.
/// Composes UsageHeaderView, UsageDetailView, ErrorBannerView, and RefreshStatusView
/// into a cohesive popover with comfortable density.
struct PopoverContentView: View {
    @Environment(UsageMonitor.self) private var monitor
    @Environment(AlertManager.self) private var alertManager
    @Environment(ThemeManager.self) private var themeManager
    @Environment(ProfileManager.self) private var profileManager
    @Environment(\.colorScheme) private var colorScheme

    // Setting for showing usage trend (stored in UserDefaults)
    @AppStorage("showUsageTrend") private var showUsageTrend: Bool = false

    // Track floating window visibility for menu label (not reactive on FloatingWindowController)
    @State private var floatingWindowVisible = false


    /// Computed theme colors based on current theme and color scheme
    private var themeColors: ThemeColors {
        themeManager.colors(for: colorScheme)
    }

    var body: some View {
        popoverContent
            .preferredColorScheme(themeColors.colorSchemeOverride)
            .onAppear {
                floatingWindowVisible = FloatingWindowController.shared.isVisible
                if let window = NSApp.windows.first(where: { $0.className.contains("StatusBarWindow") || $0.className.contains("MenuBarExtra") }) {
                    if themeColors.isGlass {
                        // Transparent window so glass can sample the desktop
                        window.backgroundColor = .clear
                        window.isOpaque = false
                        // Delay to ensure view hierarchy is fully built before patching
                        DispatchQueue.main.async {
                            makeHostingViewsTransparent(in: window.contentView)
                        }
                    } else if let override = themeColors.colorSchemeOverride {
                        window.appearance = NSAppearance(named: override == .light ? .aqua : .darkAqua)
                    } else {
                        window.appearance = nil
                    }
                }
            }
    }

    private var popoverContent: some View {
        VStack(spacing: 16) {
            // Profile switcher (only shown when 2+ profiles exist)
            if profileManager.profiles.count > 1 {
                ProfileSwitcherView()
            }

            // Big percentage number (dominant, first thing user sees)
            UsageHeaderView(usage: monitor.currentUsage, alertLevel: alertManager.currentAlertLevel)

            Divider()

            // Detail breakdown: reset time, usage windows (OAuth) or token counts (JSONL)
            UsageDetailView(usage: monitor.currentUsage, showExtraUsage: monitor.showExtraUsage)

            // Multi-profile usage summary (only when 2+ profiles)
            if profileManager.profiles.count > 1 {
                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    Text("All Profiles")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    ForEach(profileManager.profiles) { profile in
                        HStack {
                            // Active indicator
                            Circle()
                                .fill(profile.id == profileManager.activeProfileId
                                    ? Color.green : Color.clear)
                                .frame(width: 6, height: 6)

                            Text(profile.name)
                                .font(.callout)
                                .lineLimit(1)

                            Spacer()

                            // Usage percentage or status
                            if let usage = profile.lastUsage, usage.hasPercentage {
                                Text("\(Int(usage.primaryPercentage))%")
                                    .font(.callout.monospacedDigit())
                                    .foregroundStyle(usageColor(for: usage.primaryPercentage))
                            } else if !profile.hasCredentials {
                                Text("No creds")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            } else {
                                Text("--")
                                    .font(.callout)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
            }

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

            // Error banner (if error exists)
            if let error = monitor.error {
                ErrorBannerView(
                    error: error,
                    onRetry: { monitor.manualRefresh() },
                    requiresManualRetry: monitor.requiresManualRetry
                )
            }

            // Update available banner
            UpdateBannerView()

            Divider()

            // Footer: refresh status + actions
            HStack {
                RefreshStatusView(
                    isRefreshing: monitor.isRefreshing,
                    lastUpdated: monitor.lastUpdated
                )

                Spacer()

                // Refresh button
                Button {
                    monitor.manualRefresh()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.glass)
                .help("Refresh Now")

                // Settings/More menu - combines settings and quit
                Menu {
                    Button(floatingWindowVisible ? "Hide Floating Window" : "Show Floating Window") {
                        FloatingWindowController.shared.toggleFloatingWindow()
                        floatingWindowVisible = FloatingWindowController.shared.isVisible
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
        .background(themeColors.isGlass ? .clear : themeColors.primaryBackground, in: RoundedRectangle(cornerRadius: 12))
        .glassEffect(themeColors.isGlass ? .regular : .identity, in: RoundedRectangle(cornerRadius: 12))
        .tint(themeColors.primaryAccent)
    }

    /// Color for usage percentage in the multi-profile summary
    private func usageColor(for percentage: Double) -> Color {
        if percentage >= 80 {
            return Color(nsColor: GradientColors.color(for: percentage))
        }
        return .primary
    }


    /// Open settings window using our custom controller
    private func openSettingsWindow() {
        SettingsWindowController.shared.showSettings()
    }

    /// Recursively find NSHostingView instances and override isOpaque at runtime.
    /// NSHostingView.isOpaque is read-only and returns true, which draws an opaque
    /// background covering glass effects. We dynamically create a subclass that
    /// overrides isOpaque → false, then swap the view's class at runtime.
    private func makeHostingViewsTransparent(in view: NSView?) {
        guard let view = view else { return }
        let className = String(describing: type(of: view))
        if className.contains("HostingView") {
            let originalClass: AnyClass = type(of: view)
            let subclassName = "Transparent_\(NSStringFromClass(originalClass))"

            if let existingClass = objc_getClass(subclassName) as? AnyClass {
                object_setClass(view, existingClass)
            } else if let subclass = objc_allocateClassPair(originalClass, subclassName, 0) {
                let block: @convention(block) (AnyObject) -> Bool = { _ in false }
                let imp = imp_implementationWithBlock(block)
                if let method = class_getInstanceMethod(NSView.self, #selector(getter: NSView.isOpaque)) {
                    class_addMethod(subclass, #selector(getter: NSView.isOpaque), imp, method_getTypeEncoding(method))
                }
                objc_registerClassPair(subclass)
                object_setClass(view, subclass)
            }

            view.wantsLayer = true
            view.layer?.isOpaque = false
            view.layer?.backgroundColor = .clear
        }
        for subview in view.subviews {
            makeHostingViewsTransparent(in: subview)
        }
    }
}
