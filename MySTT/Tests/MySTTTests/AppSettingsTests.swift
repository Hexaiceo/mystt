import XCTest
@testable import MySTT

final class AppSettingsTests: XCTestCase {
    func test_codable_roundtrip() throws {
        let original = AppSettings()
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AppSettings.self, from: data)
        XCTAssertEqual(decoded, original)
    }

    func test_defaultValues_sttProvider() {
        let settings = AppSettings()
        XCTAssertEqual(settings.sttProvider, .whisperKit)
    }

    func test_defaultValues_llmProvider() {
        let settings = AppSettings()
        XCTAssertEqual(settings.llmProvider, .localLMStudio)
    }

    func test_defaultValues_enableLLMCorrection() {
        let settings = AppSettings()
        XCTAssertTrue(settings.enableLLMCorrection)
    }

    func test_defaultValues_enablePunctuationModel() {
        let settings = AppSettings()
        XCTAssertFalse(settings.enablePunctuationModel)
    }

    func test_defaultValues_enableDictionary() {
        let settings = AppSettings()
        XCTAssertTrue(settings.enableDictionary)
    }

    func test_defaultValues_autoPaste() {
        let settings = AppSettings()
        XCTAssertTrue(settings.autoPaste)
    }

    func test_defaultValues_showNotification() {
        let settings = AppSettings()
        XCTAssertTrue(settings.showNotification)
    }

    func test_defaultValues_playSound() {
        let settings = AppSettings()
        XCTAssertTrue(settings.playSound)
    }

    func test_defaultValues_launchAtLogin() {
        let settings = AppSettings()
        XCTAssertFalse(settings.launchAtLogin)
    }

    func test_defaultValues_whisperModelName() {
        let settings = AppSettings()
        XCTAssertEqual(settings.whisperModelName, "openai_whisper-large-v3-v20240930_turbo_632MB")
    }

    func test_defaultValues_lmStudioURL() {
        let settings = AppSettings()
        XCTAssertEqual(settings.lmStudioURL, "http://127.0.0.1:1234/v1")
    }

    func test_defaultValues_apiKeysEmpty() {
        let settings = AppSettings()
        XCTAssertEqual(settings.groqSTTAPIKey, "")
        XCTAssertEqual(settings.groqAPIKey, "")
        XCTAssertEqual(settings.openaiAPIKey, "")
    }

    func test_defaultValues_hotkeyKeyCode() {
        let settings = AppSettings()
        XCTAssertEqual(settings.hotkeyKeyCode, 0x3F)
    }

    func test_equatable_sameValues() {
        let a = AppSettings()
        let b = AppSettings()
        XCTAssertEqual(a, b)
    }

    func test_equatable_differentValues() {
        let a = AppSettings()
        var b = AppSettings()
        b.autoPaste = false
        XCTAssertNotEqual(a, b)
    }

    func test_codable_modifiedValues() throws {
        var settings = AppSettings()
        settings.sttProvider = .groqSTT
        settings.llmProvider = .groq
        settings.enableLLMCorrection = false
        settings.autoPaste = false

        let data = try JSONEncoder().encode(settings)
        let decoded = try JSONDecoder().decode(AppSettings.self, from: data)
        XCTAssertEqual(decoded.sttProvider, .groqSTT)
        XCTAssertEqual(decoded.llmProvider, .groq)
        XCTAssertFalse(decoded.enableLLMCorrection)
        XCTAssertFalse(decoded.autoPaste)
    }

    // MARK: - LLMProvider tests

    func test_llmProvider_isLocal() {
        XCTAssertTrue(LLMProvider.localMLX.isLocal)
        XCTAssertTrue(LLMProvider.localLMStudio.isLocal)
        XCTAssertFalse(LLMProvider.groq.isLocal)
        XCTAssertFalse(LLMProvider.openai.isLocal)
    }

    func test_llmProvider_requiresAPIKey() {
        XCTAssertFalse(LLMProvider.localMLX.requiresAPIKey)
        XCTAssertFalse(LLMProvider.localLMStudio.requiresAPIKey)
        XCTAssertTrue(LLMProvider.groq.requiresAPIKey)
        XCTAssertTrue(LLMProvider.openai.requiresAPIKey)
    }

    func test_llmProvider_allCases_count() {
        XCTAssertEqual(LLMProvider.allCases.count, 4)
    }

    func test_llmProvider_displayName() {
        XCTAssertEqual(LLMProvider.localMLX.displayName, "MLX (Local)")
        XCTAssertEqual(LLMProvider.localLMStudio.displayName, "LM Studio (Local)")
        XCTAssertEqual(LLMProvider.groq.displayName, "Groq Cloud")
        XCTAssertEqual(LLMProvider.openai.displayName, "OpenAI")
    }

    // MARK: - STTProvider tests

    func test_sttProvider_allCases_count() {
        XCTAssertEqual(STTProvider.allCases.count, 2)
    }

    func test_sttProvider_displayName() {
        XCTAssertEqual(STTProvider.whisperKit.displayName, "WhisperKit (Local)")
        XCTAssertEqual(STTProvider.groqSTT.displayName, "Groq API (Cloud)")
    }

    func test_sttProvider_isLocal() {
        XCTAssertTrue(STTProvider.whisperKit.isLocal)
        XCTAssertFalse(STTProvider.groqSTT.isLocal)
    }
}
