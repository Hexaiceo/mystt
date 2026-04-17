import Foundation
import Combine

enum SettingsTab: String, CaseIterable, Codable, Identifiable {
    case general
    case speech
    case llm
    case dictionary
    case hotkey

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general: return "General"
        case .speech: return "Speech"
        case .llm: return "LLM"
        case .dictionary: return "Dictionary"
        case .hotkey: return "Hotkey"
        }
    }

    var systemImage: String {
        switch self {
        case .general: return "gear"
        case .speech: return "mic"
        case .llm: return "brain"
        case .dictionary: return "book"
        case .hotkey: return "keyboard"
        }
    }
}

@MainActor
final class SettingsNavigationModel: ObservableObject {
    @Published var selectedTab: SettingsTab {
        didSet {
            defaults.set(selectedTab.rawValue, forKey: storageKey)
        }
    }

    private let defaults: UserDefaults
    private let storageKey: String

    init(
        defaults: UserDefaults = .standard,
        storageKey: String = "MySTTSelectedSettingsTab"
    ) {
        self.defaults = defaults
        self.storageKey = storageKey

        if let rawValue = defaults.string(forKey: storageKey),
           let storedTab = SettingsTab(rawValue: rawValue) {
            self.selectedTab = storedTab
        } else {
            self.selectedTab = .general
        }
    }

    func select(_ tab: SettingsTab) {
        selectedTab = tab
    }
}
