import AppKit
import ApplicationServices

enum AutoPastePermissionIssue: Equatable, Hashable {
    case accessibility
    case automation
    case unknown
}

struct AppleScriptExecutionResult {
    let succeeded: Bool
    let errorMessage: String?
}

struct TargetAppSnapshot: Equatable, Codable, Sendable {
    let processIdentifier: pid_t
    let localizedName: String?
    let bundleIdentifier: String?
}

enum PasteDeliveryMethod: String, Codable, Equatable, Sendable {
    case selectedTextReplace
    case directValueInsert
    case focusedElementPaste
    case systemEventsPaste
    case clipboardOnly
    case none
}

struct PasteDeliveryResult: Equatable, Sendable {
    enum Outcome: String, Equatable, Sendable {
        case inserted
        case clipboardOnly
        case failed
    }

    let outcome: Outcome
    let method: PasteDeliveryMethod
    let copiedToClipboard: Bool
    let wasVerified: Bool
    let failureReason: String?

    static func inserted(
        method: PasteDeliveryMethod,
        copiedToClipboard: Bool = true,
        verified: Bool,
        failureReason: String? = nil
    ) -> PasteDeliveryResult {
        PasteDeliveryResult(
            outcome: .inserted,
            method: method,
            copiedToClipboard: copiedToClipboard,
            wasVerified: verified,
            failureReason: failureReason
        )
    }

    static func clipboardOnly(reason: String) -> PasteDeliveryResult {
        PasteDeliveryResult(
            outcome: .clipboardOnly,
            method: .clipboardOnly,
            copiedToClipboard: true,
            wasVerified: false,
            failureReason: reason
        )
    }

    static func failed(reason: String, copiedToClipboard: Bool = true) -> PasteDeliveryResult {
        PasteDeliveryResult(
            outcome: .failed,
            method: .none,
            copiedToClipboard: copiedToClipboard,
            wasVerified: false,
            failureReason: reason
        )
    }
}

private struct CapturedTargetContext {
    let appSnapshot: TargetAppSnapshot
    let focusedElement: AXUIElement?
    let focusedWindow: AXUIElement?
    let focusedElementRole: String?
    let focusedElementSelectedRange: CFRange?
}

private struct AccessibilityTextState {
    let value: String
    let selectedRange: CFRange?
}

private struct TextMutationExpectation {
    let expectedValue: String
    let replacement: String
    let prefixContext: String
    let suffixContext: String
    let expectedCaretLocation: Int
}

private enum AccessibilityMutationAttempt {
    case inserted(method: PasteDeliveryMethod, verified: Bool)
    case continueWithPaste
}

class AutoPaster {
    private var targetApp: TargetAppSnapshot?
    private var targetContext: CapturedTargetContext?
    private var lastExternalApp: TargetAppSnapshot?
    private let logFile: URL
    private var promptedIssues = Set<AutoPastePermissionIssue>()
    private let workspaceNotificationCenter: NotificationCenter
    private let selfBundleIdentifier: String?
    private var activationObserver: NSObjectProtocol?

    init(
        workspaceNotificationCenter: NotificationCenter = NSWorkspace.shared.notificationCenter,
        selfBundleIdentifier: String? = Bundle.main.bundleIdentifier
    ) {
        self.workspaceNotificationCenter = workspaceNotificationCenter
        self.selfBundleIdentifier = selfBundleIdentifier
        let logDir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".mystt")
        try? FileManager.default.createDirectory(at: logDir, withIntermediateDirectories: true)
        self.logFile = logDir.appendingPathComponent("paste_debug.log")
        try? "".write(to: logFile, atomically: true, encoding: .utf8)

