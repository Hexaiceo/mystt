import Foundation

class GroqProvider: LLMProviderProtocol {
    private let client: OpenAICompatibleClient
    private let model = "llama-3.1-8b-instant"
    var providerName: String { "Groq Cloud" }

    init(apiKey: String) {
        client = OpenAICompatibleClient(baseURL: "https://api.groq.com/openai/v1", apiKey: apiKey)
    }

    func correctText(_ text: String, language: Language, promptDictionary: String, userRules: String = "") async throws -> String {
        let systemPrompt = LLMPromptBuilder.buildSystemPrompt(language: language, dictionaryTerms: promptDictionary, userRules: userRules)
        let userPrompt = LLMPromptBuilder.buildUserPrompt(transcript: text)
        return try await client.complete(model: model, systemPrompt: systemPrompt, userMessage: userPrompt)
    }

    func isAvailable() async -> Bool { !client.apiKey.isEmpty }
}
