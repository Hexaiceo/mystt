import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Status
            HStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                Text(statusText)
                    .font(.headline)
            }

            Divider()

            // Last transcription
            if !lastTranscription.isEmpty {
                Text(lastTranscription)
                    .font(.caption)
                    .lineLimit(3)
                    .foregroundColor(.secondary)

                HStack {
                    Text("Language: \(detectedLanguage)")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.accentColor.opacity(0.2)))
                }
                Divider()
            }

            // Provider info
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

            // Controls
            Toggle("Enabled", isOn: enabledBinding)

            Button("Settings...") {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            }
            .keyboardShortcut(",", modifiers: .command)

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }
        .padding()
        .frame(width: 250)
    }

    // MARK: - Computed properties (placeholder - will bind to real AppState in Session N)

    private var statusColor: Color {
        .green
    }

    private var statusText: String { "Ready" }

    private var lastTranscription: String { "" }

    private var detectedLanguage: String { "EN" }

    private var sttProviderName: String {
        AppSettings.load().sttProvider.displayName
    }

    private var llmProviderName: String {
        AppSettings.load().llmProvider.displayName
    }

    private var enabledBinding: Binding<Bool> {
        Binding(get: { true }, set: { _ in })
    }
}
