import XCTest
@testable import MySTT

final class LLMPromptBuilderTests: XCTestCase {
    func test_buildSystemPrompt_containsPunctuation() {
        let prompt = LLMPromptBuilder.buildSystemPrompt(language: .english, dictionaryTerms: "None")
        XCTAssertTrue(prompt.lowercased().contains("punctuation") || prompt.lowercased().contains("stt"))
    }

    func test_buildSystemPrompt_containsLanguage() {
        let prompt = LLMPromptBuilder.buildSystemPrompt(language: .english, dictionaryTerms: "None")
        XCTAssertTrue(prompt.contains("English"))
    }

    func test_buildSystemPrompt_containsPolish() {
        let prompt = LLMPromptBuilder.buildSystemPrompt(language: .polish, dictionaryTerms: "None")
        XCTAssertTrue(prompt.contains("Polish"))
    }

    func test_buildSystemPrompt_containsDictionaryTerms() {
        let prompt = LLMPromptBuilder.buildSystemPrompt(language: .english, dictionaryTerms: "kubernetes->Kubernetes")
        XCTAssertTrue(prompt.contains("kubernetes"))
        XCTAssertTrue(prompt.contains("Kubernetes"))
    }

    func test_buildSystemPrompt_omitsDictionaryWhenNone() {
        let prompt = LLMPromptBuilder.buildSystemPrompt(language: .english, dictionaryTerms: "None")
        XCTAssertFalse(prompt.contains("DICTIONARY"))
    }

    func test_buildSystemPrompt_containsOutputInstruction() {
        let prompt = LLMPromptBuilder.buildSystemPrompt(language: .english, dictionaryTerms: "None")
        XCTAssertTrue(prompt.lowercased().contains("corrected text") || prompt.lowercased().contains("output only"))
    }

    func test_formatDictionaryTerms_empty() {
        let result = LLMPromptBuilder.formatDictionaryTerms([:])
        XCTAssertEqual(result, "None")
    }

    func test_formatDictionaryTerms_singleTerm() {
        let result = LLMPromptBuilder.formatDictionaryTerms(["test": "Test"])
        XCTAssertTrue(result.contains("test"))
        XCTAssertTrue(result.contains("Test"))
        XCTAssertTrue(result.contains("->"))
    }

    func test_formatDictionaryTerms_multipleTerms() {
        let result = LLMPromptBuilder.formatDictionaryTerms(["a": "A", "b": "B"])
        XCTAssertTrue(result.contains("a->A"))
        XCTAssertTrue(result.contains("b->B"))
    }

    func test_buildSystemPrompt_withFormattedDictionary() {
        let terms = LLMPromptBuilder.formatDictionaryTerms(["react": "React", "swift": "Swift"])
        let prompt = LLMPromptBuilder.buildSystemPrompt(language: .english, dictionaryTerms: terms)
        XCTAssertTrue(prompt.contains("react"))
        XCTAssertTrue(prompt.contains("React"))
    }

    func test_buildSystemPrompt_withUserRules() {
        let prompt = LLMPromptBuilder.buildSystemPrompt(language: .english, dictionaryTerms: "None", userRules: "Custom rule here")
        XCTAssertTrue(prompt.contains("Custom rule here"))
    }

    func test_buildSystemPrompt_isCompact() {
        let prompt = LLMPromptBuilder.buildSystemPrompt(language: .english, dictionaryTerms: "None")
        // Compact prompt should be under 300 characters (includes core constraints)
        XCTAssertLessThan(prompt.count, 300, "System prompt should be compact for fast local inference")
    }

    func test_buildSystemPrompt_coreConstraintsFirst() {
        let prompt = LLMPromptBuilder.buildSystemPrompt(language: .english, dictionaryTerms: "None")
        // Critical constraints must appear at the very beginning
        XCTAssertTrue(prompt.hasPrefix("NEVER translate"))
        XCTAssertTrue(prompt.contains("NEVER answer"))
        XCTAssertTrue(prompt.contains("text formatter, not an assistant"))
    }
}
