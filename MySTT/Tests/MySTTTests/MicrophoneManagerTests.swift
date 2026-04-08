import XCTest
import CoreAudio
@testable import MySTT

final class MicrophoneManagerTests: XCTestCase {
    private func mic(
        _ id: AudioDeviceID,
        _ name: String,
        uid: String? = nil,
        transportType: UInt32 = kAudioDeviceTransportTypeUSB
    ) -> MicrophoneManager.Microphone {
        MicrophoneManager.Microphone(
            id: id,
            name: name,
            uid: uid ?? "uid-\(id)",
            transportType: transportType
        )
    }

    func test_selectionDecision_initialRefreshPrefersBuiltInOverContinuity() {
        let builtIn = mic(
            1,
            "MacBook Pro Microphone",
            uid: "BuiltIn-1",
            transportType: kAudioDeviceTransportTypeBuiltIn
        )
        let iPhone = mic(
            2,
            "iPhone Microphone",
            uid: "Continuity-1",
            transportType: kAudioDeviceTransportTypeContinuityCaptureWireless
        )

        let decision = MicrophoneManager.selectionDecision(
            oldMicrophones: [],
            newMicrophones: [builtIn, iPhone],
            currentSelection: nil,
            selectionMode: .automatic,
            isFirstRefresh: true
        )

        XCTAssertEqual(decision, MicrophoneManager.SelectionDecision.selectPreferred(builtIn))
    }

    func test_selectionDecision_initialRefreshUsesContinuityWhenItIsTheOnlyRealMic() {
        let iPhone = mic(
            2,
            "iPhone Microphone",
            uid: "Continuity-1",
            transportType: kAudioDeviceTransportTypeContinuityCaptureWireless
        )

        let decision = MicrophoneManager.selectionDecision(
            oldMicrophones: [],
            newMicrophones: [iPhone],
            currentSelection: nil,
            selectionMode: .automatic,
            isFirstRefresh: true
        )

        XCTAssertEqual(decision, MicrophoneManager.SelectionDecision.selectPreferred(iPhone))
    }

    func test_selectionDecision_doesNotAutoSwitchToNewlyDiscoveredContinuityMicrophone() {
        let builtIn = mic(
            1,
            "MacBook Pro Microphone",
            uid: "BuiltIn-1",
            transportType: kAudioDeviceTransportTypeBuiltIn
        )
        let iPhone = mic(
            2,
            "iPhone Microphone",
            uid: "Continuity-1",
            transportType: kAudioDeviceTransportTypeContinuityCaptureWireless
        )

        let decision = MicrophoneManager.selectionDecision(
            oldMicrophones: [builtIn],
            newMicrophones: [builtIn, iPhone],
            currentSelection: builtIn,
            selectionMode: .automatic,
            isFirstRefresh: false
        )

        XCTAssertEqual(decision, MicrophoneManager.SelectionDecision.keepCurrent(builtIn))
    }

    func test_selectionDecision_keepsBuiltInWhenNewExternalMicrophoneAppears() {
        let builtIn = mic(
            1,
            "MacBook Pro Microphone",
            uid: "BuiltIn-1",
            transportType: kAudioDeviceTransportTypeBuiltIn
        )
        let iPhone = mic(
            2,
            "iPhone Microphone",
            uid: "Continuity-1",
            transportType: kAudioDeviceTransportTypeContinuityCaptureWireless
        )
        let usb = mic(3, "USB Mic")

        let decision = MicrophoneManager.selectionDecision(
            oldMicrophones: [builtIn, iPhone],
            newMicrophones: [builtIn, iPhone, usb],
            currentSelection: builtIn,
            selectionMode: .automatic,
            isFirstRefresh: false
        )

        XCTAssertEqual(decision, MicrophoneManager.SelectionDecision.keepCurrent(builtIn))
    }

