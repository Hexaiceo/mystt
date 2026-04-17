import XCTest
@testable import MySTT

final class PipelineIntegrationTests: XCTestCase {

    // MARK: - Helpers

    private func makeSettings(
        llm: Bool = false,
        punctuation: Bool = false,
        dictionary: Bool = false
    ) -> AppSettings {
        var s = AppSettings()
        s.enableLLMCorrection = llm
        s.enablePunctuationModel = punctuation
        s.enableDictionary = dictionary
        s.llmProvider = .openai
        return s
    }

    private func makeDictionaryEngine(testName: String = #function) -> DictionaryEngine {
        let path = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("mystt-pipeline-\(UUID().uuidString)-\(testName).json")
        try? FileManager.default.removeItem(at: path)
        return DictionaryEngine(userDictionaryPath: path.path)
    }

    // MARK: - Test 1: Full pipeline English

    func test_fullPipeline_english() async throws {
        let mockLLM = MockLLMProvider()
        mockLLM.mockResult = "Hello world, how are you?"

        let processor = PostProcessor(
            dictionaryEngine: nil,
            punctuationCorrector: nil,
            llmProvider: mockLLM,
            settings: makeSettings(llm: true)
        )

        let result = try await processor.process("hello world how are you", language: .english)

        XCTAssertEqual(result, "Hello world, how are you?")
        XCTAssertEqual(mockLLM.callCount, 1)
        XCTAssertEqual(mockLLM.lastReceivedLanguage, .english)
    }

    // MARK: - Test 2: Full pipeline Polish

    func test_fullPipeline_polish() async throws {
        let mockLLM = MockLLMProvider()
        mockLLM.mockResult = "Witaj świecie, jak się masz?"

        let processor = PostProcessor(
            dictionaryEngine: nil,
            punctuationCorrector: nil,
            llmProvider: mockLLM,
            settings: makeSettings(llm: true)
        )

        let result = try await processor.process("witaj swiecie jak sie masz", language: .polish)

        XCTAssertEqual(result, "Witaj świecie, jak się masz?")
        XCTAssertEqual(mockLLM.callCount, 1)
        XCTAssertEqual(mockLLM.lastReceivedLanguage, .polish)
    }

    // MARK: - Test 3: LLM failure triggers graceful degradation

    func test_pipeline_llmFallback() async throws {
        let mockLLM = MockLLMProvider()
        mockLLM.shouldThrow = MockLLMError.timeout

        let processor = PostProcessor(
            dictionaryEngine: nil,
            punctuationCorrector: nil,
            llmProvider: mockLLM,
            settings: makeSettings(llm: true)
        )

        // PostProcessor catches LLM errors and falls back to previous stage output.
        let result = try await processor.process("hello world", language: .english)

        XCTAssertEqual(result, "hello world", "Original text should be preserved on LLM failure")
        XCTAssertEqual(mockLLM.callCount, 1, "LLM should have been called exactly once")
    }

    // MARK: - Test 4: No post-processing at all

    func test_pipeline_noPostprocessing() async throws {
        let processor = PostProcessor(
            dictionaryEngine: nil,
            punctuationCorrector: nil,
            llmProvider: nil,
            settings: makeSettings()
        )

        let result = try await processor.process("raw text unchanged", language: .english)

        XCTAssertEqual(result, "raw text unchanged")
    }

    // MARK: - Test 5: Dictionary pre-processing replaces known terms

    func test_pipeline_withDictionary() async throws {
        let dict = makeDictionaryEngine()
        dict.addTerm(key: "kubernetes", value: "Kubernetes")

        let processor = PostProcessor(
            dictionaryEngine: dict,
            punctuationCorrector: nil,
            llmProvider: nil,
            settings: makeSettings(dictionary: true)
        )

        let result = try await processor.process("I use kubernetes", language: .english)

        XCTAssertTrue(
            result.contains("Kubernetes"),
            "Expected 'kubernetes' to be replaced with 'Kubernetes', got: \(result)"
        )
    }

    // MARK: - Test 6: LLM receives dictionary terms

    func test_pipeline_llmReceivesDictionaryTerms() async throws {
        let mockLLM = MockLLMProvider()
        mockLLM.mockResult = "I use Kubernetes and React."
        let dict = makeDictionaryEngine()
        dict.addTerm(key: "kubernetes", value: "Kubernetes")
        dict.addCustomWord("Jihed")

        let processor = PostProcessor(
            dictionaryEngine: dict,
            punctuationCorrector: nil,
            llmProvider: mockLLM,
            settings: makeSettings(llm: true, dictionary: true)
        )

        let _ = try await processor.process("i use kubernetes and react", language: .english)

        XCTAssertNotNil(mockLLM.lastReceivedPromptDictionary)
        XCTAssertTrue(mockLLM.lastReceivedPromptDictionary?.contains("kubernetes->Kubernetes") ?? false)
        XCTAssertTrue(mockLLM.lastReceivedPromptDictionary?.contains("Keep exact spelling: Jihed") ?? false)
    }

