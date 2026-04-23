import SwiftUI
import AVFoundation
import Combine

struct STTEngineConfiguration: Equatable {
    let provider: STTProvider
    let whisperModelName: String
    let groqAPIKey: String

    init(settings: AppSettings) {
        self.provider = settings.sttProvider
        self.whisperModelName = settings.whisperModelName
        self.groqAPIKey = KeychainManager.groqAPIKey ?? settings.groqSTTAPIKey
    }
}

enum RecordingStartBlocker: Equatable {
    case disabled
    case alreadyRecording
    case processingPreviousDictation
}

private actor TimeoutRaceBox<T: Sendable> {
    private var hasCompleted = false

    func resume(
        _ continuation: CheckedContinuation<T, Error>,
        with result: Result<T, Error>
    ) -> Bool {
        guard !hasCompleted else { return false }
        hasCompleted = true
        continuation.resume(with: result)
        return true
    }
}

@MainActor
class AppState: ObservableObject {
    @Published var isRecording = false
    @Published var isProcessing = false
    @Published var lastTranscription = ""
    @Published var detectedLanguage: Language = .unknown
    @Published var statusMessage = "Starting..."
    @Published var isEnabled = true

    // Model status
    @Published var sttModelReady = false
    @Published var sttModelDownloading = false
    @Published var sttDownloadProgress: Double = 0  // 0.0 to 1.0
    @Published var sttDownloadStatus: String = ""   // "Downloading 234MB / 632MB..."
    @Published var llmModelReady = false
    @Published var activeMicrophoneName: String = "Unknown"

    // Shared microphone manager — used by Settings UI too
    let microphoneManager = MicrophoneManager()
    private var micCancellables = Set<AnyCancellable>()

    private var audioEngine: AudioCaptureEngine
    private var sttEngine: (any STTEngineProtocol)?
    private var postProcessor: PostProcessor
    private var dictionaryEngine: DictionaryEngine
    private var autoPaster: AutoPaster
    private var hotkeyManager: HotkeyManager
    private var soundPlayer: SoundPlayer
    private var settings: AppSettings
    private var sttEngineConfiguration: STTEngineConfiguration
    private let overlay = RecordingOverlayWindow()
    private let dictationJournal = DictationJournal()

    // Task handle for cancellation
    private var processingTask: Task<Void, Never>?

    init() {
        self.settings = AppSettings.load()
        self.audioEngine = AudioCaptureEngine()
        self.autoPaster = AutoPaster()
        self.soundPlayer = SoundPlayer(isEnabled: settings.playSound)
        self.hotkeyManager = HotkeyManager(keyCode: settings.hotkeyKeyCode)

        let dictionaryEngine = DictionaryEngine()
        self.dictionaryEngine = dictionaryEngine
        let llmProvider = Self.createLLMProvider(settings: settings)
        self.postProcessor = PostProcessor(
            dictionaryEngine: dictionaryEngine,
            punctuationCorrector: nil,
            llmProvider: llmProvider,
            settings: settings
        )
        self.sttEngineConfiguration = STTEngineConfiguration(settings: settings)

        setupHotkeyCallbacks()

        // Request mic permission once at startup, then run model checks in parallel
        Task {
            let hasMic = await audioEngine.ensureMicPermission()
            if !hasMic { print("[AppState] Microphone permission not granted") }
        }
        Task { await downloadSTTModel() }
        Task { await checkLLMStatus() }
        Task { await recoverPendingDictationIfNeeded() }

        // Get active microphone name and subscribe to changes
        updateMicrophoneName()
        microphoneManager.objectWillChange.sink { [weak self] _ in
            DispatchQueue.main.async {
                self?.updateMicrophoneName()
            }
        }.store(in: &micCancellables)
    }

    // MARK: - Model Download

