# Phase 9: Shareable Moments - Research

**Researched:** 2026-02-15
**Domain:** SwiftUI Image Rendering, Clipboard Integration, Social Card Design, Viral Marketing
**Confidence:** HIGH

## Summary

Phase 9 adds "shareable moments" functionality to Tokemon: users can generate branded usage cards showing their Claude stats and copy them to the clipboard for social media sharing. This leverages the analytics infrastructure from Phase 8 (AnalyticsEngine, UsageSummary, ProjectUsage) and the proven ImageRenderer pattern from PDFReportView.

The implementation is straightforward: (1) design a visually appealing SwiftUI card view with usage stats and Tokemon branding, (2) render it to NSImage using ImageRenderer, (3) copy to clipboard via NSPasteboard.writeObjects(). The key technical consideration is avoiding LinearGradient in the card view, as ImageRenderer on macOS has known rendering issues with gradients (already documented in Phase 8 research). Using solid colors and simple shapes ensures reliable output.

The viral marketing aspect is served by including Tokemon branding (app name, URL) on every generated card. When users share these cards on Twitter/X, LinkedIn, or other platforms, the branding travels with the content. The "copy to clipboard" workflow is intentional: users manually paste and post, ensuring explicit consent for sharing.

**Primary recommendation:** Build a `ShareableCardView` with usage stats (daily/weekly utilization, top project, token count) using solid colors only. Add an `ExportManager.copyImageToClipboard()` method that uses ImageRenderer to render the card view to NSImage and copies it via NSPasteboard. Add a "Share Usage Card" button to the Analytics tab, Pro-gated via `FeatureAccessManager.canAccess(.usageCards)`.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| ImageRenderer | macOS 14+ (native) | Render SwiftUI view to NSImage via cgImage | Already used in ExportManager for PDF; native API |
| NSPasteboard | macOS (native) | Copy NSImage to system clipboard | Standard macOS clipboard API |
| NSImage | macOS (native) | Image container created from CGImage | Platform-native image type |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| None | - | - | No additional dependencies needed |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Copy to clipboard | ShareLink | ShareLink is iOS-focused, requires Transferable conformance; NSPasteboard is simpler and more direct for macOS clipboard |
| ImageRenderer | Bitmap snapshot via NSView | ImageRenderer is SwiftUI-native, avoids bridging to AppKit for view rendering |
| Solid colors | Gradients | Gradients render incorrectly with ImageRenderer on macOS; solid colors are reliable |

**Installation:**
No additional packages needed. All capabilities use native Apple frameworks.

## Architecture Patterns

### Recommended Project Structure
```
Tokemon/
  Views/
    ShareableCard/
      ShareableCardView.swift       # NEW: The card template view
      ShareableCardPreviewView.swift # NEW: Live preview with copy button
  Services/
    ExportManager.swift             # EXTEND: Add copyImageToClipboard()
```