    func test_selectionDecision_keepsBuiltInWhenMonitorMicrophoneAppears() {
        let builtIn = mic(
            1,
            "MacBook Pro Microphone",
            uid: "BuiltIn-1",
            transportType: kAudioDeviceTransportTypeBuiltIn
        )
        let monitor = mic(
            2,
            "LG UltraFine Display Audio",
            uid: "Monitor-1",
            transportType: kAudioDeviceTransportTypeUSB
        )

        let decision = MicrophoneManager.selectionDecision(
            oldMicrophones: [builtIn],
            newMicrophones: [builtIn, monitor],
            currentSelection: builtIn,
            selectionMode: .automatic,
            isFirstRefresh: false
        )

        XCTAssertEqual(decision, MicrophoneManager.SelectionDecision.keepCurrent(builtIn))
    }

    func test_selectionDecision_keepsManualSelectionWhenContinuityAppears() {
        let builtIn = mic(
            1,
            "MacBook Pro Microphone",
            uid: "BuiltIn-1",
            transportType: kAudioDeviceTransportTypeBuiltIn
        )
        let usb = mic(2, "USB Mic", uid: "USB-1", transportType: kAudioDeviceTransportTypeUSB)
        let iPhone = mic(
            3,
            "iPhone Microphone",
            uid: "Continuity-1",
            transportType: kAudioDeviceTransportTypeContinuityCaptureWireless
        )

        let decision = MicrophoneManager.selectionDecision(
            oldMicrophones: [builtIn, usb],
            newMicrophones: [builtIn, usb, iPhone],
            currentSelection: usb,
            selectionMode: .manual,
            isFirstRefresh: false
        )

        XCTAssertEqual(decision, MicrophoneManager.SelectionDecision.keepCurrent(usb))
    }

    func test_selectionDecision_removedManualMicrophoneFallsBackToBuiltIn() {
        let builtIn = mic(
            1,
            "MacBook Pro Microphone",
            uid: "BuiltIn-1",
            transportType: kAudioDeviceTransportTypeBuiltIn
        )
        let usb = mic(2, "USB Mic", uid: "USB-1", transportType: kAudioDeviceTransportTypeUSB)

        let decision = MicrophoneManager.selectionDecision(
            oldMicrophones: [builtIn, usb],
            newMicrophones: [builtIn],
            currentSelection: usb,
            selectionMode: .manual,
            isFirstRefresh: false
        )

        XCTAssertEqual(decision, MicrophoneManager.SelectionDecision.selectFallback(builtIn))
    }

    func test_selectionDecision_automaticContinuitySelectionFallsBackToBuiltInWhenAvailable() {
        let builtIn = mic(
            1,
            "MacBook Pro Microphone",
            uid: "BuiltIn-1",
            transportType: kAudioDeviceTransportTypeBuiltIn
        )
        let iPhone = mic(
            2,
            "iPhone Microphone",
            uid: "Continuity-1",
            transportType: kAudioDeviceTransportTypeContinuityCaptureWireless
        )

        let decision = MicrophoneManager.selectionDecision(
            oldMicrophones: [iPhone],
            newMicrophones: [builtIn, iPhone],
            currentSelection: iPhone,
            selectionMode: .automatic,
            isFirstRefresh: false
        )

        XCTAssertEqual(decision, MicrophoneManager.SelectionDecision.selectFallback(builtIn))
    }

    func test_selectionDecision_keepsCurrentSelectionWhenDeviceIDChangesButUIDMatches() {
        let oldBuiltIn = mic(
            1,
            "MacBook Pro Microphone",
            uid: "BuiltIn-1",
            transportType: kAudioDeviceTransportTypeBuiltIn
        )
        let refreshedBuiltIn = mic(
            99,
            "MacBook Pro Microphone",
            uid: "BuiltIn-1",
            transportType: kAudioDeviceTransportTypeBuiltIn
        )

        let decision = MicrophoneManager.selectionDecision(
            oldMicrophones: [oldBuiltIn],
            newMicrophones: [refreshedBuiltIn],
            currentSelection: oldBuiltIn,
            selectionMode: .automatic,
            isFirstRefresh: false
        )

        XCTAssertEqual(decision, MicrophoneManager.SelectionDecision.keepCurrent(refreshedBuiltIn))
    }
}
