import AppKit

class SoundPlayer {
    private var isEnabled: Bool

    init(isEnabled: Bool = true) {
        self.isEnabled = isEnabled
    }

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
    }

    func playStartRecording() {
        play(name: "Tink")
    }

    func playStopRecording() {
        play(name: "Pop")
    }

    func playSuccess() {
        play(name: "Glass")
    }

    func playError() {
        play(name: "Basso")
    }

    private func play(name: String) {
        guard isEnabled else { return }
        NSSound(named: name)?.play()
    }
}
