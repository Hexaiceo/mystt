import AVFoundation
import WhisperKit

class WhisperKitEngine: STTEngineProtocol {
    private var whisperKit: WhisperKit?
    private var modelName: String
    private(set) var isReady: Bool = false

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

    // MARK: - Transcribe

    func transcribe(audioBuffer: AVAudioPCMBuffer) async throws -> STTResult {
        if !isReady { try await prepare() }
        guard let whisperKit = whisperKit else { throw STTError.notInitialized }

        let floats = audioBuffer.toFloatArray()
        guard !floats.isEmpty else { throw STTError.emptyAudio }

        let audioDuration = Double(floats.count) / 16000.0
        let start = CFAbsoluteTimeGetCurrent()

        print("[WhisperKit] Transcribing \(String(format: "%.1f", audioDuration))s audio...")

        do {
            // Strategy: try Polish first (primary language), then English if text looks wrong.
            // This avoids unreliable auto-detect that produces Icelandic, Slovak, Russian etc.

            // Pass 1: Transcribe as Polish
            let polishResult = try await transcribeWith(floats: floats, language: "pl")
            let polishText = polishResult.text.trimmingCharacters(in: .whitespacesAndNewlines)

            // Check if the text looks like valid Polish/English
            if Self.isValidPolishOrEnglish(polishText) {
                // Check if it's actually English — if so, re-transcribe with English for better quality
                if Self.looksLikeEnglish(polishText) {
                    print("[WhisperKit] Polish transcription looks English, re-transcribing as English...")
                    let englishResult = try await transcribeWith(floats: floats, language: "en")
                    let englishText = englishResult.text.trimmingCharacters(in: .whitespacesAndNewlines)
                    if Self.isValidPolishOrEnglish(englishText) {
                        return buildResult(from: englishResult, elapsed: CFAbsoluteTimeGetCurrent() - start)
                    }
                }
                return buildResult(from: polishResult, elapsed: CFAbsoluteTimeGetCurrent() - start)
            }

            // Pass 2: Polish didn't produce good text — try English
            print("[WhisperKit] Polish transcription invalid, trying English...")
            let englishResult = try await transcribeWith(floats: floats, language: "en")
            let englishText = englishResult.text.trimmingCharacters(in: .whitespacesAndNewlines)

            if Self.isValidPolishOrEnglish(englishText) {
                return buildResult(from: englishResult, elapsed: CFAbsoluteTimeGetCurrent() - start)
            }

            // Fallback: return Polish result even if imperfect
            print("[WhisperKit] Neither language produced clean text, using Polish result")
            return buildResult(from: polishResult, elapsed: CFAbsoluteTimeGetCurrent() - start)

        } catch {
            throw STTError.transcriptionFailed(underlying: error)
        }
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
            usePrefillCache: true,
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
        let allowedPolishEnglish = CharacterSet.letters // covers Latin + Polish diacriticals
            .union(.decimalDigits)
            .union(.whitespaces)
            .union(.punctuationCharacters)
            .union(CharacterSet(charactersIn: "'\u{2019}\u{201C}\u{201D}\u{2013}\u{2014}\u{2026}\u{20AC}$@#%&*+=<>|/~`^"))

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
        let words = text.lowercased().components(separatedBy: .whitespacesAndNewlines)
            .map { $0.trimmingCharacters(in: .punctuationCharacters) }
            .filter { !$0.isEmpty }
        guard words.count >= 2 else { return false }

        // Polish diacriticals → definitely Polish
        let polishChars: Set<Character> = ["ą", "ć", "ę", "ł", "ń", "ś", "ź", "ż"]
        if text.contains(where: { polishChars.contains($0) }) { return false }

        let englishWords: Set<String> = [
            "the", "is", "are", "was", "were", "have", "has", "had", "will", "would",
            "could", "should", "can", "this", "that", "with", "from", "they", "them",
            "what", "where", "when", "how", "why", "who", "it", "and", "but", "or",
            "not", "all", "just", "here", "there", "now", "then", "very", "also",
            "about", "into", "over", "after", "before", "between", "through",
            "apply", "check", "test", "fix", "make", "let", "get", "set", "run",
        ]

        var englishCount = 0
        for word in words {
            if englishWords.contains(word) { englishCount += 1 }
        }

        // If >40% words are common English, it's likely English
        return Double(englishCount) / Double(words.count) > 0.4
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
