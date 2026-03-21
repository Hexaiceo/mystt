import Foundation

enum Language: String, CaseIterable, Codable, Identifiable {
    case english = "en"
    case polish = "pl"
    case unknown = "unknown"
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .english: return "English"
        case .polish: return "Polish"
        case .unknown: return "Unknown"
        }
    }
    init(whisperCode: String) {
        let normalized = whisperCode.lowercased().trimmingCharacters(in: .whitespaces)
        switch normalized {
        case "en", "en-us", "en-gb", "en-au", "en-ca", "en-nz", "en-ie", "en-za", "english":
            self = .english
        case "pl", "pl-pl", "polish":
            self = .polish
        // Map Slavic/nearby languages that WhisperKit may misdetect → Polish
        case "sk", "cs", "hr", "sl", "bs", "sr", "uk", "be", "ru", "bg", "mk", "lt", "lv",
             "slovak", "czech", "croatian", "slovenian", "bosnian", "serbian",
             "ukrainian", "belarusian", "russian", "bulgarian", "macedonian",
             "lithuanian", "latvian":
            self = .polish
        default:
            if normalized.hasPrefix("en") { self = .english }
            else if normalized.hasPrefix("pl") { self = .polish }
            else { self = .unknown }
        }
    }
}