### Pattern 1: Shareable Card View with Solid Colors
**What:** A self-contained SwiftUI view that displays usage statistics with branding, designed for social sharing.
**When to use:** Rendering usage cards for clipboard copy.
**Critical constraint:** No gradients, no @Environment dependencies (ImageRenderer limitation).
**Example:**
```swift
// Source: Phase 8 PDFReportView pattern (no @Environment)
struct ShareableCardView: View {
    let periodLabel: String          // "This Week" or "Today"
    let utilizationPercentage: Double
    let topProjectName: String?
    let totalTokensUsed: Int?
    let generatedDate: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with branding
            HStack {
                Text("Tokemon")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color(hex: 0xc15f3c)) // Anthropic orange
                Spacer()
                Text(periodLabel)
                    .font(.caption)
                    .foregroundStyle(.gray)
            }

            // Main stat: utilization percentage
            VStack(alignment: .leading, spacing: 4) {
                Text(String(format: "%.0f%%", utilizationPercentage))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(.black)
                Text("Claude Usage")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
            }

            // Optional: top project
            if let project = topProjectName {
                HStack {
                    Image(systemName: "folder.fill")
                        .foregroundStyle(.gray)
                    Text("Top: \(project)")
                        .font(.caption)
                        .foregroundStyle(.black)
                }
            }

            // Optional: token count
            if let tokens = totalTokensUsed {
                HStack {
                    Image(systemName: "text.word.spacing")
                        .foregroundStyle(.gray)
                    Text(formatTokens(tokens))
                        .font(.caption)
                        .foregroundStyle(.black)
                }
            }

            Spacer()

            // Footer with URL
            Text("tokemon.app")
                .font(.caption2)
                .foregroundStyle(.gray)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(20)
        .frame(width: 320, height: 200)
        .background(Color.white)
    }

    private func formatTokens(_ count: Int) -> String {
        if count >= 1_000_000 { return String(format: "%.1fM tokens", Double(count) / 1_000_000) }
        if count >= 1_000 { return String(format: "%.1fK tokens", Double(count) / 1_000) }
        return "\(count) tokens"
    }
}
```

### Pattern 2: ImageRenderer to NSImage Conversion
**What:** Convert a SwiftUI view to NSImage using ImageRenderer.cgImage.
**When to use:** Generating clipboard-ready images from SwiftUI views.
**Example:**
```swift
// Source: Apple ImageRenderer documentation + Hacking with Swift
@MainActor
extension ExportManager {
    /// Render a SwiftUI view to NSImage.
    /// - Parameters:
    ///   - view: The SwiftUI view to render.
    ///   - scale: Rendering scale (default 2.0 for Retina).
    /// - Returns: NSImage, or nil on failure.
    static func renderToImage<V: View>(view: V, scale: CGFloat = 2.0) -> NSImage? {
        let renderer = ImageRenderer(content: view)
        renderer.scale = scale

        guard let cgImage = renderer.cgImage else {
            return nil
        }

        // Create NSImage from CGImage
        let size = CGSize(
            width: CGFloat(cgImage.width) / scale,
            height: CGFloat(cgImage.height) / scale
        )
        return NSImage(cgImage: cgImage, size: size)
    }
}
```

### Pattern 3: Clipboard Copy with NSPasteboard
**What:** Copy an NSImage to the system clipboard for pasting into any application.
**When to use:** The "copy to clipboard" action for share cards.
**Example:**
```swift
// Source: macOS NSPasteboard documentation
@MainActor
extension ExportManager {
    /// Copy an NSImage to the system clipboard.
    /// - Parameter image: The image to copy.
    /// - Returns: true if successful.
    static func copyImageToClipboard(_ image: NSImage) -> Bool {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        return pasteboard.writeObjects([image])
    }

    /// Render a view and copy the resulting image to clipboard.
    /// - Parameter view: The SwiftUI view to render.
    /// - Returns: true if successful.
    static func copyViewToClipboard<V: View>(_ view: V) -> Bool {
        guard let image = renderToImage(view: view) else {
            return false
        }
        return copyImageToClipboard(image)
    }
}
```

