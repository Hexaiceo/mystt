import Foundation

enum LLMProvider: String, CaseIterable, Codable, Identifiable {
    case localMLX = "localMLX"
    case localLMStudio = "localLMStudio"
    case ollama = "ollama"
    case groq = "groq"
    case openai = "openai"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .localMLX: return "MLX (Local)"
        case .localLMStudio: return "LM Studio (Local)"
        case .ollama: return "Ollama (Local)"
        case .groq: return "Groq Cloud"
        case .openai: return "OpenAI"
        }
    }

    var isLocal: Bool {
        switch self {
        case .localMLX, .localLMStudio, .ollama: return true
        default: return false
        }
    }

    var requiresAPIKey: Bool { !isLocal }
}
