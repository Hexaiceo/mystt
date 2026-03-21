import SwiftUI

@main
struct MySTTApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra("MySTT", systemImage: appState.isRecording ? "mic.fill" : "mic") {
            VStack(spacing: 8) {
                HStack {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)
                    Text(appState.statusMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }

                // Microphone info
                HStack(spacing: 4) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                    Text(appState.activeMicrophoneName)
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    Spacer()
                }

                Divider()

                Toggle("Enabled", isOn: $appState.isEnabled)
                    .toggleStyle(.switch)

                Divider()

                Button("Settings...") {
                    SettingsWindowManager.shared.openSettings(appState: appState)
                }
                .keyboardShortcut(",", modifiers: .command)

                Button("Quit MySTT") {
                    appState.cleanup()
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q", modifiers: .command)
            }
            .padding()
            .frame(width: 280)
            .environmentObject(appState)
        }
        .menuBarExtraStyle(.window)
    }

    private var statusColor: Color {
        if appState.isRecording { return .red }
        if appState.isProcessing { return .orange }
        if appState.isEnabled { return .green }
        return .gray
    }
}

// MARK: - Settings Window Manager (singleton, works from menu bar app)

final class SettingsWindowManager: NSObject, NSWindowDelegate {
    static let shared = SettingsWindowManager()
    private var settingsWindow: NSWindow?

    func openSettings(appState: AppState) {
        // If window already exists, just bring it to front
        if let win = settingsWindow, win.isVisible {
            win.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        // Create new window
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
        win.contentView = NSHostingView(rootView:
            SettingsView()
                .environmentObject(appState)
                .frame(minWidth: 780, minHeight: 630)
        )
        win.center()

        settingsWindow = win

        // Must activate BEFORE showing window for menu bar apps
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        win.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_ notification: Notification) {
        // Return to accessory (menu bar only) mode
        NSApp.setActivationPolicy(.accessory)
        settingsWindow = nil
    }
}
