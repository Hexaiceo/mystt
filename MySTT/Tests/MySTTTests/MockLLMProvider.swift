import Foundation
@testable import MySTT

/// Error type used in tests to simulate LLM failures.
enum MockLLMError: Error, LocalizedError {
    case timeout
    case networkUnavailable
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .timeout: return "LLM request timed out"
        case .networkUnavailable: return "Network unavailable"
        case .invalidResponse: return "Invalid response from LLM"
        }
    }
}

class MockLLMProvider: LLMProviderProtocol {
    var providerName: String = "Mock"
    var mockResult: String = ""
    var shouldThrow: Error?
    var callCount = 0
    var lastReceivedText: String?
    var lastReceivedLanguage: Language?
    var lastReceivedDictionary: [String: String]?
    var available: Bool = true

    func correctText(_ text: String, language: Language, dictionary: [String: String], userRules: String) async throws -> String {
        callCount += 1
        lastReceivedText = text
        lastReceivedLanguage = language
        lastReceivedDictionary = dictionary
        if let error = shouldThrow { throw error }
        return mockResult.isEmpty ? text.capitalized : mockResult
    }

    func isAvailable() async -> Bool {
        return available
    }
}
