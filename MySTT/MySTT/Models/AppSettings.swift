import Foundation

struct AppSettings: Codable, Equatable {
    var sttProvider: STTProvider = .whisperKit
    var whisperModelName: String = "openai_whisper-large-v3-v20240930_turbo_632MB"
    var groqSTTAPIKey: String = ""  // Groq API key for cloud STT

    var llmProvider: LLMProvider = .localLMStudio
    var mlxModelName: String = "mlx-community/Qwen2.5-3B-Instruct-4bit"
    var lmStudioModelName: String = "bielik-11b-v3.0-instruct"
    var lmStudioURL: String = "http://127.0.0.1:1234/v1"
    var ollamaModelName: String = "qwen2.5:3b"
    var ollamaURL: String = "http://127.0.0.1:11434"
    var groqAPIKey: String = ""
    var openaiAPIKey: String = ""

    var enablePunctuationModel: Bool = false
    var enableLLMCorrection: Bool = true
    var enableDictionary: Bool = true

    var hotkeyKeyCode: UInt16 = 0x3F
    var hotkeyModifiers: UInt32 = 0
    var autoPaste: Bool = true
    var showNotification: Bool = true
    var playSound: Bool = true
    var launchAtLogin: Bool = false

    private static let storageKey = "MySTTAppSettings"

    /// Load settings by reading individual @AppStorage keys (which the Settings UI writes to),
    /// falling back to the JSON blob, then to defaults.
    static func load() -> AppSettings {
        let ud = UserDefaults.standard
        func trimmed(_ value: String?) -> String? {
            value?.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Start from JSON blob if available, otherwise defaults
        var settings: AppSettings
        if let data = ud.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) {
            settings = decoded
        } else {
            settings = AppSettings()
        }

        // Override with individual @AppStorage keys (these are what the Settings UI actually writes)
        if let raw = ud.string(forKey: "sttProvider"), let val = STTProvider(rawValue: raw) {
            settings.sttProvider = val
        }
        if let val = trimmed(ud.string(forKey: "whisperModelName")), !val.isEmpty {
            settings.whisperModelName = val
        }
        if let raw = ud.string(forKey: "llmProvider"), let val = LLMProvider(rawValue: raw) {
            settings.llmProvider = val
        }
        if let val = trimmed(ud.string(forKey: "mlxModelName")), !val.isEmpty {
            settings.mlxModelName = val
        }
        if let val = trimmed(ud.string(forKey: "lmStudioModelName")), !val.isEmpty {
            settings.lmStudioModelName = val
        }
        if let val = trimmed(ud.string(forKey: "lmStudioURL")), !val.isEmpty {
            settings.lmStudioURL = val
        }
        if let val = trimmed(ud.string(forKey: "ollamaModelName")), !val.isEmpty {
            settings.ollamaModelName = val
        }
        if let val = trimmed(ud.string(forKey: "ollamaURL")), !val.isEmpty {
            settings.ollamaURL = val
        }
        // Bool overrides — only apply if the key was explicitly set
        if ud.object(forKey: "enableLLMCorrection") != nil {
            settings.enableLLMCorrection = ud.bool(forKey: "enableLLMCorrection")
        }
        if ud.object(forKey: "enablePunctuationModel") != nil {
            settings.enablePunctuationModel = ud.bool(forKey: "enablePunctuationModel")
        }
        if ud.object(forKey: "enableDictionary") != nil {
            settings.enableDictionary = ud.bool(forKey: "enableDictionary")
        }
        if ud.object(forKey: "autoPaste") != nil {
            settings.autoPaste = ud.bool(forKey: "autoPaste")
        }
        if ud.object(forKey: "playSound") != nil {
            settings.playSound = ud.bool(forKey: "playSound")
        }
        if ud.object(forKey: "showNotification") != nil {
            settings.showNotification = ud.bool(forKey: "showNotification")
        }
        if ud.object(forKey: "launchAtLogin") != nil {
            settings.launchAtLogin = ud.bool(forKey: "launchAtLogin")
        }

        return settings
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }
}
