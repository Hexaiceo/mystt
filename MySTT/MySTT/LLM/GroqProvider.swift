import Foundation

class GroqProvider: LLMProviderProtocol {
    private let client: OpenAICompatibleClient
    private let model = "llama-3.1-8b-instant"
    var providerName: String { "Groq Cloud" }

    init(apiKey: String) {
        client = OpenAICompatibleClient(baseURL: "https://api.groq.com/openai/v1", apiKey: apiKey)
    }

    func correctText(_ text: String, language: Language, dictionary: [String: String], userRules: String = "") async throws -> String {
        let terms = LLMPromptBuilder.formatDictionaryTerms(dictionary)
        let systemPrompt = LLMPromptBuilder.buildSystemPrompt(language: language, dictionaryTerms: terms, userRules: userRules)
        return try await client.complete(model: model, systemPrompt: systemPrompt, userMessage: text)
    }

    func isAvailable() async -> Bool { !client.apiKey.isEmpty }
}
