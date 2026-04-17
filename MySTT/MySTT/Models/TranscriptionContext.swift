import Foundation

struct TranscriptionContext: Sendable, Equatable {
    let prompt: String?

    static let empty = TranscriptionContext(prompt: nil)

    var isEmpty: Bool {
        prompt?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false
    }
}
