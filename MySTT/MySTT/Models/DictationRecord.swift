import Foundation

struct DictationRecord: Codable, Equatable, Identifiable, Sendable {
    enum DeliveryStatus: String, Codable, Sendable {
        case pending
        case delivered
        case deliveryUnverified
        case clipboardOnly
        case deliveryFailed
    }

    let id: UUID
    let createdAt: Date
    var updatedAt: Date
    let rawText: String
    let finalText: String
    let language: Language
    let targetApp: TargetAppSnapshot?
    var deliveryStatus: DeliveryStatus
    var deliveryMethod: String?
    var deliveryFailureReason: String?
    var copiedToClipboard: Bool
    var wasDeliveryVerified: Bool
    var recoveryAttempts: Int
    var lastRecoveredAt: Date?

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        rawText: String,
        finalText: String,
        language: Language,
        targetApp: TargetAppSnapshot?
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = createdAt
        self.rawText = rawText
        self.finalText = finalText
        self.language = language
        self.targetApp = targetApp
        self.deliveryStatus = .pending
        self.deliveryMethod = nil
        self.deliveryFailureReason = nil
        self.copiedToClipboard = false
        self.wasDeliveryVerified = false
        self.recoveryAttempts = 0
        self.lastRecoveredAt = nil
    }

    var requiresRecovery: Bool {
        switch deliveryStatus {
        case .pending, .deliveryUnverified, .clipboardOnly, .deliveryFailed:
            return true
        case .delivered:
            return false
        }
    }

    mutating func apply(_ result: PasteDeliveryResult, at date: Date = Date()) {
        updatedAt = date
        deliveryMethod = result.method.rawValue
        deliveryFailureReason = result.failureReason
        copiedToClipboard = result.copiedToClipboard
        wasDeliveryVerified = result.wasVerified

        switch result.outcome {
        case .inserted:
            deliveryStatus = result.wasVerified ? .delivered : .deliveryUnverified
        case .clipboardOnly:
            deliveryStatus = .clipboardOnly
        case .failed:
            deliveryStatus = .deliveryFailed
        }
    }

    mutating func markRecovered(at date: Date = Date(), note: String) {
        updatedAt = date
        recoveryAttempts += 1
        lastRecoveredAt = date
        deliveryFailureReason = note
    }
}
