import XCTest
import ApplicationServices
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

    func test_shouldPreferSelectedTextReplacement_whenSupported() {
        XCTAssertTrue(
            AutoPaster.shouldPreferSelectedTextReplacement(
                role: kAXTextAreaRole as String,
                supportsSelectedTextReplacement: true
            )
        )
    }

    func test_shouldUseDirectValueInsert_onlyForPlainTextLikeControlsWithoutSelectedTextReplacement() {
        XCTAssertTrue(
            AutoPaster.shouldUseDirectValueInsert(
                role: kAXTextFieldRole as String,
                supportsSelectedTextReplacement: false
            )
        )

        XCTAssertFalse(
            AutoPaster.shouldUseDirectValueInsert(
                role: kAXTextAreaRole as String,
                supportsSelectedTextReplacement: false
            )
        )
    }

    func test_mutationMatches_verifiesReplacementWithinDocument() {
        let beforeRange = CFRange(location: 6, length: 5)
        let afterRange = CFRange(location: 17, length: 0)

        XCTAssertTrue(
            AutoPaster.mutationMatches(
                beforeValue: "hello world again",
                beforeRange: beforeRange,
                afterValue: "hello translated again",
                afterRange: afterRange,
                replacement: "translated"
            )
        )
    }

    func test_mutationMatches_rejectsUnchangedText() {
        let range = CFRange(location: 6, length: 5)

        XCTAssertFalse(
            AutoPaster.mutationMatches(
                beforeValue: "hello world again",
                beforeRange: range,
                afterValue: "hello world again",
                afterRange: range,
                replacement: "translated"
            )
        )
    }

    func test_normalizedRange_acceptsCaretAtDocumentEnd() {
        let range = CFRange(location: 11, length: 0)

        XCTAssertEqual(
            AutoPaster.normalizedRange(range, stringLength: 11)?.location,
            11
        )
        XCTAssertEqual(
            AutoPaster.normalizedRange(range, stringLength: 11)?.length,
            0
        )
    }

    func test_rangesEqual_matchesLocationAndLength() {
        XCTAssertTrue(
            AutoPaster.rangesEqual(
                CFRange(location: 4, length: 0),
                CFRange(location: 4, length: 0)
            )
        )
        XCTAssertFalse(
            AutoPaster.rangesEqual(
                CFRange(location: 4, length: 0),
                CFRange(location: 5, length: 0)
            )
        )
    }

    func test_describeRange_formatsReadableDebugOutput() {
        XCTAssertEqual(
            AutoPaster.describe(range: CFRange(location: 12, length: 3)),
            "{location=12, length=3}"
        )
        XCTAssertEqual(AutoPaster.describe(range: nil), "nil")
    }
}