### Pattern 4: Card Preview with Live Data
**What:** A view that shows the card preview and a "Copy to Clipboard" button.
**When to use:** Integration point in the Analytics tab or popover.
**Example:**
```swift
// Source: Existing AnalyticsDashboardView pattern
struct ShareableCardPreviewView: View {
    @Environment(UsageMonitor.self) private var monitor
    @Environment(FeatureAccessManager.self) private var featureAccess

    @State private var isCopied = false

    var body: some View {
        VStack(spacing: 16) {
            // Card preview
            cardView
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)

            // Copy button
            if featureAccess.canAccess(.usageCards) {
                Button {
                    copyCard()
                } label: {
                    Label(
                        isCopied ? "Copied!" : "Copy to Clipboard",
                        systemImage: isCopied ? "checkmark" : "doc.on.doc"
                    )
                }
                .buttonStyle(.borderedProminent)
                .disabled(isCopied)
            } else {
                // Locked state
                Button {
                    featureAccess.openPurchasePage()
                } label: {
                    Label("Copy to Clipboard", systemImage: "lock.fill")
                }
                .buttonStyle(.bordered)
                .disabled(true)
            }
        }
    }

    @ViewBuilder
    private var cardView: some View {
        // Compute card data from monitor
        let weeklySummaries = AnalyticsEngine.weeklySummaries(from: monitor.usageHistory, weeks: 1)
        let avgUtilization = weeklySummaries.first?.averageUtilization ?? monitor.currentUsage.primaryPercentage
        let topProject = AnalyticsEngine.projectBreakdown(since: Date().addingTimeInterval(-7 * 24 * 3600)).first

        ShareableCardView(
            periodLabel: "This Week",
            utilizationPercentage: avgUtilization,
            topProjectName: topProject?.projectName,
            totalTokensUsed: topProject?.totalTokens,
            generatedDate: Date()
        )
    }

    private func copyCard() {
        let weeklySummaries = AnalyticsEngine.weeklySummaries(from: monitor.usageHistory, weeks: 1)
        let avgUtilization = weeklySummaries.first?.averageUtilization ?? monitor.currentUsage.primaryPercentage
        let topProject = AnalyticsEngine.projectBreakdown(since: Date().addingTimeInterval(-7 * 24 * 3600)).first

        let card = ShareableCardView(
            periodLabel: "This Week",
            utilizationPercentage: avgUtilization,
            topProjectName: topProject?.projectName,
            totalTokensUsed: topProject?.totalTokens,
            generatedDate: Date()
        )

        if ExportManager.copyViewToClipboard(card) {
            isCopied = true
            // Reset after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                isCopied = false
            }
        }
    }
}
```

### Anti-Patterns to Avoid
- **Using LinearGradient in the card view:** ImageRenderer on macOS renders gradients incorrectly (flat color or wrong direction). Use solid colors only.
- **Depending on @Environment in the card view:** ImageRenderer creates an isolated context without the normal SwiftUI environment. Pass all data as parameters.
- **Using ShareLink instead of NSPasteboard:** ShareLink is primarily iOS-focused and adds complexity. Direct clipboard copy is simpler and expected on macOS.
- **Adding save-to-file option:** The requirement is clipboard copy only (SHARE-02). Adding file save creates scope creep and redundancy with PDF export.
- **Complex animations or dynamic content:** ImageRenderer captures a single frame. Dynamic content (animations, timers) will render incorrectly.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Image rendering | Custom CGContext drawing | ImageRenderer.cgImage | SwiftUI-native, handles layout automatically |
| Clipboard copy | Manual pasteboard data types | NSPasteboard.writeObjects([NSImage]) | NSImage conforms to NSPasteboardWriting, handles format negotiation |
| Card layout | Custom Core Graphics drawing | SwiftUI VStack/HStack | Declarative, easier to maintain, matches existing patterns |
| Analytics data | Manual history parsing | AnalyticsEngine (existing) | Already computes weekly summaries and project breakdown |

**Key insight:** The entire implementation reuses existing infrastructure: ImageRenderer from ExportManager, analytics data from AnalyticsEngine, Pro gating from FeatureAccessManager. Only the card view and clipboard copy method are truly new.

## Common Pitfalls

### Pitfall 1: Gradient Rendering in ImageRenderer
**What goes wrong:** Card renders with flat colors or inverted gradients instead of the designed gradient.
**Why it happens:** Known macOS limitation where ImageRenderer handles LinearGradient differently than on-screen rendering.
**How to avoid:** Use only solid colors (.white, .black, .gray, Color(hex:)) in the card view. No LinearGradient, AngularGradient, or RadialGradient.
**Warning signs:** Card looks different in preview vs. pasted image, colors appear flat.

