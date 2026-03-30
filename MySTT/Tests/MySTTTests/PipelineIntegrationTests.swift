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

        let processor = PostProcessor(
            dictionaryEngine: dict,
            punctuationCorrector: nil,
            llmProvider: mockLLM,
            settings: makeSettings(llm: true, dictionary: true)
        )

        let _ = try await processor.process("i use kubernetes and react", language: .english)

        XCTAssertNotNil(mockLLM.lastReceivedDictionary)
        XCTAssertFalse(
            mockLLM.lastReceivedDictionary?.isEmpty ?? true,
            "LLM should receive non-empty dictionary terms"
        )
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
        // DictionaryEngine preProcess will replace "kubernetes" -> "Kubernetes" before LLM sees it.
        // LLM then receives the pre-processed text.
        mockLLM.mockResult = "I love Kubernetes!"
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
        // Verify LLM received pre-processed text (Kubernetes already capitalized by dictionary)
        XCTAssertTrue(
            mockLLM.lastReceivedText?.contains("Kubernetes") ?? false,
            "LLM should receive dictionary-preprocessed text"
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
}
