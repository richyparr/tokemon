import AppKit

/// Renders menu bar icons for each MenuBarIconStyle.
/// Returns either an NSImage (for visual styles) or an NSAttributedString (for text styles).
@MainActor
struct MenuBarIconRenderer {

    /// Render the menu bar content for the given style and usage state.
    ///
    /// - Parameters:
    ///   - style: The icon style to render
    ///   - percentage: Current usage percentage (0-100)
    ///   - isMonochrome: Whether to render in system label color only
    ///   - hasData: Whether valid usage data is available
    ///   - suffix: Optional suffix to append (e.g., license state indicator)
    /// - Returns: A tuple of (image, title). Exactly one will be non-nil.
    static func render(
        style: MenuBarIconStyle,
        percentage: Double,
        isMonochrome: Bool,
        hasData: Bool,
        suffix: String?
    ) -> (image: NSImage?, title: NSAttributedString?) {
        switch style {
        case .percentage:
            return renderPercentage(percentage: percentage, isMonochrome: isMonochrome, hasData: hasData, suffix: suffix)
        case .battery:
            return renderBattery(percentage: percentage, isMonochrome: isMonochrome, hasData: hasData)
        case .progressBar:
            return renderProgressBar(percentage: percentage, isMonochrome: isMonochrome, hasData: hasData)
        case .iconAndBar:
            return renderIconAndBar(percentage: percentage, isMonochrome: isMonochrome, hasData: hasData, suffix: suffix)
        case .compact:
            return renderCompact(percentage: percentage, isMonochrome: isMonochrome, hasData: hasData)
        case .trafficLight:
            return renderTrafficLight(percentage: percentage, isMonochrome: isMonochrome, hasData: hasData, suffix: suffix)
        }
    }

    // MARK: - Percentage Style (text)

