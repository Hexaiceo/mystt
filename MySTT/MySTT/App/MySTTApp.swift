import SwiftUI

@main
struct MySTTApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra("MySTT", systemImage: appState.isRecording ? "mic.fill" : "mic") {
            MenuBarView()
            .environmentObject(appState)
        }
        .menuBarExtraStyle(.window)
    }
}

// MARK: - Settings Window Manager (singleton, works from menu bar app)

@MainActor
final class SettingsWindowManager: NSObject, NSWindowDelegate {
    static let shared = SettingsWindowManager()
    private var settingsWindow: NSWindow?
    private let navigationModel = SettingsNavigationModel()

    func openSettings(appState: AppState, tab: SettingsTab = .general) {
        navigationModel.select(tab)

        if let win = settingsWindow, win.isVisible {
            win.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 810, height: 670),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        win.title = "MySTT Settings"
        win.delegate = self
        win.isReleasedWhenClosed = false
        win.level = .normal
        win.toolbarStyle = .preference
        win.titlebarAppearsTransparent = false
        win.setFrameAutosaveName("MySTTSettingsWindow")
        win.contentView = NSHostingView(rootView:
            SettingsView()
                .environmentObject(appState)
                .environmentObject(navigationModel)
                .frame(minWidth: 780, minHeight: 630)
        )
        win.center()

        settingsWindow = win

        NSApp.activate(ignoringOtherApps: true)
        win.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_ notification: Notification) {
        settingsWindow = nil
    }
}
