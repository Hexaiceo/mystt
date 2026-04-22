import XCTest
@testable import MySTT

final class DictationJournalTests: XCTestCase {
    private func makeJournal(testName: String = #function) -> DictationJournal {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("mystt-journal-\(UUID().uuidString)-\(testName)", isDirectory: true)
        try? FileManager.default.removeItem(at: directory)
        return DictationJournal(recordsDirectoryURL: directory)
    }

    func test_journalPersistsClipboardOnlyDeliveryForRecovery() async throws {
        let journal = makeJournal()
        let target = TargetAppSnapshot(
            processIdentifier: 123,
            localizedName: "Codex",
            bundleIdentifier: "com.openai.codex"
        )

        let record = try await journal.createRecord(
            rawText: "raw text",
            finalText: "final text",
            language: .english,
            targetApp: target
        )
        let updated = try await journal.markDelivery(
            recordID: record.id,
            result: .clipboardOnly(reason: "Target field lost focus")
        )
        let recoverable = try await journal.mostRecentRecoverableRecord()

        XCTAssertEqual(updated?.deliveryStatus, .clipboardOnly)
        XCTAssertTrue(updated?.requiresRecovery ?? false)
        XCTAssertEqual(recoverable?.id, record.id)
    }

    func test_markRecoveredSuppressesRepeatLaunchRecovery() async throws {
        let journal = makeJournal()
        let record = try await journal.createRecord(
            rawText: "raw text",
            finalText: "final text",
            language: .english,
            targetApp: nil
        )
        _ = try await journal.markDelivery(
            recordID: record.id,
            result: .failed(reason: "Paste failed")
        )

        _ = try await journal.markRecovered(
            recordID: record.id,
            note: "Recovered to clipboard on launch"
        )
        let recoverable = try await journal.mostRecentRecoverableRecord()

        XCTAssertNil(recoverable)
    }

    func test_unverifiedInsertionRemainsRecoverable() async throws {
        let journal = makeJournal()
        let record = try await journal.createRecord(
            rawText: "raw text",
            finalText: "final text",
            language: .english,
            targetApp: nil
        )
        let updated = try await journal.markDelivery(
            recordID: record.id,
            result: .inserted(
                method: .systemEventsPaste,
                verified: false,
                failureReason: "Paste sent, but insertion could not be verified"
            )
        )

        XCTAssertEqual(updated?.deliveryStatus, .deliveryUnverified)
        XCTAssertTrue(updated?.requiresRecovery ?? false)
    }
}
