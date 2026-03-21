import Cocoa
import AVFoundation

class PermissionChecker {
    /// Check if Accessibility permission is granted
    /// Only set prompt=true for the very first check; after that, check silently
    static func checkAccessibilityPermission(prompt: Bool = false) -> Bool {
        if prompt {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
            return AXIsProcessTrustedWithOptions(options)
        } else {
            // Silent check — no dialog
            return AXIsProcessTrusted()
        }
    }

    /// Request microphone permission
    static func requestMicrophonePermission() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        switch status {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .audio)
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }

    /// Check microphone permission status without requesting
    static func microphonePermissionStatus() -> AVAuthorizationStatus {
        AVCaptureDevice.authorizationStatus(for: .audio)
    }

    /// Open System Settings to Accessibility pane
    static func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    /// Open System Settings to Microphone pane
    static func openMicrophoneSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") {
            NSWorkspace.shared.open(url)
        }
    }
}
