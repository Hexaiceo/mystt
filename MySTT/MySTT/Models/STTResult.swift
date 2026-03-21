import Foundation

struct STTResult: Sendable {
    let text: String
    let language: Language
    let confidence: Float
    let segments: [MySTTSegment]

    static let empty = STTResult(text: "", language: .unknown, confidence: 0.0, segments: [])

    var isEmpty: Bool { text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
}
