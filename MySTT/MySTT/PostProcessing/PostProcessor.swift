import Foundation

class PostProcessor: PostProcessorProtocol {
    private let dictionaryEngine: DictionaryEngine?
    private let punctuationCorrector: PunctuationCorrector?
    private let llmProvider: LLMProviderProtocol?
    private let settings: AppSettings

    init(dictionaryEngine: DictionaryEngine? = nil, punctuationCorrector: PunctuationCorrector? = nil, llmProvider: LLMProviderProtocol? = nil, settings: AppSettings = .load()) {
        self.dictionaryEngine = dictionaryEngine
        self.punctuationCorrector = punctuationCorrector
        self.llmProvider = llmProvider
        self.settings = settings
    }

    func process(_ rawText: String, language: Language) async throws -> String {
        var text = rawText
        let startTime = CFAbsoluteTimeGetCurrent()

        // Stage 0: Dictionary pre-processing
        if settings.enableDictionary, let dict = dictionaryEngine {
            let t0 = CFAbsoluteTimeGetCurrent()
            text = dict.preProcess(text)
            print("[PostProcessor] Dictionary preProcess: \(String(format: "%.1f", (CFAbsoluteTimeGetCurrent() - t0) * 1000))ms")
        }

        // Stage 1: Punctuation correction
        if settings.enablePunctuationModel, let punct = punctuationCorrector {
            let t1 = CFAbsoluteTimeGetCurrent()
            text = (try? await punct.correct(text, language: language)) ?? text
            print("[PostProcessor] Punctuation: \(String(format: "%.1f", (CFAbsoluteTimeGetCurrent() - t1) * 1000))ms")
        }

        // Stage 2: LLM grammar correction (with language safety)
        if settings.enableLLMCorrection, let llm = llmProvider {
            // Skip Polish-only LLMs (Bielik) for non-Polish text
            let isPolishLLM = llm.providerName.lowercased().contains("bielik") ||
                              (settings.llmProvider == .localLMStudio && settings.lmStudioModelName.lowercased().contains("bielik"))
            let inputLang = Self.detectTextLanguage(text)

            if isPolishLLM && inputLang == .english {
                print("[PostProcessor] Skipping Bielik for English text (would translate to Polish)")
            } else {
                let t2 = CFAbsoluteTimeGetCurrent()
                let dictionaryTerms = dictionaryEngine?.getAllTerms() ?? [:]
                let userRules = dictionaryEngine?.getUserRulesForPrompt() ?? ""
                let textBeforeLLM = text
                do {
                    let llmResult = try await llm.correctText(text, language: language, dictionary: dictionaryTerms, userRules: userRules)

                    // Safety checks: verify LLM didn't corrupt the text
                    if Self.isCorruptedOutput(input: textBeforeLLM, output: llmResult) {
                        print("[PostProcessor] LLM corrupted text — discarding: \(llmResult.prefix(60))")
                        // Keep original text
                    } else {
                        let outputLang = Self.detectTextLanguage(llmResult)
                        if inputLang != .unknown && outputLang != .unknown && inputLang != outputLang {
                            print("[PostProcessor] LLM CHANGED LANGUAGE (\(inputLang.displayName) → \(outputLang.displayName)) — discarding")
                        } else if Self.isLikelyTranslation(input: textBeforeLLM, output: llmResult) {
                            print("[PostProcessor] LLM likely translated text — discarding")
                        } else {
                            text = llmResult
                        }
                    }

                    print("[PostProcessor] LLM: \(String(format: "%.1f", (CFAbsoluteTimeGetCurrent() - t2) * 1000))ms")
                } catch {
                    print("[PostProcessor] LLM failed (graceful degradation): \(error.localizedDescription)")
                    text = textBeforeLLM
                }
            }
        }

        // Stage 3: Dictionary post-processing (regex rules)
        if settings.enableDictionary, let dict = dictionaryEngine {
            let t3 = CFAbsoluteTimeGetCurrent()
            text = dict.postProcess(text)
            print("[PostProcessor] Dictionary postProcess: \(String(format: "%.1f", (CFAbsoluteTimeGetCurrent() - t3) * 1000))ms")
        }

        print("[PostProcessor] Total: \(String(format: "%.1f", (CFAbsoluteTimeGetCurrent() - startTime) * 1000))ms")
        return text
    }

    // MARK: - Language Detection

