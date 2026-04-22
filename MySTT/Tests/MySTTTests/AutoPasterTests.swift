import XCTest
@testable import MySTT

final class AutoPasterTests: XCTestCase {
    func test_classifyPermissionIssue_detectsAccessibilityFailure() {
        let issue = AutoPaster.classifyPermissionIssue(
            for: "System Events got an error: MySTT is not allowed to send keystrokes."
        )

        XCTAssertEqual(issue, .accessibility)
    }

    func test_classifyPermissionIssue_detectsAutomationFailure() {
        let issue = AutoPaster.classifyPermissionIssue(
            for: "Not authorized to send Apple events to System Events."
        )

        XCTAssertEqual(issue, .automation)
    }

    func test_classifyPermissionIssue_returnsUnknownForOtherErrors() {
        let issue = AutoPaster.classifyPermissionIssue(
            for: "Application isn’t running."
        )

        XCTAssertEqual(issue, .unknown)
    }

    func test_selectTargetApp_prefersFrontmostExternalApp() {
        let frontmost = TargetAppSnapshot(
            processIdentifier: 101,
            localizedName: "Arc",
            bundleIdentifier: "company.thebrowser.Browser"
        )
        let previous = TargetAppSnapshot(
            processIdentifier: 202,
            localizedName: "Codex",
            bundleIdentifier: "com.openai.codex"
        )

        let selected = AutoPaster.selectTargetApp(frontmostApp: frontmost, lastExternalApp: previous)

        XCTAssertEqual(selected, frontmost)
    }

    func test_selectTargetApp_fallsBackToPreviousExternalAppWhenFrontmostMissing() {
        let previous = TargetAppSnapshot(
            processIdentifier: 202,
            localizedName: "Codex",
            bundleIdentifier: "com.openai.codex"
        )

        let selected = AutoPaster.selectTargetApp(frontmostApp: nil, lastExternalApp: previous)

        XCTAssertEqual(selected, previous)
    }

    func test_isSelf_detectsOwnBundleIdentifier() {
        let snapshot = TargetAppSnapshot(
            processIdentifier: 303,
            localizedName: "MySTT",
            bundleIdentifier: "com.mystt.app"
        )

        XCTAssertTrue(AutoPaster.isSelf(snapshot, selfBundleIdentifier: "com.mystt.app"))
        XCTAssertFalse(AutoPaster.isSelf(snapshot, selfBundleIdentifier: "com.other.app"))
    }
}