### Pitfall 2: @Environment Access in Rendered View
**What goes wrong:** Card renders blank, crashes, or has missing data.
**Why it happens:** ImageRenderer creates an isolated rendering context without the normal SwiftUI environment chain.
**How to avoid:** Make ShareableCardView accept ALL data as init parameters. No @Environment, @EnvironmentObject, @AppStorage inside the view. Compute values before rendering and pass them in.
**Warning signs:** Blank sections, crashes during copy, values showing defaults instead of real data.

### Pitfall 3: Scale Factor for Retina Display
**What goes wrong:** Copied image looks blurry when pasted.
**Why it happens:** ImageRenderer defaults to 1.0 scale; Retina displays expect 2.0.
**How to avoid:** Set `renderer.scale = 2.0` before rendering. This produces a 2x resolution image that looks sharp on Retina displays.
**Warning signs:** Pixelated or blurry image, text looks fuzzy.

### Pitfall 4: NSPasteboard Requires clearContents()
**What goes wrong:** Old clipboard content appears alongside or instead of the new image.
**Why it happens:** Not calling clearContents() before writeObjects().
**How to avoid:** Always call `pasteboard.clearContents()` immediately before `pasteboard.writeObjects()`.
**Warning signs:** Multiple items on clipboard, old content still there.

### Pitfall 5: Large Image Sizes
**What goes wrong:** Image is larger than expected, takes too long to copy, or causes memory issues.
**Why it happens:** Card size too large, or scale factor too high.
**How to avoid:** Keep card size reasonable (320x200 points at 2x = 640x400 pixels). This is optimal for social media (fits Twitter card dimensions).
**Warning signs:** Slow copy operation, high memory usage, oversized images when pasted.

### Pitfall 6: UI State After Copy
**What goes wrong:** User doesn't know if copy succeeded.
**Why it happens:** No visual feedback after clipboard operation.
**How to avoid:** Show "Copied!" feedback on the button after successful copy. Reset after 2 seconds. Handle failure case (show error or keep button enabled).
**Warning signs:** Users repeatedly clicking, confusion about whether it worked.

## Code Examples

### Complete ShareableCardView with Branding
```swift
// Source: Existing PDFReportView pattern + GitHub Wrapped design inspiration
import SwiftUI

/// A shareable card displaying usage statistics with Tokemon branding.
/// CRITICAL: No @Environment, no gradients. All data passed as parameters.
struct ShareableCardView: View {
    // Required data
    let periodLabel: String          // "This Week" or "February 2026"
    let utilizationPercentage: Double

    // Optional stats
    let topProjectName: String?
    let totalTokensUsed: Int?

    // Metadata
    let generatedDate: Date

    // Brand colors (Anthropic-inspired)
    private let brandOrange = Color(hex: 0xc15f3c)
    private let cardBackground = Color.white
    private let primaryText = Color.black
    private let secondaryText = Color.gray

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: Tokemon branding + period
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Tokemon")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(brandOrange)
                    Text("Claude Usage Stats")
                        .font(.caption2)
                        .foregroundStyle(secondaryText)
                }
                Spacer()
                Text(periodLabel)
                    .font(.caption)
                    .foregroundStyle(secondaryText)
            }

            // Divider
            Rectangle()
                .fill(secondaryText.opacity(0.2))
                .frame(height: 1)

            // Main stat: big percentage
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(String(format: "%.0f", utilizationPercentage))
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(primaryText)
                Text("%")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(secondaryText)
            }

            // Secondary stats
            HStack(spacing: 16) {
                if let project = topProjectName {
                    statBadge(icon: "folder.fill", text: project)
                }
                if let tokens = totalTokensUsed {
                    statBadge(icon: "text.word.spacing", text: formatTokens(tokens))
                }
            }

            Spacer()

            // Footer: URL for viral marketing
            HStack {
                Spacer()
                Text("tokemon.app")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(secondaryText)
            }
        }
        .padding(20)
        .frame(width: 320, height: 200)
        .background(cardBackground)
    }

    @ViewBuilder
    private func statBadge(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(secondaryText)
            Text(text)
                .font(.caption)
                .foregroundStyle(primaryText)
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(secondaryText.opacity(0.1))
        .clipShape(Capsule())
    }

    private func formatTokens(_ count: Int) -> String {
        if count >= 1_000_000 { return String(format: "%.1fM", Double(count) / 1_000_000) }
        if count >= 1_000 { return String(format: "%.1fK", Double(count) / 1_000) }
        return "\(count)"
    }
}
```

