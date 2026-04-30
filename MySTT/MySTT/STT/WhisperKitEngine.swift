import AVFoundation
import WhisperKit

class WhisperKitEngine: STTEngineProtocol {
    private var whisperKit: WhisperKit?
    private var modelName: String
    private(set) var isReady: Bool = false
    let supportsPromptConditioning = false

    var onProgress: ((Double, String) -> Void)?

    init(modelName: String? = nil) {
        self.modelName = modelName ?? Self.selectModel()
    }

    static func selectModel() -> String {
        let totalRAMInGB = ProcessInfo.processInfo.physicalMemory / (1024 * 1024 * 1024)
        return totalRAMInGB < 12 ? "openai_whisper-small_216MB" : "openai_whisper-large-v3-v20240930_turbo_632MB"
    }

    // MARK: - Model Cache

    private static var modelSearchPaths: [String] {
        let home = NSHomeDirectory()
        return [
            "\(home)/Documents/huggingface/models/argmaxinc/whisperkit-coreml",
            "\(home)/.cache/huggingface/hub/models--argmaxinc--whisperkit-coreml/snapshots",
            "\(home)/Library/Application Support/MySTT/models",
        ]
    }

    func hasLocalModel() -> Bool { findLocalModelFolder() != nil }

    private func findLocalModelFolder() -> String? {
        let requiredFiles = ["AudioEncoder.mlmodelc", "TextDecoder.mlmodelc", "MelSpectrogram.mlmodelc"]

        for searchDir in Self.modelSearchPaths {
            let directPath = "\(searchDir)/\(modelName)"
            if checkModelFiles(at: directPath, required: requiredFiles) {
                print("[WhisperKit] Found local model at: \(directPath)")
                return directPath
            }
            if let contents = try? FileManager.default.contentsOfDirectory(atPath: searchDir) {
                for subdir in contents {
                    let nestedPath = "\(searchDir)/\(subdir)/\(modelName)"
                    if checkModelFiles(at: nestedPath, required: requiredFiles) {
                        print("[WhisperKit] Found local model at: \(nestedPath)")
                        return nestedPath
                    }
                }
            }
        }

        let hfBase = "\(NSHomeDirectory())/Documents/huggingface"
        if let found = findDirectoryRecursively(named: modelName, in: hfBase, maxDepth: 5) {
            if checkModelFiles(at: found, required: requiredFiles) {
                print("[WhisperKit] Found local model (deep search) at: \(found)")
                return found
            }
        }

        print("[WhisperKit] No local model found for '\(modelName)'")
        return nil
    }

    private func checkModelFiles(at path: String, required: [String]) -> Bool {
        required.allSatisfy { FileManager.default.fileExists(atPath: "\(path)/\($0)") }
    }

    private func findDirectoryRecursively(named target: String, in basePath: String, maxDepth: Int) -> String? {
        guard maxDepth > 0, FileManager.default.fileExists(atPath: basePath) else { return nil }
        guard let contents = try? FileManager.default.contentsOfDirectory(atPath: basePath) else { return nil }
        for item in contents {
            let fullPath = "\(basePath)/\(item)"
            var isDir: ObjCBool = false
            FileManager.default.fileExists(atPath: fullPath, isDirectory: &isDir)
            if isDir.boolValue {
                if item == target { return fullPath }
                if let found = findDirectoryRecursively(named: target, in: fullPath, maxDepth: maxDepth - 1) {
                    return found
                }
            }
        }
        return nil
    }

    private static var downloadBase: URL {
        URL(fileURLWithPath: "\(NSHomeDirectory())/Documents/huggingface")
    }

    // MARK: - Prepare

    func prepare() async throws {
        guard whisperKit == nil else { return }
        let modelToLoad: String? = modelName.isEmpty ? nil : modelName
        let start = CFAbsoluteTimeGetCurrent()

        let localFolder = findLocalModelFolder()
        if localFolder != nil {
            print("[WhisperKit] Loading from local cache: \(modelName)")
        } else {
            print("[WhisperKit] Model not found locally. Downloading: \(modelToLoad ?? "auto")...")
        }

        do {
            let config: WhisperKitConfig
            if let localFolder = localFolder {
                config = WhisperKitConfig(
                    modelFolder: localFolder,
                    verbose: true,
                    logLevel: .info,
                    prewarm: true,
                    load: true,
                    download: false
                )
            } else {
                config = WhisperKitConfig(
                    model: modelToLoad,
                    downloadBase: Self.downloadBase,
                    verbose: true,
                    logLevel: .info,
                    prewarm: true,
                    download: true
                )
            }

            let kit = try await WhisperKit(config)
            self.whisperKit = kit
            isReady = true

            let elapsed = CFAbsoluteTimeGetCurrent() - start
            print("[WhisperKit] Ready in \(String(format: "%.1f", elapsed))s")
            onProgress?(1.0, "Model ready")
        } catch {
            isReady = false
            print("[WhisperKit] ERROR: \(error)")
            onProgress?(-1, "Error: \(error.localizedDescription)")
            throw STTError.modelNotFound(name: "\(modelToLoad ?? "auto") - \(error.localizedDescription)")
        }
    }

