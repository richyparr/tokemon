import AppKit

extension NSWindow {
    /// Position specification for window placement
    struct Position {
        enum Horizontal { case left, center, right }
        enum Vertical { case top, center, bottom }

        var vertical: Vertical
        var horizontal: Horizontal
        var padding: CGFloat

        init(vertical: Vertical, horizontal: Horizontal, padding: CGFloat = 16) {
            self.vertical = vertical
            self.horizontal = horizontal
            self.padding = padding
        }
    }

    /// Set the window position relative to the visible screen area.
    /// Respects the menu bar and Dock when calculating position.
    ///
    /// - Parameters:
    ///   - position: Position specification (corner + padding)
    ///   - screen: Target screen (defaults to window's current screen)
    func setPosition(_ position: Position, in screen: NSScreen? = nil) {
        guard let visibleFrame = (screen ?? self.screen ?? NSScreen.main)?.visibleFrame else { return }

        let x: CGFloat
        switch position.horizontal {
        case .left:
            x = visibleFrame.minX + position.padding
        case .center:
            x = visibleFrame.midX - frame.width / 2
        case .right:
            x = visibleFrame.maxX - frame.width - position.padding
        }

        let y: CGFloat
        switch position.vertical {
        case .top:
            y = visibleFrame.maxY - frame.height - position.padding
        case .center:
            y = visibleFrame.midY - frame.height / 2
        case .bottom:
            y = visibleFrame.minY + position.padding
        }

        setFrameOrigin(CGPoint(x: x, y: y))
    }

    /// Convenience method for setting position with separate parameters.
    func setPosition(vertical: Position.Vertical, horizontal: Position.Horizontal, padding: CGFloat = 16) {
        setPosition(Position(vertical: vertical, horizontal: horizontal, padding: padding))
    }
}
