import SwiftUI
import ServiceManagement

/// Supported API key providers the user can add
enum APIKeyProvider: String, CaseIterable, Identifiable {
    case groq = "groq"
    case openai = "openai"
    case anthropic = "anthropic"
    case mistral = "mistral"
    case together = "together"
    case perplexity = "perplexity"
    case fireworks = "fireworks"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .groq: return "Groq"
        case .openai: return "OpenAI"
        case .anthropic: return "Anthropic"
        case .mistral: return "Mistral AI"
        case .together: return "Together AI"
        case .perplexity: return "Perplexity"
        case .fireworks: return "Fireworks AI"
        }
    }

    var placeholder: String {
        switch self {
        case .groq: return "Enter your Groq API key"
        case .openai: return "Enter your OpenAI API key"
        case .anthropic: return "Enter your Anthropic API key"
        case .mistral: return "Enter your Mistral API key"
        case .together: return "Enter your Together AI API key"
        case .perplexity: return "Enter your Perplexity API key"
        case .fireworks: return "Enter your Fireworks API key"
        }
    }

    var description: String {
        switch self {
        case .groq: return "Used for Groq STT and Groq LLM. Get key at console.groq.com"
        case .openai: return "Used for OpenAI LLM. Get key at platform.openai.com"
        case .anthropic: return "Used for Anthropic Claude. Get key at console.anthropic.com"
        case .mistral: return "Used for Mistral models. Get key at console.mistral.ai"
        case .together: return "Used for Together AI models. Get key at api.together.xyz"
        case .perplexity: return "Used for Perplexity models. Get key at perplexity.ai"
        case .fireworks: return "Used for Fireworks models. Get key at fireworks.ai"
        }
    }

    var validationURL: String {
        switch self {
        case .groq: return "https://api.groq.com/openai/v1/models"
        case .openai: return "https://api.openai.com/v1/models"
        case .anthropic: return "https://api.anthropic.com/v1/messages"
        case .mistral: return "https://api.mistral.ai/v1/models"
        case .together: return "https://api.together.xyz/v1/models"
        case .perplexity: return "https://api.perplexity.ai/chat/completions"
        case .fireworks: return "https://api.fireworks.ai/inference/v1/models"
        }
    }

    var keychainKey: String { "\(rawValue)_api_key" }
}

struct GeneralSettingsTab: View {
    @EnvironmentObject var appState: AppState
    @AppStorage("autoPaste") private var autoPaste = true
    @AppStorage("playSound") private var playSound = true
    @AppStorage("showNotification") private var showNotification = true
    @AppStorage("launchAtLogin") private var launchAtLogin = false

    // Track which providers are visible (have keys or were added)
    @State private var visibleProviders: [APIKeyProvider] = []
    @State private var keys: [APIKeyProvider: String] = [:]
    @State private var statuses: [APIKeyProvider: String] = [:]
    @State private var validating: Set<APIKeyProvider> = []
    @State private var showAddMenu = false

    var body: some View {
        Form {
            Section("Model Status") {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: sttIcon)
                            .foregroundColor(sttColor)
                        Text("STT: \(sttModelLabel)")
                        Spacer()
                        Text(sttStatusText)
                            .foregroundColor(sttColor)
                            .font(.caption)
                    }
                    if appState.sttModelDownloading {
                        VStack(alignment: .leading, spacing: 4) {
                            ProgressView(value: appState.sttDownloadProgress).tint(.orange)
                            Text(appState.sttDownloadStatus).font(.caption2).foregroundColor(.secondary)
                        }
                    }
                    if appState.sttModelReady && !appState.sttDownloadStatus.isEmpty {
                        Text(appState.sttDownloadStatus).font(.caption2).foregroundColor(.secondary)
                    }
                }

                HStack {
                    Image(systemName: appState.llmModelReady ? "checkmark.circle.fill" : "xmark.circle")
                        .foregroundColor(appState.llmModelReady ? .green : .red)
                    Text("LLM: \(llmModelLabel)")
                    Spacer()
                    Text(appState.llmModelReady ? "Ready" : "Not available")
                        .foregroundColor(appState.llmModelReady ? .green : .red)
                        .font(.caption)
                }

