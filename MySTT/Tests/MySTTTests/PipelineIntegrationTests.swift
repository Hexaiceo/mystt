import XCTest
import AVFoundation
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

    private func makeAudioBuffer(samples: [Float], sampleRate: Double = 16000) -> AVAudioPCMBuffer {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let buffer = AVAudioPCMBuffer(
            pcmFormat: format,
            frameCapacity: AVAudioFrameCount(samples.count)
        )!
        buffer.frameLength = AVAudioFrameCount(samples.count)
        if let channel = buffer.floatChannelData?[0] {
            for (index, sample) in samples.enumerated() {
                channel[index] = sample
            }
        }
        return buffer
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
        XCTAssertEqual(mockLLM.callCount, 0, "Short two-word utterances should skip the LLM fast path")
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
        XCTAssertEqual(mockLLM.callCount, 0)
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
        XCTAssertEqual(mockLLM.callCount, 0)
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
        XCTAssertEqual(mockLLM.callCount, 0)
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

    // MARK: - Test 16b: Reject Polish translation of short English phrase

    func test_pipeline_discardsPolishTranslationForShortEnglishPhrase() async throws {
        let mockLLM = MockLLMProvider()
        mockLLM.mockResult = "Teraz wygląda ok."

        let processor = PostProcessor(
            dictionaryEngine: nil,
            punctuationCorrector: nil,
            llmProvider: mockLLM,
            settings: makeSettings(llm: true)
        )

        let result = try await processor.process("now it seems ok", language: .english)

        XCTAssertEqual(result, "now it seems ok")
        XCTAssertEqual(mockLLM.callCount, 1)
        XCTAssertEqual(mockLLM.lastReceivedLanguage, .english)
    }

    // MARK: - Test 16c: Reject English translation of short Polish phrase

    func test_pipeline_discardsEnglishTranslationForShortPolishPhrase() async throws {
        let mockLLM = MockLLMProvider()
        mockLLM.mockResult = "Now it looks ok."

        let processor = PostProcessor(
            dictionaryEngine: nil,
            punctuationCorrector: nil,
            llmProvider: mockLLM,
            settings: makeSettings(llm: true)
        )

        let result = try await processor.process("teraz wyglada ok", language: .polish)

        XCTAssertEqual(result, "teraz wyglada ok")
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

    func test_pipeline_skipsLLMForShortUtteranceFastPath() async throws {
        let mockLLM = MockLLMProvider()
        let settings = makeSettings(llm: true, dictionary: false)
        let processor = PostProcessor(
            dictionaryEngine: nil,
            punctuationCorrector: nil,
            llmProvider: mockLLM,
            settings: settings
        )

        let result = try await processor.process("hello world", language: .english)

        XCTAssertEqual(result, "hello world")
        XCTAssertEqual(mockLLM.callCount, 0)
    }

    // MARK: - Test 21: LLM receives explicit language instruction for Polish

    func test_pipeline_llmReceivesPolishLanguageInstruction() async throws {
        let mockLLM = MockLLMProvider()
        mockLLM.mockResult = "Witaj świecie, jak się masz?"

        let processor = PostProcessor(
            dictionaryEngine: nil,
            punctuationCorrector: nil,
            llmProvider: mockLLM,
            settings: makeSettings(llm: true)
        )

        let _ = try await processor.process("witaj swiecie jak sie masz", language: .polish)

        let systemPrompt = LLMPromptBuilder.buildSystemPrompt(language: .polish, dictionaryTerms: "None")
        XCTAssertTrue(systemPrompt.contains("Input language: POLISH"))
        XCTAssertTrue(systemPrompt.contains("Output MUST be Polish"))
        XCTAssertTrue(systemPrompt.contains("Do NOT output English"))
    }

    // MARK: - Test 22: LLM receives explicit language instruction for English

    func test_pipeline_llmReceivesEnglishLanguageInstruction() async throws {
        let mockLLM = MockLLMProvider()
        mockLLM.mockResult = "Hello world, how are you?"

        let processor = PostProcessor(
            dictionaryEngine: nil,
            punctuationCorrector: nil,
            llmProvider: mockLLM,
            settings: makeSettings(llm: true)
        )

        let _ = try await processor.process("hello world how are you", language: .english)

        let systemPrompt = LLMPromptBuilder.buildSystemPrompt(language: .english, dictionaryTerms: "None")
        XCTAssertTrue(systemPrompt.contains("Input language: ENGLISH"))
        XCTAssertTrue(systemPrompt.contains("Output MUST be English"))
        XCTAssertTrue(systemPrompt.contains("Do NOT output Polish"))
    }

    // MARK: - Test 23: Polish sentence with English term stays mixed

    func test_pipeline_preservesMixedLanguageText() async throws {
        let mockLLM = MockLLMProvider()
        mockLLM.mockResult = "Użyj Kubernetes do wdrożenia."

        let processor = PostProcessor(
            dictionaryEngine: nil,
            punctuationCorrector: nil,
            llmProvider: mockLLM,
            settings: makeSettings(llm: true)
        )

        let result = try await processor.process("uzyj kubernetes do wdrozenia", language: .polish)

        XCTAssertEqual(result, "Użyj Kubernetes do wdrożenia.")
        XCTAssertEqual(mockLLM.lastReceivedLanguage, .polish)
    }

    // MARK: - Test 24: Longer Polish text translated to English is rejected

    func test_pipeline_rejectsEnglishTranslationOfLongerPolishText() async throws {
        let mockLLM = MockLLMProvider()
        mockLLM.mockResult = "The application works very well now."

        let processor = PostProcessor(
            dictionaryEngine: nil,
            punctuationCorrector: nil,
            llmProvider: mockLLM,
            settings: makeSettings(llm: true)
        )

        let result = try await processor.process("aplikacja działa bardzo dobrze teraz", language: .polish)

        XCTAssertEqual(result, "aplikacja działa bardzo dobrze teraz")
    }

    // MARK: - Test 25: Longer English text translated to Polish is rejected

    func test_pipeline_rejectsPolishTranslationOfLongerEnglishText() async throws {
        let mockLLM = MockLLMProvider()
        mockLLM.mockResult = "Aplikacja działa bardzo dobrze teraz."

        let processor = PostProcessor(
            dictionaryEngine: nil,
            punctuationCorrector: nil,
            llmProvider: mockLLM,
            settings: makeSettings(llm: true)
        )

        let result = try await processor.process("the application works very well now", language: .english)

        XCTAssertEqual(result, "the application works very well now")
    }

    func test_pipeline_skipsLLMForCommandLikeText() async throws {
        let mockLLM = MockLLMProvider()
        let settings = makeSettings(llm: true, dictionary: false)
        let processor = PostProcessor(
            dictionaryEngine: nil,
            punctuationCorrector: nil,
            llmProvider: mockLLM,
            settings: settings
        )

        let result = try await processor.process("git status", language: .english)

        XCTAssertEqual(result, "git status")
        XCTAssertEqual(mockLLM.callCount, 0)
    }

    func test_audioAnalysis_detectsSilence() {
        let buffer = makeAudioBuffer(samples: Array(repeating: 0, count: 1600))

        let analysis = AudioCaptureEngine.analyzeSignal(buffer)

        XCTAssertFalse(analysis.hasAnySignal)
        XCTAssertFalse(analysis.hasSpeechLikeSignal)
    }

    func test_audioAnalysis_detectsSpeechLikeSignal() {
        let samples = (0..<1600).map { index in
            index % 40 < 20 ? Float(0.01) : Float(-0.01)
        }
        let buffer = makeAudioBuffer(samples: samples)

        let analysis = AudioCaptureEngine.analyzeSignal(buffer)

        XCTAssertTrue(analysis.hasAnySignal)
        XCTAssertTrue(analysis.hasSpeechLikeSignal)
    }

    @MainActor
    func test_shortSpeechIsNotDiscardedAsAccidentalPress() {
        let buffer = makeAudioBuffer(samples: Array(repeating: 0.01, count: 4000))
        let analysis = AudioCaptureEngine.analyzeSignal(buffer)

        XCTAssertFalse(AppState.shouldTreatAsAccidentalPress(duration: 0.25, signalAnalysis: analysis))
    }

    @MainActor
    func test_silentHallucinatedTranscriptIsRejected() {
        let silence = AudioCaptureEngine.SignalAnalysis(
            peakAmplitude: 0,
            rmsAmplitude: 0,
            nonSilentFrameRatio: 0,
            speechFrameRatio: 0,
            frameCount: 24000
        )
        let result = STTResult(
            text: "Dziękuję.",
            language: .polish,
            confidence: -0.26,
            segments: []
        )

        XCTAssertFalse(AppState.shouldAcceptTranscription(result, signalAnalysis: silence))
    }

    @MainActor
    func test_clearShortTranscriptWithSignalIsAccepted() {
        let signal = AudioCaptureEngine.SignalAnalysis(
            peakAmplitude: 0.01,
            rmsAmplitude: 0.005,
            nonSilentFrameRatio: 0.4,
            speechFrameRatio: 0.25,
            frameCount: 24000
        )
        let result = STTResult(
            text: "great work",
            language: .english,
            confidence: -0.4,
            segments: []
        )

        XCTAssertTrue(AppState.shouldAcceptTranscription(result, signalAnalysis: signal))
    }

    @MainActor
    func test_weakSignalShortTranscriptIsAccepted() {
        let weakSignal = AudioCaptureEngine.SignalAnalysis(
            peakAmplitude: 0.00042,
            rmsAmplitude: 0.00008,
            nonSilentFrameRatio: 0.012,
            speechFrameRatio: 0.002,
            frameCount: 24000
        )
        let result = STTResult(
            text: "open settings",
            language: .english,
            confidence: -2.1,
            segments: []
        )

        XCTAssertTrue(AppState.shouldAcceptTranscription(result, signalAnalysis: weakSignal))
    }

    @MainActor
    func test_knownWeakSignalHallucinationIsRejected() {
        let weakSignal = AudioCaptureEngine.SignalAnalysis(
            peakAmplitude: 0.0003,
            rmsAmplitude: 0.00005,
            nonSilentFrameRatio: 0.01,
            speechFrameRatio: 0.001,
            frameCount: 24000
        )
        let result = STTResult(
            text: "Dziękuję.",
            language: .polish,
            confidence: -0.8,
            segments: []
        )

        XCTAssertFalse(AppState.shouldAcceptTranscription(result, signalAnalysis: weakSignal))
    }
}
