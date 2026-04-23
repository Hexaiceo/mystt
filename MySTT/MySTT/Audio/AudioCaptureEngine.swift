import AVFoundation
import AudioToolbox
import CoreAudio
import Combine

class AudioCaptureEngine: ObservableObject {
    struct SignalAnalysis: Equatable {
        let peakAmplitude: Float
        let rmsAmplitude: Float
        let nonSilentFrameRatio: Float
        let speechFrameRatio: Float
        let frameCount: Int

        var hasAnySignal: Bool {
            peakAmplitude >= 0.0001 || rmsAmplitude >= 0.00003 || nonSilentFrameRatio >= 0.003
        }

        var hasSpeechLikeSignal: Bool {
            peakAmplitude >= 0.0015 || rmsAmplitude >= 0.00025 || speechFrameRatio >= 0.01
        }
    }

    @Published var isRecording = false

    private var audioEngine = AVAudioEngine()
    private var audioBuffers: [AVAudioPCMBuffer] = []
    private let audioBuffersLock = NSLock()
    private let targetFormat: AVAudioFormat
    private var micPermissionGranted = false
    private(set) var activeInputDeviceID: AudioDeviceID?
    private(set) var activeInputDeviceName: String = "Unknown"
    private var activeRecordingSessionID: UInt64 = 0
    private var nextRecordingSessionID: UInt64 = 0

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

    func startRecording(deviceID: AudioDeviceID? = nil) throws {
        guard !isRecording else { return }
        let sessionID = beginRecordingSession()

        // Always create a fresh engine so a newly selected device can be bound cleanly.
        audioEngine.stop()
        audioEngine = AVAudioEngine()

        let inputNode = audioEngine.inputNode
        let preferredDeviceID = deviceID ?? Self.defaultInputDeviceID()

        if let preferredDeviceID {
            try bindInputDevice(preferredDeviceID, on: inputNode)
            activeInputDeviceID = preferredDeviceID
        } else {
            activeInputDeviceID = nil
        }

        let resolvedDeviceID = activeInputDeviceID ?? Self.defaultInputDeviceID()
        activeInputDeviceID = resolvedDeviceID
        activeInputDeviceName = resolvedDeviceID.flatMap(Self.deviceName(for:)) ?? "Unknown"
        let inputFormat = inputNode.outputFormat(forBus: 0)

        guard inputFormat.sampleRate > 0, inputFormat.channelCount > 0 else {
            throw NSError(domain: "AudioCaptureEngine", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "No microphone available or invalid format"])
        }

        print("[AudioCapture] Using input '\(activeInputDeviceName)': \(inputFormat.sampleRate)Hz \(inputFormat.channelCount)ch")

