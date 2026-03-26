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

        // Request accessibility permission (silent check, prompt only once)
        let hasAccessibility = AXIsProcessTrusted()
        if !hasAccessibility {
            if !UserDefaults.standard.bool(forKey: "accessibilityPrompted") {
                UserDefaults.standard.set(true, forKey: "accessibilityPrompted")
                let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
                AXIsProcessTrustedWithOptions(options)
            }
        }

        // Proactively request Automation permission for System Events
        requestAutomationPermission()
    }

    func applicationWillTerminate(_ notification: Notification) {}

    // MARK: - Automation Permission

    /// Trigger a harmless System Events call to prompt for Automation permission on first launch.
    /// Uses NSAppleScript (in-process) so the permission is tied directly to MySTT's bundle ID,
    /// ensuring it persists across restarts.
    private func requestAutomationPermission() {
        // Only do this once
        guard !UserDefaults.standard.bool(forKey: "automationPermissionRequested") else { return }
        UserDefaults.standard.set(true, forKey: "automationPermissionRequested")

        // Run on background queue to avoid blocking app launch
        DispatchQueue.global(qos: .utility).async {
            var error: NSDictionary?
            let script = NSAppleScript(source: "tell application \"System Events\" to return name")
            script?.executeAndReturnError(&error)
            if let error = error {
                let msg = error[NSAppleScript.errorMessage] as? String ?? "unknown"
                print("[AppDelegate] Automation permission request failed: \(msg)")
            } else {
                print("[AppDelegate] Automation permission granted")
            }
        }
    }

    // MARK: - App Icon

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
            for bundle in [Bundle.module, Bundle.main] {
                let path = "\(bundle.bundlePath)/Assets.xcassets/AppIcon.appiconset/icon_512x512@2x.png"
                if let image = NSImage(contentsOfFile: path) {
                    NSApp.applicationIconImage = image
                    return
                }
            }
        }
    }
}
