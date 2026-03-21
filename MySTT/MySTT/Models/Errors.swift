import Foundation

enum STTError: LocalizedError {
    case notInitialized
    case emptyAudio
    case transcriptionFailed(underlying: Error?)
    case modelNotFound(name: String)
    case timeout

    var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "STT engine is not initialized."
        case .emptyAudio:
            return "Audio buffer is empty."
        case .transcriptionFailed(let e):
            return "Transcription failed: \(e?.localizedDescription ?? "unknown")"
        case .modelNotFound(let n):
            return "Model '\(n)' not found."
        case .timeout:
            return "STT timed out."
        }
    }
}

enum LLMError: LocalizedError {
    case providerUnavailable(provider: String)
    case apiKeyMissing(provider: String)
    case requestFailed(statusCode: Int, message: String)
    case timeout
    case invalidResponse(details: String)

    var errorDescription: String? {
        switch self {
        case .providerUnavailable(let p):
            return "LLM provider '\(p)' unavailable."
        case .apiKeyMissing(let p):
            return "API key for '\(p)' missing."
        case .requestFailed(let s, let m):
            return "Request failed (\(s)): \(m)"
        case .timeout:
            return "LLM request timed out."
        case .invalidResponse(let d):
            return "Invalid response: \(d)"
        }
    }
}

enum PasteError: LocalizedError {
    case accessibilityDenied
    case pasteFailed(underlying: Error?)

    var errorDescription: String? {
        switch self {
        case .accessibilityDenied:
            return "Accessibility permission required."
        case .pasteFailed(let e):
            return "Paste failed: \(e?.localizedDescription ?? "unknown")"
        }
    }
}
