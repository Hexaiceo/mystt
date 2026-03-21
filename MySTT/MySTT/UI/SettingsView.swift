import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsTab()
                .tabItem { Label("General", systemImage: "gear") }
            STTSettingsTab()
                .tabItem { Label("Speech", systemImage: "mic") }
            LLMSettingsTab()
                .tabItem { Label("LLM", systemImage: "brain") }
            DictionarySettingsTab()
                .tabItem { Label("Dictionary", systemImage: "book") }
            HotkeySettingsTab()
                .tabItem { Label("Hotkey", systemImage: "keyboard") }
        }
        .frame(width: 780, height: 630)
        .padding()
    }
}