        inputNode.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { [weak self] buffer, _ in
            guard let self = self else { return }
            if inputFormat.sampleRate != self.targetFormat.sampleRate || inputFormat.channelCount != self.targetFormat.channelCount {
                if let converted = self.convertBuffer(buffer, from: inputFormat, to: self.targetFormat) {
                    self.appendAudioBuffer(converted, forSessionID: sessionID)
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
                    self.appendAudioBuffer(copy, forSessionID: sessionID)
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
        let buffers = drainAudioBuffersAndDeactivateSession()
        return mergeBuffers(buffers)
    }

    /// Check if an audio buffer contains actual audio signal (not silence)
    static func hasAudioSignal(_ buffer: AVAudioPCMBuffer, threshold: Float = 0.0001) -> Bool {
        analyzeSignal(buffer, silenceThreshold: threshold).hasAnySignal
    }

    static func analyzeSignal(
        _ buffer: AVAudioPCMBuffer,
        silenceThreshold: Float = 0.0001,
        speechThreshold: Float = 0.0015
    ) -> SignalAnalysis {
        guard let data = buffer.floatChannelData?[0] else {
            return SignalAnalysis(
                peakAmplitude: 0,
                rmsAmplitude: 0,
                nonSilentFrameRatio: 0,
                speechFrameRatio: 0,
                frameCount: 0
            )
        }
        let count = Int(buffer.frameLength)
        guard count > 0 else {
            return SignalAnalysis(
                peakAmplitude: 0,
                rmsAmplitude: 0,
                nonSilentFrameRatio: 0,
                speechFrameRatio: 0,
                frameCount: 0
            )
        }

        var peakAmplitude: Float = 0
        var squaredSum: Float = 0
        var nonSilentFrames = 0
        var speechFrames = 0

        for i in 0..<count {
            let amplitude = abs(data[i])
            peakAmplitude = max(peakAmplitude, amplitude)
            squaredSum += amplitude * amplitude
            if amplitude > silenceThreshold { nonSilentFrames += 1 }
            if amplitude > speechThreshold { speechFrames += 1 }
        }

        let rmsAmplitude = sqrt(squaredSum / Float(count))
        return SignalAnalysis(
            peakAmplitude: peakAmplitude,
            rmsAmplitude: rmsAmplitude,
            nonSilentFrameRatio: Float(nonSilentFrames) / Float(count),
            speechFrameRatio: Float(speechFrames) / Float(count),
            frameCount: count
        )
    }

    static func defaultInputDeviceID() -> AudioDeviceID? {
        var addr = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var deviceID: AudioDeviceID = 0
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        let status = AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &addr, 0, nil, &size, &deviceID)
        guard status == noErr, deviceID != 0 else { return nil }
        return deviceID
    }

    static func deviceName(for deviceID: AudioDeviceID) -> String? {
        stringProperty(selector: kAudioObjectPropertyName, for: deviceID) ??
        stringProperty(selector: kAudioDevicePropertyDeviceNameCFString, for: deviceID)
    }

    // MARK: - Private

    private func bindInputDevice(_ deviceID: AudioDeviceID, on inputNode: AVAudioInputNode) throws {
        guard let audioUnit = inputNode.audioUnit else {
            throw NSError(
                domain: "AudioCaptureEngine",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "Unable to access the audio input unit"]
            )
        }

        var mutableDeviceID = deviceID
        let status = AudioUnitSetProperty(
            audioUnit,
            kAudioOutputUnitProperty_CurrentDevice,
            kAudioUnitScope_Global,
            0,
            &mutableDeviceID,
            UInt32(MemoryLayout<AudioDeviceID>.size)
        )
        guard status == noErr else {
            throw NSError(
                domain: "AudioCaptureEngine",
                code: Int(status),
                userInfo: [NSLocalizedDescriptionKey: "Unable to select microphone (Core Audio error \(status))"]
            )
        }
    }

    private static func stringProperty(selector: AudioObjectPropertySelector, for deviceID: AudioDeviceID) -> String? {
        var address = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var value: Unmanaged<CFString>?
        var size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
        let status = withUnsafeMutablePointer(to: &value) { ptr in
            AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, ptr)
        }
        guard status == noErr, let value else { return nil }
        return value.takeUnretainedValue() as String
    }

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

    private func beginRecordingSession() -> UInt64 {
        audioBuffersLock.lock()
        defer { audioBuffersLock.unlock() }
        audioBuffers = []
        nextRecordingSessionID &+= 1
        activeRecordingSessionID = nextRecordingSessionID
        return activeRecordingSessionID
    }

    private func appendAudioBuffer(_ buffer: AVAudioPCMBuffer, forSessionID sessionID: UInt64) {
        audioBuffersLock.lock()
        defer { audioBuffersLock.unlock() }
        guard activeRecordingSessionID == sessionID else { return }
        audioBuffers.append(buffer)
    }

    private func drainAudioBuffersAndDeactivateSession() -> [AVAudioPCMBuffer] {
        audioBuffersLock.lock()
        defer { audioBuffersLock.unlock() }
        let buffers = audioBuffers
        audioBuffers = []
        activeRecordingSessionID = 0
        return buffers
    }
}
