import Cocoa
import Carbon

class HotkeyManager: ObservableObject {
    @Published var isEnabled = true
    @Published var isRecordingActive = false

    var onRecordingStart: (() -> Void)?
    var onRecordingStop: (() -> Void)?
    var onCancel: (() -> Void)?

    private var fnMonitor: Any?
    private var localFnMonitor: Any?
    private var escMonitor: Any?
    private var localEscMonitor: Any?
    private var monitoredKeyCode: UInt16

    /// true = tap to speak (toggle), false = hold to speak (push-to-talk)
    private var toggleMode: Bool = true

    init(keyCode: UInt16 = KeyCodes.function) {
        self.monitoredKeyCode = keyCode
        self.toggleMode = UserDefaults.standard.object(forKey: "hotkeyToggleMode") as? Bool ?? true
    }

    func start() {
        setupFnMonitor()
        setupEscMonitor()
        print("[HotkeyManager] Started. Key: \(KeyCodes.name(for: monitoredKeyCode)), mode: \(toggleMode ? "tap" : "hold")")
    }

    func stop() {
        if let m = fnMonitor { NSEvent.removeMonitor(m); fnMonitor = nil }
        if let m = localFnMonitor { NSEvent.removeMonitor(m); localFnMonitor = nil }
        if let m = escMonitor { NSEvent.removeMonitor(m); escMonitor = nil }
        if let m = localEscMonitor { NSEvent.removeMonitor(m); localEscMonitor = nil }
    }

    func updateKeyCode(_ keyCode: UInt16) {
        stop()
        monitoredKeyCode = keyCode
        reloadToggleMode()
        start()
    }

    func reloadToggleMode() {
        toggleMode = UserDefaults.standard.object(forKey: "hotkeyToggleMode") as? Bool ?? true
        print("[HotkeyManager] Mode: \(toggleMode ? "tap" : "hold")")
    }

    // MARK: - Fn/Globe monitor

    private func setupFnMonitor() {
        guard fnMonitor == nil else { return }

        fnMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagsChanged(event)
        }

        localFnMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            guard let self = self else { return event }
            self.handleFlagsChanged(event)
            // Consume Fn key events when in our app
            if self.monitoredKeyCode == KeyCodes.function && self.isEnabled {
                return nil
            }
            return event
        }
    }

    private func handleFlagsChanged(_ event: NSEvent) {
        guard isEnabled else { return }

        if monitoredKeyCode == KeyCodes.function {
            let fnPressed = event.modifierFlags.contains(.function)
            if toggleMode {
                // Tap mode: only react on key-down
                if fnPressed { handleToggle() }
            } else {
                // Hold mode: start on key-down, stop on key-up
                handleHold(pressed: fnPressed)
            }
            return
        }

        // Other modifier keys
        let keyCode = event.keyCode
        if keyCode == monitoredKeyCode {
            let isPressed: Bool
            switch keyCode {
            case KeyCodes.rightOption, KeyCodes.leftOption:
                isPressed = event.modifierFlags.contains(.option)
            case KeyCodes.rightCommand, KeyCodes.leftCommand:
                isPressed = event.modifierFlags.contains(.command)
            default:
                isPressed = false
            }

            if toggleMode {
                if isPressed { handleToggle() }
            } else {
                handleHold(pressed: isPressed)
            }
        }
    }

    // MARK: - ESC key monitor (cancel)

    private func setupEscMonitor() {
        guard escMonitor == nil else { return }

        escMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == KeyCodes.escape {
                DispatchQueue.main.async { self?.onCancel?() }
            }
        }

        localEscMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == KeyCodes.escape {
                DispatchQueue.main.async { self?.onCancel?() }
                return nil
            }
            return event
        }
    }

    // MARK: - Tap mode (toggle)

    private func handleToggle() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if self.isRecordingActive {
                self.isRecordingActive = false
                self.onRecordingStop?()
            } else {
                self.isRecordingActive = true
                self.onRecordingStart?()
            }
        }
    }

    // MARK: - Hold mode (push-to-talk)

    private func handleHold(pressed: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if pressed && !self.isRecordingActive {
                self.isRecordingActive = true
                self.onRecordingStart?()
            } else if !pressed && self.isRecordingActive {
                self.isRecordingActive = false
                self.onRecordingStop?()
            }
        }
    }

    deinit { stop() }
}