    func downloadSTTModel(forceReload: Bool = false) async {
        if forceReload {
            if let sttEngine {
                await sttEngine.reset()
            }
            sttEngine = nil
            sttModelReady = false
            sttModelDownloading = false
            sttDownloadProgress = 0
            sttDownloadStatus = ""
        }

        guard !sttModelReady, !sttModelDownloading else { return }

        switch settings.sttProvider {
        case .whisperKit:
            sttModelDownloading = true
            sttDownloadProgress = 0
            let modelName = settings.whisperModelName
            let engine = WhisperKitEngine(modelName: modelName.isEmpty ? nil : modelName)
            self.sttEngine = engine

            // Show appropriate status based on whether model is cached
            let isCached = engine.hasLocalModel()
            sttDownloadStatus = isCached ? "Loading cached model..." : "Downloading model..."
            statusMessage = isCached ? "Loading Whisper model..." : "Downloading Whisper model..."

            let progressTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] timer in
                Task { @MainActor [weak self] in
                    guard let self = self else { timer.invalidate(); return }
                    if self.sttModelDownloading {
                        let dots = String(repeating: ".", count: (Int(Date().timeIntervalSince1970) % 3) + 1)
                        self.sttDownloadStatus = isCached
                            ? "Compiling model\(dots)"
                            : "Downloading & compiling model\(dots)"
                    }
                }
            }

            let startTime = CFAbsoluteTimeGetCurrent()
            do {
                try await engine.prepare()
                progressTimer.invalidate()
                let elapsed = CFAbsoluteTimeGetCurrent() - startTime
                sttModelReady = true
                sttModelDownloading = false
                sttDownloadProgress = 1.0
                sttDownloadStatus = "Ready (loaded in \(String(format: "%.0f", elapsed))s)"
                statusMessage = "Ready - press Fn to record"
            } catch {
                progressTimer.invalidate()
                sttModelDownloading = false
                sttModelReady = false
                sttDownloadProgress = 0
                sttDownloadStatus = "Error: \(error.localizedDescription)"
                statusMessage = "STT error: \(error.localizedDescription)"
                print("[AppState] STT error: \(error)")
            }

