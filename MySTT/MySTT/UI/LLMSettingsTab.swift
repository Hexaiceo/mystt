import SwiftUI

struct LLMSettingsTab: View {
    @EnvironmentObject var appState: AppState
    @AppStorage("llmProvider") private var llmProvider = LLMProvider.localLMStudio.rawValue
    @AppStorage("enableLLMCorrection") private var enableLLM = true
    @AppStorage("enablePunctuationModel") private var enablePunctuation = false
    @AppStorage("mlxModelName") private var mlxModel = "mlx-community/Qwen2.5-3B-Instruct-4bit"
    @AppStorage("lmStudioModelName") private var lmStudioModel = "bielik-11b-v3.0-instruct"
    @AppStorage("lmStudioURL") private var lmStudioURL = "http://127.0.0.1:1234/v1"
    @State private var testResult = ""
    @State private var isTesting = false

    var body: some View {
        Form {
            Section("Processing") {
                Toggle("Enable LLM correction", isOn: $enableLLM)
                Toggle("Enable punctuation model", isOn: $enablePunctuation)
            }

            Section("LLM Provider") {
                Picker("Provider", selection: $llmProvider) {
                    ForEach(LLMProvider.allCases) { provider in
                        Text(provider.displayName).tag(provider.rawValue)
                    }
                }
            }

            if llmProvider == LLMProvider.localMLX.rawValue {
                Section("MLX Settings") {
                    TextField("Model", text: $mlxModel)
                    Text("Load an MLX model in LM Studio, then enter its name here. No Python required.")
                        .font(.caption).foregroundColor(.secondary)
                }
            }
            if llmProvider == LLMProvider.localLMStudio.rawValue {
                Section("LM Studio Settings") {
                    TextField("Model", text: $lmStudioModel)
                    TextField("Server URL", text: $lmStudioURL)
                    Text("Ensure LM Studio is running with the model loaded.").font(.caption).foregroundColor(.secondary)
                }
            }
            if llmProvider == LLMProvider.groq.rawValue {
                Section("Groq LLM") {
                    let hasKey = !(KeychainManager.groqAPIKey ?? "").isEmpty
                    HStack {
                        Image(systemName: hasKey ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundColor(hasKey ? .green : .orange)
                        Text(hasKey ? "Using Groq API key from General → API Keys" : "Add Groq API key in General → API Keys")
                            .font(.caption)
                    }
                }
            }
            if llmProvider == LLMProvider.openai.rawValue {
                Section("OpenAI LLM") {
                    let hasKey = !(KeychainManager.openaiAPIKey ?? "").isEmpty
                    HStack {
                        Image(systemName: hasKey ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundColor(hasKey ? .green : .orange)
                        Text(hasKey ? "Using OpenAI API key from General → API Keys" : "Add OpenAI API key in General → API Keys")
                            .font(.caption)
                    }
                }
            }

            Section("Test") {
                HStack {
                    Button("Test Connection") { testConnection() }
                        .disabled(isTesting)
                    if isTesting { ProgressView().controlSize(.small) }
                    Text(testResult)
                        .font(.caption)
                        .foregroundColor(testResult.contains("OK") ? .green : (testResult.contains("FAIL") ? .red : .secondary))
                }
            }
        }
        .formStyle(.grouped)
        .onChange(of: llmProvider) { _, _ in appState.reloadSettings() }
        .onChange(of: enableLLM) { _, _ in appState.reloadSettings() }
        .onChange(of: enablePunctuation) { _, _ in appState.reloadSettings() }
        .onChange(of: mlxModel) { _, _ in appState.reloadSettings() }
        .onChange(of: lmStudioModel) { _, _ in appState.reloadSettings() }
        .onChange(of: lmStudioURL) { _, _ in appState.reloadSettings() }
    }

    private func testConnection() {
        isTesting = true
        testResult = "Testing..."

        Task {
            let start = Date()
            do {
                let baseURL: String
                let model: String
                let apiKey: String

                switch LLMProvider(rawValue: llmProvider) {
                case .localLMStudio:
                    baseURL = lmStudioURL; model = lmStudioModel; apiKey = "lm-studio"
                case .localMLX:
                    baseURL = "http://127.0.0.1:1234/v1"; model = mlxModel; apiKey = "lm-studio"
                case .groq:
                    baseURL = "https://api.groq.com/openai/v1"; model = "llama-3.1-8b-instant"; apiKey = KeychainManager.groqAPIKey ?? ""
                case .openai:
                    baseURL = "https://api.openai.com/v1"; model = "gpt-4o-mini"; apiKey = KeychainManager.openaiAPIKey ?? ""
                case .none:
                    testResult = "FAIL: Unknown provider"; isTesting = false; return
                }

                guard !apiKey.isEmpty else {
                    testResult = "FAIL: No API key — add it in General → API Keys"
                    isTesting = false
                    return
                }

                let client = OpenAICompatibleClient(baseURL: baseURL, apiKey: apiKey, timeout: 15)
                let result = try await client.complete(model: model, systemPrompt: "Reply with exactly: OK", userMessage: "Test", temperature: 0.0, maxTokens: 5)
                let elapsed = Date().timeIntervalSince(start)
                testResult = "OK: \"\(result.prefix(20))\" (\(String(format: "%.1f", elapsed))s)"
                // Update main page status immediately on success
                appState.llmModelReady = true
            } catch {
                testResult = "FAIL: \(error.localizedDescription)"
                appState.llmModelReady = false
            }
            isTesting = false
        }
    }
}
