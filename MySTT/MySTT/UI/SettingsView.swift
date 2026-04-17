import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var navigation: SettingsNavigationModel

    var body: some View {
        TabView(selection: $navigation.selectedTab) {
            GeneralSettingsTab()
                .tag(SettingsTab.general)
                .tabItem { Label("General", systemImage: "gear") }
            STTSettingsTab()
                .tag(SettingsTab.speech)
                .tabItem { Label("Speech", systemImage: "mic") }
            LLMSettingsTab()
                .tag(SettingsTab.llm)
                .tabItem { Label("LLM", systemImage: "brain") }
            DictionarySettingsTab()
                .tag(SettingsTab.dictionary)
                .tabItem { Label("Dictionary", systemImage: "book") }
            HotkeySettingsTab()
                .tag(SettingsTab.hotkey)
                .tabItem { Label("Hotkey", systemImage: "keyboard") }
        }
        .frame(width: 780, height: 630)
        .padding()
    }
}
