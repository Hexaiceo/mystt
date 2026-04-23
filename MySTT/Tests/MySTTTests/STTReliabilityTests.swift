import XCTest
@testable import MySTT

final class STTReliabilityTests: XCTestCase {
    func test_recordingStartBlocker_detectsInFlightProcessing() {
        let blocker = AppState.recordingStartBlocker(
            isEnabled: true,
            isRecording: false,
            isProcessing: true
        )

        XCTAssertEqual(blocker, .processingPreviousDictation)
    }

    func test_recordingStartBlocker_detectsActiveRecordingBeforeProcessing() {
        let blocker = AppState.recordingStartBlocker(
            isEnabled: true,
            isRecording: true,
            isProcessing: true
        )

        XCTAssertEqual(blocker, .alreadyRecording)
    }

    func test_transcriptionTimeout_scalesWithAudioDurationButStaysBounded() {
        XCTAssertEqual(AppState.transcriptionTimeout(forAudioDuration: 0.1), 8, accuracy: 0.001)
        XCTAssertEqual(AppState.transcriptionTimeout(forAudioDuration: 5.0), 15, accuracy: 0.001)
        XCTAssertEqual(AppState.transcriptionTimeout(forAudioDuration: 30.0), 25, accuracy: 0.001)
    }

    func test_shouldRetryTranscription_retriesRecoverableFailures() {
        XCTAssertTrue(AppState.shouldRetryTranscription(after: STTError.timeout))
        XCTAssertTrue(AppState.shouldRetryTranscription(after: STTError.notInitialized))
        XCTAssertTrue(AppState.shouldRetryTranscription(after: STTError.transcriptionFailed(underlying: nil)))
        XCTAssertTrue(AppState.shouldRetryTranscription(after: STTError.modelNotFound(name: "test")))
    }

    func test_shouldRetryTranscription_doesNotRetryNonRecoverableFailures() {
        XCTAssertFalse(AppState.shouldRetryTranscription(after: STTError.emptyAudio))
        XCTAssertFalse(AppState.shouldRetryTranscription(after: MockLLMError.timeout))
    }
}