### ExportManager Extension for Clipboard
```swift
// Source: NSPasteboard documentation + existing ExportManager pattern
import SwiftUI
import AppKit

extension ExportManager {

    // MARK: - Image Rendering

    /// Render a SwiftUI view to NSImage.
    /// - Parameters:
    ///   - view: The SwiftUI view to render.
    ///   - scale: Rendering scale (2.0 for Retina).
    /// - Returns: NSImage, or nil on failure.
    static func renderToImage<V: View>(_ view: V, scale: CGFloat = 2.0) -> NSImage? {
        let renderer = ImageRenderer(content: view)
        renderer.scale = scale

        guard let cgImage = renderer.cgImage else {
            return nil
        }

        let size = CGSize(
            width: CGFloat(cgImage.width) / scale,
            height: CGFloat(cgImage.height) / scale
        )
        return NSImage(cgImage: cgImage, size: size)
    }

    // MARK: - Clipboard Operations

    /// Copy an NSImage to the system clipboard.
    /// - Parameter image: The image to copy.
    /// - Returns: true if successful.
    static func copyImageToClipboard(_ image: NSImage) -> Bool {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        return pasteboard.writeObjects([image])
    }

    /// Render a SwiftUI view and copy the resulting image to clipboard.
    /// Convenience method combining render + copy.
    /// - Parameter view: The SwiftUI view to render and copy.
    /// - Returns: true if successful.
    static func copyViewToClipboard<V: View>(_ view: V) -> Bool {
        guard let image = renderToImage(view) else {
            return false
        }
        return copyImageToClipboard(image)
    }
}
```

