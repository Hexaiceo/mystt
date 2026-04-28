import SwiftUI
import AppKit

struct MenuBarView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                Text(statusText)
                    .font(.headline)
                Spacer()
            }

            if !lastTranscription.isEmpty {
                Divider()

                Text(lastTranscription)
                    .font(.caption)
                    .lineLimit(3)
                    .foregroundColor(.secondary)

                HStack {
                    if appState.detectedLanguage == .unknown {
                        Label("Language not recognized", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.orange.opacity(0.3)))
                    } else {
                        Text("Language: \(detectedLanguage)")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.accentColor.opacity(0.2)))
                    }
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Text("Microphone")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Menu {
                    if appState.microphoneManager.availableMicrophones.isEmpty {
                        Text("No microphones found")
                    } else {
                        ForEach(appState.microphoneManager.availableMicrophones) { mic in
                            Button {
                                appState.selectMicrophone(mic)
                            } label: {
                                if mic.uid == appState.microphoneManager.selectedMicrophone?.uid {
                                    Label(mic.name, systemImage: "checkmark")
                                } else {
                                    Text(mic.name)
                                }
                            }
                        }
                    }

                    Divider()

                    Button("Refresh Microphones") {
                        appState.refreshMicrophones()
                    }

                    Button("Open Speech Settings") {
                        openSettings(.speech)
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "mic.fill")
                            .foregroundColor(.secondary)
                        Text(appState.activeMicrophoneName)
                            .lineLimit(1)
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .menuStyle(.borderlessButton)
            }

            Divider()

            HStack {
                Text("STT:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(sttProviderName)
                    .font(.caption)
            }
            HStack {
                Text("LLM:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(llmProviderName)
                    .font(.caption)
            }

            Divider()

            Toggle("Enabled", isOn: enabledBinding)

            VStack(alignment: .leading, spacing: 8) {
                Text("Open Settings")
                    .font(.caption)
                    .foregroundColor(.secondary)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(SettingsTab.allCases) { tab in
                        Button {
                            openSettings(tab)
                        } label: {
                            Label(tab.title, systemImage: tab.systemImage)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            }

            Button("Settings…") {
                openSettings(.general)
            }
            .keyboardShortcut(",", modifiers: .command)

            Button("Quit") {
                appState.cleanup()
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }
        .padding()
        .frame(width: 320)
    }

    private var statusColor: Color {
        if appState.isRecording { return .red }
        if appState.isProcessing { return .orange }
        if appState.isEnabled { return .green }
        return .gray
    }

    private var statusText: String { appState.statusMessage }

    private var lastTranscription: String { appState.lastTranscription }

    private var detectedLanguage: String { appState.detectedLanguage.displayName }

    private var sttProviderName: String {
        AppSettings.load().sttProvider.displayName
    }

    private var llmProviderName: String {
        AppSettings.load().llmProvider.displayName
    }

    private var enabledBinding: Binding<Bool> {
        $appState.isEnabled
    }

    private func openSettings(_ tab: SettingsTab) {
        SettingsWindowManager.shared.openSettings(appState: appState, tab: tab)
    }
}
