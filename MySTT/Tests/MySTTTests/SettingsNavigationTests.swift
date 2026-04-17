import XCTest
@testable import MySTT

@MainActor
final class SettingsNavigationTests: XCTestCase {
    private func makeDefaults(testName: String = #function) -> UserDefaults {
        let suiteName = "mystt-settings-navigation-\(UUID().uuidString)-\(testName)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    func test_initializesFromStoredTab() {
        let defaults = makeDefaults()
        defaults.set(SettingsTab.dictionary.rawValue, forKey: "selectedTab")

        let model = SettingsNavigationModel(defaults: defaults, storageKey: "selectedTab")

        XCTAssertEqual(model.selectedTab, .dictionary)
    }

    func test_defaultsToGeneralWhenStoredValueIsInvalid() {
        let defaults = makeDefaults()
        defaults.set("not-a-tab", forKey: "selectedTab")

        let model = SettingsNavigationModel(defaults: defaults, storageKey: "selectedTab")

        XCTAssertEqual(model.selectedTab, .general)
    }

    func test_selectPersistsValue() {
        let defaults = makeDefaults()
        let model = SettingsNavigationModel(defaults: defaults, storageKey: "selectedTab")

        model.select(.hotkey)

        XCTAssertEqual(model.selectedTab, .hotkey)
        XCTAssertEqual(defaults.string(forKey: "selectedTab"), SettingsTab.hotkey.rawValue)
    }

    func test_tabOrderMatchesMenuShortcuts() {
        XCTAssertEqual(
            SettingsTab.allCases,
            [.general, .speech, .llm, .dictionary, .hotkey]
        )
    }
}