    // MARK: - Test 7: LLM disabled means no LLM call

    func test_pipeline_llmDisabled_noCall() async throws {
        let mockLLM = MockLLMProvider()
        mockLLM.mockResult = "SHOULD NOT APPEAR"

        let processor = PostProcessor(
            dictionaryEngine: nil,
            punctuationCorrector: nil,
            llmProvider: mockLLM,
            settings: makeSettings(llm: false)
        )

        let result = try await processor.process("original text", language: .english)

        XCTAssertEqual(result, "original text")
        XCTAssertEqual(mockLLM.callCount, 0, "LLM should not be called when disabled")
    }

    // MARK: - Test 8: Multiple LLM error types degrade gracefully

    func test_pipeline_networkError_gracefulDegradation() async throws {
        let mockLLM = MockLLMProvider()
        mockLLM.shouldThrow = MockLLMError.networkUnavailable

        let processor = PostProcessor(
            dictionaryEngine: nil,
            punctuationCorrector: nil,
            llmProvider: mockLLM,
            settings: makeSettings(llm: true)
        )

        let result = try await processor.process("some important text", language: .english)

        XCTAssertEqual(result, "some important text", "Network error should not lose text")
    }

    // MARK: - Test 9: Dictionary + LLM combined pipeline

    func test_pipeline_dictionaryThenLLM() async throws {
        let mockLLM = MockLLMProvider()
        // DictionaryEngine preProcess replaces the term, then the LLM sees a protected placeholder.
        mockLLM.mockResult = "I love MYSTTTERM0TOKEN!"
        let dict = makeDictionaryEngine()
        dict.addTerm(key: "kubernetes", value: "Kubernetes")

        let processor = PostProcessor(
            dictionaryEngine: dict,
            punctuationCorrector: nil,
            llmProvider: mockLLM,
            settings: makeSettings(llm: true, dictionary: true)
        )

        let result = try await processor.process("i love kubernetes", language: .english)

        XCTAssertEqual(result, "I love Kubernetes!")
        // Verify LLM received protected placeholder rather than the raw canonical token.
        XCTAssertTrue(
            mockLLM.lastReceivedText?.contains("MYSTTTERM0TOKEN") ?? false,
            "LLM should receive protected placeholders for canonical dictionary terms"
        )
    }

    // MARK: - Test 10: Empty input passes through pipeline

    func test_pipeline_emptyInput() async throws {
        let mockLLM = MockLLMProvider()

        let processor = PostProcessor(
            dictionaryEngine: nil,
            punctuationCorrector: nil,
            llmProvider: mockLLM,
            settings: makeSettings(llm: true)
        )

        let result = try await processor.process("", language: .english)

        // Empty string capitalized is still empty, so mockResult fallback applies
        XCTAssertNotNil(result)
    }

    // MARK: - Test 11: Polish-only models are skipped for English hints even when heuristic is unknown

    func test_pipeline_skipsPolishModelForEnglishHint() async throws {
        let mockLLM = MockLLMProvider()
        mockLLM.providerName = "Bielik"

        var settings = makeSettings(llm: true)
        settings.llmProvider = .localLMStudio
        settings.lmStudioModelName = "bielik-11b-v3.0-instruct"

        let processor = PostProcessor(
            dictionaryEngine: nil,
            punctuationCorrector: nil,
            llmProvider: mockLLM,
            settings: settings
        )

        let result = try await processor.process("great work", language: .english)

        XCTAssertEqual(result, "great work")
        XCTAssertEqual(mockLLM.callCount, 0)
    }

    // MARK: - Test 12: Reject translated output using expected language hint

    func test_pipeline_discardsTranslatedOutputWhenExpectedLanguageIsKnown() async throws {
        let mockLLM = MockLLMProvider()
        mockLLM.mockResult = "swietna praca"

        let processor = PostProcessor(
            dictionaryEngine: nil,
            punctuationCorrector: nil,
            llmProvider: mockLLM,
            settings: makeSettings(llm: true)
        )

        let result = try await processor.process("great work", language: .english)

        XCTAssertEqual(result, "great work")
        XCTAssertEqual(mockLLM.callCount, 1)
    }

    // MARK: - Test 13: Dictionary replacements are re-applied after LLM output

    func test_pipeline_reappliesDictionaryTermsAfterLLM() async throws {
        let mockLLM = MockLLMProvider()
        mockLLM.mockResult = "Hey MYSTTTERM0TOKEN, sure."
        let dict = makeDictionaryEngine()
        dict.addTerm(key: "Cihat", value: "Jihed")

        let processor = PostProcessor(
            dictionaryEngine: dict,
            punctuationCorrector: nil,
            llmProvider: mockLLM,
            settings: makeSettings(llm: true, dictionary: true)
        )

        let result = try await processor.process("hey cihat sure", language: .english)

        XCTAssertEqual(result, "Hey Jihed, sure.")
    }

