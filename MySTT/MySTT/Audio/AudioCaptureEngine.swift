import AVFoundation
import CoreAudio
import Combine

class AudioCaptureEngine: ObservableObject {
    @Published var isRecording = false

    private var audioEngine = AVAudioEngine()
    private var audioBuffers: [AVAudioPCMBuffer] = []
    private let targetFormat: AVAudioFormat
    private var micPermissionGranted = false

    init() {
        targetFormat = AVAudioFormat(standardFormatWithSampleRate: 16000, channels: 1)!
        checkMicPermission()
    }

    private func checkMicPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        micPermissionGranted = (status == .authorized)
    }

    func ensureMicPermission() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        switch status {
        case .authorized:
            micPermissionGranted = true
            return true
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .audio)
            micPermissionGranted = granted
            return granted
        default:
            micPermissionGranted = false
            return false
        }
    }

    func startRecording() throws {
        guard !isRecording else { return }
        audioBuffers = []

        // Always create fresh engine to pick up the current system default input device
        audioEngine.stop()
        audioEngine = AVAudioEngine()

        // Try to use a working microphone — test default first, fall back to built-in
        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)

        guard inputFormat.sampleRate > 0, inputFormat.channelCount > 0 else {
            throw NSError(domain: "AudioCaptureEngine", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "No microphone available or invalid format"])
        }

        print("[AudioCapture] Using input: \(inputFormat.sampleRate)Hz \(inputFormat.channelCount)ch")

        inputNode.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { [weak self] buffer, _ in
            guard let self = self else { return }
            if inputFormat.sampleRate != self.targetFormat.sampleRate || inputFormat.channelCount != self.targetFormat.channelCount {
                if let converted = self.convertBuffer(buffer, from: inputFormat, to: self.targetFormat) {
                    self.audioBuffers.append(converted)
                }
            } else {
                // Copy buffer — the tap's buffer memory is reused after callback returns
                if let copy = AVAudioPCMBuffer(pcmFormat: buffer.format, frameCapacity: buffer.frameLength) {
                    copy.frameLength = buffer.frameLength
                    if let src = buffer.floatChannelData, let dst = copy.floatChannelData {
                        for ch in 0..<Int(buffer.format.channelCount) {
                            memcpy(dst[ch], src[ch], Int(buffer.frameLength) * MemoryLayout<Float>.size)
                        }
                    }
                    self.audioBuffers.append(copy)
                }
            }
        }

        audioEngine.prepare()
        try audioEngine.start()
        DispatchQueue.main.async { self.isRecording = true }
    }

    func stopRecording() -> AVAudioPCMBuffer? {
        guard isRecording else { return nil }

        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        DispatchQueue.main.async { self.isRecording = false }

        let buffers = audioBuffers
        audioBuffers = []
        return mergeBuffers(buffers)
    }

    /// Check if an audio buffer contains actual audio signal (not silence)
    static func hasAudioSignal(_ buffer: AVAudioPCMBuffer, threshold: Float = 0.0001) -> Bool {
        guard let data = buffer.floatChannelData?[0] else { return false }
        let count = Int(buffer.frameLength)
        for i in 0..<count {
            if abs(data[i]) > threshold { return true }
        }
        return false
    }

    /// Get the name of the current default input device
    static func defaultInputDeviceName() -> String {
        var addr = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var deviceID: AudioDeviceID = 0
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &addr, 0, nil, &size, &deviceID)

        var nameAddr = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertyName,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var name: CFString = "" as CFString
        var nameSize = UInt32(MemoryLayout<CFString>.size)
        AudioObjectGetPropertyData(deviceID, &nameAddr, 0, nil, &nameSize, &name)
        return name as String
    }

    // MARK: - Private

    private func convertBuffer(_ buffer: AVAudioPCMBuffer, from inputFormat: AVAudioFormat, to outputFormat: AVAudioFormat) -> AVAudioPCMBuffer? {
        guard let converter = AVAudioConverter(from: inputFormat, to: outputFormat) else { return nil }
        let ratio = outputFormat.sampleRate / inputFormat.sampleRate
        let outputFrameCount = AVAudioFrameCount(Double(buffer.frameLength) * ratio)
        guard outputFrameCount > 0 else { return nil }
        guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: outputFrameCount) else { return nil }

        var error: NSError?
        var consumed = false
        let inputBlock: AVAudioConverterInputBlock = { _, outStatus in
            if consumed { outStatus.pointee = .noDataNow; return nil }
            consumed = true
            outStatus.pointee = .haveData
            return buffer
        }
        converter.convert(to: outputBuffer, error: &error, withInputFrom: inputBlock)
        return error == nil ? outputBuffer : nil
    }

    private func mergeBuffers(_ buffers: [AVAudioPCMBuffer]) -> AVAudioPCMBuffer? {
        guard !buffers.isEmpty else { return nil }
        let totalFrames = buffers.reduce(AVAudioFrameCount(0)) { $0 + $1.frameLength }
        guard totalFrames > 0 else { return nil }
        guard let merged = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: totalFrames) else { return nil }

        var offset: AVAudioFrameCount = 0
        for buffer in buffers {
            guard let src = buffer.floatChannelData?[0], let dst = merged.floatChannelData?[0] else { continue }
            let count = Int(buffer.frameLength)
            guard count > 0 else { continue }
            memcpy(dst.advanced(by: Int(offset)), src, count * MemoryLayout<Float>.size)
            offset += buffer.frameLength
        }
        merged.frameLength = totalFrames
        return merged
    }
}