    private static func renderPercentage(
        percentage: Double,
        isMonochrome: Bool,
        hasData: Bool,
        suffix: String?
    ) -> (image: NSImage?, title: NSAttributedString?) {
        let text: String
        if hasData {
            var base = "\(Int(percentage))%"
            if let suffix = suffix {
                base = "\(base) \(suffix)"
            }
            text = base
        } else {
            text = "--"
        }

        let color = GradientColors.nsColor(for: percentage, isMonochrome: isMonochrome)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium),
            .foregroundColor: color,
        ]
        return (image: nil, title: NSAttributedString(string: text, attributes: attributes))
    }

    // MARK: - Battery Style (image)

    private static func renderBattery(
        percentage: Double,
        isMonochrome: Bool,
        hasData: Bool
    ) -> (image: NSImage?, title: NSAttributedString?) {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            // Battery body dimensions
            let bodyWidth: CGFloat = 13
            let bodyHeight: CGFloat = 9
            let bodyX: CGFloat = 1
            let bodyY: CGFloat = (rect.height - bodyHeight) / 2
            let cornerRadius: CGFloat = 1.5

            // Battery terminal nub
            let nubWidth: CGFloat = 2
            let nubHeight: CGFloat = 4
            let nubX: CGFloat = bodyX + bodyWidth
            let nubY: CGFloat = bodyY + (bodyHeight - nubHeight) / 2

            // Draw battery outline
            let bodyRect = NSRect(x: bodyX, y: bodyY, width: bodyWidth, height: bodyHeight)
            let bodyPath = NSBezierPath(roundedRect: bodyRect, xRadius: cornerRadius, yRadius: cornerRadius)

            if isMonochrome {
                NSColor.labelColor.setStroke()
            } else {
                NSColor.labelColor.withAlphaComponent(0.7).setStroke()
            }
            bodyPath.lineWidth = 1.0
            bodyPath.stroke()

            // Draw terminal nub
            let nubRect = NSRect(x: nubX, y: nubY, width: nubWidth, height: nubHeight)
            let nubPath = NSBezierPath(roundedRect: nubRect, xRadius: 0.5, yRadius: 0.5)
            if isMonochrome {
                NSColor.labelColor.setFill()
            } else {
                NSColor.labelColor.withAlphaComponent(0.5).setFill()
            }
            nubPath.fill()

            // Draw fill
            let fillPercentage = hasData ? max(0, min(percentage, 100)) / 100.0 : 0
            if fillPercentage > 0 {
                let inset: CGFloat = 1.5
                let fillMaxWidth = bodyWidth - (inset * 2)
                let fillWidth = fillMaxWidth * CGFloat(fillPercentage)
                let fillRect = NSRect(
                    x: bodyX + inset,
                    y: bodyY + inset,
                    width: fillWidth,
                    height: bodyHeight - (inset * 2)
                )
                let fillPath = NSBezierPath(roundedRect: fillRect, xRadius: 0.5, yRadius: 0.5)

                if isMonochrome {
                    NSColor.labelColor.withAlphaComponent(0.5).setFill()
                } else {
                    GradientColors.nsColor(for: percentage, isMonochrome: false).setFill()
                }
                fillPath.fill()
            }

            return true
        }

        if isMonochrome {
            image.isTemplate = true
        }

        return (image: image, title: nil)
    }

    // MARK: - Progress Bar Style (image)

    private static func renderProgressBar(
        percentage: Double,
        isMonochrome: Bool,
        hasData: Bool
    ) -> (image: NSImage?, title: NSAttributedString?) {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            let barWidth: CGFloat = 14
            let barHeight: CGFloat = 4
            let barX: CGFloat = (rect.width - barWidth) / 2
            let barY: CGFloat = (rect.height - barHeight) / 2
            let cornerRadius: CGFloat = 2

            // Background track
            let trackRect = NSRect(x: barX, y: barY, width: barWidth, height: barHeight)
            let trackPath = NSBezierPath(roundedRect: trackRect, xRadius: cornerRadius, yRadius: cornerRadius)
            NSColor.labelColor.withAlphaComponent(0.2).setFill()
            trackPath.fill()

            // Fill
            let fillPercentage = hasData ? max(0, min(percentage, 100)) / 100.0 : 0
            if fillPercentage > 0 {
                let fillWidth = barWidth * CGFloat(fillPercentage)
                let fillRect = NSRect(x: barX, y: barY, width: fillWidth, height: barHeight)
                let fillPath = NSBezierPath(roundedRect: fillRect, xRadius: cornerRadius, yRadius: cornerRadius)

                if isMonochrome {
                    NSColor.labelColor.setFill()
                } else {
                    GradientColors.nsColor(for: percentage, isMonochrome: false).setFill()
                }
                fillPath.fill()
            }

            return true
        }

        if isMonochrome {
            image.isTemplate = true
        }

        return (image: image, title: nil)
    }

    // MARK: - Icon + Bar Style (text with SF Symbol)

    private static func renderIconAndBar(
        percentage: Double,
        isMonochrome: Bool,
        hasData: Bool,
        suffix: String?
    ) -> (image: NSImage?, title: NSAttributedString?) {
        let color = GradientColors.nsColor(for: percentage, isMonochrome: isMonochrome)

        let result = NSMutableAttributedString()

        // SF Symbol attachment
        let symbolConfig = NSImage.SymbolConfiguration(pointSize: 10, weight: .medium)
        if let symbolImage = NSImage(systemSymbolName: "bolt.fill", accessibilityDescription: "Usage")?.withSymbolConfiguration(symbolConfig) {
            let attachment = NSTextAttachment()
            attachment.image = symbolImage
            let symbolString = NSAttributedString(attachment: attachment)
            result.append(symbolString)
        }

        // Space + percentage text
        let text: String
        if hasData {
            var base = " \(Int(percentage))%"
            if let suffix = suffix {
                base = "\(base) \(suffix)"
            }
            text = base
        } else {
            text = " --"
        }

        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium),
            .foregroundColor: color,
        ]
        result.append(NSAttributedString(string: text, attributes: textAttributes))

        // Apply color to the entire string including the symbol
        result.addAttribute(.foregroundColor, value: color, range: NSRange(location: 0, length: result.length))

        return (image: nil, title: result)
    }

    // MARK: - Compact Style (text)

    private static func renderCompact(
        percentage: Double,
        isMonochrome: Bool,
        hasData: Bool
    ) -> (image: NSImage?, title: NSAttributedString?) {
        let text = hasData ? "\(Int(percentage))" : "--"
        let color = GradientColors.nsColor(for: percentage, isMonochrome: isMonochrome)

        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium),
            .foregroundColor: color,
        ]
        return (image: nil, title: NSAttributedString(string: text, attributes: attributes))
    }

    // MARK: - Traffic Light Style (colored circle + text)

    private static func renderTrafficLight(
        percentage: Double,
        isMonochrome: Bool,
        hasData: Bool,
        suffix: String?
    ) -> (image: NSImage?, title: NSAttributedString?) {
        let color = GradientColors.nsColor(for: percentage, isMonochrome: isMonochrome)
        let result = NSMutableAttributedString()

        // Draw a filled circle as an image attachment (sized to match Raycast menu bar icon)
        let circleSize: CGFloat = 13
        let circleImage = NSImage(size: NSSize(width: circleSize, height: circleSize), flipped: false) { rect in
            let circlePath = NSBezierPath(ovalIn: rect)
            color.setFill()
            circlePath.fill()
            return true
        }

        let attachment = NSTextAttachment()
        attachment.image = circleImage
        // Vertically center the circle with the text baseline
        attachment.bounds = CGRect(x: 0, y: -2, width: circleSize, height: circleSize)
        result.append(NSAttributedString(attachment: attachment))

        // Space + percentage text
        let text: String
        if hasData {
            var base = " \(Int(percentage))%"
            if let suffix = suffix {
                base = "\(base) \(suffix)"
            }
            text = base
        } else {
            text = " --"
        }

        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .medium),
            .foregroundColor: color,
        ]
        result.append(NSAttributedString(string: text, attributes: textAttributes))

        return (image: nil, title: result)
    }
}
