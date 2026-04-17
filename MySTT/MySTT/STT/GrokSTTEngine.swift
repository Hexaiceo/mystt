import Foundation
import AVFoundation

/// Groq API speech-to-text using /v1/audio/transcriptions endpoint
class GroqSTTEngine: STTEngineProtocol {
    private let apiKey: String
    private let baseURL = "https://api.groq.com/openai/v1/audio/transcriptions"
    private(set) var isReady: Bool = false

    init(apiKey: String) {
        self.apiKey = apiKey
        self.isReady = !apiKey.isEmpty
    }

    func prepare() async throws {
        guard !apiKey.isEmpty else { throw STTError.notInitialized }
        // Validate key
        var request = URLRequest(url: URL(string: "https://api.groq.com/openai/v1/models")!)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw STTError.transcriptionFailed(underlying: NSError(
                domain: "GroqSTT", code: code,
                userInfo: [NSLocalizedDescriptionKey: "Groq API key validation failed (HTTP \(code))"]
            ))
        }
        isReady = true
    }

    func transcribe(audioBuffer: AVAudioPCMBuffer, context: TranscriptionContext = .empty) async throws -> STTResult {
        guard isReady else { throw STTError.notInitialized }

        let audioData = audioBuffer.toWAVData()
        guard !audioData.isEmpty else { throw STTError.emptyAudio }

        let boundary = UUID().uuidString
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.wav\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/wav\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("whisper-large-v3-turbo\r\n".data(using: .utf8)!)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"response_format\"\r\n\r\n".data(using: .utf8)!)
        body.append("verbose_json\r\n".data(using: .utf8)!)
        if let prompt = context.prompt?.trimmingCharacters(in: .whitespacesAndNewlines), !prompt.isEmpty {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"prompt\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(prompt)\r\n".data(using: .utf8)!)
        }
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            let msg = String(data: data, encoding: .utf8) ?? "Unknown"
            throw STTError.transcriptionFailed(underlying: NSError(
                domain: "GroqSTT", code: code,
                userInfo: [NSLocalizedDescriptionKey: "HTTP \(code): \(msg.prefix(200))"]
            ))
        }

        return try parseResponse(data)
    }

    private func parseResponse(_ data: Data) throws -> STTResult {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return STTResult.empty
        }

        let text = json["text"] as? String ?? ""
        let langCode = json["language"] as? String ?? "unknown"
        let language = Language(whisperCode: langCode)

        let segments: [MySTTSegment]
        if let jsonSegments = json["segments"] as? [[String: Any]] {
            segments = jsonSegments.map { seg in
                MySTTSegment(
                    text: seg["text"] as? String ?? "",
                    start: seg["start"] as? TimeInterval ?? 0,
                    end: seg["end"] as? TimeInterval ?? 0,
                    confidence: Float(seg["avg_logprob"] as? Double ?? 0)
                )
            }
        } else {
            segments = []
        }

        return STTResult(
            text: text,
            language: language,
            confidence: segments.isEmpty ? 0.9 : segments.reduce(0) { $0 + $1.confidence } / Float(segments.count),
            segments: segments
        )
    }
}
