import XCTest
import AVFoundation
import WhisperKit
@testable import MySTT

final class WhisperKitRegressionTests: XCTestCase {
    private func makeAudioBuffer(samples: [Float], sampleRate: Double = 16000) -> AVAudioPCMBuffer {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let buffer = AVAudioPCMBuffer(
            pcmFormat: format,
            frameCapacity: AVAudioFrameCount(samples.count)
        )!
        buffer.frameLength = AVAudioFrameCount(samples.count)
        if let channel = buffer.floatChannelData?[0] {
            for (index, sample) in samples.enumerated() {
                channel[index] = sample
            }
        }
        return buffer
    }

    private func synthesizeSpeechToTempFile(_ text: String) throws -> String {
        let outputURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("mystt-whisper-regression-\(UUID().uuidString).aiff")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/say")
        process.arguments = ["-o", outputURL.path, text]
        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw XCTSkip("say failed with status \(process.terminationStatus)")
        }

        return outputURL.path
    }

    private func loadSamples(from path: String) throws -> [Float] {
        try AudioProcessor.loadAudioAsFloatArray(fromPath: path)
    }

    func test_whisperKitEngine_repeatedTranscribe_withoutPrompt() async throws {
        let audioPath = try synthesizeSpeechToTempFile("hello this is a repeated transcription test")
        let buffer = makeAudioBuffer(samples: try loadSamples(from: audioPath))
        let engine = WhisperKitEngine()
        try await engine.prepare()

        let first = try await engine.transcribe(audioBuffer: buffer, context: .empty)
        let second = try await engine.transcribe(audioBuffer: buffer, context: .empty)
        let third = try await engine.transcribe(audioBuffer: buffer, context: .empty)

        XCTAssertFalse(first.isEmpty)
        XCTAssertFalse(second.isEmpty)
        XCTAssertFalse(third.isEmpty)
    }

    func test_whisperKitEngine_repeatedTranscribe_withPrompt() async throws {
        let audioPath = try synthesizeSpeechToTempFile("hello this is a repeated transcription test")
        let buffer = makeAudioBuffer(samples: try loadSamples(from: audioPath))
        let engine = WhisperKitEngine()
        try await engine.prepare()

        let context = TranscriptionContext(prompt: "Use exact spelling for MySTT and Kubernetes.")
        let first = try await engine.transcribe(audioBuffer: buffer, context: context)
        let second = try await engine.transcribe(audioBuffer: buffer, context: context)
        let third = try await engine.transcribe(audioBuffer: buffer, context: context)

        XCTAssertFalse(first.isEmpty)
        XCTAssertFalse(second.isEmpty)
        XCTAssertFalse(third.isEmpty)
    }
}
