import AVFoundation

protocol STTEngineProtocol {
    func transcribe(audioBuffer: AVAudioPCMBuffer, context: TranscriptionContext) async throws -> STTResult
    var isReady: Bool { get }
    var supportsPromptConditioning: Bool { get }
    func prepare() async throws
    func reset() async
}

extension STTEngineProtocol {
    var supportsPromptConditioning: Bool { true }

    func transcribe(audioBuffer: AVAudioPCMBuffer) async throws -> STTResult {
        try await transcribe(audioBuffer: audioBuffer, context: .empty)
    }

    func reset() async {}
}
