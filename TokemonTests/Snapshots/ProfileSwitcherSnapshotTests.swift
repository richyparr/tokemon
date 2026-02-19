import SnapshotTesting
import SwiftUI
import AppKit
import XCTest
@testable import tokemon

/// Snapshot tests for ProfileSwitcherView.
///
/// ProfileSwitcherView is a compact dropdown displayed at the top of the popover
/// when 2+ profiles exist. It reads from `@Environment(ProfileManager.self)`.
///
/// ProfileManager uses UserDefaults for profile storage and keychain for credentials.
/// In test context, init() creates a "Default" profile and attempts keychain sync
/// (which may fail silently in test environment). Additional profiles can be created
/// via `createProfile(name:)` without issue.
@MainActor
final class ProfileSwitcherSnapshotTests: SnapshotTestCase {

    /// Width matches popover inner content (320 minus padding = ~290 usable).
    private let switcherWidth: CGFloat = 290
    /// Compact height for the profile switcher row.
    private let switcherHeight: CGFloat = 40

    override func setUp() {
        super.setUp()
        // Clear profile data between tests to prevent profile accumulation.
        UserDefaults.standard.removeObject(forKey: "tokemon.profiles")
        UserDefaults.standard.removeObject(forKey: "tokemon.activeProfileId")
    }

    // MARK: - Two Profiles

    func testProfileSwitcher_TwoProfiles() {
        let profileManager = ProfileManager()
        // ProfileManager init creates a "Default" profile automatically.
        // Add a second profile to trigger multi-profile display.
        profileManager.createProfile(name: "Work")

        let view = ProfileSwitcherView()
            .environment(profileManager)

        let vc = view.snapshotController(width: switcherWidth, height: switcherHeight)
        assertSnapshot(of: vc, as: .image(precision: snapshotPrecision))
    }

    // MARK: - Three Profiles

    func testProfileSwitcher_ThreeProfiles() {
        let profileManager = ProfileManager()
        let workProfile = profileManager.createProfile(name: "Work")
        profileManager.createProfile(name: "Personal")

        // Switch active to the second profile to show it in the dropdown label
        profileManager.setActiveProfile(id: workProfile.id)

        let view = ProfileSwitcherView()
            .environment(profileManager)

        let vc = view.snapshotController(width: switcherWidth, height: switcherHeight)
        assertSnapshot(of: vc, as: .image(precision: snapshotPrecision))
    }
}
