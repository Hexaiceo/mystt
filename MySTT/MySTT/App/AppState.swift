import SwiftUI
import AVFoundation
import Combine

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
    private var autoPaster: AutoPaster
    private var hotkeyManager: HotkeyManager
    private var soundPlayer: SoundPlayer
    private var settings: AppSettings
    private let overlay = RecordingOverlayWindow()

    // Task handle for cancellation
    private var processingTask: Task<Void, Never>?

    init() {
        self.settings = AppSettings.load()
        self.audioEngine = AudioCaptureEngine()
        self.autoPaster = AutoPaster()
        self.soundPlayer = SoundPlayer(isEnabled: settings.playSound)
        self.hotkeyManager = HotkeyManager(keyCode: settings.hotkeyKeyCode)

        let dictionaryEngine = DictionaryEngine()
        let llmProvider = Self.createLLMProvider(settings: settings)
        self.postProcessor = PostProcessor(
            dictionaryEngine: dictionaryEngine,
            punctuationCorrector: nil,
            llmProvider: llmProvider,
            settings: settings
        )

        setupHotkeyCallbacks()

        // Request mic permission once at startup, then run model checks in parallel
        Task {
            let hasMic = await audioEngine.ensureMicPermission()
            if !hasMic { print("[AppState] Microphone permission not granted") }
        }
        Task { await downloadSTTModel() }
        Task { await checkLLMStatus() }

        // Get active microphone name and subscribe to changes
        updateMicrophoneName()
        microphoneManager.objectWillChange.sink { [weak self] _ in
            DispatchQueue.main.async {
                self?.updateMicrophoneName()
            }
        }.store(in: &micCancellables)
    }

    // MARK: - Model Download

    func downloadSTTModel() async {
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

    private static func createLLMProvider(settings: AppSettings) -> (any LLMProviderProtocol)? {
        guard settings.enableLLMCorrection else { return nil }
        switch settings.llmProvider {
        case .localMLX:
            print("[AppState] LLM provider: MLX, model: \(settings.mlxModelName)")
            return MLXProvider(modelPath: settings.mlxModelName)
        case .localLMStudio:
            print("[AppState] LLM provider: LM Studio, model: \(settings.lmStudioModelName)")
            return LMStudioProvider(model: settings.lmStudioModelName, baseURL: settings.lmStudioURL)
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

    func startRecording() {
        guard isEnabled, !isRecording, !isProcessing else { return }
        guard sttModelReady else {
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
            try audioEngine.startRecording()
            isRecording = true
            statusMessage = "Listening... (Fn=stop, ESC=cancel)"
            soundPlayer.playStartRecording()
            overlay.show(status: .listening)
        } catch {
            statusMessage = "Mic error: \(error.localizedDescription)"
            soundPlayer.playError()
        }
    }

    // MARK: - Stop + Process

    func stopAndProcess() {
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

        // If audio is too short (< 1s), treat as accidental press - cancel silently
        if audioDuration < 1.0 {
            statusMessage = "Ready - press Fn to record"
            overlay.hide()
            return
        }

        // Check if microphone actually captured audio (not silence)
        if !AudioCaptureEngine.hasAudioSignal(buffer) {
            let micName = AudioCaptureEngine.defaultInputDeviceName()
            statusMessage = "Mic silent (\(micName)) — check mic or switch device"
            soundPlayer.playError()
            overlay.hide()
            print("[Pipeline] WARNING: Microphone '\(micName)' delivered \(String(format: "%.1f", audioDuration))s of silence")
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
            let sttResult = try await sttEngine.transcribe(audioBuffer: buffer)
            let sttTime = CFAbsoluteTimeGetCurrent() - sttStart

            try Task.checkCancellation()

            guard !sttResult.isEmpty else {
                statusMessage = "No speech detected"
                overlay.hide()
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
            overlay.show(status: .processing, detail: "LLM correction (ESC=cancel)")

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
            let totalTime = CFAbsoluteTimeGetCurrent() - pipelineStart

            if settings.autoPaste {
                // Hide overlay BEFORE pasting so it doesn't steal focus
                overlay.hide()
                // paste() also copies to clipboard
                await autoPaster.paste(finalText)
            } else {
                // Even without auto-paste, always copy to clipboard
                autoPaster.copyToClipboard(finalText)
                overlay.show(status: .done, detail: "\(String(format: "%.1f", totalTime))s")
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 1_500_000_000)
                    overlay.hide()
                }
            }

            statusMessage = "Done! (\(String(format: "%.1f", totalTime))s)"
            soundPlayer.playSuccess()

            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                if statusMessage.starts(with: "Done!") { statusMessage = "Ready - press Fn to record" }
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

    // MARK: - Cancel (ESC key)

    func cancelEverything() {
        if isRecording {
            _ = audioEngine.stopRecording()
            isRecording = false
            hotkeyManager.isRecordingActive = false
            overlay.hide()
            soundPlayer.playError()
            statusMessage = "Cancelled"
        }

        if isProcessing {
            processingTask?.cancel()
            isProcessing = false
            hotkeyManager.isRecordingActive = false
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
        settings = AppSettings.load()
        soundPlayer.setEnabled(settings.playSound)
        hotkeyManager.updateKeyCode(settings.hotkeyKeyCode)
        let llmProvider = Self.createLLMProvider(settings: settings)
        postProcessor = PostProcessor(
            dictionaryEngine: DictionaryEngine(), punctuationCorrector: nil,
            llmProvider: llmProvider, settings: settings
        )
        Task { await downloadSTTModel(); await checkLLMStatus() }
    }

    func updateMicrophoneName() {
        activeMicrophoneName = microphoneManager.selectedMicrophone?.name ?? "No microphone"
    }

    func cleanup() {
        hotkeyManager.stop()
        processingTask?.cancel()
        overlay.hide()
        if isRecording { _ = audioEngine.stopRecording() }
    }
}