### Integration in Analytics Tab
```swift
// Source: Existing AnalyticsDashboardView export section pattern
// Add to exportSection in AnalyticsDashboardView.swift

// Share Card Button (alongside existing PDF/CSV buttons)
exportButton(
    title: "Share Usage Card",
    icon: "photo.fill",
    feature: .usageCards
) {
    await copyUsageCard()
}

// Action method
private func copyUsageCard() async {
    let weeklySummaries = AnalyticsEngine.weeklySummaries(from: monitor.usageHistory, weeks: 1)
    let avgUtilization = weeklySummaries.first?.averageUtilization ?? monitor.currentUsage.primaryPercentage
    let topProject = AnalyticsEngine.projectBreakdown(since: Date().addingTimeInterval(-7 * 24 * 3600)).first

    let card = ShareableCardView(
        periodLabel: "This Week",
        utilizationPercentage: avgUtilization,
        topProjectName: topProject?.projectName,
        totalTokensUsed: topProject?.totalTokens,
        generatedDate: Date()
    )

    let success = ExportManager.copyViewToClipboard(card)

    if success {
        // Show feedback (could add a toast or change button state)
    }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| UIGraphicsRenderer | ImageRenderer | iOS 16 / macOS 13 (2022) | SwiftUI-native rendering, cross-platform |
| NSImage.lockFocus() | ImageRenderer.cgImage | macOS 10.14+ deprecated | Modern thread-safe approach |
| UIPasteboard (iOS) | NSPasteboard (macOS) | Platform-specific | macOS has always used NSPasteboard |

**Deprecated/outdated:**
- `NSImage.lockFocus()` / `unlockFocus()` - Deprecated in macOS 10.14, not thread-safe
- Custom CGContext image drawing - Replaced by ImageRenderer for SwiftUI views
- Third-party image sharing libraries - NSPasteboard is sufficient for clipboard

## Open Questions

1. **Card Variants / Templates**
   - What we know: One card design is required for MVP (SHARE-01).
   - What's unclear: Should there be multiple templates (daily, weekly, monthly, all-time)?
   - Recommendation: Start with one "This Week" template. If users want variety, add templates in a future update. Keep MVP simple.

2. **Dark Mode Card Variant**
   - What we know: The card uses a white background for maximum platform compatibility.
   - What's unclear: Should there be a dark mode card variant?
   - Recommendation: Use the light card always (white background, dark text). Dark mode cards look worse on light backgrounds where most social posts appear. Light cards are universally readable.

3. **Card Size for Social Platforms**
   - What we know: Twitter cards are 1200x675 (2:1), Instagram is 1080x1080 (1:1), LinkedIn is flexible.
   - What's unclear: What aspect ratio is best?
   - Recommendation: Use 320x200 (1.6:1 aspect ratio at 2x = 640x400 pixels). This fits well in Twitter feeds, is not too tall for Instagram stories, and looks good inline. Larger sizes add no value and increase clipboard data size.

4. **Branding Placement**
   - What we know: SHARE-03 requires Tokemon branding for viral marketing.
   - What's unclear: Logo image or text-only branding?
   - Recommendation: Text-only ("Tokemon" + "tokemon.app"). The app currently has no logo asset, and text branding is clean and reliable in ImageRenderer. Adding a logo image requires asset management and potential rendering issues.

## Sources

### Primary (HIGH confidence)
- **Apple ImageRenderer documentation** - cgImage property, scale setting, @MainActor requirement
- **Apple NSPasteboard documentation** - clearContents(), writeObjects(), NSImage conformance
- **Phase 8 08-RESEARCH.md** - ImageRenderer gradient limitation, PDFReportView patterns
- **Existing codebase** - ExportManager.swift (ImageRenderer usage), FeatureAccessManager.swift (.usageCards gate), AnalyticsEngine.swift (weeklySummaries, projectBreakdown)
- [Hacking with Swift: How to convert a SwiftUI view to an image](https://www.hackingwithswift.com/quick-start/swiftui/how-to-convert-a-swiftui-view-to-an-image) - Complete ImageRenderer example
- [SwiftUI Lab: SwiftUI Renderers and Their Tricks](https://swiftui-lab.com/swiftui-renders/) - Scale setting, environment limitations

### Secondary (MEDIUM confidence)
- [Pol Piella: Export SwiftUI views as images in macOS](https://www.polpiella.dev/how-to-save-swiftui-views-as-images-in-macos) - NSImage from CGImage, clipboard integration
- [GitHub Wrapped](https://git-wrapped.com/) - Design inspiration for shareable stats cards
- [Apple Developer Forums: ImageRenderer macOS limitations](https://developer.apple.com/forums/thread/736400) - Gradient rendering issues confirmed

### Tertiary (LOW confidence)
- [Medium: Spotify Wrapped for Developers (GitHub Wrapped 2025)](https://medium.com/@programmerraja/spotify-wrapped-but-for-developers-introducing-github-wrapped-2025-0dfe450f1337) - Concept validation for developer stats cards

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - All native Apple frameworks, already proven in ExportManager
- Architecture: HIGH - Extends existing ExportManager pattern, reuses AnalyticsEngine data
- Card design: MEDIUM - Design is subjective; solid colors constraint limits creativity but ensures reliability
- Clipboard integration: HIGH - NSPasteboard.writeObjects() is well-documented and widely used
- Pitfalls: HIGH - Based on Phase 8 ImageRenderer experience and Apple documentation

**Research date:** 2026-02-15
**Valid until:** 2026-03-17 (30 days - stable frameworks, no API changes expected)