    func reset() async {
        whisperKit = nil
        isReady = false
    }

    // MARK: - Transcribe

    func transcribe(audioBuffer: AVAudioPCMBuffer, context: TranscriptionContext = .empty) async throws -> STTResult {
        if !isReady { try await prepare() }
        guard let whisperKit else { throw STTError.notInitialized }

        let floats = audioBuffer.toFloatArray()
        guard !floats.isEmpty else { throw STTError.emptyAudio }

        let audioDuration = Double(floats.count) / 16000.0
        let start = CFAbsoluteTimeGetCurrent()

        print("[WhisperKit] Transcribing \(String(format: "%.1f", audioDuration))s audio...")

        do {
            let detectedSpokenLanguage = await detectSpokenLanguage(from: floats, whisperKit: whisperKit)
            // Strategy: decode both Polish and English, then choose the better candidate.
            // This is slower than a single pass, but much more robust for short dictation where
            // a forced Polish decode can transliterate English speech into Polish words.
            if let prompt = context.prompt?.trimmingCharacters(in: .whitespacesAndNewlines),
               !prompt.isEmpty {
                print("[WhisperKit] Ignoring STT prompt conditioning because WhisperKit prompt tokens can suppress output")
            }

            let polishResult = try await transcribeWith(floats: floats, language: "pl")
            let polishText = polishResult.text.trimmingCharacters(in: .whitespacesAndNewlines)
            let englishResult = try await transcribeWith(floats: floats, language: "en")
            let englishText = englishResult.text.trimmingCharacters(in: .whitespacesAndNewlines)
            let polishQuality = Self.segmentQuality(polishResult)
            let englishQuality = Self.segmentQuality(englishResult)
            let preferredLanguage = Self.preferredForcedLanguage(
                polishText: polishText,
                englishText: englishText,
                polishAverageLogProb: Self.averageLogProb(polishResult),
                englishAverageLogProb: Self.averageLogProb(englishResult),
                polishAverageNoSpeechProb: polishQuality.averageNoSpeechProb,
                englishAverageNoSpeechProb: englishQuality.averageNoSpeechProb,
                polishAverageCompressionRatio: polishQuality.averageCompressionRatio,
                englishAverageCompressionRatio: englishQuality.averageCompressionRatio,
                detectedSpokenLanguage: detectedSpokenLanguage
            )

            if preferredLanguage == .english && Self.isValidPolishOrEnglish(englishText) {
                print("[WhisperKit] Choosing English candidate over Polish candidate")
                return buildResult(from: englishResult, elapsed: CFAbsoluteTimeGetCurrent() - start)
            }

            if Self.isValidPolishOrEnglish(polishText) {
                return buildResult(from: polishResult, elapsed: CFAbsoluteTimeGetCurrent() - start)
            }

            if Self.isValidPolishOrEnglish(englishText) {
                print("[WhisperKit] Polish candidate invalid, using English candidate")
                return buildResult(from: englishResult, elapsed: CFAbsoluteTimeGetCurrent() - start)
            }

            print("[WhisperKit] Neither language produced clean text, using Polish result")
            return buildResult(from: polishResult, elapsed: CFAbsoluteTimeGetCurrent() - start)

        } catch {
            throw STTError.transcriptionFailed(underlying: error)
        }
    }

    // MARK: - Preview (single-pass for live display)