        activationObserver = workspaceNotificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: nil
        ) { [weak self] notification in
            guard let self,
                  let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
            else { return }

            self.rememberExternalApp(app)
        }
    }

    deinit {
        if let activationObserver {
            workspaceNotificationCenter.removeObserver(activationObserver)
        }
    }

    func currentTargetAppSnapshot() -> TargetAppSnapshot? {
        targetApp
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
        let frontmostSnapshot = NSWorkspace.shared.frontmostApplication.flatMap(snapshotIfEligible(_:))
        targetApp = Self.selectTargetApp(
            frontmostApp: frontmostSnapshot,
            lastExternalApp: lastExternalApp
        )

        if let targetApp {
            lastExternalApp = targetApp
            targetContext = captureTargetContext(for: targetApp)
        } else {
            targetContext = nil
        }

        log("Captured target: \(targetApp?.localizedName ?? "nil") pid=\(targetApp?.processIdentifier ?? 0) bundle=\(targetApp?.bundleIdentifier ?? "nil")")
    }

    func paste(_ text: String) async -> PasteDeliveryResult {
        log("paste() text=\(text.prefix(50))...")
        copyToClipboard(text)

        guard let app = resolvedTargetApp() else {
            log("No target app! Text preserved in clipboard only.")
            return .clipboardOnly(reason: "Target app is no longer running")
        }

        let appName = app.localizedName ?? ""
        let hasAccessibility = PermissionChecker.checkAccessibilityPermission()
        log("Target: \(appName), AXTrusted=\(hasAccessibility)")

        log("Activating \(appName.isEmpty ? "target app" : appName) via NSRunningApplication...")
        let activateOK = app.activate(options: [.activateAllWindows])
        log("Activate result: \(activateOK)")

        await waitForFrontmostApp(processIdentifier: app.processIdentifier)
        log("Frontmost: \(NSWorkspace.shared.frontmostApplication?.localizedName ?? "nil")")

        if hasAccessibility {
            let accessibilityResult = await deliverWithAccessibility(text, to: app)
            switch accessibilityResult.outcome {
            case .inserted:
                log("DELIVERY RESULT: \(accessibilityResult.method.rawValue) verified=\(accessibilityResult.wasVerified)")
                return accessibilityResult
            case .clipboardOnly, .failed:
                log("Accessibility delivery did not verify insertion: \(accessibilityResult.failureReason ?? "unknown")")
            }
        }

        log("Accessibility missing or could not verify insertion, trying System Events fallback...")
        let pasteResult = runAppleScript("tell application \"System Events\" to keystroke \"v\" using command down")
        log("Paste result: \(pasteResult.succeeded)")

        if pasteResult.succeeded {
            return .inserted(
                method: .systemEventsPaste,
                verified: false,
                failureReason: "Paste sent, but insertion could not be verified"
            )
        }

        let issue = Self.classifyPermissionIssue(for: pasteResult.errorMessage)
        log("FAILED: auto-paste could not complete (\(issue))")
        promptForPermissionIssue(issue)
        return .clipboardOnly(reason: pasteResult.errorMessage ?? "Auto-paste failed; text is on the clipboard")
    }

    func copyToClipboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        log("Clipboard: \(NSPasteboard.general.string(forType: .string)?.prefix(50) ?? "nil")")
    }

    private func deliverWithAccessibility(_ text: String, to app: NSRunningApplication) async -> PasteDeliveryResult {
        let contexts = preferredDeliveryContexts(for: app)

        for context in contexts {
            let contextLabel = context.focusedElementRole ?? "unknown"
            log("Trying accessibility delivery via focused element role=\(contextLabel)")
            let restored = await restoreFocus(using: context, app: app)
            if !restored {
                log("Could not restore focus for role=\(contextLabel)")
                continue
            }

            if let element = context.focusedElement {
                switch deliverWithAccessibilityMutation(
                    text,
                    into: element,
                    role: context.focusedElementRole
                ) {
                case let .inserted(method, verified):
                    return .inserted(method: method, verified: verified)
                case .continueWithPaste:
                    break
                }

                let beforeState = textState(of: element)
                simulatePaste()
                try? await Task.sleep(nanoseconds: 220_000_000)
                if verifyPaste(into: element, before: beforeState, expectedText: text) {
                    return .inserted(method: .focusedElementPaste, verified: true)
                }

                // simulatePaste() already sent Cmd+V — do NOT continue the loop
                // or fall through to System Events, as that would paste again.
                log("simulatePaste sent but could not verify — returning to prevent double paste")
                return .inserted(
                    method: .focusedElementPaste,
                    verified: false,
                    failureReason: "Paste sent via CGEvent but insertion could not be verified"
                )
            }
        }

        return .clipboardOnly(reason: "Target field lost focus or does not expose an editable value")
    }

    private func deliverWithAccessibilityMutation(
        _ text: String,
        into element: AXUIElement,
        role: String?
    ) -> AccessibilityMutationAttempt {
        let beforeState = textState(of: element)
        let supportsSelectedTextReplacement = isAttributeSettable(
            kAXSelectedTextAttribute as CFString,
            on: element
        )

        if Self.shouldPreferSelectedTextReplacement(
            role: role,
            supportsSelectedTextReplacement: supportsSelectedTextReplacement
        ) {
            return trySelectedTextReplacement(text, into: element, beforeState: beforeState)
        }

        if Self.shouldUseDirectValueInsert(
            role: role,
            supportsSelectedTextReplacement: supportsSelectedTextReplacement
        ) {
            return tryDirectInsert(text, into: element, beforeState: beforeState)
        }

        return .continueWithPaste
    }

    private func preferredDeliveryContexts(for app: NSRunningApplication) -> [CapturedTargetContext] {
        var contexts: [CapturedTargetContext] = []

        if let targetContext,
           targetContext.appSnapshot.bundleIdentifier == app.bundleIdentifier {
            contexts.append(targetContext)
        }

        let currentSnapshot = TargetAppSnapshot(
            processIdentifier: app.processIdentifier,
            localizedName: app.localizedName,
            bundleIdentifier: app.bundleIdentifier
        )
        if let currentContext = captureTargetContext(for: currentSnapshot),
           !contexts.contains(where: { Self.contextsReferToSameElement($0, currentContext) }) {
            contexts.append(currentContext)
        }

        return contexts
    }

    private func captureTargetContext(for snapshot: TargetAppSnapshot) -> CapturedTargetContext? {
        guard PermissionChecker.checkAccessibilityPermission() else { return nil }

        let appElement = AXUIElementCreateApplication(snapshot.processIdentifier)
        let focusedElement = copyAXElementAttribute(kAXFocusedUIElementAttribute as CFString, from: appElement)
        let focusedWindow = copyAXElementAttribute(kAXFocusedWindowAttribute as CFString, from: appElement)
        let role = focusedElement.flatMap { copyStringAttribute(kAXRoleAttribute as CFString, from: $0) }
        let frame = focusedElement.flatMap(frame(of:))
        let selectedRange = focusedElement.flatMap(copySelectedRange(from:))

        if let role {
            let frameDescription = frame.map { NSStringFromRect(NSRect(origin: $0.origin, size: $0.size)) } ?? "unknown"
            log(
                "Captured focused element role=\(role) frame=\(frameDescription) " +
                "selectedRange=\(Self.describe(range: selectedRange))"
            )
        }

        return CapturedTargetContext(
            appSnapshot: snapshot,
            focusedElement: focusedElement,
            focusedWindow: focusedWindow,
            focusedElementRole: role,
            focusedElementSelectedRange: selectedRange
        )
    }

    private func restoreFocus(using context: CapturedTargetContext, app: NSRunningApplication) async -> Bool {
        let activated = app.activate(options: [.activateAllWindows])
        if !activated {
            log("Activation reported failure while restoring focus")
        }

        await waitForFrontmostApp(processIdentifier: app.processIdentifier)

        if let window = context.focusedWindow {
            _ = AXUIElementPerformAction(window, kAXRaiseAction as CFString)
            _ = AXUIElementSetAttributeValue(window, kAXMainAttribute as CFString, kCFBooleanTrue)
        }

        guard let element = context.focusedElement else { return false }

        let focusStatus = AXUIElementSetAttributeValue(element, kAXFocusedAttribute as CFString, kCFBooleanTrue)
        if focusStatus != .success {
            log("Failed to restore AX focus with status \(focusStatus.rawValue)")
        }

        var restoredSelection = false
        if let selectedRange = context.focusedElementSelectedRange {
            restoredSelection = restoreSelectedRange(selectedRange, on: element)
            if restoredSelection {
                log("Restored selection range to \(Self.describe(range: selectedRange))")
            }
        }

        let currentFocusedElement = copyAXElementAttribute(
            kAXFocusedUIElementAttribute as CFString,
            from: AXUIElementCreateApplication(app.processIdentifier)
        )

        if currentFocusedElement.map({ CFEqual($0, element) }) ?? false {
            return true
        }

        return restoredSelection || focusStatus == .success
    }

    private func trySelectedTextReplacement(
        _ text: String,
        into element: AXUIElement,
        beforeState: AccessibilityTextState?
    ) -> AccessibilityMutationAttempt {
        guard isAttributeSettable(kAXSelectedTextAttribute as CFString, on: element) else {
            return .continueWithPaste
        }

        let setStatus = AXUIElementSetAttributeValue(
            element,
            kAXSelectedTextAttribute as CFString,
            text as CFTypeRef
        )
        guard setStatus == .success else {
            log("Selected-text replacement failed with AX status \(setStatus.rawValue)")
            return .continueWithPaste
        }

        guard let beforeState else {
            return .inserted(method: .selectedTextReplace, verified: false)
        }

        guard let afterState = textState(of: element) else {
            return .inserted(method: .selectedTextReplace, verified: false)
        }

        if Self.mutationMatches(
            beforeValue: beforeState.value,
            beforeRange: beforeState.selectedRange,
            afterValue: afterState.value,
            afterRange: afterState.selectedRange,
            replacement: text
        ) {
            return .inserted(method: .selectedTextReplace, verified: true)
        }

        if Self.normalizedText(afterState.value) != Self.normalizedText(beforeState.value) {
            log("Selected-text replacement changed the field but could not be fully verified")
            return .inserted(method: .selectedTextReplace, verified: false)
        }

        log("Selected-text replacement reported success but text did not change")
        return .continueWithPaste
    }

    private func tryDirectInsert(
        _ text: String,
        into element: AXUIElement,
        beforeState: AccessibilityTextState?
    ) -> AccessibilityMutationAttempt {
        guard isAttributeSettable(kAXValueAttribute as CFString, on: element),
              let beforeState else {
            return .continueWithPaste
        }

        let insertionRange = Self.normalizedRange(
            beforeState.selectedRange,
            stringLength: (beforeState.value as NSString).length
        )
        guard let insertionRange else { return .continueWithPaste }

        let newValue = (beforeState.value as NSString).replacingCharacters(
            in: NSRange(location: insertionRange.location, length: insertionRange.length),
            with: text
        )

        let setStatus = AXUIElementSetAttributeValue(
            element,
            kAXValueAttribute as CFString,
            newValue as CFTypeRef
        )
        guard setStatus == .success else {
            log("Direct insert failed with AX status \(setStatus.rawValue)")
            return .continueWithPaste
        }

        let caretLocation = insertionRange.location + (text as NSString).length
        var caretRange = CFRange(location: caretLocation, length: 0)
        if let rangeValue = AXValueCreate(.cfRange, &caretRange) {
            _ = AXUIElementSetAttributeValue(
                element,
                kAXSelectedTextRangeAttribute as CFString,
                rangeValue
            )
        }

        guard let afterState = textState(of: element) else {
            return .inserted(method: .directValueInsert, verified: false)
        }

        if Self.mutationMatches(
            beforeValue: beforeState.value,
            beforeRange: beforeState.selectedRange,
            afterValue: afterState.value,
            afterRange: afterState.selectedRange,
            replacement: text
        ) {
            return .inserted(method: .directValueInsert, verified: true)
        }

        if Self.normalizedText(afterState.value) != Self.normalizedText(beforeState.value) {
            log("Direct insert changed the field but could not be fully verified")
            return .inserted(method: .directValueInsert, verified: false)
        }

        log("Direct insert reported success but text did not change")
        return .continueWithPaste
    }

    private func verifyPaste(
        into element: AXUIElement,
        before: AccessibilityTextState?,
        expectedText: String
    ) -> Bool {
        guard let before,
              let after = textState(of: element),
              after.value != before.value else {
            return false
        }

        if after.value.contains(expectedText) {
            return true
        }

        let normalizedExpected = expectedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalizedExpected.count >= 12 else { return false }

        let prefix = String(normalizedExpected.prefix(12))
        let suffix = String(normalizedExpected.suffix(12))
        return after.value.contains(prefix) && after.value.contains(suffix)
    }

    private func textState(of element: AXUIElement) -> AccessibilityTextState? {
        guard let value = copyStringAttribute(kAXValueAttribute as CFString, from: element) else {
            return nil
        }

        return AccessibilityTextState(
            value: value,
            selectedRange: copySelectedRange(from: element)
        )
    }

    private func copySelectedRange(from element: AXUIElement) -> CFRange? {
        var attributeValue: CFTypeRef?
        let status = AXUIElementCopyAttributeValue(
            element,
            kAXSelectedTextRangeAttribute as CFString,
            &attributeValue
        )
        guard status == .success,
              let attributeValue,
              CFGetTypeID(attributeValue) == AXValueGetTypeID(),
              AXValueGetType(attributeValue as! AXValue) == .cfRange else {
            return nil
        }

        var range = CFRange()
        let success = AXValueGetValue(attributeValue as! AXValue, .cfRange, &range)
        return success ? range : nil
    }

    private func restoreSelectedRange(_ range: CFRange, on element: AXUIElement) -> Bool {
        guard isAttributeSettable(kAXSelectedTextRangeAttribute as CFString, on: element) else {
            return false
        }

        let stringLength = copyStringAttribute(kAXValueAttribute as CFString, from: element)
            .map { ($0 as NSString).length }
            ?? Int.max
        guard let normalizedRange = Self.normalizedRange(range, stringLength: stringLength) else {
            log("Skipping selection restore because range is out of bounds")
            return false
        }

        var mutableRange = normalizedRange
        guard let rangeValue = AXValueCreate(.cfRange, &mutableRange) else {
            return false
        }

        let status = AXUIElementSetAttributeValue(
            element,
            kAXSelectedTextRangeAttribute as CFString,
            rangeValue
        )
        guard status == .success else {
            log("Restoring selected-text range failed with AX status \(status.rawValue)")
            return false
        }

        guard let afterRange = copySelectedRange(from: element) else {
            return true
        }

        return Self.rangesEqual(afterRange, normalizedRange)
    }

    static func shouldPreferSelectedTextReplacement(
        role: String?,
        supportsSelectedTextReplacement: Bool
    ) -> Bool {
        supportsSelectedTextReplacement
    }

    static func shouldUseDirectValueInsert(
        role: String?,
        supportsSelectedTextReplacement: Bool
    ) -> Bool {
        guard !supportsSelectedTextReplacement, let role else { return false }
        return role == kAXTextFieldRole as String || role == kAXComboBoxRole as String
    }

    static func mutationMatches(
        beforeValue: String,
        beforeRange: CFRange?,
        afterValue: String,
        afterRange: CFRange?,
        replacement: String
    ) -> Bool {
        guard let insertionRange = normalizedRange(
            beforeRange,
            stringLength: (beforeValue as NSString).length
        ),
        let expectation = mutationExpectation(
            beforeValue: beforeValue,
            insertionRange: insertionRange,
            replacement: replacement
        ) else {
            return false
        }

        if normalizedText(afterValue) == normalizedText(expectation.expectedValue) {
            return true
        }

        let normalizedAfter = normalizedText(afterValue)
        let normalizedPrefix = normalizedText(expectation.prefixContext)
        let normalizedSuffix = normalizedText(expectation.suffixContext)
        let normalizedReplacement = normalizedText(replacement)

        if !normalizedReplacement.isEmpty {
            let anchored = normalizedPrefix + normalizedReplacement + normalizedSuffix
            if !anchored.isEmpty && normalizedAfter.contains(anchored) {
                return true
            }
        }

        guard normalizedText(afterValue) != normalizedText(beforeValue),
              let afterRange = normalizedRange(afterRange, stringLength: (afterValue as NSString).length) else {
            return false
        }

        return afterRange.location == expectation.expectedCaretLocation
            && afterRange.length == 0
            && normalizedAfter.contains(normalizedReplacement)
    }

    static func normalizedRange(_ range: CFRange?, stringLength: Int) -> CFRange? {
        guard stringLength >= 0 else { return nil }
        guard let range else {
            return stringLength == 0 ? CFRange(location: 0, length: 0) : nil
        }

        if range.location < 0 || range.location > stringLength {
            return nil
        }

        if range.length < 0 || range.location + range.length > stringLength {
            return nil
        }

        return range
    }

    private static func mutationExpectation(
        beforeValue: String,
        insertionRange: CFRange,
        replacement: String
    ) -> TextMutationExpectation? {
        let stringLength = (beforeValue as NSString).length
        guard let insertionRange = normalizedRange(insertionRange, stringLength: stringLength) else {
            return nil
        }

        let nsValue = beforeValue as NSString
        let range = NSRange(location: insertionRange.location, length: insertionRange.length)
        let expectedValue = nsValue.replacingCharacters(in: range, with: replacement)

        let prefixRange = NSRange(location: max(0, insertionRange.location - 24), length: min(24, insertionRange.location))
        let suffixStart = insertionRange.location + insertionRange.length
        let suffixRange = NSRange(location: suffixStart, length: min(24, stringLength - suffixStart))

        return TextMutationExpectation(
            expectedValue: expectedValue,
            replacement: replacement,
            prefixContext: nsValue.substring(with: prefixRange),
            suffixContext: nsValue.substring(with: suffixRange),
            expectedCaretLocation: insertionRange.location + (replacement as NSString).length
        )
    }

    static func normalizedText(_ text: String) -> String {
        text.replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
    }

    static func describe(range: CFRange?) -> String {
        guard let range else { return "nil" }
        return "{location=\(range.location), length=\(range.length)}"
    }

    static func rangesEqual(_ lhs: CFRange, _ rhs: CFRange) -> Bool {
        lhs.location == rhs.location && lhs.length == rhs.length
    }

    private func copyStringAttribute(_ attribute: CFString, from element: AXUIElement) -> String? {
        var attributeValue: CFTypeRef?
        let status = AXUIElementCopyAttributeValue(element, attribute, &attributeValue)
        guard status == .success, let value = attributeValue as? String else { return nil }
        return value
    }

    private func copyAXElementAttribute(_ attribute: CFString, from element: AXUIElement) -> AXUIElement? {
        var attributeValue: CFTypeRef?
        let status = AXUIElementCopyAttributeValue(element, attribute, &attributeValue)
        guard status == .success,
              let attributeValue,
              CFGetTypeID(attributeValue) == AXUIElementGetTypeID() else {
            return nil
        }
        return (attributeValue as! AXUIElement)
    }

    private func frame(of element: AXUIElement) -> CGRect? {
        var positionValue: CFTypeRef?
        var sizeValue: CFTypeRef?
        let positionStatus = AXUIElementCopyAttributeValue(
            element,
            kAXPositionAttribute as CFString,
            &positionValue
        )
        let sizeStatus = AXUIElementCopyAttributeValue(
            element,
            kAXSizeAttribute as CFString,
            &sizeValue
        )
        guard positionStatus == .success,
              sizeStatus == .success,
              let positionAXValue = positionValue,
              let sizeAXValue = sizeValue,
              CFGetTypeID(positionAXValue) == AXValueGetTypeID(),
              CFGetTypeID(sizeAXValue) == AXValueGetTypeID() else {
            return nil
        }

        var point = CGPoint.zero
        var size = CGSize.zero
        guard AXValueGetValue(positionAXValue as! AXValue, .cgPoint, &point),
              AXValueGetValue(sizeAXValue as! AXValue, .cgSize, &size) else {
            return nil
        }

        return CGRect(origin: point, size: size)
    }

    private func isAttributeSettable(_ attribute: CFString, on element: AXUIElement) -> Bool {
        var settable: DarwinBoolean = false
        let status = AXUIElementIsAttributeSettable(element, attribute, &settable)
        return status == .success && settable.boolValue
    }

    private static func contextsReferToSameElement(
        _ lhs: CapturedTargetContext,
        _ rhs: CapturedTargetContext
    ) -> Bool {
        if lhs.appSnapshot != rhs.appSnapshot { return false }
        switch (lhs.focusedElement, rhs.focusedElement) {
        case let (lhsElement?, rhsElement?):
            return CFEqual(lhsElement, rhsElement)
        case (nil, nil):
            return true
        default:
            return false
        }
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
            alert.informativeText = "MySTT needs Accessibility access to restore focus and paste dictated text into the original input field.\n\nGo to: System Settings → Privacy & Security → Accessibility\nand enable MySTT.\n\nYour text is already copied to the clipboard, so you can still paste it manually with Cmd+V."
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
            alert.informativeText = "MySTT needs Automation permission to paste text into other apps when Accessibility-based delivery cannot be verified.\n\nGo to: System Settings → Privacy & Security → Automation\nand enable \"System Events\" for MySTT.\n\nText is still copied to clipboard — you can paste manually with Cmd+V."
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

    private func rememberExternalApp(_ app: NSRunningApplication) {
        guard let snapshot = snapshotIfEligible(app) else { return }
        lastExternalApp = snapshot
    }

    private func snapshotIfEligible(_ app: NSRunningApplication) -> TargetAppSnapshot? {
        let snapshot = TargetAppSnapshot(
            processIdentifier: app.processIdentifier,
            localizedName: app.localizedName,
            bundleIdentifier: app.bundleIdentifier
        )

        guard !Self.isSelf(snapshot, selfBundleIdentifier: selfBundleIdentifier) else {
            return nil
        }

        return snapshot
    }

    static func selectTargetApp(
        frontmostApp: TargetAppSnapshot?,
        lastExternalApp: TargetAppSnapshot?
    ) -> TargetAppSnapshot? {
        frontmostApp ?? lastExternalApp
    }

    static func isSelf(_ snapshot: TargetAppSnapshot, selfBundleIdentifier: String?) -> Bool {
        guard let selfBundleIdentifier else { return false }
        return snapshot.bundleIdentifier == selfBundleIdentifier
    }
}
