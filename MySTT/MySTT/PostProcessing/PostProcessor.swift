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
            let expectedLanguage = Self.resolvedProcessingLanguage(text, hint: language)

            if isPolishLLM && expectedLanguage != .polish {
                print("[PostProcessor] Skipping Bielik for non-Polish text (would translate to Polish)")
            } else {
                let t2 = CFAbsoluteTimeGetCurrent()
                let promptDictionary = dictionaryEngine?.getDictionaryTermsForPrompt() ?? "None"
                let userRules = dictionaryEngine?.getUserRulesForPrompt() ?? ""
                let textBeforeLLM = text
                do {
                    let llmResult = try await llm.correctText(text, language: expectedLanguage, promptDictionary: promptDictionary, userRules: userRules)

                    // Safety checks: verify LLM didn't corrupt the text
                    if Self.isAnswerLikeOutput(input: textBeforeLLM, output: llmResult, expectedLanguage: expectedLanguage) {
                        print("[PostProcessor] LLM answered instead of transforming — discarding: \(llmResult.prefix(80))")
                    } else if Self.isCorruptedOutput(input: textBeforeLLM, output: llmResult) {
                        print("[PostProcessor] LLM corrupted text — discarding: \(llmResult.prefix(60))")
                        // Keep original text
                    } else {
                        let outputLang = Self.detectTextLanguage(llmResult)
                        if expectedLanguage != .unknown && outputLang != .unknown && expectedLanguage != outputLang {
                            print("[PostProcessor] LLM CHANGED LANGUAGE (\(expectedLanguage.displayName) → \(outputLang.displayName)) — discarding")
                        } else if Self.isLikelyTranslation(input: textBeforeLLM, output: llmResult, expectedLanguage: expectedLanguage) {
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

    private static func resolvedProcessingLanguage(_ text: String, hint: Language) -> Language {
        let detected = detectTextLanguage(text)
        return detected == .unknown ? hint : detected
    }

    // MARK: - Language Detection

    /// Detect if text is primarily Polish or English
    static func detectTextLanguage(_ text: String) -> Language {
        let scores = languageScores(text)

        if scores.polish > scores.english && scores.polish >= 2 { return .polish }
        if scores.english > scores.polish && scores.english >= 2 { return .english }

        return .unknown
    }

    static func languageScores(_ text: String) -> (english: Int, polish: Int) {
        let lowered = text.lowercased()
        let words = lowered.components(separatedBy: .whitespacesAndNewlines)
            .map { $0.trimmingCharacters(in: .punctuationCharacters) }
            .filter { !$0.isEmpty }

        guard !words.isEmpty else { return (0, 0) }

        // Polish diacritics are a very strong signal
        let polishChars: Set<Character> = ["ą", "ć", "ę", "ł", "ń", "ś", "ź", "ż"]
        let polishCharCount = lowered.filter { polishChars.contains($0) }.count

        // Common function words
        let polishFunctionWords: Set<String> = [
            "jest", "nie", "tak", "jak", "się", "czy", "dla", "ale", "był", "była",
            "będzie", "może", "już", "też", "aby", "lub", "albo", "oraz", "więc",
            "tylko", "gdzie", "kiedy", "dlaczego", "bardzo", "dobrze", "teraz",
            "tutaj", "dzisiaj", "jutro", "wczoraj", "działa", "mam", "masz",
            "proszę", "dziękuję", "dzięki", "sprawdźmy", "możemy", "chcę", "odpowiedz",
            "hej", "cześć", "siema", "pewnie", "jasne", "okej",
            "otwórz", "utwórz", "zapisz", "edytuj", "zmień", "plik", "folder",
            "wklej", "kopiuj", "autokopiuj", "wygląda", "powinno"
        ]

        let englishFunctionWords: Set<String> = [
            "the", "is", "are", "was", "were", "have", "has", "had", "will",
            "would", "could", "should", "can", "may", "might", "shall",
            "let's", "lets", "let", "how", "what", "where", "when", "why", "who",
            "this", "that", "these", "those", "with", "from", "they", "them",
            "in", "on", "to", "for", "of", "into", "at", "by", "as", "if",
            "it's", "don't", "doesn't", "didn't", "won't", "wouldn't", "isn't",
            "check", "works", "hello", "please", "thanks", "thank", "good",
            "just", "also", "but", "and", "or", "not", "yes", "no",
            "hey", "hi", "sure", "okay", "ok", "yep", "yeah",
            "copy", "paste", "auto", "test", "here", "there", "answer", "open",
            "create", "edit", "save", "write", "update", "change", "file", "folder",
            "html", "markdown", "json", "swift", "code"
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

        // File-like tokens are much more common in English coding dictation.
        if lowered.range(of: #"\b[a-z0-9_-]+\.(html|md|txt|json|swift|js|ts|tsx|jsx|css|py|java|kt|go|rs)\b"#, options: .regularExpression) != nil {
            englishScore += 2
        }

        return (englishScore, polishScore)
    }

    /// Check if LLM output looks like a translation (very different words but similar length)
    static func isLikelyTranslation(input: String, output: String, expectedLanguage: Language = .unknown) -> Bool {
        let inputLang = resolvedProcessingLanguage(input, hint: expectedLanguage)
        let outputLang = detectTextLanguage(output)

        if expectedLanguage != .unknown && outputLang != .unknown && expectedLanguage != outputLang {
            return true
        }

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

    /// Reject assistant-style responses. The LLM must transform the dictated text, not answer it.
    static func isAnswerLikeOutput(input: String, output: String, expectedLanguage: Language = .unknown) -> Bool {
        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        let inputTokens = normalizedTokens(from: input)
        let outputTokens = normalizedTokens(from: trimmed)
        guard !outputTokens.isEmpty else { return false }

        let assistantPreambles = assistantPreambles(for: expectedLanguage == .unknown ? detectTextLanguage(input) : expectedLanguage)
        for phrase in assistantPreambles {
            if starts(with: phrase, in: outputTokens) && !starts(with: phrase, in: inputTokens) {
                return true
            }
        }

        let lowered = trimmed.lowercased()
        let normalizedInput = input.lowercased()
        let labelPatterns = [
            "corrected text:",
            "corrected transcript:",
            "revised text:",
            "revised transcript:",
            "response:",
            "answer:",
            "poprawiony tekst:",
            "poprawiona transkrypcja:",
            "odpowiedz:",
            "odpowiedź:"
        ]
        if labelPatterns.contains(where: { lowered.hasPrefix($0) }) {
            return true
        }

        let outputTokenSet = Set(outputTokens)
        let inputTokenSet = Set(inputTokens)
        let newTokenCount = outputTokenSet.subtracting(inputTokenSet).count
        let samePrefixCount = zip(inputTokens, outputTokens).prefix { $0 == $1 }.count
        let excessiveGrowth = outputTokens.count > inputTokens.count + max(3, inputTokens.count / 3)
        if excessiveGrowth && newTokenCount > max(2, inputTokens.count / 4) && samePrefixCount < min(2, inputTokens.count) {
            return true
        }

        if lowered.contains("let me know") && !normalizedInput.contains("let me know") { return true }
        if lowered.contains("i can help") && !normalizedInput.contains("i can help") { return true }
        if lowered.contains("moge pomoc") && !normalizedInput.contains("moge pomoc") { return true }
        if lowered.contains("mogę pomóc") && !normalizedInput.contains("mogę pomóc") { return true }

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

    private static func assistantPreambles(for language: Language) -> [[String]] {
        let common = [
            ["corrected", "text"],
            ["corrected", "transcript"],
            ["revised", "text"],
            ["revised", "transcript"]
        ]

        switch language {
        case .polish:
            return common + [
                ["jasne"],
                ["pewnie"],
                ["oczywiscie"],
                ["oczywiście"],
                ["oto"],
                ["moge"],
                ["mogę"],
                ["chetnie"],
                ["chętnie"],
                ["poprawiony", "tekst"],
                ["poprawiona", "transkrypcja"]
            ]
        case .english, .unknown:
            return common + [
                ["sure"],
                ["certainly"],
                ["of", "course"],
                ["absolutely"],
                ["here", "is"],
                ["heres"],
                ["here's"],
                ["i", "can"],
                ["i", "will"],
                ["let", "me"]
            ]
        }
    }

    private static func starts(with phrase: [String], in tokens: [String]) -> Bool {
        guard phrase.count <= tokens.count else { return false }
        return Array(tokens.prefix(phrase.count)) == phrase
    }

    private static func normalizedTokens(from text: String) -> [String] {
        let folded = text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        guard let regex = try? NSRegularExpression(pattern: #"[[:alnum:]']+"#, options: []) else {
            return folded
                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                .filter { !$0.isEmpty }
        }

        let range = NSRange(folded.startIndex..., in: folded)
        return regex.matches(in: folded, range: range).compactMap { match in
            guard let range = Range(match.range, in: folded) else { return nil }
            return String(folded[range]).lowercased()
        }
    }
}
