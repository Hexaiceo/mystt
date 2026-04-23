import Foundation

class OllamaProvider: LLMProviderProtocol {
    private let client: OpenAICompatibleClient
    private let model: String
    private let openAICompatibleBaseURL: String
    private let nativeAPIBaseURL: String
    private let session: URLSession
    private var resolvedModel: String?
    var providerName: String { "Ollama (Local)" }

    struct OllamaChatRequest: Codable {
        let model: String
        let messages: [ChatMessage]
        let stream: Bool
        let options: OllamaOptions?
    }
    struct OllamaOptions: Codable {
        let temperature: Double
        let num_predict: Int
    }
    struct OllamaChatResponse: Codable {
        struct Message: Codable { let content: String }
        let message: Message
    }

    init(
        model: String = "qwen2.5:3b",
        baseURL: String = "http://127.0.0.1:11434",
        session: URLSession = .shared
    ) {
        self.model = model
        self.session = session
        self.openAICompatibleBaseURL = Self.normalizedBaseURL(baseURL)
        self.nativeAPIBaseURL = Self.nativeAPIBaseURL(from: baseURL)
        self.client = OpenAICompatibleClient(baseURL: self.openAICompatibleBaseURL, apiKey: "ollama", timeout: 45, session: session)
    }

    func correctText(_ text: String, language: Language, promptDictionary: String, userRules: String = "") async throws -> String {
        let resolvedModel = try await resolveModel()
        let systemPrompt = LLMPromptBuilder.buildSystemPrompt(language: language, dictionaryTerms: promptDictionary, userRules: userRules)
        let userPrompt = LLMPromptBuilder.buildUserPrompt(transcript: text)
        let requestSizing = OpenAICompatibleClient.requestSizing(for: userPrompt, defaultTimeout: 45)

        do {
            return try await client.complete(
                model: resolvedModel,
                systemPrompt: systemPrompt,
                userMessage: userPrompt,
                temperature: 0.0,
                maxTokens: requestSizing.maxTokens
            )
        } catch let error as LLMError {
            switch error {
            case .requestFailed(let statusCode, _)
                where statusCode == 400 || statusCode == 404 || statusCode == 405 || statusCode == 501:
                return try await completeWithNativeChat(
                    model: resolvedModel,
                    systemPrompt: systemPrompt,
                    userPrompt: userPrompt,
                    maxTokens: requestSizing.maxTokens,
                    timeout: requestSizing.timeout
                )
            case .invalidResponse:
                return try await completeWithNativeChat(
                    model: resolvedModel,
                    systemPrompt: systemPrompt,
                    userPrompt: userPrompt,
                    maxTokens: requestSizing.maxTokens,
                    timeout: requestSizing.timeout
                )
            default:
                throw error
            }
        }
    }

    func isAvailable() async -> Bool {
        if !(await OpenAICompatibleClient.fetchAvailableModels(
            baseURL: openAICompatibleBaseURL,
            apiKey: "ollama",
            session: session
        )).isEmpty {
            return true
        }

        return !(await fetchNativeModels()).isEmpty
    }

    static func normalizedBaseURL(_ rawBaseURL: String) -> String {
        let normalized = OpenAICompatibleClient.normalizedBaseURL(
            rawBaseURL,
            defaultBaseURL: "http://127.0.0.1:11434/v1"
        )

        guard var components = URLComponents(string: normalized) else { return normalized }
        let trimmedPath = components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        if trimmedPath.isEmpty || trimmedPath == "api" {
            components.path = "/v1"
        } else if trimmedPath.hasPrefix("api/") {
            components.path = "/v1"
        } else if !trimmedPath.hasSuffix("v1") && !trimmedPath.contains("/v1/") {
            components.path = components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/")) + "/v1"
            if !components.path.hasPrefix("/") {
                components.path = "/" + components.path
            }
        }

        components.query = nil
        components.fragment = nil
        return components.string?.trimmingCharacters(in: CharacterSet(charactersIn: "/")) ?? normalized
    }

    static func nativeAPIBaseURL(from rawBaseURL: String) -> String {
        let openAIBaseURL = normalizedBaseURL(rawBaseURL)
        guard var components = URLComponents(string: openAIBaseURL) else { return "http://127.0.0.1:11434/api" }
        components.path = "/api"
        components.query = nil
        components.fragment = nil
        return components.string?.trimmingCharacters(in: CharacterSet(charactersIn: "/")) ?? "http://127.0.0.1:11434/api"
    }

    private func resolveModel() async throws -> String {
        if let resolvedModel { return resolvedModel }

        let available = await OpenAICompatibleClient.fetchAvailableModels(
            baseURL: openAICompatibleBaseURL,
            apiKey: "ollama",
            session: session
        )

        if available.contains(model) {
            resolvedModel = model
            return model
        }

        let nativeModels = await fetchNativeModels()
        if nativeModels.contains(model) {
            resolvedModel = model
            return model
        }

        if let firstAvailable = (available + nativeModels).first(where: { !$0.isEmpty }) {
            resolvedModel = firstAvailable
            print("[OllamaProvider] Configured model '\(model)' not found. Using: \(firstAvailable)")
            return firstAvailable
        }

        print("[OllamaProvider] WARNING: No models discovered. Trying configured model '\(model)'")
        return model
    }

    private func fetchNativeModels() async -> [String] {
        guard let url = URL(string: "\(nativeAPIBaseURL)/tags") else { return [] }
        do {
            let (data, response) = try await session.data(from: url)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return [] }
            return OpenAICompatibleClient.parseAvailableModelIdentifiers(from: data)
        } catch {
            return []
        }
    }

    private func completeWithNativeChat(
        model: String,
        systemPrompt: String,
        userPrompt: String,
        maxTokens: Int,
        timeout: TimeInterval
    ) async throws -> String {
        guard let url = URL(string: "\(nativeAPIBaseURL)/chat") else {
            throw LLMError.providerUnavailable(provider: providerName)
        }

        var request = URLRequest(url: url, timeoutInterval: timeout)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            OllamaChatRequest(
                model: model,
                messages: [
                    ChatMessage(role: "system", content: systemPrompt),
                    ChatMessage(role: "user", content: userPrompt)
                ],
                stream: false,
                options: OllamaOptions(temperature: 0.0, num_predict: maxTokens)
            )
        )

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError where error.code == .timedOut {
            throw LLMError.timeout
        } catch {
            throw error
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMError.invalidResponse(details: "Not HTTP response")
        }
        guard httpResponse.statusCode == 200 else {
            throw LLMError.requestFailed(
                statusCode: httpResponse.statusCode,
                message: String(data: data, encoding: .utf8) ?? "unknown"
            )
        }

        let decoded = try JSONDecoder().decode(OllamaChatResponse.self, from: data)
        let cleaned = OpenAICompatibleClient.cleanLLMOutput(decoded.message.content)
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
