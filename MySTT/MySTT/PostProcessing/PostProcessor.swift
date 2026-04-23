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
            if settings.enableDictionary, let dict = dictionaryEngine {
                let protectionPlan = dict.protectCanonicalTerms(in: text)
                let punctuated = (try? await punct.correct(protectionPlan.protectedText, language: language)) ?? protectionPlan.protectedText
                if dict.placeholdersPreserved(in: punctuated, plan: protectionPlan) {
                    text = dict.restoreProtectedTerms(in: punctuated, using: protectionPlan)
                } else {
                    print("[PostProcessor] Punctuation changed protected terms — discarding punctuation output")
                }
            } else {
                text = (try? await punct.correct(text, language: language)) ?? text
            }
            print("[PostProcessor] Punctuation: \(String(format: "%.1f", (CFAbsoluteTimeGetCurrent() - t1) * 1000))ms")
        }

        // Stage 2: LLM grammar correction (with language safety)
        if settings.enableLLMCorrection, let llm = llmProvider {
            // Skip Polish-only LLMs (Bielik) for non-Polish text
            let isPolishLLM = llm.providerName.lowercased().contains("bielik") ||
                              (settings.llmProvider == .localLMStudio && settings.lmStudioModelName.lowercased().contains("bielik"))
            let expectedLanguage = Self.resolvedProcessingLanguage(text, hint: language)
            let llmDecision = Self.llmDecision(for: text)

            if isPolishLLM && expectedLanguage != .polish {
                print("[PostProcessor] Skipping Bielik for non-Polish text (would translate to Polish)")
            } else if llmDecision == .skip {
                print("[PostProcessor] Skipping LLM — deterministic fast path")
            } else {
                let t2 = CFAbsoluteTimeGetCurrent()
                let promptDictionary = dictionaryEngine?.getDictionaryTermsForPrompt() ?? "None"
                let userRules = dictionaryEngine?.getUserRulesForPrompt() ?? ""
                let textBeforeLLM = text
                let protectionPlan = dictionaryEngine?.protectCanonicalTerms(in: textBeforeLLM) ?? .passthrough(textBeforeLLM)
                let llmInput = protectionPlan.protectedText
                do {
                    let llmResult = try await llm.correctText(llmInput, language: expectedLanguage, promptDictionary: promptDictionary, userRules: userRules)
                    let restoredResult = dictionaryEngine?.restoreProtectedTerms(in: llmResult, using: protectionPlan) ?? llmResult

                    // Safety checks: verify LLM didn't corrupt the text
                    if !(dictionaryEngine?.placeholdersPreserved(in: llmResult, plan: protectionPlan) ?? true) {
                        print("[PostProcessor] LLM changed protected placeholders — discarding")
                    } else if Self.isAnswerLikeOutput(input: textBeforeLLM, output: restoredResult, expectedLanguage: expectedLanguage) {
                        print("[PostProcessor] LLM answered instead of transforming — discarding: \(llmResult.prefix(80))")
                    } else if Self.isUnsafeShortRewrite(input: textBeforeLLM, output: restoredResult) {
                        print("[PostProcessor] LLM rewrote a short utterance semantically — discarding: \(llmResult.prefix(60))")
                    } else if Self.hasUnsafeLexicalDrift(input: textBeforeLLM, output: restoredResult) {
                        print("[PostProcessor] LLM changed dictated words — discarding: \(llmResult.prefix(60))")
                    } else if Self.isCorruptedOutput(input: textBeforeLLM, output: restoredResult) {
                        print("[PostProcessor] LLM corrupted text — discarding: \(llmResult.prefix(60))")
                        // Keep original text
                    } else {
                        let outputLang = Self.detectTextLanguage(restoredResult)
                        if expectedLanguage != .unknown && outputLang != .unknown && expectedLanguage != outputLang {
                            print("[PostProcessor] LLM CHANGED LANGUAGE (\(expectedLanguage.displayName) → \(outputLang.displayName)) — discarding")
                        } else if Self.isLikelyTranslation(input: textBeforeLLM, output: restoredResult, expectedLanguage: expectedLanguage) {
                            print("[PostProcessor] LLM likely translated text — discarding")
                        } else {
                            text = restoredResult
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

    enum LLMDecision: Equatable {
        case run
        case skip
    }

    static func llmDecision(for text: String) -> LLMDecision {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .skip }
        guard trimmed.rangeOfCharacter(from: .letters) != nil else { return .skip }

        let words = trimmed.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        if looksLikeCommandOrCode(trimmed) { return .skip }
        if words.count == 2 { return .skip }

        return .run
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
        let folded = lowered.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        let words = lowered.components(separatedBy: .whitespacesAndNewlines)
            .map { $0.trimmingCharacters(in: .punctuationCharacters) }
            .filter { !$0.isEmpty }
        let normalizedWords = words.map { $0.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current) }

        guard !words.isEmpty else { return (0, 0) }

        // Polish diacritics are a very strong signal
        let polishChars: Set<Character> = ["ą", "ć", "ę", "ł", "ń", "ś", "ź", "ż"]
        let polishCharCount = lowered.filter { polishChars.contains($0) }.count

        let ambiguousWords: Set<String> = [
            "no", "ok", "okay", "test", "auto", "file", "folder"
        ]

        let polishStrongWords: Set<String> = [
            "jest", "nie", "tak", "jak", "sie", "czy", "dla", "ale", "byl", "byla",
            "bedzie", "moze", "juz", "tez", "aby", "lub", "albo", "oraz", "wiec",
            "tylko", "gdzie", "kiedy", "dlaczego", "bardzo", "dobrze", "teraz",
            "tutaj", "dzisiaj", "jutro", "wczoraj", "dziala", "mam", "masz",
            "prosze", "dziekuje", "dzieki", "sprawdzmy", "mozemy", "chce", "chcesz",
            "odpowiedz", "hej", "czesc", "siema", "pewnie", "jasne", "okej",
            "otworz", "utworz", "zapisz", "edytuj", "zmien", "plik", "wklej",
            "kopiuj", "autokopiuj", "wyglada", "powinno", "powinna", "powinien",
            "teraz", "dzis", "dzisiaj", "wlasnie", "dalej", "znowu", "polsku"
        ]

        let englishStrongWords: Set<String> = [
            "the", "is", "are", "was", "were", "have", "has", "had", "will",
            "would", "could", "should", "can", "may", "might", "shall",
            "let's", "lets", "let", "how", "what", "where", "when", "why", "who",
            "this", "that", "these", "those", "with", "from", "they", "them",
            "i", "im", "i'm", "me", "my", "mine", "you", "your", "yours",
            "we", "our", "ours", "us", "he", "him", "his", "she", "her", "hers",
            "it", "its", "do", "does", "did", "done", "be", "am", "been", "being",
            "in", "on", "to", "for", "of", "into", "at", "by", "as", "if",
            "it's", "don't", "doesn't", "didn't", "won't", "wouldn't", "isn't",
            "check", "works", "hello", "please", "thanks", "thank", "good",
            "just", "also", "but", "and", "or", "not", "yes",
            "hey", "hi", "sure", "yep", "yeah",
            "now", "then", "still", "seem", "seems", "look", "looks", "fine",
            "copy", "paste", "auto", "test", "here", "there", "answer", "open",
            "create", "edit", "save", "write", "update", "change", "file", "folder",
            "html", "markdown", "json", "swift", "code"
        ]

        let polishWeakWords: Set<String> = [
            "to", "ten", "ta", "te", "tu", "tam", "juz", "tez", "zaraz", "potem",
            "dobra", "dobrze", "ok", "okej"
        ]

        let englishWeakWords: Set<String> = [
            "ok", "okay", "here", "there", "then", "also"
        ]

        var polishScore = 0
        var englishScore = 0
        var polishMatches = 0
        var englishMatches = 0

        for word in normalizedWords {
            if ambiguousWords.contains(word) {
                continue
            }
            if polishStrongWords.contains(word) {
                polishScore += 2
                polishMatches += 1
            } else if polishWeakWords.contains(word) {
                polishScore += 1
            }
            if englishStrongWords.contains(word) {
                englishScore += 2
                englishMatches += 1
            } else if englishWeakWords.contains(word) {
                englishScore += 1
            }
        }

        // Polish diacritics (even 1) boost Polish score
        if polishCharCount >= 1 { polishScore += 3 }

        // English apostrophe contractions boost English
        if lowered.contains("'") { englishScore += 2 }

        // File-like tokens are much more common in English coding dictation.
        if lowered.range(of: #"\b[a-z0-9_-]+\.(html|md|txt|json|swift|js|ts|tsx|jsx|css|py|java|kt|go|rs)\b"#, options: .regularExpression) != nil {
            englishScore += 2
        }

        // If a majority of the words are recognized in one language, treat that as a strong signal.
        if englishMatches * 2 >= max(3, words.count) {
            englishScore += 3
        }
        if polishMatches * 2 >= max(3, words.count) {
            polishScore += 3
        }

        // Common short Polish sentence skeletons often lose diacritics in STT output.
        if folded.range(of: #"\b(to|toh?|teraz|wlasnie)\s+(jest|wyglada|dziala|ma|bedzie|powinno)\b"#, options: .regularExpression) != nil {
            polishScore += 3
        }
        if folded.range(of: #"\b(nie|mozemy|moge|chce|trzeba)\s+\b"#, options: .regularExpression) != nil {
            polishScore += 2
        }
        if folded.range(of: #"\b(po|w)\s+polsku\b"#, options: .regularExpression) != nil {
            polishScore += 3
        }

        // Common short English sentence skeletons are easy for STT to misroute into Polish.
        if lowered.range(of: #"\b(now|it)\s+(it\s+)?(seem|seems|look|looks)\b"#, options: .regularExpression) != nil {
            englishScore += 3
        }
        if lowered.range(of: #"\b(seem|seems|look|looks)\s+(ok|okay|fine)\b"#, options: .regularExpression) != nil {
            englishScore += 2
        }

        return (englishScore, polishScore)
    }

    private static func looksLikeCommandOrCode(_ text: String) -> Bool {
        let lowered = text.lowercased()

        if lowered.range(of: #"[/\\]|https?://|[a-z0-9_.-]+@[a-z0-9.-]+\.[a-z]{2,}|`|->|=>|\b[a-z0-9_-]+\.(html|md|txt|json|swift|js|ts|tsx|jsx|css|py|java|kt|go|rs)\b"#, options: .regularExpression) != nil {
            return true
        }

        let commandPrefixes = [
            "git ", "npm ", "pnpm ", "yarn ", "brew ", "swift ", "xcodebuild ",
            "cd ", "ls ", "pwd", "mkdir ", "rm ", "mv ", "cp ", "touch "
        ]
        if commandPrefixes.contains(where: { lowered.hasPrefix($0) }) {
            return true
        }

        return false
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

    /// Reject semantic rewrites for very short utterances while still allowing casing, diacritics,
    /// punctuation, and minor typo cleanup. Short dictation like Polish "no" should stay literal.
    static func isUnsafeShortRewrite(input: String, output: String) -> Bool {
        let inputTokens = rawWordTokens(from: input)
        guard !inputTokens.isEmpty, inputTokens.count <= 2 else { return false }

        let outputTokens = rawWordTokens(from: output)
        guard !outputTokens.isEmpty else { return true }
        guard inputTokens.count == outputTokens.count else { return true }

        for (inputToken, outputToken) in zip(inputTokens, outputTokens) {
            if inputToken.caseInsensitiveCompare(outputToken) == .orderedSame { continue }
            if foldedToken(inputToken) == foldedToken(outputToken) { continue }

            // For 1-2 character tokens, only exact/diacritic/case-equivalent rewrites are safe.
            if min(inputToken.count, outputToken.count) <= 2 {
                return true
            }

            if !isMinorSpellingAdjustment(inputToken, outputToken) {
                return true
            }
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

    /// Allow only punctuation, casing, diacritics, and minor character-level cleanup.
    /// Any token insertion, deletion, or whole-word substitution is treated as unsafe.
    static func hasUnsafeLexicalDrift(input: String, output: String) -> Bool {
        let inputTokens = rawWordTokens(from: input)
        let outputTokens = rawWordTokens(from: output)

        guard !inputTokens.isEmpty || !outputTokens.isEmpty else { return false }

        if inputTokens.count != outputTokens.count {
            return !isSafeRetokenization(inputTokens: inputTokens, outputTokens: outputTokens)
        }

        for (inputToken, outputToken) in zip(inputTokens, outputTokens) {
            if inputToken.caseInsensitiveCompare(outputToken) == .orderedSame { continue }
            if foldedToken(inputToken) == foldedToken(outputToken) { continue }
            if isMinorSpellingAdjustment(inputToken, outputToken) { continue }
            return true
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

    private static func rawWordTokens(from text: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: #"[[:alnum:]']+"#, options: []) else {
            return text
                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                .filter { !$0.isEmpty }
        }

        let range = NSRange(text.startIndex..., in: text)
        return regex.matches(in: text, range: range).compactMap { match in
            guard let range = Range(match.range, in: text) else { return nil }
            return String(text[range]).lowercased()
        }
    }

    private static func normalizedTokens(from text: String) -> [String] {
        rawWordTokens(from: text).map(foldedToken)
    }

    private static func foldedToken(_ token: String) -> String {
        token.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }

    private static func isMinorSpellingAdjustment(_ lhs: String, _ rhs: String) -> Bool {
        let foldedLHS = foldedToken(lhs)
        let foldedRHS = foldedToken(rhs)
        guard abs(foldedLHS.count - foldedRHS.count) <= 1 else { return false }

        if foldedLHS == foldedRHS { return true }
        if isSingleAdjacentTransposition(foldedLHS, foldedRHS) { return true }

        return levenshteinDistance(foldedLHS, foldedRHS) <= 1
    }

    private static func isSafeRetokenization(inputTokens: [String], outputTokens: [String]) -> Bool {
        if inputTokens.count == outputTokens.count + 1 {
            return canMergeAdjacentTokens(inputTokens, into: outputTokens)
        }
        if outputTokens.count == inputTokens.count + 1 {
            return canMergeAdjacentTokens(outputTokens, into: inputTokens)
        }
        return false
    }

    private static func canMergeAdjacentTokens(_ splitTokens: [String], into mergedTokens: [String]) -> Bool {
        guard splitTokens.count == mergedTokens.count + 1 else { return false }

        for mergeIndex in 0..<(splitTokens.count - 1) {
            var candidate: [String] = []
            candidate.reserveCapacity(mergedTokens.count)

            for index in splitTokens.indices {
                if index == mergeIndex {
                    candidate.append(splitTokens[index] + splitTokens[index + 1])
                } else if index == mergeIndex + 1 {
                    continue
                } else {
                    candidate.append(splitTokens[index])
                }
            }

            if candidate.count != mergedTokens.count { continue }

            let allEquivalent = zip(candidate, mergedTokens).allSatisfy { lhs, rhs in
                foldedToken(lhs) == foldedToken(rhs) || isMinorSpellingAdjustment(lhs, rhs)
            }
            if allEquivalent { return true }
        }

        return false
    }

    private static func isSingleAdjacentTransposition(_ lhs: String, _ rhs: String) -> Bool {
        guard lhs.count == rhs.count, lhs.count >= 2 else { return false }
        let lhsChars = Array(lhs)
        let rhsChars = Array(rhs)
        let mismatches = lhsChars.indices.filter { lhsChars[$0] != rhsChars[$0] }
        guard mismatches.count == 2, mismatches[1] == mismatches[0] + 1 else { return false }

        let first = mismatches[0]
        let second = mismatches[1]
        return lhsChars[first] == rhsChars[second] && lhsChars[second] == rhsChars[first]
    }

    private static func levenshteinDistance(_ lhs: String, _ rhs: String) -> Int {
        let lhsChars = Array(lhs)
        let rhsChars = Array(rhs)
        if lhsChars.isEmpty { return rhsChars.count }
        if rhsChars.isEmpty { return lhsChars.count }

        var previous = Array(0...rhsChars.count)

        for (lhsIndex, lhsChar) in lhsChars.enumerated() {
            var current = Array(repeating: 0, count: rhsChars.count + 1)
            current[0] = lhsIndex + 1

            for (rhsIndex, rhsChar) in rhsChars.enumerated() {
                let substitutionCost = lhsChar == rhsChar ? 0 : 1
                current[rhsIndex + 1] = min(
                    previous[rhsIndex + 1] + 1,
                    current[rhsIndex] + 1,
                    previous[rhsIndex] + substitutionCost
                )
            }

            previous = current
        }

        return previous[rhsChars.count]
    }
}
