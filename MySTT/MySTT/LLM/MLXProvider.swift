import Foundation

/// MLX provider — uses LM Studio's OpenAI-compatible API with MLX-accelerated models.
/// No Python required. Just load an MLX model in LM Studio.
class MLXProvider: LLMProviderProtocol {
    private let client: OpenAICompatibleClient
    private let configuredModel: String
    private let baseURL: String
    private var resolvedModel: String?
    var providerName: String { "MLX via LM Studio" }

    init(modelPath: String = "mlx-community/Qwen2.5-7B-Instruct-4bit",
         baseURL: String = "http://127.0.0.1:1234/v1") {
        self.configuredModel = modelPath
        self.baseURL = baseURL
        self.client = OpenAICompatibleClient(baseURL: baseURL, apiKey: "lm-studio", timeout: 30)
    }

    func correctText(_ text: String, language: Language, promptDictionary: String, userRules: String = "") async throws -> String {
        let model = try await resolveModel()
        let systemPrompt = LLMPromptBuilder.buildSystemPrompt(language: language, dictionaryTerms: promptDictionary, userRules: userRules)
        let userPrompt = LLMPromptBuilder.buildUserPrompt(transcript: text)
        return try await client.complete(model: model, systemPrompt: systemPrompt, userMessage: userPrompt)
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

        let available = await Self.fetchAvailableModels(baseURL: baseURL)

        // 1. Use configured model if it's available
        if available.contains(configuredModel) {
            resolvedModel = configuredModel
            print("[MLXProvider] Using configured model: \(configuredModel)")
            return configuredModel
        }

        // 2. Configured model not found — pick the best LLM model available
        //    (skip embedding models)
        let llmModels = available.filter { !$0.contains("embed") && !$0.contains("embedding") }
        if let first = llmModels.first {
            resolvedModel = first
            print("[MLXProvider] Configured model '\(configuredModel)' not found. Using: \(first)")
            print("[MLXProvider] Available models: \(available)")
            return first
        }

        // 3. No models at all — try configured model anyway (will get a clear error from LM Studio)
        print("[MLXProvider] WARNING: No models found at \(baseURL)/models, trying '\(configuredModel)'")
        return configuredModel
    }

    /// Query LM Studio /v1/models endpoint for loaded models
    static func fetchAvailableModels(baseURL: String) async -> [String] {
        guard let url = URL(string: "\(baseURL)/models") else { return [] }
        do {
            var request = URLRequest(url: url, timeoutInterval: 5)
            request.setValue("Bearer lm-studio", forHTTPHeaderField: "Authorization")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return [] }
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let models = json["data"] as? [[String: Any]] {
                return models.compactMap { $0["id"] as? String }
            }
        } catch {}
        return []
    }
}
