import Foundation

/// MySTT's own segment type (distinct from WhisperKit's TranscriptionSegment)
struct MySTTSegment: Codable, Identifiable, Sendable {
    let id: UUID
    let text: String
    let start: TimeInterval
    let end: TimeInterval
    let confidence: Float

    init(text: String, start: TimeInterval, end: TimeInterval, confidence: Float) {
        self.id = UUID()
        self.text = text
        self.start = start
        self.end = end
        self.confidence = confidence
    }

    var duration: TimeInterval { end - start }
}
