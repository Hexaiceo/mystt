import Carbon

struct KeyCodes {
    // Modifier keys
    static let rightOption: UInt16 = 0x3D
    static let leftOption: UInt16 = 0x3A
    static let rightCommand: UInt16 = 0x36
    static let leftCommand: UInt16 = 0x37
    static let rightShift: UInt16 = 0x3C
    static let leftShift: UInt16 = 0x38
    static let rightControl: UInt16 = 0x3E
    static let leftControl: UInt16 = 0x3B
    static let function: UInt16 = 0x3F
    static let capsLock: UInt16 = 0x39

    // Common keys
    static let returnKey: UInt16 = 0x24
    static let tab: UInt16 = 0x30
    static let space: UInt16 = 0x31
    static let delete: UInt16 = 0x33
    static let escape: UInt16 = 0x35
    static let f1: UInt16 = 0x7A
    static let f2: UInt16 = 0x78
    static let f3: UInt16 = 0x63
    static let f4: UInt16 = 0x76
    static let f5: UInt16 = 0x60
    static let f6: UInt16 = 0x61
    static let f7: UInt16 = 0x62
    static let f8: UInt16 = 0x64
    static let f9: UInt16 = 0x65
    static let f10: UInt16 = 0x6D
    static let f11: UInt16 = 0x67
    static let f12: UInt16 = 0x6F

    static let codeToName: [UInt16: String] = [
        rightOption: "Right Option", leftOption: "Left Option",
        rightCommand: "Right Command", leftCommand: "Left Command",
        rightShift: "Right Shift", leftShift: "Left Shift",
        rightControl: "Right Control", leftControl: "Left Control",
        function: "Fn", capsLock: "Caps Lock",
        returnKey: "Return", tab: "Tab", space: "Space",
        delete: "Delete", escape: "Escape",
        f1: "F1", f2: "F2", f3: "F3", f4: "F4",
        f5: "F5", f6: "F6", f7: "F7", f8: "F8",
        f9: "F9", f10: "F10", f11: "F11", f12: "F12"
    ]

    static func name(for code: UInt16) -> String {
        codeToName[code] ?? "Key 0x\(String(code, radix: 16, uppercase: true))"
    }
}
