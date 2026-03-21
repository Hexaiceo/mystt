import AVFoundation

protocol STTEngineProtocol {
    func transcribe(audioBuffer: AVAudioPCMBuffer) async throws -> STTResult
    var isReady: Bool { get }
    func prepare() async throws
}
