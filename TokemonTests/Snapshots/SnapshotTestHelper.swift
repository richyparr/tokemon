import SnapshotTesting
import SwiftUI
import AppKit
import XCTest
@testable import tokemon

// MARK: - SwiftUI View Snapshotting Helper

extension SwiftUI.View {
    /// Wraps a SwiftUI view in NSHostingController with explicit dimensions for snapshot testing.
    /// The hosting controller is laid out immediately so the view hierarchy is ready for capture.
    ///
    /// - Parameters:
    ///   - width: The width of the snapshot frame. Defaults to 320.
    ///   - height: The height of the snapshot frame. Defaults to 400.
    /// - Returns: An NSViewController suitable for use with `assertSnapshot`.
    func snapshotController(
        width: CGFloat = 320,
        height: CGFloat = 400
    ) -> NSViewController {
        let vc = NSHostingController(rootView: self)
        vc.view.frame = CGRect(x: 0, y: 0, width: width, height: height)
        vc.view.layoutSubtreeIfNeeded()
        return vc
    }
}

// MARK: - Snapshot Test Base Class

/// Base class for snapshot tests. Configures `record: .missing` so reference
/// images are auto-recorded on first run, then compared on subsequent runs.
///
/// Usage:
/// ```swift
/// final class MyViewSnapshotTests: SnapshotTestCase {
///     func testMyView() {
///         let view = MyView()
///         let vc = view.snapshotController(width: 320, height: 400)
///         assertSnapshot(of: vc, as: .image(precision: snapshotPrecision))
///     }
/// }
/// ```
class SnapshotTestCase: XCTestCase {
    override func invokeTest() {
        withSnapshotTesting(record: .missing) {
            super.invokeTest()
        }
    }

    /// Standard precision for cross-machine tolerance (Retina vs CI).
    /// 0.98 allows for minor anti-aliasing and font rendering differences.
    let snapshotPrecision: Float = 0.98

    /// Higher precision for tests where pixel-perfect accuracy matters.
    let strictPrecision: Float = 0.995

    /// Lower precision for tests with known rendering variations (e.g., gradients, charts).
    let relaxedPrecision: Float = 0.95
}
