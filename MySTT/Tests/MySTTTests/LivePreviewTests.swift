import XCTest
import AVFoundation
@testable import MySTT

final class LivePreviewTests: XCTestCase {

    // MARK: - AudioCaptureEngine.currentBuffer()

    func test_currentBuffer_returnsNilWhenNotRecording() {
        let engine = AudioCaptureEngine()
        XCTAssertNil(engine.currentBuffer())
    }

    // MARK: - STTEngineProtocol default preview

    func test_defaultPreviewTranscribe_returnsEmptyString() async throws {
        let engine = DefaultPreviewEngine()
        let buffer = Self.makeSilentBuffer(frames: 16000)
        let result = try await engine.previewTranscribe(audioBuffer: buffer)
        XCTAssertEqual(result, "")
    }

    // MARK: - MockSTTEngine preview

    func test_mockPreviewTranscribe_returnsConfiguredText() async throws {
        let engine = MockSTTEngine()
        engine.mockPreviewText = "Hello world"
        let buffer = Self.makeSilentBuffer(frames: 16000)
        let result = try await engine.previewTranscribe(audioBuffer: buffer)
        XCTAssertEqual(result, "Hello world")
        XCTAssertEqual(engine.previewCallCount, 1)
    }

    func test_mockPreviewTranscribe_doesNotIncrementTranscribeCount() async throws {
        let engine = MockSTTEngine()
        let buffer = Self.makeSilentBuffer(frames: 16000)
        _ = try await engine.previewTranscribe(audioBuffer: buffer)
        XCTAssertEqual(engine.transcribeCallCount, 0)
        XCTAssertEqual(engine.previewCallCount, 1)
    }

    // MARK: - RecordingOverlayWindow preview text

    @MainActor
    func test_overlay_updatePreviewText_requiresListeningStatus() {
        let overlay = RecordingOverlayWindow()
        overlay.show(status: .processing)
        overlay.updatePreviewText("should not appear")
        // No crash, just a no-op
    }

    @MainActor
    func test_overlay_hideResetsPreview() {
        let overlay = RecordingOverlayWindow()
        overlay.show(status: .listening)
        overlay.updatePreviewText("some text")
        overlay.hide()
        // After hide, showing again should not retain old preview
        overlay.show(status: .listening)
        overlay.updatePreviewText("")
    }

    // MARK: - Helpers

    private static func makeSilentBuffer(frames: AVAudioFrameCount) -> AVAudioPCMBuffer {
        let format = AVAudioFormat(standardFormatWithSampleRate: 16000, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames)!
        buffer.frameLength = frames
        if let data = buffer.floatChannelData?[0] {
            for i in 0..<Int(frames) { data[i] = 0 }
        }
        return buffer
    }
}

private class DefaultPreviewEngine: STTEngineProtocol {
    var isReady: Bool = true
    var supportsPromptConditioning: Bool = true

    func prepare() async throws {}
    func transcribe(audioBuffer: AVAudioPCMBuffer, context: TranscriptionContext) async throws -> STTResult {
        STTResult(text: "", language: .unknown, confidence: 0, segments: [])
    }
}
