import AVFoundation
import CoreAudio
import Combine

/// Manages the app's microphone preference independently from the macOS global default.
class MicrophoneManager: ObservableObject {
    struct Microphone: Identifiable, Equatable {
        let id: AudioDeviceID
        let name: String
        let uid: String
        let transportType: UInt32

        var isBuiltIn: Bool {
            transportType == kAudioDeviceTransportTypeBuiltIn ||
            uid.localizedCaseInsensitiveContains("BuiltIn") ||
            name.localizedCaseInsensitiveContains("MacBook") ||
            name.localizedCaseInsensitiveContains("Built-in") ||
            name.localizedCaseInsensitiveContains("Mikrofon")
        }

        var isContinuity: Bool {
            transportType == kAudioDeviceTransportTypeContinuityCaptureWired ||
            transportType == kAudioDeviceTransportTypeContinuityCaptureWireless ||
            uid.localizedCaseInsensitiveContains("iPhone") ||
            uid.localizedCaseInsensitiveContains("Continuity") ||
            name.localizedCaseInsensitiveContains("iPhone") ||
            name.localizedCaseInsensitiveContains("Continuity")
        }

        var isVirtual: Bool {
            transportType == kAudioDeviceTransportTypeVirtual
        }

        var isAggregate: Bool {
            uid.contains("CADefaultDeviceAggregate") ||
            uid.contains("AggregateDevice") ||
            name.contains("CADefaultDeviceAggregate") ||
            name.contains("AggregateDevice")
        }

        var automaticPriority: Int {
            if isBuiltIn { return 0 }
            if !isContinuity && !isVirtual { return 1 }
            if isContinuity { return 2 }
            return 3
        }

    }

    enum SelectionMode {
        case automatic
        case manual
    }

    enum SelectionDecision: Equatable {
        case keepCurrent(Microphone)
        case selectPreferred(Microphone)
        case autoSwitchToNewDevice(Microphone)
        case selectFallback(Microphone)
        case clearSelection
    }

    @Published var availableMicrophones: [Microphone] = []
    @Published var selectedMicrophone: Microphone?
    @Published var previousMicrophone: Microphone?

    private var listenerBlock: AudioObjectPropertyListenerBlock?
    private var isFirstRefresh = true
    private var selectionMode: SelectionMode = .automatic

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
        let oldSelection = selectedMicrophone
        availableMicrophones = Self.listInputDevices()

        print("[Mic] Devices: \(availableMicrophones.map { $0.name })")
        let decision = Self.selectionDecision(
            oldMicrophones: oldList,
            newMicrophones: availableMicrophones,
            currentSelection: oldSelection,
            selectionMode: selectionMode,
            isFirstRefresh: isFirstRefresh
        )
        isFirstRefresh = false

        applySelectionDecision(decision, previousSelection: oldSelection)
    }

    func selectMicrophone(_ mic: Microphone) {
        previousMicrophone = selectedMicrophone
        selectedMicrophone = mic
        selectionMode = .manual
        print("[Mic] User selected: \(mic.name)")
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

            guard
                let name = stringProperty(
                    selector: kAudioDevicePropertyDeviceNameCFString,
                    for: deviceID
                ),
                let uid = stringProperty(
                    selector: kAudioDevicePropertyDeviceUID,
                    for: deviceID
                ),
                let transportType = uint32Property(
                    selector: kAudioDevicePropertyTransportType,
                    for: deviceID
                )
            else {
                return nil
            }

            // Filter out virtual/aggregate devices
            let microphone = Microphone(
                id: deviceID,
                name: name,
                uid: uid,
                transportType: transportType
            )
            guard !microphone.isAggregate else { return nil }

            return microphone
        }
        .sorted(by: automaticSort)
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

    private static func uint32Property(selector: AudioObjectPropertySelector, for deviceID: AudioDeviceID) -> UInt32? {
        var address = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var value: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        let status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &value)
        guard status == noErr else { return nil }
        return value
    }

    // MARK: - Monitor device changes

    static func selectionDecision(
        oldMicrophones _: [Microphone],
        newMicrophones: [Microphone],
        currentSelection: Microphone?,
        selectionMode: SelectionMode,
        isFirstRefresh: Bool
    ) -> SelectionDecision {
        let refreshedCurrentSelection = currentSelection.flatMap { current in
            newMicrophones.first { $0.uid == current.uid }
        }

        if selectionMode == .manual, let refreshedCurrentSelection {
            return .keepCurrent(refreshedCurrentSelection)
        }

        if let refreshedCurrentSelection {
            if let preferred = preferredAutomaticMicrophone(in: newMicrophones),
               preferred.uid != refreshedCurrentSelection.uid,
               preferred.automaticPriority < refreshedCurrentSelection.automaticPriority {
                return .selectFallback(preferred)
            }
            return .keepCurrent(refreshedCurrentSelection)
        }

        if let preferred = preferredAutomaticMicrophone(in: newMicrophones) {
            return isFirstRefresh ? .selectPreferred(preferred) : .selectFallback(preferred)
        }

        return .clearSelection
    }

    private func applySelectionDecision(_ decision: SelectionDecision, previousSelection: Microphone?) {
        switch decision {
        case .keepCurrent(let microphone):
            if selectedMicrophone != microphone {
                selectedMicrophone = microphone
            }
            return
        case .selectPreferred(let microphone):
            previousMicrophone = previousSelection
            selectedMicrophone = microphone
            selectionMode = .automatic
            print("[Mic] Preferred automatic microphone → \(microphone.name)")
        case .autoSwitchToNewDevice(let microphone):
            previousMicrophone = previousSelection
            selectedMicrophone = microphone
            selectionMode = .automatic
            print("[Mic] Auto-switched to newly connected microphone → \(microphone.name)")
        case .selectFallback(let microphone):
            previousMicrophone = previousSelection
            selectedMicrophone = microphone
            selectionMode = .automatic
            print("[Mic] Falling back to preferred microphone → \(microphone.name)")
        case .clearSelection:
            previousMicrophone = previousSelection
            selectedMicrophone = nil
            selectionMode = .automatic
            print("[Mic] No microphones available")
        }
    }

    private static func preferredAutomaticMicrophone(in microphones: [Microphone]) -> Microphone? {
        microphones.sorted(by: automaticSort).first
    }

    private static func automaticSort(lhs: Microphone, rhs: Microphone) -> Bool {
        if lhs.automaticPriority != rhs.automaticPriority {
            return lhs.automaticPriority < rhs.automaticPriority
        }
        return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
    }

    private func startMonitoring() {
        var devicesAddress = AudioObjectPropertyAddress(
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
            AudioObjectID(kAudioObjectSystemObject), &devicesAddress,
            DispatchQueue.main, block
        )
    }

    private func stopMonitoring() {
        guard let block = listenerBlock else { return }
        var devicesAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        AudioObjectRemovePropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject), &devicesAddress,
            DispatchQueue.main, block
        )
    }
}
