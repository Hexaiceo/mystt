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
}
