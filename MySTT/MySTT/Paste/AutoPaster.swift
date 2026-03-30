import AppKit

enum AutoPastePermissionIssue: Equatable, Hashable {
    case accessibility
    case automation
    case unknown
}

struct AppleScriptExecutionResult {
    let succeeded: Bool
    let errorMessage: String?
}

class AutoPaster {
    private struct TargetAppSnapshot {
        let processIdentifier: pid_t
        let localizedName: String?
        let bundleIdentifier: String?
    }

    private var targetApp: TargetAppSnapshot?
    private let logFile: URL
    private var promptedIssues = Set<AutoPastePermissionIssue>()

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
        let app = NSWorkspace.shared.frontmostApplication
        targetApp = app.map {
            TargetAppSnapshot(
                processIdentifier: $0.processIdentifier,
                localizedName: $0.localizedName,
                bundleIdentifier: $0.bundleIdentifier
            )
        }
        log("Captured target: \(targetApp?.localizedName ?? "nil") pid=\(targetApp?.processIdentifier ?? 0) bundle=\(targetApp?.bundleIdentifier ?? "nil")")
    }

    func paste(_ text: String) async {
        log("paste() text=\(text.prefix(50))...")

        // 1. Copy text to clipboard
        copyToClipboard(text)

        guard let app = resolvedTargetApp() else {
            log("No target app!")
            return
        }

        let appName = app.localizedName ?? ""
        let hasAccessibility = PermissionChecker.checkAccessibilityPermission()
        log("Target: \(appName), AXTrusted=\(hasAccessibility)")

        // 2. Bring the original app back to the foreground without Apple Events.
        log("Activating \(appName.isEmpty ? "target app" : appName) via NSRunningApplication...")
        let activateOK = app.activate()
        log("Activate result: \(activateOK)")

        // Wait for app to come to front
        await waitForFrontmostApp(processIdentifier: app.processIdentifier)
        log("Frontmost: \(NSWorkspace.shared.frontmostApplication?.localizedName ?? "nil")")

        // 3. Accessibility paste is the most stable path and survives relaunches without Automation.
        if hasAccessibility {
            log("Sending Cmd+V via CGEvent...")
            simulatePaste()
            log("SUCCESS: pasted \(text.count) chars into \(appName)")
            return
        }

        // 4. Fallback to System Events for setups that already rely on Automation.
        log("Accessibility missing, trying System Events fallback...")
        let pasteResult = runAppleScript("tell application \"System Events\" to keystroke \"v\" using command down")
        log("Paste result: \(pasteResult.succeeded)")

        if pasteResult.succeeded {
            log("SUCCESS: pasted \(text.count) chars into \(appName)")
            return
        }

        let issue = Self.classifyPermissionIssue(for: pasteResult.errorMessage)
        log("FAILED: auto-paste could not complete (\(issue))")
        promptForPermissionIssue(issue)
    }

    func copyToClipboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        log("Clipboard: \(NSPasteboard.general.string(forType: .string)?.prefix(50) ?? "nil")")
    }

    // MARK: - NSAppleScript (in-process, uses MySTT's TCC permissions directly)

    private func runAppleScript(_ source: String) -> AppleScriptExecutionResult {
        var error: NSDictionary?
        let script = NSAppleScript(source: source)
        script?.executeAndReturnError(&error)
        if let error = error {
            let errorMsg = error[NSAppleScript.errorMessage] as? String ?? "unknown"
            log("AppleScript error: \(errorMsg)")
            return AppleScriptExecutionResult(succeeded: false, errorMessage: errorMsg)
        }
        return AppleScriptExecutionResult(succeeded: true, errorMessage: nil)
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

    private func promptForPermissionIssue(_ issue: AutoPastePermissionIssue) {
        guard promptedIssues.insert(issue).inserted else { return }

        switch issue {
        case .accessibility:
            promptForAccessibilityPermission()
        case .automation:
            promptForAutomationPermission()
        case .unknown:
            if PermissionChecker.checkAccessibilityPermission() {
                promptForAutomationPermission()
            } else {
                promptForAccessibilityPermission()
            }
        }
    }

    private func promptForAccessibilityPermission() {
        DispatchQueue.main.async {
            _ = PermissionChecker.checkAccessibilityPermission(prompt: true)

            let alert = NSAlert()
            alert.messageText = "Auto-paste requires Accessibility"
            alert.informativeText = "MySTT needs Accessibility access to send Cmd+V into the app you were dictating into.\n\nGo to: System Settings → Privacy & Security → Accessibility\nand enable MySTT.\n\nYour text is already copied to the clipboard, so you can still paste it manually with Cmd+V."
            alert.alertStyle = .informational
            alert.addButton(withTitle: "Open Accessibility Settings")
            alert.addButton(withTitle: "OK")

            NSApp.activate(ignoringOtherApps: true)
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                PermissionChecker.openAccessibilitySettings()
            }
        }
    }

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
                PermissionChecker.openAutomationSettings()
            }
        }
    }

    private func resolvedTargetApp() -> NSRunningApplication? {
        guard let targetApp else { return nil }

        if let app = NSRunningApplication(processIdentifier: targetApp.processIdentifier), !app.isTerminated {
            return app
        }

        if let bundleIdentifier = targetApp.bundleIdentifier {
            return NSWorkspace.shared.runningApplications.first { $0.bundleIdentifier == bundleIdentifier }
        }

        return nil
    }

    private func waitForFrontmostApp(processIdentifier: pid_t) async {
        for _ in 0..<10 {
            if NSWorkspace.shared.frontmostApplication?.processIdentifier == processIdentifier {
                return
            }
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
    }

    static func classifyPermissionIssue(for errorMessage: String?) -> AutoPastePermissionIssue {
        let normalized = (errorMessage ?? "").lowercased()

        if normalized.contains("not allowed to send keystrokes")
            || normalized.contains("assistive access")
            || normalized.contains("accessibility") {
            return .accessibility
        }

        if normalized.contains("not authorized to send apple events")
            || normalized.contains("not authorised to send apple events")
            || normalized.contains("not permitted to send apple events") {
            return .automation
        }

        return .unknown
    }
}