        case .groqSTT:
            let key = KeychainManager.groqAPIKey ?? settings.groqSTTAPIKey
            guard !key.isEmpty else {
                statusMessage = "Groq STT: add API key in Settings → General → API Keys"
                sttModelReady = false
                return
            }
            let engine = GroqSTTEngine(apiKey: key)
            self.sttEngine = engine
            do {
                try await engine.prepare()
                sttModelReady = true
                statusMessage = "Ready - press Fn to record (Groq STT)"
            } catch {
                sttModelReady = false
                statusMessage = "Groq key invalid: \(error.localizedDescription)"
            }
        }
    }

    func checkLLMStatus() async {
        guard settings.enableLLMCorrection else { llmModelReady = false; return }
        let provider = Self.createLLMProvider(settings: settings)
        llmModelReady = await provider?.isAvailable() ?? false
        print("[AppState] LLM available: \(llmModelReady)")
    }

    // MARK: - LLM Factory

    static func createLLMProvider(settings: AppSettings) -> (any LLMProviderProtocol)? {
        guard settings.enableLLMCorrection else { return nil }
        switch settings.llmProvider {
        case .localMLX:
            print("[AppState] LLM provider: MLX, model: \(settings.mlxModelName)")
            return MLXProvider(modelPath: settings.mlxModelName)
        case .localLMStudio:
            print("[AppState] LLM provider: LM Studio, model: \(settings.lmStudioModelName)")
            return LMStudioProvider(model: settings.lmStudioModelName, baseURL: settings.lmStudioURL)
        case .ollama:
            print("[AppState] LLM provider: Ollama, model: \(settings.ollamaModelName), url: \(settings.ollamaURL)")
            return OllamaProvider(model: settings.ollamaModelName, baseURL: settings.ollamaURL)
        case .groq:
            print("[AppState] LLM provider: Groq")
            return GroqProvider(apiKey: KeychainManager.groqAPIKey ?? settings.groqAPIKey)
        case .openai:
            print("[AppState] LLM provider: OpenAI")
            return OpenAIProvider(apiKey: KeychainManager.openaiAPIKey ?? settings.openaiAPIKey)
        }
    }

    // MARK: - Hotkey

    private func setupHotkeyCallbacks() {
        hotkeyManager.onRecordingStart = { [weak self] in
            Task { @MainActor in self?.startRecording() }
        }
        hotkeyManager.onRecordingStop = { [weak self] in
            Task { @MainActor in self?.stopAndProcess() }
        }
        hotkeyManager.onCancel = { [weak self] in
            Task { @MainActor in self?.cancelEverything() }
        }
        hotkeyManager.start()
    }

    // MARK: - Recording

    nonisolated static func recordingStartBlocker(
        isEnabled: Bool,
        isRecording: Bool,
        isProcessing: Bool
    ) -> RecordingStartBlocker? {
        if !isEnabled { return .disabled }
        if isRecording { return .alreadyRecording }
        if isProcessing { return .processingPreviousDictation }
        return nil
    }

    nonisolated static func transcriptionTimeout(forAudioDuration duration: Double) -> TimeInterval {
        min(25, max(8, 6 + duration * 1.8))
    }

    nonisolated static func shouldRetryTranscription(after error: Error) -> Bool {
        if error is CancellationError { return false }
        guard let error = error as? STTError else { return false }
        switch error {
        case .emptyAudio:
            return false
        case .notInitialized, .transcriptionFailed, .modelNotFound, .timeout:
            return true
        }
    }

    func startRecording() {
        if let blocker = Self.recordingStartBlocker(
            isEnabled: isEnabled,
            isRecording: isRecording,
            isProcessing: isProcessing
        ) {
            handleRecordingStartBlocked(by: blocker)
            return
        }

        guard sttModelReady else {
            synchronizeHotkeyState(isActive: false)
            statusMessage = "STT model not ready - downloading..."
            if sttModelDownloading {
                overlay.showStatusIndicator(mode: .loading(detail: "Compiling STT..."))
            } else {
                overlay.showStatusIndicator(mode: .notReady(detail: "STT not ready"))
            }
            soundPlayer.playError()
            // Auto-hide after 3 seconds
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                overlay.hideStatusIndicator()
            }
            Task { await downloadSTTModel() }
            return
        }

        // Check microphone permission before recording
        let micStatus = PermissionChecker.microphonePermissionStatus()
        guard micStatus == .authorized else {
            synchronizeHotkeyState(isActive: false)
            statusMessage = "Microphone access denied"
            soundPlayer.playError()
            overlay.showStatusIndicator(mode: .notReady(detail: "No mic access"))
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                overlay.hideStatusIndicator()
            }
            if micStatus == .notDetermined {
                Task { await PermissionChecker.requestMicrophonePermission() }
            } else {
                PermissionChecker.openMicrophoneSettings()
            }
            return
        }

        // Remember which app the user is in (for auto-paste later)
        autoPaster.captureTargetApp()
        updateMicrophoneName()

        do {
            try audioEngine.startRecording(deviceID: microphoneManager.selectedMicrophone?.id)
            isRecording = true
            synchronizeHotkeyState(isActive: true)
            statusMessage = "Listening... (Fn=stop, ESC=cancel)"
            soundPlayer.playStartRecording()
            overlay.show(status: .listening)
        } catch {
            synchronizeHotkeyState(isActive: false)
            statusMessage = "Mic error: \(error.localizedDescription)"
            soundPlayer.playError()
        }
    }

    // MARK: - Stop + Process

    func stopAndProcess() {
        synchronizeHotkeyState(isActive: false)
        guard isRecording else { return }

        let buffer = audioEngine.stopRecording()
        isRecording = false
        isProcessing = true
        statusMessage = "Processing... (ESC=cancel)"
        soundPlayer.playStopRecording()
        overlay.show(status: .processing)

        // Run pipeline in cancellable Task
        processingTask = Task { @MainActor in
            await runPipeline(buffer: buffer)
        }
    }

    private func runPipeline(buffer: AVAudioPCMBuffer?) async {
        defer {
            isProcessing = false
            processingTask = nil
            synchronizeHotkeyState(isActive: false)
        }

        guard let buffer = buffer, buffer.frameLength > 0 else {
            statusMessage = "No audio captured"
            overlay.hide()
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                statusMessage = "Ready - press Fn to record"
            }
            return
        }

        let audioDuration = Double(buffer.frameLength) / 16000.0
        let signalAnalysis = AudioCaptureEngine.analyzeSignal(buffer)

        if Self.shouldTreatAsAccidentalPress(duration: audioDuration, signalAnalysis: signalAnalysis) {
            statusMessage = "Ready - press Fn to record"
            overlay.hide()
            return
        }

        // Check if microphone actually captured audio (not silence)
        if !signalAnalysis.hasAnySignal {
            let micName = audioEngine.activeInputDeviceName
            statusMessage = "Mic silent (\(micName)) — check mic or switch device"
            soundPlayer.playError()
            overlay.hide()
            print("[Pipeline] WARNING: Microphone '\(micName)' delivered \(String(format: "%.1f", audioDuration))s of silence (peak=\(signalAnalysis.peakAmplitude), rms=\(signalAnalysis.rmsAmplitude), nonSilent=\(String(format: "%.2f%%", signalAnalysis.nonSilentFrameRatio * 100)))")
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 4_000_000_000)
                if statusMessage.starts(with: "Mic silent") { statusMessage = "Ready - press Fn to record" }
            }
            return
        }

        let pipelineStart = CFAbsoluteTimeGetCurrent()

        do {
            try Task.checkCancellation()

            guard let sttEngine = sttEngine else {
                statusMessage = "STT not ready"
                overlay.hide()
                return
            }

            statusMessage = "Transcribing \(String(format: "%.1f", audioDuration))s audio..."
            overlay.show(status: .processing, detail: "STT: \(String(format: "%.1f", audioDuration))s audio")

            let sttStart = CFAbsoluteTimeGetCurrent()
            let transcriptionContext = transcriptionContext(for: sttEngine)
            let sttResult = try await transcribeWithRecovery(
                using: sttEngine,
                audioBuffer: buffer,
                context: transcriptionContext,
                audioDuration: audioDuration
            )
            let sttTime = CFAbsoluteTimeGetCurrent() - sttStart

            try Task.checkCancellation()

            guard Self.shouldAcceptTranscription(sttResult, signalAnalysis: signalAnalysis) else {
                statusMessage = "No speech detected"
                overlay.hide()
                print("[Pipeline] Rejecting unusable transcript: text='\(sttResult.text.prefix(80))' confidence=\(sttResult.confidence) peak=\(signalAnalysis.peakAmplitude) rms=\(signalAnalysis.rmsAmplitude)")
                return
            }

            // Use heuristic language detection on actual text (more reliable than WhisperKit's detection)
            let heuristicLang = PostProcessor.detectTextLanguage(sttResult.text)
            if heuristicLang != .unknown {
                detectedLanguage = heuristicLang
            } else {
                detectedLanguage = sttResult.language
            }
            var finalText = sttResult.text
            print("[Pipeline] STT in \(String(format: "%.1f", sttTime))s → whisper=[\(sttResult.language.displayName)] heuristic=[\(heuristicLang.displayName)] → using [\(detectedLanguage.displayName)] \(finalText.prefix(80))")

            // Step 2: LLM correction
            try Task.checkCancellation()
            statusMessage = "Correcting text..."
            overlay.show(status: .processing, detail: "LLM")

            let llmStart = CFAbsoluteTimeGetCurrent()
            do {
                finalText = try await postProcessor.process(finalText, language: detectedLanguage)
                let llmTime = CFAbsoluteTimeGetCurrent() - llmStart
                print("[Pipeline] LLM in \(String(format: "%.1f", llmTime))s → \(finalText.prefix(80))")
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                print("[Pipeline] LLM failed (\(error)), using raw STT")
            }

            try Task.checkCancellation()

            lastTranscription = finalText
            let dictationRecordID = await storeDictationRecord(
                rawText: sttResult.text,
                finalText: finalText,
                language: detectedLanguage
            )
            let totalTime = CFAbsoluteTimeGetCurrent() - pipelineStart
            var shouldReportSuccess = true

            if settings.autoPaste {
                // Hide overlay BEFORE pasting so it doesn't steal focus
                overlay.hide()
                let pasteResult = await autoPaster.paste(finalText)
                await finalizeDictationRecord(id: dictationRecordID, with: pasteResult)
                let handled = handlePasteResult(pasteResult, totalTime: totalTime)
                shouldReportSuccess = !handled
                if shouldReportSuccess {
                    soundPlayer.playSuccess()
                }
            } else {
                // Even without auto-paste, always copy to clipboard
                autoPaster.copyToClipboard(finalText)
                await finalizeDictationRecord(
                    id: dictationRecordID,
                    with: .inserted(method: .clipboardOnly, verified: true)
                )
                overlay.show(status: .done, detail: "\(String(format: "%.1f", totalTime))s")
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 1_500_000_000)
                    overlay.hide()
                }
                soundPlayer.playSuccess()
            }

            if shouldReportSuccess {
                statusMessage = "Done! (\(String(format: "%.1f", totalTime))s)"
            }
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                if statusMessage.starts(with: "Done!")
                    || statusMessage.starts(with: "Text copied")
                    || statusMessage.starts(with: "Recovered undelivered") {
                    statusMessage = "Ready - press Fn to record"
                }
            }

        } catch is CancellationError {
            statusMessage = "Cancelled"
            overlay.hide()
            soundPlayer.playError()
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                statusMessage = "Ready - press Fn to record"
            }
        } catch {
            statusMessage = "Error: \(error.localizedDescription)"
            soundPlayer.playError()
            overlay.hide()
            print("[Pipeline] Error: \(error)")
        }
    }

    static func shouldTreatAsAccidentalPress(
        duration: Double,
        signalAnalysis: AudioCaptureEngine.SignalAnalysis
    ) -> Bool {
        if duration < 0.20 { return true }
        if duration < 0.55 && !signalAnalysis.hasAnySignal { return true }
        return false
    }

    static func shouldAcceptTranscription(
        _ result: STTResult,
        signalAnalysis: AudioCaptureEngine.SignalAnalysis
    ) -> Bool {
        guard !result.isEmpty else { return false }
        guard signalAnalysis.hasAnySignal else { return false }

        let trimmedText = result.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard Self.isUsableTranscriptText(trimmedText) else { return false }

        let words = trimmedText
            .components(separatedBy: .whitespacesAndNewlines)
            .map { $0.trimmingCharacters(in: .punctuationCharacters) }
            .filter { !$0.isEmpty }

        if Self.isKnownWeakSignalHallucination(
            trimmedText,
            wordCount: words.count,
            confidence: result.confidence,
            signalAnalysis: signalAnalysis
        ) {
            return false
        }

        if signalAnalysis.hasSpeechLikeSignal {
            return true
        }

        let hasUsableWeakSignal =
            signalAnalysis.peakAmplitude >= 0.0003 ||
            signalAnalysis.rmsAmplitude >= 0.00005 ||
            signalAnalysis.nonSilentFrameRatio >= 0.008

        if hasUsableWeakSignal {
            return words.count >= 1
        }

        if words.count <= 2 {
            return result.confidence >= -2.5
        }

        return result.confidence >= -3.0
    }

    private static func isUsableTranscriptText(_ text: String) -> Bool {
        guard !text.isEmpty else { return false }
        guard WhisperKitEngine.isValidPolishOrEnglish(text) else { return false }
        return text.rangeOfCharacter(from: .letters) != nil
    }

    private static func isKnownWeakSignalHallucination(
        _ text: String,
        wordCount: Int,
        confidence: Float,
        signalAnalysis: AudioCaptureEngine.SignalAnalysis
    ) -> Bool {
        guard !signalAnalysis.hasSpeechLikeSignal else { return false }
        guard wordCount <= 3 else { return false }
        guard confidence < -0.2 else { return false }
        guard signalAnalysis.peakAmplitude < 0.0008 || signalAnalysis.rmsAmplitude < 0.00012 else { return false }

        let normalized = text
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))

        let hallucinations: Set<String> = [
            "dziekuje",
            "dziękuję",
            "thank you",
            "thanks for watching",
            "napisy stworzone przez spolecznosc amara org",
            "subtitles by the amara org community"
        ]

        return hallucinations.contains(normalized)
    }

    // MARK: - Cancel (ESC key)

    func cancelEverything() {
        if isRecording {
            _ = audioEngine.stopRecording()
            isRecording = false
            synchronizeHotkeyState(isActive: false)
            overlay.hide()
            soundPlayer.playError()
            statusMessage = "Cancelled"
        }

        if isProcessing {
            processingTask?.cancel()
            isProcessing = false
            synchronizeHotkeyState(isActive: false)
            overlay.hide()
            soundPlayer.playError()
            statusMessage = "Cancelled"
        }

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            if statusMessage == "Cancelled" { statusMessage = "Ready - press Fn to record" }
        }
    }

    // MARK: - Settings

    func reloadSettings() {
        let previousSTTConfiguration = sttEngineConfiguration
        settings = AppSettings.load()
        sttEngineConfiguration = STTEngineConfiguration(settings: settings)
        soundPlayer.setEnabled(settings.playSound)
        hotkeyManager.updateKeyCode(settings.hotkeyKeyCode)
        let llmProvider = Self.createLLMProvider(settings: settings)
        dictionaryEngine = DictionaryEngine()
        postProcessor = PostProcessor(
            dictionaryEngine: dictionaryEngine, punctuationCorrector: nil,
            llmProvider: llmProvider, settings: settings
        )
        let shouldReloadSTT = previousSTTConfiguration != sttEngineConfiguration
        Task {
            await downloadSTTModel(forceReload: shouldReloadSTT)
            await checkLLMStatus()
        }
    }

    func updateMicrophoneName() {
        activeMicrophoneName = microphoneManager.selectedMicrophone?.name ?? "No microphone"
    }

    func refreshMicrophones() {
        microphoneManager.refreshDevices()
        updateMicrophoneName()
    }

    func selectMicrophone(_ microphone: MicrophoneManager.Microphone) {
        microphoneManager.selectMicrophone(microphone)
        updateMicrophoneName()
    }

    func cleanup() {
        hotkeyManager.stop()
        processingTask?.cancel()
        overlay.hide()
        if isRecording { _ = audioEngine.stopRecording() }
        synchronizeHotkeyState(isActive: false)
    }

    private func handleRecordingStartBlocked(by blocker: RecordingStartBlocker) {
        switch blocker {
        case .disabled:
            synchronizeHotkeyState(isActive: false)
        case .alreadyRecording:
            synchronizeHotkeyState(isActive: true)
        case .processingPreviousDictation:
            synchronizeHotkeyState(isActive: false)
            statusMessage = "Finishing previous dictation..."
            overlay.showStatusIndicator(mode: .loading(detail: "Finishing previous dictation"))
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                overlay.hideStatusIndicator()
                if !isProcessing && statusMessage == "Finishing previous dictation..." {
                    statusMessage = "Ready - press Fn to record"
                }
            }
        }
    }

    private func synchronizeHotkeyState(isActive: Bool) {
        hotkeyManager.isRecordingActive = isActive
    }

    private func transcribeWithRecovery(
        using engine: any STTEngineProtocol,
        audioBuffer: AVAudioPCMBuffer,
        context: TranscriptionContext,
        audioDuration: Double
    ) async throws -> STTResult {
        let timeout = Self.transcriptionTimeout(forAudioDuration: audioDuration)
        var lastError: Error?

        for attempt in 1...2 {
            do {
                let result = try await Self.withTimeout(seconds: timeout) {
                    if attempt > 1 {
                        await engine.reset()
                        try await engine.prepare()
                    }
                    return try await engine.transcribe(audioBuffer: audioBuffer, context: context)
                }
                sttModelReady = true
                return result
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                lastError = error
                print("[Pipeline] STT attempt \(attempt) failed: \(error.localizedDescription)")
                guard attempt == 1, Self.shouldRetryTranscription(after: error) else { break }
                statusMessage = "Recovering speech engine..."
                overlay.show(status: .processing, detail: "Recovering STT")
                sttModelReady = false
            }
        }

        throw lastError ?? STTError.timeout
    }

    private func transcriptionContext(for engine: any STTEngineProtocol) -> TranscriptionContext {
        guard settings.enableDictionary, engine.supportsPromptConditioning else {
            return .empty
        }

        return TranscriptionContext(prompt: dictionaryEngine.buildSTTPrompt())
    }

    private static func withTimeout<T: Sendable>(
        seconds: TimeInterval,
        operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            let race = TimeoutRaceBox<T>()
            var operationTask: Task<Void, Never>?
            var timeoutTask: Task<Void, Never>?

            operationTask = Task {
                do {
                    let value = try await operation()
                    let resumed = await race.resume(continuation, with: .success(value))
                    if resumed { timeoutTask?.cancel() }
                } catch {
                    let resumed = await race.resume(continuation, with: .failure(error))
                    if resumed { timeoutTask?.cancel() }
                }
            }

            timeoutTask = Task {
                do {
                    let nanoseconds = UInt64(seconds * 1_000_000_000)
                    try await Task.sleep(nanoseconds: nanoseconds)
                    let resumed = await race.resume(continuation, with: .failure(STTError.timeout))
                    if resumed { operationTask?.cancel() }
                } catch {}
            }
        }
    }

    private func storeDictationRecord(
        rawText: String,
        finalText: String,
        language: Language
    ) async -> UUID? {
        do {
            let record = try await dictationJournal.createRecord(
                rawText: rawText,
                finalText: finalText,
                language: language,
                targetApp: autoPaster.currentTargetAppSnapshot()
            )
            return record.id
        } catch {
            print("[AppState] Failed to persist dictation record: \(error)")
            return nil
        }
    }

    private func finalizeDictationRecord(id: UUID?, with result: PasteDeliveryResult) async {
        guard let id else { return }
        do {
            _ = try await dictationJournal.markDelivery(recordID: id, result: result)
        } catch {
            print("[AppState] Failed to finalize dictation record: \(error)")
        }
    }

    @discardableResult
    private func handlePasteResult(_ result: PasteDeliveryResult, totalTime: Double) -> Bool {
        switch result.outcome {
        case .inserted where result.wasVerified:
            return false
        case .inserted:
            statusMessage = "Text copied — paste sent but could not be verified"
            overlay.hide()
            soundPlayer.playError()
            return true
        case .clipboardOnly, .failed:
            statusMessage = "Text copied — target field lost focus"
            overlay.hide()
            soundPlayer.playError()
            presentDeliveryRecoveryAlert(message: result.failureReason ?? "Text is safely copied to the clipboard.")
            return true
        }
    }

    private func recoverPendingDictationIfNeeded() async {
        do {
            guard let record = try await dictationJournal.mostRecentRecoverableRecord() else { return }
            autoPaster.copyToClipboard(record.finalText)
            _ = try await dictationJournal.markRecovered(
                recordID: record.id,
                note: "Recovered undelivered dictation to clipboard on launch"
            )
            statusMessage = "Recovered undelivered dictation to clipboard"
            presentDeliveryRecoveryAlert(
                message: "Recovered undelivered text from \(record.createdAt.formatted(date: .abbreviated, time: .shortened)). It is copied to the clipboard."
            )
        } catch {
            print("[AppState] Failed to recover pending dictation: \(error)")
        }
    }

    private func presentDeliveryRecoveryAlert(message: String) {
        let alert = NSAlert()
        alert.messageText = "Dictation preserved"
        alert.informativeText = "\(message)\n\nThe latest text is already on the clipboard, so you can paste it manually."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")

        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }
}