    /// Detect if text is primarily Polish or English
    static func detectTextLanguage(_ text: String) -> Language {
        let lowered = text.lowercased()
        let words = lowered.components(separatedBy: .whitespacesAndNewlines)
            .map { $0.trimmingCharacters(in: .punctuationCharacters) }
            .filter { !$0.isEmpty }

        guard !words.isEmpty else { return .unknown }

        // Polish diacritics are a very strong signal
        let polishChars: Set<Character> = ["ą", "ć", "ę", "ł", "ń", "ś", "ź", "ż"]
        let polishCharCount = lowered.filter { polishChars.contains($0) }.count
        if polishCharCount >= 2 { return .polish }

        // Common function words
        let polishFunctionWords: Set<String> = [
            "jest", "nie", "tak", "jak", "się", "czy", "dla", "ale", "był", "była",
            "będzie", "może", "już", "też", "aby", "lub", "albo", "oraz", "więc",
            "tylko", "gdzie", "kiedy", "dlaczego", "bardzo", "dobrze", "teraz",
            "tutaj", "dzisiaj", "jutro", "wczoraj", "działa", "mam", "masz",
            "proszę", "dziękuję", "dzięki", "sprawdźmy", "możemy", "chcę",
            "wklej", "kopiuj", "autokopiuj", "wygląda", "powinno"
        ]

        let englishFunctionWords: Set<String> = [
            "the", "is", "are", "was", "were", "have", "has", "had", "will",
            "would", "could", "should", "can", "may", "might", "shall",
            "let's", "lets", "let", "how", "what", "where", "when", "why", "who",
            "this", "that", "these", "those", "with", "from", "they", "them",
            "it's", "don't", "doesn't", "didn't", "won't", "wouldn't", "isn't",
            "check", "works", "hello", "please", "thanks", "thank", "good",
            "just", "also", "but", "and", "or", "not", "yes", "no",
            "copy", "paste", "auto", "test", "here", "there"
        ]

        var polishScore = 0
        var englishScore = 0

        for word in words {
            if polishFunctionWords.contains(word) { polishScore += 2 }
            if englishFunctionWords.contains(word) { englishScore += 2 }
        }

        // Polish diacritics (even 1) boost Polish score
        if polishCharCount >= 1 { polishScore += 3 }

        // English apostrophe contractions boost English
        if lowered.contains("'") { englishScore += 2 }

        if polishScore > englishScore && polishScore >= 2 { return .polish }
        if englishScore > polishScore && englishScore >= 2 { return .english }

        return .unknown
    }

    /// Check if LLM output looks like a translation (very different words but similar length)
    static func isLikelyTranslation(input: String, output: String) -> Bool {
        let inputLang = detectTextLanguage(input)
        let outputLang = detectTextLanguage(output)

        // If we can detect both languages and they differ, it's a translation
        if inputLang != .unknown && outputLang != .unknown && inputLang != outputLang {
            return true
        }

        // Check if the words are mostly different (translation) vs similar (correction)
        let inputWords = Set(input.lowercased().components(separatedBy: .whitespacesAndNewlines)
            .map { $0.trimmingCharacters(in: .punctuationCharacters) }
            .filter { !$0.isEmpty })
        let outputWords = Set(output.lowercased().components(separatedBy: .whitespacesAndNewlines)
            .map { $0.trimmingCharacters(in: .punctuationCharacters) }
            .filter { !$0.isEmpty })

        guard !inputWords.isEmpty, !outputWords.isEmpty else { return false }

        let overlap = inputWords.intersection(outputWords).count
        let overlapRatio = Double(overlap) / Double(max(inputWords.count, outputWords.count))

        // If less than 30% words overlap, likely a translation
        if overlapRatio < 0.3 && inputWords.count >= 3 {
            print("[PostProcessor] Word overlap ratio: \(String(format: "%.1f%%", overlapRatio * 100)) — likely translation")
            return true
        }

        return false
    }

    /// Check if LLM output is corrupted (phonetic symbols, wrong script, gibberish)
    static func isCorruptedOutput(input: String, output: String) -> Bool {
        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return true }

        // Check for IPA/phonetic characters that shouldn't appear in normal text
        let ipaChars: Set<Character> = ["ə", "ɛ", "ɪ", "ʊ", "ɔ", "ʃ", "ʒ", "ʧ", "ʤ", "θ", "ð", "ŋ", "ɑ", "ʰ", "ˈ", "ˌ"]
        let hasIPA = trimmed.contains { ipaChars.contains($0) }
        if hasIPA { return true }

        // Check word overlap — if almost no words match, output is corrupted
        let inputWords = Set(input.lowercased().components(separatedBy: .whitespacesAndNewlines)
            .map { $0.trimmingCharacters(in: .punctuationCharacters) }
            .filter { !$0.isEmpty })
        let outputWords = Set(trimmed.lowercased().components(separatedBy: .whitespacesAndNewlines)
            .map { $0.trimmingCharacters(in: .punctuationCharacters) }
            .filter { !$0.isEmpty })

        if inputWords.count >= 2 && outputWords.count >= 2 {
            let overlap = inputWords.intersection(outputWords).count
            let overlapRatio = Double(overlap) / Double(max(inputWords.count, outputWords.count))
            if overlapRatio < 0.2 {
                print("[PostProcessor] Corruption check: overlap \(String(format: "%.0f%%", overlapRatio * 100))")
                return true
            }
        }

        return false
    }
}