    func previewTranscribe(audioBuffer: AVAudioPCMBuffer) async throws -> String {
        guard isReady, let whisperKit else { return "" }

        let floats = audioBuffer.toFloatArray()
        guard floats.count >= 16000 else { return "" }

        let detectedLang = await detectSpokenLanguage(from: floats, whisperKit: whisperKit)
        let langCode = detectedLang == .polish ? "pl" : "en"

        let options = DecodingOptions(
            verbose: false,
            task: .transcribe,
            language: langCode,
            temperature: 0.0,
            usePrefillPrompt: true,
            usePrefillCache: false,
            detectLanguage: false,
            skipSpecialTokens: true,
            withoutTimestamps: true,
            compressionRatioThreshold: 2.4,
            logProbThreshold: -1.0,
            noSpeechThreshold: 0.6
        )

        let results = try await whisperKit.transcribe(audioArray: floats, decodeOptions: options)
        return results.first?.text.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    // MARK: - Helpers

    private func transcribeWith(floats: [Float], language: String) async throws -> TranscriptionResult {
        guard let whisperKit = whisperKit else { throw STTError.notInitialized }

        let options = DecodingOptions(
            verbose: false,
            task: .transcribe,
            language: language,
            temperature: 0.0,
            usePrefillPrompt: true,
            usePrefillCache: false,
            detectLanguage: false,
            skipSpecialTokens: true,
            withoutTimestamps: false,
            compressionRatioThreshold: 2.4,
            logProbThreshold: -1.0,
            noSpeechThreshold: 0.6
        )

        let results = try await whisperKit.transcribe(audioArray: floats, decodeOptions: options)
        guard let result = results.first else {
            throw STTError.transcriptionFailed(underlying: NSError(domain: "WhisperKit", code: 0,
                userInfo: [NSLocalizedDescriptionKey: "Empty transcription result"]))
        }
        return result
    }

    private func detectSpokenLanguage(from floats: [Float], whisperKit: WhisperKit) async -> Language? {
        do {
            let detection = try await whisperKit.detectLangauge(audioArray: floats)
            let sortedProbabilities = detection.langProbs.sorted { $0.value > $1.value }
            let topProbability = sortedProbabilities.first?.value ?? 0
            let runnerUpProbability = sortedProbabilities.dropFirst().first?.value ?? 0
            let detectedLanguage = Language(whisperCode: detection.language)

            guard detectedLanguage != .unknown else { return nil }
            guard topProbability >= 0.35 else { return nil }
            guard topProbability - runnerUpProbability >= 0.12 else { return nil }

            print(
                "[WhisperKit] Audio language prior: \(detectedLanguage.displayName) " +
                "(p=\(String(format: "%.2f", topProbability)), margin=\(String(format: "%.2f", topProbability - runnerUpProbability)))"
            )
            return detectedLanguage
        } catch {
            print("[WhisperKit] Audio language detection unavailable: \(error.localizedDescription)")
            return nil
        }
    }

    private func buildResult(from result: TranscriptionResult, elapsed: Double) -> STTResult {
        let language = Language(whisperCode: result.language)
        let segments: [MySTTSegment] = result.segments.map { seg in
            MySTTSegment(text: seg.text, start: TimeInterval(seg.start), end: TimeInterval(seg.end), confidence: seg.avgLogprob)
        }
        let avgConf = segments.isEmpty ? 0 : segments.reduce(0) { $0 + $1.confidence } / Float(segments.count)
        print("[WhisperKit] Done in \(String(format: "%.1f", elapsed))s → [\(language.displayName)] \(result.text.prefix(80))")
        return STTResult(text: result.text, language: language, confidence: avgConf, segments: segments)
    }

    /// Check that text contains only characters valid in Polish or English
    /// (Latin alphabet, Polish diacriticals, common punctuation)
    static func isValidPolishOrEnglish(_ text: String) -> Bool {
        guard !text.isEmpty else { return false }

        // Allowed: Latin letters, Polish diacriticals, digits, common punctuation, whitespace
        // Forbidden characters that indicate wrong language
        let forbiddenChars: Set<Character> = [
            // Icelandic
            "þ", "ð", "Þ", "Ð",
            // IPA / phonetic
            "ə", "ɛ", "ɪ", "ʊ", "ɔ", "ʃ", "ʒ", "ʧ", "ʤ", "θ", "ŋ", "ɑ", "ʰ", "ˈ", "ˌ",
            // Arabic
            "ع", "غ", "ف", "ق", "ك", "ل", "م", "ن",
            // CJK (sample)
            "的", "是", "了", "我", "你",
            // Devanagari (sample)
            "क", "ख", "ग", "घ",
        ]

        for char in text {
            if forbiddenChars.contains(char) {
                print("[WhisperKit] Forbidden character found: '\(char)' in: \(text.prefix(40))")
                return false
            }
        }

        // Check for Cyrillic block (U+0400–U+04FF)
        for scalar in text.unicodeScalars {
            if scalar.value >= 0x0400 && scalar.value <= 0x04FF {
                print("[WhisperKit] Cyrillic character found in: \(text.prefix(40))")
                return false
            }
        }

        return true
    }

    /// Quick heuristic: does the text look like English rather than Polish?
    static func looksLikeEnglish(_ text: String) -> Bool {
        PostProcessor.detectTextLanguage(text) == .english
    }

    static func preferredForcedLanguage(
        polishText: String,
        englishText: String,
        polishAverageLogProb: Double = 0,
        englishAverageLogProb: Double = 0,
        polishAverageNoSpeechProb: Double = 0,
        englishAverageNoSpeechProb: Double = 0,
        polishAverageCompressionRatio: Double = 1,
        englishAverageCompressionRatio: Double = 1,
        detectedSpokenLanguage: Language? = nil
    ) -> Language {
        let polishLang = PostProcessor.detectTextLanguage(polishText)
        let englishLang = PostProcessor.detectTextLanguage(englishText)
        let crossCheck = crossCandidateAnalysis(polishText: polishText, englishText: englishText)

        // When both candidates produced text in their respective forced languages but
        // with very different words, one is a genuine transcription and the other is
        // Whisper translating the speech into the forced language.
        if crossCheck.isTranslationPair {
            if polishLang == .polish && englishLang == .english {
                if detectedSpokenLanguage == .english {
                    print("[WhisperKit] Cross-candidate: translation pair, audio prior = English → choosing English")
                    return .english
                }
                if detectedSpokenLanguage == .polish {
                    print("[WhisperKit] Cross-candidate: translation pair, audio prior = Polish → choosing Polish")
                    return .polish
                }
                // No audio prior. Use Polish diacritics as a decisive signal:
                // Whisper only generates ą/ć/ę/ł/ń/ś/ź/ż when the audio contains
                // genuine Polish phonemes. English speech forced through Polish decode
                // produces ASCII-only transliterations like "Hej" not "Hęj".
                let polishDiacritics: Set<Character> = ["ą", "ć", "ę", "ł", "ń", "ś", "ź", "ż"]
                let hasDiacritics = polishText.lowercased().contains(where: { polishDiacritics.contains($0) })
                if hasDiacritics {
                    print("[WhisperKit] Cross-candidate: translation pair, Polish diacritics present → choosing Polish")
                    return .polish
                }
                // No diacritics in Polish candidate. Use logprob gap: a very poor Polish
                // logprob with confident English suggests English audio transliterated to Polish.
                let logProbGap = englishAverageLogProb - polishAverageLogProb
                if polishAverageLogProb < -0.9 && logProbGap > 0.5 {
                    print("[WhisperKit] Cross-candidate: translation pair, Polish logprob very poor (\(String(format: "%.2f", polishAverageLogProb))) → likely English speech")
                    return .english
                }
                print("[WhisperKit] Cross-candidate: translation pair, no clear signal → falling through to scoring")
            }
            if polishLang == .english && englishLang == .english {
                print("[WhisperKit] Cross-candidate: both candidates are English → choosing English")
                return .english
            }
            if polishLang == .unknown && englishLang == .english {
                print("[WhisperKit] Cross-candidate: Polish candidate ambiguous, English clear → choosing English")
                return .english
            }
        }

        // If both candidates produced essentially the same text, trust the text language
        if crossCheck.isSameContent {
            if polishLang == .polish { return .polish }
            if englishLang == .english { return .english }
        }

        let polishScore = candidateScore(
            text: polishText,
            targetLanguage: .polish,
            otherText: englishText,
            averageLogProb: polishAverageLogProb,
            averageNoSpeechProb: polishAverageNoSpeechProb,
            averageCompressionRatio: polishAverageCompressionRatio
        )
        let englishScore = candidateScore(
            text: englishText,
            targetLanguage: .english,
            otherText: polishText,
            averageLogProb: englishAverageLogProb,
            averageNoSpeechProb: englishAverageNoSpeechProb,
            averageCompressionRatio: englishAverageCompressionRatio
        )

        print("[WhisperKit] Scores: polish=\(String(format: "%.2f", polishScore)) english=\(String(format: "%.2f", englishScore)) spoken=\(detectedSpokenLanguage?.displayName ?? "nil")")

        if let detectedSpokenLanguage {
            let spokenLanguagePriorSlack = 7.0
            switch detectedSpokenLanguage {
            case .polish:
                if isValidPolishOrEnglish(polishText), polishScore >= englishScore - spokenLanguagePriorSlack {
                    return .polish
                }
            case .english:
                if isValidPolishOrEnglish(englishText), englishScore >= polishScore - spokenLanguagePriorSlack {
                    return .english
                }
            case .unknown:
                break
            }
        }

        return englishScore > polishScore ? .english : .polish
    }

    struct CrossCandidateResult {
        let wordOverlap: Double
        let isTranslationPair: Bool
        let isSameContent: Bool
    }

    static func crossCandidateAnalysis(polishText: String, englishText: String) -> CrossCandidateResult {
        let polishWords = Set(polishText.lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .map { $0.trimmingCharacters(in: .punctuationCharacters) }
            .filter { !$0.isEmpty })
        let englishWords = Set(englishText.lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .map { $0.trimmingCharacters(in: .punctuationCharacters) }
            .filter { !$0.isEmpty })

        guard !polishWords.isEmpty, !englishWords.isEmpty else {
            return CrossCandidateResult(wordOverlap: 0, isTranslationPair: false, isSameContent: false)
        }

        let overlap = polishWords.intersection(englishWords).count
        let maxCount = max(polishWords.count, englishWords.count)
        let overlapRatio = Double(overlap) / Double(maxCount)

        let foldedPolish = Set(polishWords.map { $0.folding(options: .diacriticInsensitive, locale: .current) })
        let foldedEnglish = Set(englishWords.map { $0.folding(options: .diacriticInsensitive, locale: .current) })
        let foldedOverlap = foldedPolish.intersection(foldedEnglish).count
        let foldedOverlapRatio = Double(foldedOverlap) / Double(maxCount)

        let isTranslation = overlapRatio < 0.35 && maxCount >= 2
        let isSame = foldedOverlapRatio > 0.8

        return CrossCandidateResult(wordOverlap: overlapRatio, isTranslationPair: isTranslation, isSameContent: isSame)
    }

    static func candidateScore(
        text: String,
        targetLanguage: Language,
        otherText: String = "",
        averageLogProb: Double = 0,
        averageNoSpeechProb: Double = 0,
        averageCompressionRatio: Double = 1
    ) -> Double {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return -100 }

        let detectedLanguage = PostProcessor.detectTextLanguage(text)
        let languageScores = PostProcessor.languageScores(text)
        let words = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count

        // Reduce logprob weight to prevent English model bias from dominating
        var score = averageLogProb * 4.0 + Double(min(words, 12)) * 0.1

        if !isValidPolishOrEnglish(text) { score -= 100 }
        score -= averageNoSpeechProb * 8.0
        if averageCompressionRatio > 1.8 {
            score -= (averageCompressionRatio - 1.8) * 2.5
        }

        // Increase weight of text-level language heuristics
        switch targetLanguage {
        case .english:
            score += Double(languageScores.english - languageScores.polish) * 2.5
            if detectedLanguage == .english { score += 6 }
            if detectedLanguage == .polish { score -= 8 }
        case .polish:
            score += Double(languageScores.polish - languageScores.english) * 2.5
            if detectedLanguage == .polish { score += 6 }
            if detectedLanguage == .english { score -= 8 }
        case .unknown:
            break
        }

        // Cross-candidate penalty: if this candidate's text is detected as the wrong language,
        // apply a strong penalty (the other decode likely captured the actual speech)
        if !otherText.isEmpty {
            let otherLang = PostProcessor.detectTextLanguage(otherText)
            if targetLanguage == .english && detectedLanguage != .english && otherLang == .polish {
                score -= 6
            }
            if targetLanguage == .polish && detectedLanguage != .polish && otherLang == .english {
                score -= 6
            }
        }

        return score
    }

    private static func averageLogProb(_ result: TranscriptionResult) -> Double {
        guard !result.segments.isEmpty else { return -2.0 }
        let total = result.segments.reduce(0.0) { $0 + Double($1.avgLogprob) }
        return total / Double(result.segments.count)
    }

    private static func segmentQuality(_ result: TranscriptionResult) -> (averageNoSpeechProb: Double, averageCompressionRatio: Double) {
        guard !result.segments.isEmpty else { return (0, 1) }
        let noSpeechTotal = result.segments.reduce(0.0) { $0 + Double($1.noSpeechProb) }
        let compressionTotal = result.segments.reduce(0.0) { $0 + Double($1.compressionRatio) }
        let count = Double(result.segments.count)
        return (
            averageNoSpeechProb: noSpeechTotal / count,
            averageCompressionRatio: compressionTotal / count
        )
    }
}

private extension AVAudioPCMBuffer {
    func toFloatArray() -> [Float] {
        guard let channelData = floatChannelData else { return [] }
        let frameCount = Int(frameLength)
        guard frameCount > 0 else { return [] }
        return Array(UnsafeBufferPointer(start: channelData[0], count: frameCount))
    }
}
