import AVFoundation
import CoreAudio
import Combine

/// Manages microphone selection with auto-switch to newly connected devices
class MicrophoneManager: ObservableObject {
    struct Microphone: Identifiable, Equatable {
        let id: AudioDeviceID
        let name: String
        let uid: String
    }

    @Published var availableMicrophones: [Microphone] = []
    @Published var selectedMicrophone: Microphone?
    @Published var previousMicrophone: Microphone?

    private var listenerBlock: AudioObjectPropertyListenerBlock?
    private var isFirstRefresh = true

    init() {
        refreshDevices()
        startMonitoring()
    }

    deinit {
        stopMonitoring()
    }

    // MARK: - Device enumeration

    func refreshDevices() {
        let oldList = availableMicrophones
        availableMicrophones = Self.listInputDevices()

        print("[Mic] Devices: \(availableMicrophones.map { $0.name })")

        if isFirstRefresh {
            // First launch: read the current system default input device
            isFirstRefresh = false
            let systemDefault = getSystemDefaultInputDevice()
            if let defaultMic = availableMicrophones.first(where: { $0.id == systemDefault }) {
                selectedMicrophone = defaultMic
                print("[Mic] Initial: using system default → \(defaultMic.name)")
            } else {
                // System default not in list (virtual?), fall back to built-in
                selectedMicrophone = builtInMicrophone ?? availableMicrophones.first
                if let sel = selectedMicrophone {
                    setDefaultInputDevice(sel.id)
                    print("[Mic] Initial: system default not found, using → \(sel.name)")
                }
            }
            return
        }

        // Not first refresh: check for newly connected devices
        let newDevices = availableMicrophones.filter { mic in !oldList.contains(mic) }
        if let newDevice = newDevices.first {
            previousMicrophone = selectedMicrophone
            selectedMicrophone = newDevice
            setDefaultInputDevice(newDevice.id)
            print("[Mic] Auto-switched to new device: \(newDevice.name)")
        }

        // If selected device was removed, revert
        if let sel = selectedMicrophone, !availableMicrophones.contains(sel) {
            let fallback: Microphone?
            if let prev = previousMicrophone, availableMicrophones.contains(prev) {
                fallback = prev
                print("[Mic] Reverted to previous: \(prev.name)")
            } else {
                fallback = builtInMicrophone ?? availableMicrophones.first
                print("[Mic] Reverted to default: \(fallback?.name ?? "none")")
            }
            selectedMicrophone = fallback
            if let fb = fallback {
                setDefaultInputDevice(fb.id)
            }
            previousMicrophone = nil
        }
    }

    /// Returns the built-in MacBook microphone if available
    private var builtInMicrophone: Microphone? {
        availableMicrophones.first { mic in
            mic.uid.localizedCaseInsensitiveContains("BuiltIn") ||
            mic.name.localizedCaseInsensitiveContains("MacBook") ||
            mic.name.localizedCaseInsensitiveContains("Built-in") ||
            mic.name.localizedCaseInsensitiveContains("Mikrofon")
        }
    }

    func selectMicrophone(_ mic: Microphone) {
        previousMicrophone = selectedMicrophone
        selectedMicrophone = mic
        setDefaultInputDevice(mic.id)
        print("[Mic] User selected: \(mic.name)")
    }

    // MARK: - System default input device

    private func getSystemDefaultInputDevice() -> AudioDeviceID {
        var defaultID: AudioDeviceID = 0
        var propAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &propAddress, 0, nil, &size, &defaultID)
        return defaultID
    }

    private func setDefaultInputDevice(_ deviceID: AudioDeviceID) {
        var propAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var deviceIDVar = deviceID
        let status = AudioObjectSetPropertyData(
            AudioObjectID(kAudioObjectSystemObject), &propAddress, 0, nil,
            UInt32(MemoryLayout<AudioDeviceID>.size), &deviceIDVar
        )
        if status != noErr {
            print("[Mic] Failed to set default input device (error \(status))")
        }
    }

    // MARK: - CoreAudio device listing

    static func listInputDevices() -> [Microphone] {
        var propAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var dataSize: UInt32 = 0
        AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &propAddress, 0, nil, &dataSize)

        let deviceCount = Int(dataSize) / MemoryLayout<AudioDeviceID>.size
        var deviceIDs = [AudioDeviceID](repeating: 0, count: deviceCount)
        AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &propAddress, 0, nil, &dataSize, &deviceIDs)

        return deviceIDs.compactMap { deviceID -> Microphone? in
            // Check if device has input channels
            var inputAddress = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyStreamConfiguration,
                mScope: kAudioDevicePropertyScopeInput,
                mElement: kAudioObjectPropertyElementMain
            )
            var inputSize: UInt32 = 0
            AudioObjectGetPropertyDataSize(deviceID, &inputAddress, 0, nil, &inputSize)
            guard inputSize > 0 else { return nil }

            let bufferListPtr = UnsafeMutablePointer<AudioBufferList>.allocate(capacity: 1)
            defer { bufferListPtr.deallocate() }
            AudioObjectGetPropertyData(deviceID, &inputAddress, 0, nil, &inputSize, bufferListPtr)

            let bufferList = UnsafeMutableAudioBufferListPointer(bufferListPtr)
            let inputChannels = bufferList.reduce(0) { $0 + Int($1.mNumberChannels) }
            guard inputChannels > 0 else { return nil }

            // Get device name
            var nameAddress = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyDeviceNameCFString,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain
            )
            var nameRef: CFString = "" as CFString
            var nameSize = UInt32(MemoryLayout<CFString>.size)
            AudioObjectGetPropertyData(deviceID, &nameAddress, 0, nil, &nameSize, &nameRef)

            // Get UID
            var uidAddress = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyDeviceUID,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain
            )
            var uidRef: CFString = "" as CFString
            var uidSize = UInt32(MemoryLayout<CFString>.size)
            AudioObjectGetPropertyData(deviceID, &uidAddress, 0, nil, &uidSize, &uidRef)

            let name = nameRef as String
            let uid = uidRef as String

            // Filter out virtual/aggregate devices
            let isVirtual = uid.contains("CADefaultDeviceAggregate") ||
                            uid.contains("AggregateDevice") ||
                            name.contains("CADefaultDeviceAggregate") ||
                            name.contains("AggregateDevice")
            guard !isVirtual else { return nil }

            return Microphone(id: deviceID, name: name, uid: uid)
        }
    }

    // MARK: - Monitor device changes

    private func startMonitoring() {
        var propAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        let block: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
            DispatchQueue.main.async {
                self?.refreshDevices()
            }
        }
        self.listenerBlock = block

        AudioObjectAddPropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject), &propAddress,
            DispatchQueue.main, block
        )
    }

    private func stopMonitoring() {
        guard let block = listenerBlock else { return }
        var propAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        AudioObjectRemovePropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject), &propAddress,
            DispatchQueue.main, block
        )
    }
}
