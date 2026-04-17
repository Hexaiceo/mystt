import AVFoundation

protocol STTEngineProtocol {
    func transcribe(audioBuffer: AVAudioPCMBuffer, context: TranscriptionContext) async throws -> STTResult
    var isReady: Bool { get }
    func prepare() async throws
}

extension STTEngineProtocol {
    func transcribe(audioBuffer: AVAudioPCMBuffer) async throws -> STTResult {
        try await transcribe(audioBuffer: audioBuffer, context: .empty)
    }
}