                if !appState.sttModelReady && !appState.sttModelDownloading {
                    Button("Download STT Model Now") {
                        Task { await appState.downloadSTTModel() }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            // Dynamic API Keys
            Section {
                Text("Enter API keys once here. They are shared across STT and LLM providers.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 2)

                ForEach(visibleProviders) { provider in
                    apiKeyRow(provider: provider)

                    if provider != visibleProviders.last {
                        Divider().padding(.vertical, 2)
                    }
                }

                // Add Key button
                HStack {
                    Spacer()
                    Menu {
                        ForEach(availableProviders) { provider in
                            Button(provider.displayName) {
                                addProvider(provider)
                            }
                        }
                    } label: {
                        Label("Add API Key", systemImage: "plus.circle.fill")
                            .font(.callout)
                    }
                    .menuStyle(.borderlessButton)
                    .fixedSize()
                    .disabled(availableProviders.isEmpty)
                    Spacer()
                }
                .padding(.top, 4)
            } header: {
                Label("API Keys", systemImage: "key.fill")
            }

            Section("Behavior") {
                Toggle("Auto-paste into active window", isOn: $autoPaste)
                Toggle("Play sounds", isOn: $playSound)
                Toggle("Show notifications", isOn: $showNotification)
            }
            Section("System") {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        do {
                            if newValue { try SMAppService.mainApp.register() }
                            else { try SMAppService.mainApp.unregister() }
                        } catch { print("Launch at login error: \(error)") }
                    }
            }
            Section("About") {
                LabeledContent("Version", value: "1.0.0")
            }
        }
        .formStyle(.grouped)
        .onAppear { loadSavedKeys() }
    }

    // MARK: - Providers not yet added

    private var availableProviders: [APIKeyProvider] {
        APIKeyProvider.allCases.filter { !visibleProviders.contains($0) }
    }

    // MARK: - Load keys from Keychain on appear

    private func loadSavedKeys() {
        visibleProviders = []
        keys = [:]
        for provider in APIKeyProvider.allCases {
            if let saved = KeychainManager.load(key: provider.keychainKey), !saved.isEmpty {
                visibleProviders.append(provider)
                keys[provider] = saved
            }
        }
        // Also check legacy groq_stt key
        if !visibleProviders.contains(.groq) {
            if let legacy = KeychainManager.load(key: "groq_stt_api_key"), !legacy.isEmpty {
                visibleProviders.append(.groq)
                keys[.groq] = legacy
                // Migrate to unified key
                KeychainManager.groqAPIKey = legacy
            }
        }
    }

    private func addProvider(_ provider: APIKeyProvider) {
        guard !visibleProviders.contains(provider) else { return }
        visibleProviders.append(provider)
        keys[provider] = ""
    }

    // MARK: - API Key Row