    // MARK: - Test 14: Reject assistant-style English answers

    func test_pipeline_discardsAssistantStyleEnglishAnswer() async throws {
        let mockLLM = MockLLMProvider()
        mockLLM.mockResult = "Sure, here is the corrected text: Hello world."

        let processor = PostProcessor(
            dictionaryEngine: nil,
            punctuationCorrector: nil,
            llmProvider: mockLLM,
            settings: makeSettings(llm: true)
        )

        let result = try await processor.process("hello world", language: .english)

        XCTAssertEqual(result, "hello world")
        XCTAssertEqual(mockLLM.callCount, 1)
    }

    // MARK: - Test 15: Reject assistant-style Polish answers

    func test_pipeline_discardsAssistantStylePolishAnswer() async throws {
        let mockLLM = MockLLMProvider()
        mockLLM.mockResult = "Jasne, oto poprawiony tekst: Witaj świecie."

        let processor = PostProcessor(
            dictionaryEngine: nil,
            punctuationCorrector: nil,
            llmProvider: mockLLM,
            settings: makeSettings(llm: true)
        )

        let result = try await processor.process("witaj swiecie", language: .polish)

        XCTAssertEqual(result, "witaj swiecie")
        XCTAssertEqual(mockLLM.callCount, 1)
    }

    // MARK: - Test 16: Preserve short Polish interjection "no"

    func test_pipeline_preservesShortPolishNoInsteadOfAllowingTranslation() async throws {
        let mockLLM = MockLLMProvider()
        mockLLM.mockResult = "nie"

        let processor = PostProcessor(
            dictionaryEngine: nil,
            punctuationCorrector: nil,
            llmProvider: mockLLM,
            settings: makeSettings(llm: true)
        )

        let result = try await processor.process("no", language: .polish)

        XCTAssertEqual(result, "no")
        XCTAssertEqual(mockLLM.callCount, 1)
        XCTAssertEqual(mockLLM.lastReceivedLanguage, .polish)
    }

    // MARK: - Test 17: Allow short typo cleanup when meaning is unchanged

    func test_pipeline_allowsShortOrthographicCleanup() async throws {
        let mockLLM = MockLLMProvider()
        mockLLM.mockResult = "hello"

        let processor = PostProcessor(
            dictionaryEngine: nil,
            punctuationCorrector: nil,
            llmProvider: mockLLM,
            settings: makeSettings(llm: true)
        )

        let result = try await processor.process("helo", language: .english)

        XCTAssertEqual(result, "hello")
        XCTAssertEqual(mockLLM.callCount, 1)
    }

    // MARK: - Test 18: Reject lexical drift in longer utterances

    func test_pipeline_discardsLongerLexicalRewrite() async throws {
        let mockLLM = MockLLMProvider()
        mockLLM.mockResult = "Please inspect the file"

        let processor = PostProcessor(
            dictionaryEngine: nil,
            punctuationCorrector: nil,
            llmProvider: mockLLM,
            settings: makeSettings(llm: true)
        )

        let result = try await processor.process("please open the file", language: .english)

        XCTAssertEqual(result, "please open the file")
        XCTAssertEqual(mockLLM.callCount, 1)
    }

    // MARK: - Test 19: Protected custom words survive LLM processing

    func test_pipeline_protectsCustomWordsDuringLLMCorrection() async throws {
        let mockLLM = MockLLMProvider()
        mockLLM.mockResult = "MYSTTTERM0TOKEN works here."
        let dict = makeDictionaryEngine()
        dict.addCustomWord("Jihed")

        let processor = PostProcessor(
            dictionaryEngine: dict,
            punctuationCorrector: nil,
            llmProvider: mockLLM,
            settings: makeSettings(llm: true, dictionary: true)
        )

        let result = try await processor.process("jihed works here", language: .english)

        XCTAssertEqual(result, "Jihed works here.")
        XCTAssertTrue(mockLLM.lastReceivedText?.contains("MYSTTTERM0TOKEN") ?? false)
    }

    // MARK: - Test 20: Missing placeholder invalidates LLM output

    func test_pipeline_discardsLLMOutputWhenProtectedPlaceholderIsDropped() async throws {
        let mockLLM = MockLLMProvider()
        mockLLM.mockResult = "Jihad works here."
        let dict = makeDictionaryEngine()
        dict.addCustomWord("Jihed")

        let processor = PostProcessor(
            dictionaryEngine: dict,
            punctuationCorrector: nil,
            llmProvider: mockLLM,
            settings: makeSettings(llm: true, dictionary: true)
        )

        let result = try await processor.process("jihed works here", language: .english)

        XCTAssertEqual(result, "jihed works here")
        XCTAssertEqual(mockLLM.callCount, 1)
    }
}
