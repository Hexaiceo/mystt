import Foundation

struct ChatMessage: Codable {
    let role: String
    let content: String
}
struct ChatCompletionRequest: Encodable {
    let model: String
    let messages: [ChatMessage]
    let temperature: Double
    let max_tokens: Int
    // Extra fields for thinking model control (Qwen3, DeepSeek, etc.)
    let extra: [String: AnyCodableValue]?

    enum CodingKeys: String, CodingKey {
        case model, messages, temperature, max_tokens
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(model, forKey: .model)
        try container.encode(messages, forKey: .messages)
        try container.encode(temperature, forKey: .temperature)
        try container.encode(max_tokens, forKey: .max_tokens)
        // Merge extra fields at top level
        if let extra = extra {
            var topLevel = encoder.container(keyedBy: DynamicCodingKey.self)
            for (key, value) in extra {
                try topLevel.encode(value, forKey: DynamicCodingKey(stringValue: key))
            }
        }
    }
}

// Helper types for dynamic JSON encoding
struct DynamicCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int? { nil }
    init(stringValue: String) { self.stringValue = stringValue }
    init?(intValue: Int) { return nil }
}

enum AnyCodableValue: Encodable {
    case bool(Bool)
    case string(String)
    case int(Int)
    case double(Double)

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .bool(let v): try container.encode(v)
        case .string(let v): try container.encode(v)
        case .int(let v): try container.encode(v)
        case .double(let v): try container.encode(v)
        }
    }
}

struct ChatCompletionResponse: Codable {
    struct Choice: Codable {
        struct Message: Codable { let content: String }
        let message: Message
    }
    let choices: [Choice]
}

class OpenAICompatibleClient {
    let baseURL: String
    let apiKey: String
    let defaultTimeout: TimeInterval

    init(baseURL: String, apiKey: String, timeout: TimeInterval = 10) {
        self.baseURL = baseURL; self.apiKey = apiKey; self.defaultTimeout = timeout
    }

    func complete(model: String, systemPrompt: String, userMessage: String, temperature: Double = 0.0, maxTokens: Int = 0) async throws -> String {
        // Dynamic max_tokens: estimate ~1.5x input word count (STT correction produces similar length)
        let effectiveMaxTokens: Int
        if maxTokens > 0 {
            effectiveMaxTokens = maxTokens
        } else {
            let wordCount = userMessage.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
            effectiveMaxTokens = max(64, min(256, wordCount * 3))
        }

        let url = URL(string: "\(baseURL)/chat/completions")!
        var request = URLRequest(url: url, timeoutInterval: defaultTimeout)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Detect thinking models (Qwen3, DeepSeek-R1, etc.) and send disable flag
        let modelLower = model.lowercased()
        let isThinkingModel = modelLower.contains("qwen3") || modelLower.contains("qwq") ||
                              modelLower.contains("deepseek-r1") || modelLower.contains("thinking")
        let extraParams: [String: AnyCodableValue]? = isThinkingModel
            ? ["enable_thinking": .bool(false)]
            : nil

        let body = ChatCompletionRequest(model: model, messages: [
            ChatMessage(role: "system", content: systemPrompt),
            ChatMessage(role: "user", content: userMessage)
        ], temperature: temperature, max_tokens: effectiveMaxTokens, extra: extraParams)
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMError.invalidResponse(details: "Not HTTP response")
        }
        switch httpResponse.statusCode {
        case 200: break
        case 401: throw LLMError.apiKeyMissing(provider: baseURL)
        case 429: throw LLMError.requestFailed(statusCode: 429, message: "Rate limited")
        default: throw LLMError.requestFailed(statusCode: httpResponse.statusCode, message: String(data: data, encoding: .utf8) ?? "unknown")
        }
        let decoded = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        guard var text = decoded.choices.first?.message.content else {
            throw LLMError.invalidResponse(details: "No choices in response")
        }

        // Strip thinking blocks and artifacts from LLM output
        text = Self.cleanLLMOutput(text)

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Clean LLM output: remove thinking blocks, /no_think tags, and other artifacts
    static func cleanLLMOutput(_ text: String) -> String {
        var result = text

        // Strip <think>...</think> blocks (Qwen3, DeepSeek-R1)
        if let regex = try? NSRegularExpression(pattern: "<think>[\\s\\S]*?</think>\\s*", options: []) {
            let range = NSRange(result.startIndex..., in: result)
            let cleaned = regex.stringByReplacingMatches(in: result, range: range, withTemplate: "")
            if !cleaned.isEmpty { result = cleaned }
        }

        // Strip /no_think that models may echo back
        result = result.replacingOccurrences(of: " /no_think", with: "")
        result = result.replacingOccurrences(of: "/no_think", with: "")

        // Strip common LLM prefixes/wrappers
        result = result.replacingOccurrences(of: "```\n", with: "")
        result = result.replacingOccurrences(of: "\n```", with: "")
        result = result.replacingOccurrences(of: "```", with: "")

        return result
    }
}
