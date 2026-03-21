import Foundation

class LMStudioProvider: LLMProviderProtocol {
    private let client: OpenAICompatibleClient
    private let configuredModel: String
    private let baseURL: String
    private var resolvedModel: String?
    var providerName: String { "LM Studio" }

    init(model: String = "bielik-11b-v3.0-instruct", baseURL: String = "http://127.0.0.1:1234/v1") {
        self.configuredModel = model
        self.baseURL = baseURL
        self.client = OpenAICompatibleClient(baseURL: baseURL, apiKey: "lm-studio", timeout: 30)
    }

    func correctText(_ text: String, language: Language, dictionary: [String: String], userRules: String = "") async throws -> String {
        let model = try await resolveModel()
        let terms = LLMPromptBuilder.formatDictionaryTerms(dictionary)
        let systemPrompt = LLMPromptBuilder.buildSystemPrompt(language: language, dictionaryTerms: terms, userRules: userRules)
        return try await client.complete(model: model, systemPrompt: systemPrompt, userMessage: text)
    }

    func isAvailable() async -> Bool {
        guard let url = URL(string: "\(baseURL)/models") else { return false }
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch { return false }
    }

    /// Resolve the model to use: configured model if available, otherwise first loaded LLM model
    private func resolveModel() async throws -> String {
        if let resolved = resolvedModel { return resolved }

        let available = await MLXProvider.fetchAvailableModels(baseURL: baseURL)

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
