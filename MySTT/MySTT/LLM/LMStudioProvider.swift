import Foundation

class LMStudioProvider: LLMProviderProtocol {
    private let client: OpenAICompatibleClient
    private let configuredModel: String
    private let baseURL: String
    private let session: URLSession
    private var resolvedModel: String?
    var providerName: String { "LM Studio" }

    init(
        model: String = "qwen/qwen3-4b-2507",
        baseURL: String = "http://127.0.0.1:1234/v1",
        session: URLSession = .shared
    ) {
        self.configuredModel = model.trimmingCharacters(in: .whitespacesAndNewlines)
        self.baseURL = OpenAICompatibleClient.normalizedBaseURL(baseURL, defaultBaseURL: "http://127.0.0.1:1234/v1")
        self.session = session
        self.client = OpenAICompatibleClient(baseURL: self.baseURL, apiKey: "lm-studio", timeout: 30, session: session)
    }

    func correctText(_ text: String, language: Language, promptDictionary: String, userRules: String = "") async throws -> String {
        let model = try await resolveModel()
        let systemPrompt = LLMPromptBuilder.buildSystemPrompt(language: language, dictionaryTerms: promptDictionary, userRules: userRules)
        let userPrompt = LLMPromptBuilder.buildUserPrompt(transcript: text)
        return try await client.complete(model: model, systemPrompt: systemPrompt, userMessage: userPrompt)
    }

    func isAvailable() async -> Bool {
        !(await MLXProvider.fetchAvailableModels(baseURL: baseURL, session: session)).isEmpty
    }

    /// Resolve the model to use: configured model if available, otherwise first loaded LLM model
    private func resolveModel() async throws -> String {
        if let resolved = resolvedModel { return resolved }

        let available = await MLXProvider.fetchAvailableModels(baseURL: baseURL, session: session)

        if available.contains(configuredModel) {
            resolvedModel = configuredModel
            print("[LMStudioProvider] Using configured model: \(configuredModel)")
            return configuredModel
        }

        let llmModels = available.filter { !$0.contains("embed") && !$0.contains("embedding") }
        if let first = llmModels.first {
            resolvedModel = first
            print("[LMStudioProvider] Configured model '\(configuredModel)' not found. Using: \(first)")
            return first
        }

        print("[LMStudioProvider] WARNING: No models found, trying '\(configuredModel)'")
        return configuredModel
    }
}
