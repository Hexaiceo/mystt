import AppKit

class AutoPaster {
    private var targetApp: NSRunningApplication?
    private let logFile: URL
    private var accessibilityPrompted = false

    init() {
        let logDir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".mystt")
        try? FileManager.default.createDirectory(at: logDir, withIntermediateDirectories: true)
        self.logFile = logDir.appendingPathComponent("paste_debug.log")
        // Truncate log on init
        try? "".write(to: logFile, atomically: true, encoding: .utf8)
    }

    private func log(_ msg: String) {
        let entry = "[\(DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium))] \(msg)\n"
        print("[AutoPaster] \(msg)")
        if let data = entry.data(using: .utf8) {
            if let handle = try? FileHandle(forWritingTo: logFile) {
                handle.seekToEndOfFile()
                handle.write(data)
                handle.closeFile()
            } else {
                try? data.write(to: logFile)
            }
        }
    }

    func captureTargetApp() {
        targetApp = NSWorkspace.shared.frontmostApplication
        log("Captured target: \(targetApp?.localizedName ?? "nil") pid=\(targetApp?.processIdentifier ?? 0) bundle=\(targetApp?.bundleIdentifier ?? "nil")")
    }

    func paste(_ text: String) async {
        log("paste() text=\(text.prefix(50))...")

        // 1. Copy text to clipboard
        copyToClipboard(text)

        guard let app = targetApp else {
            log("No target app!")
            return
        }

        let appName = app.localizedName ?? ""
        log("Target: \(appName), AXTrusted=\(AXIsProcessTrusted())")

        // 2. Activate target app via NSAppleScript (runs in-process, uses MySTT's Automation permission)
        if !appName.isEmpty {
            log("Activating \(appName)...")
            let ok = runAppleScript("tell application \"\(appName)\" to activate")
            log("Activate result: \(ok)")
        }

        // Wait for app to come to front
        try? await Task.sleep(nanoseconds: 500_000_000)
        log("Frontmost: \(NSWorkspace.shared.frontmostApplication?.localizedName ?? "nil")")

        // 3. Send Cmd+V via NSAppleScript (in-process — directly uses MySTT's Automation permission)
        log("Sending Cmd+V via NSAppleScript...")
        let pasteOK = runAppleScript("tell application \"System Events\" to keystroke \"v\" using command down")
        log("Paste result: \(pasteOK)")

        if pasteOK {
            log("SUCCESS: pasted \(text.count) chars into \(appName)")
            return
        }

        // 4. Fallback: try CGEvent (requires MySTT to have accessibility)
        if AXIsProcessTrusted() {
            log("NSAppleScript failed, trying CGEvent...")
            simulatePaste()
            log("CGEvent sent")
        } else {
            log("FAILED: AppleScript keystroke failed and no accessibility for CGEvent")
            log("User needs to grant Automation permission: System Settings → Privacy & Security → Automation → MySTT → System Events")

            // Prompt user once
            if !accessibilityPrompted {
                accessibilityPrompted = true
                promptForAutomationPermission()
            }
        }
    }

    func copyToClipboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        log("Clipboard: \(NSPasteboard.general.string(forType: .string)?.prefix(50) ?? "nil")")
    }

    // MARK: - NSAppleScript (in-process, uses MySTT's TCC permissions directly)

    private func runAppleScript(_ source: String) -> Bool {
        var error: NSDictionary?
        let script = NSAppleScript(source: source)
        script?.executeAndReturnError(&error)
        if let error = error {
            let errorMsg = error[NSAppleScript.errorMessage] as? String ?? "unknown"
            log("AppleScript error: \(errorMsg)")
            return false
        }
        return true
    }

    // MARK: - CGEvent fallback

    private func simulatePaste() {
        let source = CGEventSource(stateID: .hidSystemState)
        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false) else {
            log("CGEvent creation failed")
            return
        }
        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand
        keyDown.post(tap: .cgSessionEventTap)
        usleep(80_000)
        keyUp.post(tap: .cgSessionEventTap)
    }

    // MARK: - Permission prompt

    private func promptForAutomationPermission() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Auto-paste requires permission"
            alert.informativeText = "MySTT needs Automation permission to paste text into other apps.\n\nGo to: System Settings → Privacy & Security → Automation\nand enable \"System Events\" for MySTT.\n\nText is still copied to clipboard — you can paste manually with Cmd+V."
            alert.alertStyle = .informational
            alert.addButton(withTitle: "Open System Settings")
            alert.addButton(withTitle: "OK")

            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }
}
