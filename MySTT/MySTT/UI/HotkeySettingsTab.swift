import SwiftUI

struct HotkeySettingsTab: View {
    @EnvironmentObject var appState: AppState
    @AppStorage("hotkeyKeyCode") private var hotkeyKeyCode: Int = Int(KeyCodes.function)
    @AppStorage("hotkeyToggleMode") private var toggleMode: Bool = true

    var body: some View {
        Form {
            Section("Hotkey") {
                Picker("Recording hotkey", selection: $hotkeyKeyCode) {
                    Text("Fn / Globe").tag(Int(KeyCodes.function))
                    Text("Right Option (\u{2325})").tag(Int(KeyCodes.rightOption))
                    Text("Left Option (\u{2325})").tag(Int(KeyCodes.leftOption))
                    Text("Right Command (\u{2318})").tag(Int(KeyCodes.rightCommand))
                    Text("F5").tag(Int(KeyCodes.f5))
                    Text("F6").tag(Int(KeyCodes.f6))
                    Text("F9").tag(Int(KeyCodes.f9))
                }
            }

            Section("Recording Mode") {
                Picker("Mode", selection: $toggleMode) {
                    Label("Tap to speak (press once to start, press again to stop)", systemImage: "hand.tap")
                        .tag(true)
                    Label("Hold to speak (hold key while speaking, release to stop)", systemImage: "hand.raised")
                        .tag(false)
                }
                .pickerStyle(.radioGroup)

                if toggleMode {
                    Text("1. Press Fn to start recording\n2. Speak in English or Polish\n3. Press Fn again to stop and process\n4. Text will be pasted into the active window")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("1. Press and hold Fn\n2. Speak while holding\n3. Release Fn to stop and process\n4. Text will be pasted into the active window")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Section("Current") {
                HStack {
                    Text("Active hotkey:")
                    Text(KeyCodes.name(for: UInt16(hotkeyKeyCode)))
                        .bold()
                }
                HStack {
                    Text("Mode:")
                    Text(toggleMode ? "Tap to speak" : "Hold to speak")
                        .bold()
                }
                Button("Reset to Defaults") {
                    hotkeyKeyCode = Int(KeyCodes.function)
                    toggleMode = true
                }
            }
        }
        .formStyle(.grouped)
        .onChange(of: hotkeyKeyCode) { _, _ in appState.reloadSettings() }
        .onChange(of: toggleMode) { _, _ in appState.reloadSettings() }
    }
}
