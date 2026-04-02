import SwiftUI

struct STTSettingsTab: View {
    @EnvironmentObject var appState: AppState
    @AppStorage("sttProvider") private var sttProvider = STTProvider.whisperKit.rawValue
    @AppStorage("whisperModelName") private var whisperModel = "openai_whisper-large-v3-v20240930_turbo_632MB"

    /// Use the shared MicrophoneManager from AppState
    private var micManager: MicrophoneManager {
        appState.microphoneManager
    }

    var body: some View {
        Form {
            Section("STT Provider") {
                Picker("Provider", selection: $sttProvider) {
                    ForEach(STTProvider.allCases) { provider in
                        Text(provider.displayName).tag(provider.rawValue)
                    }
                }
            }

            if sttProvider == STTProvider.whisperKit.rawValue {
                Section("WhisperKit Model") {
                    Picker("Model", selection: $whisperModel) {
                        Text("Large V3 Turbo 632MB (recommended)")
                            .tag("openai_whisper-large-v3-v20240930_turbo_632MB")
                        Text("Large V3 Turbo 954MB")
                            .tag("openai_whisper-large-v3_turbo_954MB")
                        Text("Large V3 947MB (highest quality)")
                            .tag("openai_whisper-large-v3_947MB")
                        Text("Small 216MB (fastest, lower quality)")
                            .tag("openai_whisper-small_216MB")
                    }
                    let ram = ProcessInfo.processInfo.physicalMemory / (1024*1024*1024)
                    Text("Device RAM: \(ram) GB. Model downloads on first launch.")
                        .font(.caption).foregroundColor(.secondary)
                }
            }

            if sttProvider == STTProvider.groqSTT.rawValue {
                Section("Groq STT") {
                    let hasKey = !(KeychainManager.groqAPIKey ?? "").isEmpty
                    HStack {
                        Image(systemName: hasKey ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundColor(hasKey ? .green : .orange)
                        Text(hasKey ? "Using Groq API key from General → API Keys" : "Add Groq API key in General → API Keys")
                            .font(.caption)
                    }
                    Text("Uses Groq's Whisper Large V3 Turbo for cloud-based STT.")
                        .font(.caption).foregroundColor(.secondary)
                }
            }

            // Microphone selection — uses shared MicrophoneManager
            Section("Microphone") {
                if micManager.availableMicrophones.isEmpty {
                    Text("No microphones found")
                        .foregroundColor(.red)
                } else {
                    Picker("Input device", selection: Binding(
                        get: { micManager.selectedMicrophone?.id ?? 0 },
                        set: { newID in
                            if let mic = micManager.availableMicrophones.first(where: { $0.id == newID }) {
                                micManager.selectMicrophone(mic)
                                // Update the menu bar display immediately
                                appState.updateMicrophoneName()
                            }
                        }
                    )) {
                        ForEach(micManager.availableMicrophones) { mic in
                            Text(mic.name).tag(mic.id)
                        }
                    }

                    HStack {
                        Image(systemName: "mic.fill")
                            .foregroundColor(.green)
                        Text("Active: \(micManager.selectedMicrophone?.name ?? "None")")
                            .font(.caption)
                    }

                    Text("MySTT now keeps its own microphone preference. It favors the built-in MacBook microphone over Continuity/iPhone microphones, but it can still auto-switch when you connect a new non-Continuity microphone. Choosing a device here does not change the macOS system-wide input device.")
                        .font(.caption).foregroundColor(.secondary)

                    Button("Refresh") {
                        micManager.refreshDevices()
                        appState.updateMicrophoneName()
                    }
                }
            }
        }
        .formStyle(.grouped)
        .onChange(of: sttProvider) { _, _ in appState.reloadSettings() }
        .onChange(of: whisperModel) { _, _ in appState.reloadSettings() }
    }
}
