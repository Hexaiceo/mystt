import AVFoundation
@testable import MySTT

class MockSTTEngine: STTEngineProtocol {
    var isReady: Bool = true
    var mockResult: STTResult = STTResult(text: "hello world", language: .english, confidence: 0.95, segments: [])
    var shouldThrow: Error?
    var transcribeCallCount = 0
    var prepareCallCount = 0

    func prepare() async throws {
        prepareCallCount += 1
    }

    func transcribe(audioBuffer: AVAudioPCMBuffer) async throws -> STTResult {
        transcribeCallCount += 1
        if let error = shouldThrow { throw error }
        return mockResult
    }
}
