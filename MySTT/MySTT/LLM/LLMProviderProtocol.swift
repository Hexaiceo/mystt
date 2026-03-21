import Foundation

protocol LLMProviderProtocol {
    func correctText(_ text: String, language: Language, dictionary: [String: String], userRules: String) async throws -> String
    var providerName: String { get }
    func isAvailable() async -> Bool
}