    @ViewBuilder
    private func apiKeyRow(provider: APIKeyProvider) -> some View {
        let key = Binding<String>(
            get: { keys[provider] ?? "" },
            set: { keys[provider] = $0 }
        )
        let hasKey = !(keys[provider] ?? "").isEmpty
        let status = statuses[provider] ?? ""
        let isValidating = validating.contains(provider)

        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(provider.displayName)
                    .font(.headline)
                Spacer()
                if hasKey {
                    Label("Saved", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                } else {
                    Label("Not set", systemImage: "circle.dashed")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                // Remove button
                Button(action: { removeProvider(provider) }) {
                    Image(systemName: "xmark.circle")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .help("Remove this API key")
            }

            SecureField(provider.placeholder, text: key)
                .textFieldStyle(.plain)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(nsColor: .controlBackgroundColor))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(hasKey ? Color.green.opacity(0.4) : Color.secondary.opacity(0.3), lineWidth: 1)
                )
                .onChange(of: key.wrappedValue) { _, newValue in
                    saveKey(provider: provider, value: newValue)
                    statuses[provider] = nil
                }

            HStack(spacing: 8) {
                Button(action: { validateKey(provider) }) {
                    Label("Validate", systemImage: "checkmark.shield")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(!hasKey || isValidating)

                if isValidating {
                    ProgressView().controlSize(.small)
                }

                if !status.isEmpty {
                    Text(status)
                        .font(.caption)
                        .foregroundColor(status.contains("Valid") ? .green : .red)
                }
            }

            Text(provider.description)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    private func removeProvider(_ provider: APIKeyProvider) {
        _ = KeychainManager.delete(key: provider.keychainKey)
        // Also clean legacy key for groq
        if provider == .groq {
            _ = KeychainManager.delete(key: "groq_stt_api_key")
        }
        visibleProviders.removeAll { $0 == provider }
        keys.removeValue(forKey: provider)
        statuses.removeValue(forKey: provider)
    }

    private func saveKey(provider: APIKeyProvider, value: String) {
        if value.isEmpty {
            _ = KeychainManager.delete(key: provider.keychainKey)
        } else {
            _ = KeychainManager.save(key: provider.keychainKey, value: value)
        }
        // Keep groq STT key in sync
        if provider == .groq {
            if value.isEmpty {
                _ = KeychainManager.delete(key: "groq_stt_api_key")
            } else {
                _ = KeychainManager.save(key: "groq_stt_api_key", value: value)
            }
        }
    }

    // MARK: - Validation

    private func validateKey(_ provider: APIKeyProvider) {
        validating.insert(provider)
        statuses[provider] = "Validating..."
        let key = keys[provider] ?? ""

        Task {
            var request = URLRequest(url: URL(string: provider.validationURL)!)
            if provider == .anthropic {
                request.setValue(key, forHTTPHeaderField: "x-api-key")
                request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
                // Anthropic needs POST, just check auth header
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = "{\"model\":\"claude-3-haiku-20240307\",\"max_tokens\":1,\"messages\":[{\"role\":\"user\",\"content\":\"hi\"}]}".data(using: .utf8)
            } else {
                request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
            }
            request.timeoutInterval = 10

            do {
                let (_, response) = try await URLSession.shared.data(for: request)
                let code = (response as? HTTPURLResponse)?.statusCode ?? 0
                if code == 200 || code == 201 {
                    statuses[provider] = "Valid"
                } else if code == 401 || code == 403 {
                    statuses[provider] = "Invalid key"
                } else {
                    statuses[provider] = "HTTP \(code)"
                }
            } catch {
                statuses[provider] = "Error"
            }
            validating.remove(provider)
        }
    }

    // MARK: - Dynamic Model Labels

    private var sttModelLabel: String {
        let settings = AppSettings.load()
        switch settings.sttProvider {
        case .whisperKit:
            let model = settings.whisperModelName
            // Extract human-readable name from model ID
            if model.contains("turbo_632MB") { return "WhisperKit Large V3 Turbo 632MB" }
            if model.contains("turbo_954MB") { return "WhisperKit Large V3 Turbo 954MB" }
            if model.contains("large-v3_947MB") { return "WhisperKit Large V3 947MB" }
            if model.contains("small_216MB") { return "WhisperKit Small 216MB" }
            return "WhisperKit (\(model))"
        case .groqSTT:
            return "Groq Cloud STT"
        }
    }

    private var llmModelLabel: String {
        let settings = AppSettings.load()
        guard settings.enableLLMCorrection else { return "Disabled" }
        switch settings.llmProvider {
        case .localMLX:
            let model = settings.mlxModelName
            // Show just the model name, trimming common prefixes
            let short = model
                .replacingOccurrences(of: "mlx-community/", with: "")
                .replacingOccurrences(of: "mlx-", with: "")
            return "\(short) (MLX)"
        case .localLMStudio:
            return "\(settings.lmStudioModelName) (LM Studio)"
        case .ollama:
            return "\(settings.ollamaModelName) (Ollama)"
        case .groq:
            return "Groq Cloud"
        case .openai:
            return "OpenAI GPT-4o-mini"
        }
    }

    // MARK: - Model Status Computed

    private var sttIcon: String {
        if appState.sttModelReady { return "checkmark.circle.fill" }
        if appState.sttModelDownloading { return "arrow.down.circle" }
        return "xmark.circle"
    }

    private var sttColor: Color {
        if appState.sttModelReady { return .green }
        if appState.sttModelDownloading { return .orange }
        return .red
    }

    private var sttStatusText: String {
        if appState.sttModelReady { return "Ready" }
        if appState.sttModelDownloading {
            // Show "Loading..." if status indicates cached model
            let status = appState.sttDownloadStatus
            if status.contains("cached") || status.contains("Compiling") || status.contains("Loading") {
                return "Loading..."
            }
            return "Downloading..."
        }
        return "Not loaded"
    }
}
