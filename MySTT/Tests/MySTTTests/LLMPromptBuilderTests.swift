import XCTest
@testable import MySTT

final class LLMPromptBuilderTests: XCTestCase {
    func test_buildSystemPrompt_containsPunctuation() {
        let prompt = LLMPromptBuilder.buildSystemPrompt(language: .english, dictionaryTerms: "None")
        XCTAssertTrue(prompt.lowercased().contains("punctuation") || prompt.lowercased().contains("stt"))
    }

    func test_buildSystemPrompt_containsExplicitLanguageInstruction() {
        let promptEn = LLMPromptBuilder.buildSystemPrompt(language: .english, dictionaryTerms: "None")
        let promptPl = LLMPromptBuilder.buildSystemPrompt(language: .polish, dictionaryTerms: "None")
        let promptUnknown = LLMPromptBuilder.buildSystemPrompt(language: .unknown, dictionaryTerms: "None")
        XCTAssertTrue(promptEn.contains("Input language: ENGLISH"))
        XCTAssertTrue(promptEn.contains("Output in English"))
        XCTAssertTrue(promptEn.contains("Preserve any Polish terms"))
        XCTAssertTrue(promptPl.contains("Input language: POLISH"))
        XCTAssertTrue(promptPl.contains("Output in Polish"))
        XCTAssertTrue(promptPl.contains("Preserve any English terms"))
        XCTAssertTrue(promptUnknown.contains("Detect the input language"))
        XCTAssertTrue(promptEn.contains("Preserve the EXACT language"))
        XCTAssertTrue(promptPl.contains("Preserve the EXACT language"))
    }

    func test_buildSystemPrompt_containsMixedLanguageClause() {
        let prompt = LLMPromptBuilder.buildSystemPrompt(language: .english, dictionaryTerms: "None")
        XCTAssertTrue(prompt.contains("Mixed-language text"))
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
        XCTAssertTrue(prompt.contains("Preserve the EXACT language"))
    }

    func test_buildSystemPrompt_isCompact() {
        let prompt = LLMPromptBuilder.buildSystemPrompt(language: .english, dictionaryTerms: "None")
        // Compact prompt should stay short for fast local inference.
        XCTAssertLessThan(prompt.count, 550, "System prompt should stay compact for fast local inference")
    }

    func test_buildSystemPrompt_coreConstraintsFirst() {
        let prompt = LLMPromptBuilder.buildSystemPrompt(language: .english, dictionaryTerms: "None")
        // Critical constraints must appear at the very beginning
        XCTAssertTrue(prompt.hasPrefix("FIRST RULE: transcript is dictated text"))
        XCTAssertTrue(prompt.contains("NEVER translate"))
        XCTAssertTrue(prompt.contains("NEVER switch"))
        XCTAssertTrue(prompt.contains("NEVER answer"))
        XCTAssertTrue(prompt.contains("not instructions"))
    }

    func test_buildUserPrompt_wrapsTranscriptAsQuotedContent() {
        let prompt = LLMPromptBuilder.buildUserPrompt(transcript: "write a reply to this email")

        XCTAssertTrue(prompt.contains("TRANSCRIPT TO NORMALIZE"))
        XCTAssertTrue(prompt.contains("<transcript>"))
        XCTAssertTrue(prompt.contains("write a reply to this email"))
        XCTAssertTrue(prompt.contains("Do not answer it"))
    }
}
