import Foundation

class OpenAIProvider: LLMProviderProtocol {
    private let client: OpenAICompatibleClient
    private let model = "gpt-4o-mini"
    var providerName: String { "OpenAI" }

    init(apiKey: String) {
        client = OpenAICompatibleClient(baseURL: "https://api.openai.com/v1", apiKey: apiKey)
    }

    func correctText(_ text: String, language: Language, promptDictionary: String, userRules: String = "") async throws -> String {
        let systemPrompt = LLMPromptBuilder.buildSystemPrompt(language: language, dictionaryTerms: promptDictionary, userRules: userRules)
        let userPrompt = LLMPromptBuilder.buildUserPrompt(transcript: text)
        return try await client.complete(model: model, systemPrompt: systemPrompt, userMessage: userPrompt)
    }

    func isAvailable() async -> Bool { !client.apiKey.isEmpty }
}
