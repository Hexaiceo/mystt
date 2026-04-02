import Foundation

protocol LLMProviderProtocol {
    func correctText(_ text: String, language: Language, promptDictionary: String, userRules: String) async throws -> String
    var providerName: String { get }
    func isAvailable() async -> Bool
}
