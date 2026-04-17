import Cocoa
import AVFoundation

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Migrate keychain items to avoid password prompts
        KeychainManager.migrateKeysIfNeeded()

        // Request microphone permission early — macOS delivers silent audio if denied
        Task {
            let granted = await PermissionChecker.requestMicrophonePermission()
            print("[AppDelegate] Microphone permission: \(granted ? "granted" : "DENIED")")
            if !granted {
                await MainActor.run {
                    PermissionChecker.openMicrophoneSettings()
                }
            }
        }

        Task { @MainActor in
            promptForAccessibilityIfNeeded()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {}

    // MARK: - App Icon

    private func promptForAccessibilityIfNeeded() {
        guard !PermissionChecker.checkAccessibilityPermission() else { return }

        UserDefaults.standard.set(false, forKey: "accessibilityPrompted")
        _ = PermissionChecker.checkAccessibilityPermission(prompt: true)

        let alert = NSAlert()
        alert.messageText = "Enable Accessibility for Auto-Paste"
        alert.informativeText = "MySTT needs Accessibility access to paste dictated text into Terminal, Teams, and other apps.\n\nmacOS should show a permission prompt now. If it does not, open System Settings and enable MySTT in Privacy & Security → Accessibility."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Open Accessibility Settings")
        alert.addButton(withTitle: "OK")

        NSApp.activate(ignoringOtherApps: true)
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            PermissionChecker.openAccessibilitySettings()
        }
    }

    private func setAppIcon() {
        let execPath = ProcessInfo.processInfo.arguments[0]
        let execDir = (execPath as NSString).deletingLastPathComponent
        let bundlePath = "\(execDir)/MySTT_MySTT.bundle"
        let iconPath = "\(bundlePath)/Assets.xcassets/AppIcon.appiconset/icon_512x512@2x.png"

        if let image = NSImage(contentsOfFile: iconPath) {
            NSApp.applicationIconImage = image
        } else {
            // Try Bundle.main Resources
            if let resourcePath = Bundle.main.resourcePath {
                let resIconPath = "\(resourcePath)/MySTT_MySTT.bundle/Assets.xcassets/AppIcon.appiconset/icon_512x512@2x.png"
                if let image = NSImage(contentsOfFile: resIconPath) {
                    NSApp.applicationIconImage = image
                    return
                }
            }
            for bundle in iconCandidateBundles() {
                let path = "\(bundle.bundlePath)/Assets.xcassets/AppIcon.appiconset/icon_512x512@2x.png"
                if let image = NSImage(contentsOfFile: path) {
                    NSApp.applicationIconImage = image
                    return
                }
            }
        }
    }

    private func iconCandidateBundles() -> [Bundle] {
        #if SWIFT_PACKAGE
        return [Bundle.module, Bundle.main]
        #else
        return [Bundle.main]
        #endif
    }
}
