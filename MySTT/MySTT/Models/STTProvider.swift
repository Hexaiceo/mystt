import Foundation

enum STTProvider: String, CaseIterable, Codable, Identifiable {
    case whisperKit = "whisperKit"
    case groqSTT = "groqSTT"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .whisperKit: return "WhisperKit (Local)"
        case .groqSTT: return "Groq API (Cloud)"
        }
    }

    var isLocal: Bool { self == .whisperKit }
}
