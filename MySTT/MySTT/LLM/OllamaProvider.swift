import Foundation

class OllamaProvider: LLMProviderProtocol {
    private let baseURL: String
    private let model: String
    var providerName: String { "Ollama (Local)" }

    struct OllamaRequest: Codable { let model: String; let prompt: String; let stream: Bool; let options: OllamaOptions? }
    struct OllamaOptions: Codable { let temperature: Double; let num_predict: Int }
    struct OllamaResponse: Codable { let response: String }

    init(model: String = "qwen2.5:3b", baseURL: String = "http://localhost:11434") {
        self.model = model; self.baseURL = baseURL
    }

    func correctText(_ text: String, language: Language, promptDictionary: String, userRules: String = "") async throws -> String {
        let systemPrompt = LLMPromptBuilder.buildSystemPrompt(language: language, dictionaryTerms: promptDictionary, userRules: userRules)
        let userPrompt = LLMPromptBuilder.buildUserPrompt(transcript: text)
        let fullPrompt = "\(systemPrompt)\n\n\(userPrompt)"

        // Dynamic token limit based on input length
        let wordCount = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
        let maxTokens = max(64, min(256, wordCount * 3))

        let url = URL(string: "\(baseURL)/api/generate")!
        var request = URLRequest(url: url, timeoutInterval: 30)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = OllamaRequest(model: model, prompt: fullPrompt, stream: false, options: OllamaOptions(temperature: 0.0, num_predict: maxTokens))
        request.httpBody = try JSONEncoder().encode(body)

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(OllamaResponse.self, from: data)
        let cleaned = OpenAICompatibleClient.cleanLLMOutput(response.response)
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func isAvailable() async -> Bool {
        guard let url = URL(string: "\(baseURL)/api/tags") else { return false }
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch { return false }
    }
}
