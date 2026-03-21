# MySTT - macOS Speech-to-Text Application Architecture

## Table of Contents

1. [Overview](#1-overview)
2. [Technology Research & Decisions](#2-technology-research--decisions)
3. [System Architecture](#3-system-architecture)
4. [Component Design](#4-component-design)
5. [STT Engine Layer](#5-stt-engine-layer)
6. [LLM Post-Processing Layer](#6-llm-post-processing-layer)
7. [Dictionary & Rules Engine](#7-dictionary--rules-engine)
8. [Auto-Paste System](#8-auto-paste-system)
9. [Configuration & API Switching](#9-configuration--api-switching)
10. [Local LLM Guide for macOS](#10-local-llm-guide-for-macos)
11. [Data Flow](#11-data-flow)
12. [Project Structure](#12-project-structure)
13. [Dependencies](#13-dependencies)
14. [Build & Distribution](#14-build--distribution)
15. [Performance Targets](#15-performance-targets)

---

## 1. Overview

**MySTT** is a lightweight macOS menu bar application that converts speech to text with one button press, processes it through an LLM for punctuation/grammar correction, and auto-pastes the result into the currently active window.

### Key Requirements

| Requirement | Solution |
|---|---|
| One-button activation (toggle) | Fn key: press once to start, press again to stop (NSEvent flagsChanged) |
| Visual recording indicator | Floating overlay with pulsing mic icon centered on screen |
| Speech-to-text (English + Polish, auto-detect) | Whisper large-v3-turbo via WhisperKit (local) |
| LLM correction (punctuation, grammar, dictionary) | LM Studio with Bielik-11B-v3.0 (best for Polish) |
| API switching: local vs remote | Configurable provider (LM Studio / MLX / Grok / Groq / OpenAI) |
| Auto-paste into active window | NSPasteboard + simulated Cmd+V |
| Lightweight, always works | Menu bar app, ~50 MB base + models on first launch |
| Bilingual without language switching | Whisper auto-detects language per utterance |

---

## 2. Technology Research & Decisions

### 2.1 Speech-to-Text Engine Comparison

| Engine | Type | Polish | English | Latency (Apple Silicon) | RAM | Verdict |
|---|---|---|---|---|---|---|
| **WhisperKit (large-v3-turbo)** | Local, Swift-native | Excellent | Excellent | ~1.2s per utterance | ~2.2 GB | **PRIMARY CHOICE** |
| whisper.cpp + CoreML | Local, C/C++ | Excellent | Excellent | ~1.5s per utterance | ~2.2 GB | Backup option |
| Apple SFSpeechRecognizer | Local/Cloud | Good (pl-PL) | Good | Fast but limited | System | Legacy, limited |
| Apple SpeechAnalyzer (macOS 26+) | Local | Unknown (10 langs) | Good | ~70x realtime (fast) | System-managed | Future option, no Polish yet |
| Deepgram Nova-3 | Cloud | Yes | Excellent | ~300ms | N/A | Cloud fallback |

**Decision: WhisperKit with `large-v3-turbo` model.**

Why:
- Pure Swift integration via Swift Package Manager
- Automatic model selection for device hardware
- CoreML + Metal acceleration on Apple Silicon
- Whisper natively supports 99+ languages with auto-detection (no language switching needed)
- `large-v3-turbo` is a distilled model: 809M params, 5.4x faster than large-v3, near-identical accuracy
- ~1.2 seconds average processing time per utterance on Apple Silicon

For machines with 8 GB RAM, fall back to `small` model (244M params, ~852 MB RAM, still good accuracy).

### 2.2 How Wispr Flow Works (Competitive Analysis)

Wispr Flow is the gold standard for macOS dictation:
- **Cloud-based**: All processing on remote servers (OpenAI + Meta models). Requires internet.
- **Multi-layer AI pipeline**: Layer 1 = raw transcription, Layer 2+ = filler word removal, grammar, punctuation, contextual formatting.
- **Hotkey UX**: Hold Function key to record; release to process. Text appears in 1-2 seconds.
- **Auto-paste**: Uses accessibility APIs + pasteboard simulation to insert at cursor.
- **Context-aware**: Adapts formatting based on target app (email vs code editor vs chat).
- **Accuracy**: 97.2% (vs Apple Dictation 85-90%). Effective speed: 170-179 WPM.

**What we replicate**: The core UX (hold-to-talk, LLM cleanup, auto-paste). **What we improve**: Fully offline-capable with local STT + local LLM.

### 2.3 LLM for Post-Processing

#### Two-Stage Pipeline (Recommended)

**Stage 1 - Fast Punctuation Model (~50-100ms):**

| Model | Size | Languages | Latency | Use |
|---|---|---|---|---|
| **sdadas/byt5-text-correction** | ~1.2 GB | EN, PL, DE, FR, ES, IT, NL, PT, RO, RU | <100ms on CPU | Punctuation + capitalization + Polish diacritics |
| oliverguhr/fullstop-punctuation-multilingual | ~1.1 GB | EN, PL, DE, FR, ES, IT, NL, CZ, PT, SK, SL, BG | <100ms on CPU | Punctuation only |
| deepmultilingualpunctuation (pip package) | ~1.1 GB | Same as above | <100ms on CPU | Easy pip install |

**Decision: `sdadas/byt5-text-correction`** - purpose-built for punctuation + capitalization + Polish diacritics restoration. Prefix input with `<pl>` for Polish or `<en>` for English (auto-detected by Whisper).

**Stage 2 - LLM Grammar + Dictionary (~100-500ms):**

| Provider | Model | Cost | Latency | Polish | RAM |
|---|---|---|---|---|---|
| **MLX (local)** | Qwen 2.5 3B (4-bit) | Free | 100-300ms | Good | ~4 GB |
| Ollama (local) | Qwen 2.5 7B (Q4_K_M) | Free | 200-500ms | Very Good | ~6.4 GB |
| Groq (remote) | Llama 3.1 8B | $0.05/M tokens | 200-400ms | Good | N/A |
| xAI (remote) | Grok 4.1 Fast | $0.20/M tokens | 300-600ms | Good | N/A |
| OpenAI (remote) | GPT-4o-mini | $0.15/M tokens | 500-1500ms | Very Good | N/A |

**Decision: MLX + Qwen 2.5 3B as default local provider.** Fastest on Apple Silicon (50% faster than Ollama). Ollama as alternative local provider. Groq/Grok/OpenAI as remote options.

### 2.4 Programming Language & Framework

**Decision: Swift + SwiftUI menu bar app.**

- `MenuBarExtra` (macOS 13+) for lightweight menu bar presence
- `LSUIElement = true` to hide from Dock
- Native access to AVAudioEngine, CGEvent, NSPasteboard
- WhisperKit integrates via Swift Package Manager
- No Electron, no Python wrapper - pure native, minimal footprint

### 2.5 Global Hotkey

**Decision: CGEvent tap for push-to-talk.**

- Detects both keyDown (start recording) and keyUp (stop recording) globally
- Required for hold-to-talk UX (like Wispr Flow's Function key)
- Requires Accessibility permission (System Settings > Privacy & Security > Accessibility)
- Not App Store compatible (fine - we distribute via Developer ID or direct download)

### 2.6 Auto-Paste Mechanism

**Decision: NSPasteboard + simulated Cmd+V with clipboard save/restore.**

1. Save current clipboard contents
2. Set transcribed text to NSPasteboard
3. Simulate Cmd+V via CGEvent
4. Restore original clipboard contents after a short delay

This is the most reliable cross-application approach. AXUIElement direct text insertion can be tried first as a cleaner option but not all apps expose text fields.

---

## 3. System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    MySTT Menu Bar App                        │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌─────────────┐ │
│  │  Hotkey   │  │  Status  │  │ Settings │  │  Language    │ │
│  │ Manager   │  │  UI      │  │  Panel   │  │  Indicator  │ │
│  └────┬─────┘  └──────────┘  └──────────┘  └─────────────┘ │
│       │                                                      │
│  ┌────▼──────────────────────────────────────────────────┐  │
│  │              Audio Capture (AVAudioEngine)              │  │
│  └────┬───────────────────────────────────────────────────┘  │
│       │ audio buffers                                        │
│  ┌────▼──────────────────────────────────────────────────┐  │
│  │              STT Engine (WhisperKit)                    │  │
│  │  ┌────────────┐  ┌─────────────┐  ┌────────────────┐ │  │
│  │  │ large-v3-  │  │  small      │  │  Cloud STT     │ │  │
│  │  │ turbo      │  │  (8GB Macs) │  │  (Deepgram)    │ │  │
│  │  └────────────┘  └─────────────┘  └────────────────┘ │  │
│  └────┬───────────────────────────────────────────────────┘  │
│       │ raw text + detected language                         │
│  ┌────▼──────────────────────────────────────────────────┐  │
│  │         Post-Processing Pipeline                       │  │
│  │  ┌─────────────────┐    ┌───────────────────────────┐ │  │
│  │  │ Stage 1:        │    │ Stage 2:                   │ │  │
│  │  │ Punctuation      │───▶│ LLM Grammar + Dictionary  │ │  │
│  │  │ (byt5-text-corr) │    │ (Local MLX / Ollama /     │ │  │
│  │  │ ~50-100ms        │    │  Grok / Groq / OpenAI)    │ │  │
│  │  └─────────────────┘    └───────────────────────────┘ │  │
│  └────┬───────────────────────────────────────────────────┘  │
│       │ corrected text                                       │
│  ┌────▼──────────────────────────────────────────────────┐  │
│  │         Dictionary & Rules Engine                      │  │
│  │  • Custom term replacements                            │  │
│  │  • Abbreviation expansion                              │  │
│  │  • Regex-based post-rules                              │  │
│  └────┬───────────────────────────────────────────────────┘  │
│       │ final text                                           │
│  ┌────▼──────────────────────────────────────────────────┐  │
│  │         Auto-Paste (NSPasteboard + CGEvent Cmd+V)      │  │
│  └────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## 4. Component Design

### 4.1 App Lifecycle

```swift
@main
struct MySTTApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra("MySTT", systemImage: appState.isRecording ? "mic.fill" : "mic") {
            MenuBarView()
                .environmentObject(appState)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }
}
```

- **Info.plist**: `LSUIElement = true` (no Dock icon)
- **Activation policy**: `.accessory`
- **Launch at login**: Use `SMAppService` (macOS 13+)

### 4.2 AppState (Central State Manager)

```swift
@MainActor
class AppState: ObservableObject {
    @Published var isRecording = false
    @Published var isProcessing = false
    @Published var lastTranscription = ""
    @Published var detectedLanguage: Language = .unknown
    @Published var selectedSTTProvider: STTProvider = .whisperKit
    @Published var selectedLLMProvider: LLMProvider = .localMLX
    @Published var statusMessage = "Ready"

    let audioEngine: AudioCaptureEngine
    let sttEngine: STTEngineProtocol
    let postProcessor: PostProcessorProtocol
    let autoPaster: AutoPaster
    let hotkeyManager: HotkeyManager
    let settings: AppSettings
}
```

### 4.3 Key Protocols

```swift
protocol STTEngineProtocol {
    func transcribe(audioBuffer: AVAudioPCMBuffer) async throws -> STTResult
}

struct STTResult {
    let text: String
    let language: Language  // .english, .polish, .unknown
    let confidence: Float
    let segments: [TranscriptionSegment]
}

protocol LLMProviderProtocol {
    func correctText(_ text: String, language: Language, dictionary: [String: String]) async throws -> String
}

protocol PostProcessorProtocol {
    func process(_ rawText: String, language: Language) async throws -> String
}
```

---

## 5. STT Engine Layer

### 5.1 WhisperKit Integration (Primary)

```swift
import WhisperKit

class WhisperKitSTTEngine: STTEngineProtocol {
    private var whisperKit: WhisperKit?
    private let modelName: String

    init(modelName: String = "large-v3-turbo") {
        self.modelName = modelName
    }

    func initialize() async throws {
        whisperKit = try await WhisperKit(
            model: modelName,
            computeOptions: .init(audioEncoderCompute: .cpuAndGPU,
                                  textDecoderCompute: .cpuAndGPU)
        )
    }

    func transcribe(audioBuffer: AVAudioPCMBuffer) async throws -> STTResult {
        guard let whisperKit else { throw STTError.notInitialized }

        let result = try await whisperKit.transcribe(audioArray: audioBuffer.floatArray)
        let language = Language(whisperCode: result?.first?.language ?? "unknown")

        return STTResult(
            text: result?.first?.text ?? "",
            language: language,
            confidence: result?.first?.avgLogprob ?? 0,
            segments: result?.first?.segments.map { ... } ?? []
        )
    }
}
```

### 5.2 Model Selection by Device

```swift
func selectModel() -> String {
    let totalRAM = ProcessInfo.processInfo.physicalMemory / (1024 * 1024 * 1024)  // GB
    switch totalRAM {
    case 0..<12:  return "small"           // 8 GB Macs: ~852 MB RAM for model
    case 12..<20: return "large-v3-turbo"  // 16 GB Macs: ~2.2 GB RAM for model
    default:      return "large-v3-turbo"  // 24+ GB Macs: plenty of room
    }
}
```

### 5.3 Whisper Model Specs

| Model | Parameters | Disk | RAM | WER (EN) | WER (PL) | Speed (M2) |
|---|---|---|---|---|---|---|
| tiny | 39M | 75 MB | ~273 MB | ~8% | ~15% | <0.3s |
| base | 74M | 142 MB | ~388 MB | ~6% | ~12% | <0.5s |
| small | 244M | 466 MB | ~852 MB | ~4.5% | ~8% | <1.0s |
| large-v3-turbo | 809M | 1.6 GB | ~2.2 GB | ~3% | ~5% | ~1.2s |
| large-v3 | 1.55B | 2.9 GB | ~3.9 GB | ~2.7% | ~4% | ~3.0s |

### 5.4 Cloud STT Fallback (Deepgram)

```swift
class DeepgramSTTEngine: STTEngineProtocol {
    private let apiKey: String
    private let baseURL = "https://api.deepgram.com/v1/listen"

    func transcribe(audioBuffer: AVAudioPCMBuffer) async throws -> STTResult {
        let audioData = audioBuffer.toWAVData()
        var request = URLRequest(url: URL(string: "\(baseURL)?model=nova-3&detect_language=true&punctuate=true")!)
        request.httpMethod = "POST"
        request.setValue("Token \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("audio/wav", forHTTPHeaderField: "Content-Type")
        request.httpBody = audioData

        let (data, _) = try await URLSession.shared.data(for: request)
        // Parse Deepgram JSON response...
    }
}
```

---

## 6. LLM Post-Processing Layer

### 6.1 Stage 1: Fast Punctuation Model

The `sdadas/byt5-text-correction` model runs locally via a Python subprocess or a pre-compiled CoreML version.

**Option A: Python subprocess (simpler, development phase)**

```swift
class PunctuationCorrector {
    func correct(_ text: String, language: Language) async throws -> String {
        let prefix = language == .polish ? "<pl>" : "<en>"
        let input = "\(prefix) \(text)"

        // Call embedded Python script
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        process.arguments = [bundledScriptPath, input]
        // ... capture output
    }
}
```

**Option B: CoreML conversion (production, fastest)**

Convert the ByT5 model to CoreML using `coremltools` and run natively in Swift:

```bash
python3 -c "
import coremltools as ct
from transformers import T5ForConditionalGeneration
model = T5ForConditionalGeneration.from_pretrained('sdadas/byt5-text-correction')
mlmodel = ct.convert(model, ...)
mlmodel.save('byt5-text-correction.mlpackage')
"
```

**Alternative: deepmultilingualpunctuation (pip package)**

```python
from deepmultilingualpunctuation import PunctuationModel
model = PunctuationModel()
result = model.restore_punctuation("witaj swiecie jak sie masz")
# Output: "Witaj swiecie, jak sie masz."
```

### 6.2 Stage 2: LLM Grammar + Dictionary

#### System Prompt Template

```
You are a speech-to-text post-processor. Correct the transcription output. Rules:
1. Fix remaining punctuation errors (periods, commas, question marks, exclamation marks)
2. Fix grammar errors while preserving original meaning exactly
3. Do NOT rephrase, add, or remove content
4. If text is Polish, apply Polish grammar and punctuation rules
5. Restore Polish diacritical characters where missing (a->ą, e->ę, c->ć, s->ś, z->ż/ź, o->ó, l->ł, n->ń)
6. Apply these domain-specific terms (use exact spelling):
{DICTIONARY_TERMS}

Return ONLY the corrected text. No explanations.
```

#### 6.2.1 Local: MLX Provider (Fastest on Apple Silicon)

```swift
class MLXLLMProvider: LLMProviderProtocol {
    private let modelPath: String  // e.g., "mlx-community/Qwen2.5-3B-Instruct-4bit"

    func correctText(_ text: String, language: Language, dictionary: [String: String]) async throws -> String {
        // Call mlx-lm via embedded Python or subprocess
        let prompt = buildPrompt(text: text, language: language, dictionary: dictionary)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: pythonPath)
        process.arguments = [mlxScriptPath, "--model", modelPath, "--prompt", prompt, "--max-tokens", "512", "--temp", "0.1"]
        // ... capture output
    }
}
```

MLX Python helper script (`mlx_infer.py`):
```python
import sys, json
from mlx_lm import load, generate

model, tokenizer = load(sys.argv[2])
response = generate(model, tokenizer, prompt=sys.argv[4],
                    max_tokens=int(sys.argv[6]), temp=float(sys.argv[8]))
print(response)
```

**Performance**: Qwen 2.5 3B (4-bit) via MLX achieves ~80-120 tokens/second on M1/M2, giving ~100-300ms for a paragraph correction.

#### 6.2.2 Local: Ollama Provider

```swift
class OllamaLLMProvider: LLMProviderProtocol {
    private let baseURL = "http://localhost:11434"
    private let model: String  // e.g., "qwen2.5:3b"

    func correctText(_ text: String, language: Language, dictionary: [String: String]) async throws -> String {
        let prompt = buildPrompt(text: text, language: language, dictionary: dictionary)

        var request = URLRequest(url: URL(string: "\(baseURL)/api/generate")!)
        request.httpMethod = "POST"
        request.httpBody = try JSONEncoder().encode(OllamaRequest(
            model: model,
            prompt: prompt,
            stream: false,
            options: OllamaOptions(temperature: 0.1, num_predict: 512)
        ))

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(OllamaResponse.self, from: data)
        return response.response.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
```

**Recommended Ollama models:**
- `qwen2.5:3b` - fast, good multilingual (4 GB RAM)
- `qwen2.5:7b` - better Polish, slower (6.4 GB RAM)
- `jobautomation/OpenEuroLLM-Polish` - best for Polish-only use

#### 6.2.3 Remote: Grok API Provider

```swift
class GrokLLMProvider: LLMProviderProtocol {
    private let apiKey: String
    private let baseURL = "https://api.x.ai/v1/chat/completions"
    private let model = "grok-4.1-fast"

    func correctText(_ text: String, language: Language, dictionary: [String: String]) async throws -> String {
        let systemPrompt = buildSystemPrompt(language: language, dictionary: dictionary)
        let request = ChatCompletionRequest(
            model: model,
            messages: [
                .init(role: "system", content: systemPrompt),
                .init(role: "user", content: text)
            ],
            temperature: 0.1,
            max_tokens: 512
        )
        // POST to baseURL with Bearer token...
    }
}
```

**Grok API pricing**: Grok 4.1 Fast = $0.20/M input tokens, $0.50/M output tokens. Very affordable for short text corrections.

#### 6.2.4 Remote: Groq Provider (Fastest Remote)

```swift
class GroqLLMProvider: LLMProviderProtocol {
    private let apiKey: String
    private let baseURL = "https://api.groq.com/openai/v1/chat/completions"
    private let model = "llama-3.1-8b-instant"

    func correctText(_ text: String, language: Language, dictionary: [String: String]) async throws -> String {
        // Same OpenAI-compatible format as Grok
        // Groq achieves sub-300ms time-to-first-token, 750+ tokens/second
    }
}
```

**Groq pricing**: Llama 3.1 8B = ~$0.05/M input, $0.08/M output. Cheapest and fastest remote option.

#### 6.2.5 Remote: OpenAI Provider

```swift
class OpenAILLMProvider: LLMProviderProtocol {
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    private let model = "gpt-4o-mini"

    // Same OpenAI-compatible format
    // GPT-4o-mini: $0.15/M input, $0.60/M output
    // Best multilingual quality, slightly higher latency
}
```

### 6.3 Unified LLM Provider Interface

```swift
enum LLMProvider: String, CaseIterable, Codable {
    case localMLX = "Local (MLX)"
    case localOllama = "Local (Ollama)"
    case grok = "Grok API"
    case groq = "Groq API"
    case openai = "OpenAI API"

    var isLocal: Bool {
        switch self {
        case .localMLX, .localOllama: return true
        default: return false
        }
    }

    func createProvider(settings: AppSettings) -> LLMProviderProtocol {
        switch self {
        case .localMLX:    return MLXLLMProvider(modelPath: settings.mlxModel)
        case .localOllama: return OllamaLLMProvider(model: settings.ollamaModel)
        case .grok:        return GrokLLMProvider(apiKey: settings.grokAPIKey)
        case .groq:        return GroqLLMProvider(apiKey: settings.groqAPIKey)
        case .openai:      return OpenAILLMProvider(apiKey: settings.openaiAPIKey)
        }
    }
}
```

---

## 7. Dictionary & Rules Engine

### 7.1 Custom Dictionary

Stored as a JSON file (`~/.mystt/dictionary.json`):

```json
{
    "terms": {
        "kubernetes": "Kubernetes",
        "react": "React",
        "typescript": "TypeScript",
        "claude": "Claude",
        "grok": "Grok",
        "mac os": "macOS",
        "iphone": "iPhone",
        "my s t t": "MySTT",
        "wolak": "Wolak"
    },
    "abbreviations": {
        "btw": "by the way",
        "asap": "ASAP",
        "eta": "ETA"
    },
    "polish_terms": {
        "klod": "Claude",
        "grok": "Grok"
    }
}
```

### 7.2 Punctuation Rules

```json
{
    "rules": [
        {"pattern": "\\s+([.,!?;:])", "replacement": "$1"},
        {"pattern": "([.!?])\\s*([a-ząćęłńóśźż])", "replacement": "$1 $2", "capitalize_group": 2},
        {"pattern": "^([a-ząćęłńóśźż])", "replacement": "$1", "capitalize_group": 1},
        {"pattern": "\\s{2,}", "replacement": " "}
    ]
}
```

### 7.3 Dictionary Application Order

1. **Pre-LLM**: Apply case-insensitive term replacements from dictionary
2. **LLM processing**: Grammar and punctuation correction (dictionary terms injected into prompt)
3. **Post-LLM**: Apply regex rules for spacing/formatting cleanup
4. **Final**: Abbreviation expansion (if enabled)

```swift
class DictionaryEngine {
    private var terms: [String: String] = [:]
    private var rules: [RegexRule] = []

    func preProcess(_ text: String) -> String {
        var result = text
        for (key, value) in terms {
            result = result.replacingOccurrences(of: key, with: value,
                                                  options: .caseInsensitive)
        }
        return result
    }

    func postProcess(_ text: String) -> String {
        var result = text
        for rule in rules {
            result = result.replacingOccurrences(of: rule.pattern, with: rule.replacement,
                                                  options: .regularExpression)
        }
        return result
    }
}
```

---

## 8. Auto-Paste System

### 8.1 Implementation

```swift
class AutoPaster {
    func paste(_ text: String) async {
        // 1. Save current clipboard
        let savedClipboard = NSPasteboard.general.string(forType: .string)

        // 2. Set new text
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)

        // 3. Small delay for pasteboard to update
        try? await Task.sleep(nanoseconds: 50_000_000)  // 50ms

        // 4. Simulate Cmd+V
        simulatePaste()

        // 5. Restore clipboard after a delay
        try? await Task.sleep(nanoseconds: 200_000_000)  // 200ms
        if let savedClipboard {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(savedClipboard, forType: .string)
        }
    }

    private func simulatePaste() {
        let source = CGEventSource(stateID: .combinedSessionState)

        // Key code 0x09 = V
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)

        keyDown?.flags = .maskCommand
        keyDown?.post(tap: .cgAnnotatedSessionEventTap)
        keyUp?.post(tap: .cgAnnotatedSessionEventTap)
    }
}
```

### 8.2 Required Permissions

The app must be granted **Accessibility** permission:
- System Settings > Privacy & Security > Accessibility > Add MySTT
- On first launch, show a dialog guiding the user to enable this
- Use `AXIsProcessTrusted()` to check if permission is granted

```swift
func checkAccessibilityPermission() -> Bool {
    let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): true] as CFDictionary
    return AXIsProcessTrustedWithOptions(options)
}
```

---

## 9. Configuration & API Switching

### 9.1 Settings Model

```swift
struct AppSettings: Codable {
    // STT
    var sttProvider: STTProvider = .whisperKit
    var whisperModel: String = "large-v3-turbo"  // auto-selected by device
    var deepgramAPIKey: String = ""

    // LLM
    var llmProvider: LLMProvider = .localMLX
    var mlxModel: String = "mlx-community/Qwen2.5-3B-Instruct-4bit"
    var ollamaModel: String = "qwen2.5:3b"
    var ollamaURL: String = "http://localhost:11434"
    var grokAPIKey: String = ""
    var groqAPIKey: String = ""
    var openaiAPIKey: String = ""

    // Post-processing
    var enablePunctuationModel: Bool = true
    var enableLLMCorrection: Bool = true
    var enableDictionary: Bool = true

    // Hotkey
    var hotkeyKeyCode: UInt16 = 0x3F  // Function key
    var hotkeyModifiers: CGEventFlags = []

    // Behavior
    var autoPaste: Bool = true
    var showNotification: Bool = true
    var playSound: Bool = true
    var launchAtLogin: Bool = false
}

enum STTProvider: String, CaseIterable, Codable {
    case whisperKit = "WhisperKit (Local)"
    case deepgram = "Deepgram (Cloud)"
}
```

### 9.2 Settings UI

```swift
struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @AppStorage("settings") var settings = AppSettings()

    var body: some View {
        TabView {
            GeneralSettingsTab(settings: $settings)
                .tabItem { Label("General", systemImage: "gear") }
            STTSettingsTab(settings: $settings)
                .tabItem { Label("Speech", systemImage: "mic") }
            LLMSettingsTab(settings: $settings)
                .tabItem { Label("LLM", systemImage: "brain") }
            DictionarySettingsTab(settings: $settings)
                .tabItem { Label("Dictionary", systemImage: "book") }
            HotkeySettingsTab(settings: $settings)
                .tabItem { Label("Hotkey", systemImage: "keyboard") }
        }
        .frame(width: 500, height: 400)
    }
}
```

The LLM settings tab shows:
- Dropdown to select provider (Local MLX / Local Ollama / Grok / Groq / OpenAI)
- Model name field (for local providers)
- API key field (for remote providers, stored in Keychain)
- "Test Connection" button
- Latency estimate display

---

## 10. Local LLM Guide for macOS

### 10.1 MLX (Recommended for MySTT)

**What it is**: Apple's machine learning framework optimized for Apple Silicon. MLX-LM is the text generation library built on it.

**Installation**:
```bash
pip3 install mlx-lm
```

**Download a model**:
```bash
# The model downloads automatically on first use, or pre-download:
python3 -c "from mlx_lm import load; load('mlx-community/Qwen2.5-3B-Instruct-4bit')"
```

**Available models (mlx-community on HuggingFace)**:

| Model | Size (4-bit) | RAM | Speed (M2) | Good for Polish |
|---|---|---|---|---|
| Qwen2.5-1.5B-Instruct-4bit | ~0.9 GB | ~3 GB | ~120 t/s | Decent |
| **Qwen2.5-3B-Instruct-4bit** | ~1.8 GB | ~4 GB | ~90 t/s | Good |
| Qwen2.5-7B-Instruct-4bit | ~4.2 GB | ~6 GB | ~50 t/s | Very Good |
| Llama-3.2-3B-Instruct-4bit | ~1.8 GB | ~4 GB | ~90 t/s | Moderate |
| Phi-3-mini-4k-instruct-4bit | ~2.1 GB | ~4 GB | ~80 t/s | Moderate |

**Why MLX is fastest**: It uses unified memory architecture on Apple Silicon - no CPU-GPU data transfer overhead. Benchmarks show 50% faster inference than Ollama's GGUF format.

### 10.2 Ollama

**Installation**:
```bash
brew install ollama
ollama serve  # Start the server (runs on port 11434)
```

**Pull recommended models**:
```bash
ollama pull qwen2.5:3b          # Best balance of speed + quality
ollama pull qwen2.5:7b          # Better Polish, needs 16GB RAM
```

**API is OpenAI-compatible**:
```bash
curl http://localhost:11434/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen2.5:3b",
    "messages": [{"role": "user", "content": "Fix: hello world how are you today"}],
    "temperature": 0.1
  }'
```

**Resource requirements**:

| Mac | RAM | Recommended Model | Speed |
|---|---|---|---|
| M1/M2 Air 8GB | 8 GB | qwen2.5:3b (Q4_K_S) | 60-90 t/s |
| M1/M2 Pro 16GB | 16 GB | qwen2.5:7b (Q4_K_M) | 30-50 t/s |
| M3 Pro 18GB | 18 GB | qwen2.5:7b (Q5_K_M) | 35-55 t/s |
| M3 Max 32GB+ | 32+ GB | qwen2.5:14b (Q5_K_M) | 20-30 t/s |

### 10.3 Running STT Locally with Whisper

WhisperKit handles this within the Swift app. For testing from CLI:

```bash
brew install whisperkit-cli
whisperkit-cli transcribe --model large-v3-turbo --audio-path recording.wav --language auto
```

### 10.4 Full Local Stack (No Internet Required)

For fully offline operation:
1. **STT**: WhisperKit with `large-v3-turbo` model (~1.6 GB download once)
2. **Punctuation**: `sdadas/byt5-text-correction` CoreML model (~1.2 GB)
3. **Grammar**: MLX + Qwen 2.5 3B 4-bit (~1.8 GB download once)

**Total disk**: ~4.6 GB for models
**Total RAM during operation**: ~6-8 GB (on 16 GB Mac, leaves plenty for other apps)
**Latency**: ~1.5-2.5 seconds total (STT ~1.2s + punctuation ~0.1s + LLM ~0.3s)

---

## 11. Data Flow

### 11.1 Happy Path (Hold-to-Talk)

```
1. User holds hotkey (e.g., Fn key)
   → HotkeyManager detects keyDown
   → AudioCaptureEngine.startRecording()
   → Status: 🔴 Recording (menu bar icon changes)

2. User releases hotkey
   → HotkeyManager detects keyUp
   → AudioCaptureEngine.stopRecording() → returns AVAudioPCMBuffer
   → Status: ⏳ Processing

3. STT Engine processes audio
   → WhisperKit.transcribe(audioBuffer)
   → Returns: STTResult { text: "hello world how are you today", language: .english }

4. Stage 1: Punctuation correction
   → byt5-text-correction("<en> hello world how are you today")
   → Returns: "Hello world, how are you today?"

5. Dictionary pre-processing
   → Apply term replacements (if any matches)

6. Stage 2: LLM grammar correction (if enabled)
   → LLMProvider.correctText("Hello world, how are you today?", ...)
   → Returns: "Hello world, how are you today?"
   (In this simple case, no change. For complex speech, fixes grammar.)

7. Dictionary post-processing
   → Apply regex rules for final cleanup

8. Auto-paste
   → Save clipboard → Set text → Simulate Cmd+V → Restore clipboard
   → Text appears in active window
   → Status: ✅ Done (brief flash, then back to ready)
```

### 11.2 Error Handling

```
STT fails → Show error notification, offer to retry
LLM fails → Skip Stage 2, paste Stage 1 output (still usable)
Ollama not running → Show notification "Start Ollama: ollama serve"
No internet + remote API selected → Fall back to local provider
No accessibility permission → Show setup guide dialog
```

---

## 12. Project Structure

```
MySTT/
├── MySTT.xcodeproj
├── MySTT/
│   ├── App/
│   │   ├── MySTTApp.swift              # App entry point, MenuBarExtra
│   │   ├── AppState.swift              # Central state manager
│   │   └── AppDelegate.swift           # For non-SwiftUI lifecycle needs
│   ├── Audio/
│   │   ├── AudioCaptureEngine.swift    # AVAudioEngine wrapper
│   │   └── AudioBuffer+Extensions.swift
│   ├── STT/
│   │   ├── STTEngineProtocol.swift     # Protocol definition
│   │   ├── WhisperKitEngine.swift      # WhisperKit implementation
│   │   └── DeepgramEngine.swift        # Cloud fallback
│   ├── PostProcessing/
│   │   ├── PostProcessor.swift         # Orchestrates Stage 1 + 2
│   │   ├── PunctuationCorrector.swift  # byt5-text-correction wrapper
│   │   └── DictionaryEngine.swift      # Term replacement + rules
│   ├── LLM/
│   │   ├── LLMProviderProtocol.swift   # Protocol definition
│   │   ├── MLXProvider.swift           # Local MLX inference
│   │   ├── OllamaProvider.swift        # Local Ollama HTTP
│   │   ├── GrokProvider.swift          # Remote Grok API
│   │   ├── GroqProvider.swift          # Remote Groq API
│   │   └── OpenAIProvider.swift        # Remote OpenAI API
│   ├── Hotkey/
│   │   ├── HotkeyManager.swift         # CGEvent tap for global hotkey
│   │   └── KeyCodes.swift              # Virtual key code constants
│   ├── Paste/
│   │   └── AutoPaster.swift            # NSPasteboard + CGEvent Cmd+V
│   ├── UI/
│   │   ├── MenuBarView.swift           # Menu bar dropdown content
│   │   ├── SettingsView.swift          # Settings window
│   │   ├── STTSettingsTab.swift
│   │   ├── LLMSettingsTab.swift
│   │   ├── DictionarySettingsTab.swift
│   │   ├── HotkeySettingsTab.swift
│   │   └── OnboardingView.swift        # First-launch permissions guide
│   ├── Models/
│   │   ├── AppSettings.swift           # Settings model (Codable)
│   │   ├── Language.swift              # Language enum
│   │   └── STTResult.swift             # Transcription result model
│   ├── Utilities/
│   │   ├── KeychainManager.swift       # Secure API key storage
│   │   ├── SoundPlayer.swift           # Recording start/stop sounds
│   │   └── PermissionChecker.swift     # Accessibility + Microphone checks
│   └── Resources/
│       ├── Assets.xcassets
│       ├── Sounds/
│       │   ├── start_recording.aiff
│       │   └── stop_recording.aiff
│       └── default_dictionary.json
├── Scripts/
│   ├── mlx_infer.py                    # MLX inference helper
│   ├── punctuation_correct.py          # byt5 punctuation helper
│   └── setup_models.sh                 # Download models script
├── Tests/
│   ├── STTTests/
│   ├── PostProcessingTests/
│   ├── LLMProviderTests/
│   └── DictionaryTests/
└── architecture.md                     # This file
```

---

## 13. Dependencies

### Swift Package Manager

```swift
// Package.swift dependencies
dependencies: [
    .package(url: "https://github.com/argmaxinc/WhisperKit", from: "0.9.0"),
    .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", from: "2.0.0"),  // Optional: for UI shortcut recorder
]
```

### Python (bundled or system)

For MLX and punctuation model inference:
```bash
pip3 install mlx-lm transformers torch
```

Alternatively, bundle a minimal Python environment with the app using `py2app` or call system Python.

### System Frameworks

- `AVFoundation` - audio capture
- `Speech` - Apple STT (optional fallback)
- `ApplicationServices` - CGEvent for hotkey + paste simulation
- `AppKit` - NSPasteboard
- `ServiceManagement` - launch at login (SMAppService)
- `Security` - Keychain for API keys
- `CoreML` - for running converted models natively

---

## 14. Build & Distribution

### 14.1 Build Requirements

- macOS 14.0+ (Sonoma) target
- Xcode 16.0+
- Apple Silicon recommended (Intel supported with reduced performance)

### 14.2 Entitlements

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "...">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <false/>  <!-- Required for CGEvent tap + Accessibility -->
    <key>com.apple.security.device.audio-input</key>
    <true/>
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
</dict>
</plist>
```

### 14.3 Info.plist Keys

```xml
<key>LSUIElement</key>
<true/>  <!-- Hide from Dock -->
<key>NSMicrophoneUsageDescription</key>
<string>MySTT needs microphone access to transcribe your speech.</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>MySTT uses speech recognition to convert your voice to text.</string>
```

### 14.4 Distribution

- **Not via Mac App Store** (CGEvent tap and Accessibility APIs require non-sandboxed app)
- Distribute via **Developer ID** signing + notarization
- Or direct `.dmg` download with ad-hoc signing for personal use

```bash
# Build release
xcodebuild -scheme MySTT -configuration Release -archivePath MySTT.xcarchive archive

# Create DMG
create-dmg MySTT.app MySTT.dmg
```

---

## 15. Performance Targets

| Metric | Target | How |
|---|---|---|
| Recording start latency | <50ms | Pre-initialized AVAudioEngine |
| STT processing (10s audio) | <1.5s | WhisperKit large-v3-turbo + CoreML |
| Punctuation correction | <100ms | byt5-text-correction or deepmultilingualpunctuation |
| LLM correction (local) | <500ms | MLX Qwen 2.5 3B, temp=0.1, max_tokens=512 |
| LLM correction (remote) | <1000ms | Groq Llama 3.1 8B |
| Auto-paste | <100ms | NSPasteboard + CGEvent |
| **Total end-to-end** | **<2.5s local, <3s remote** | Pipeline with early-exit for simple text |
| App memory (idle) | <100 MB | Models loaded on-demand |
| App memory (active) | <3 GB | WhisperKit + LLM loaded |
| App disk footprint | ~50 MB base | Models downloaded separately (~4.6 GB total) |
| Language detection accuracy | >95% | Whisper built-in language detection |

### Performance Optimization Strategies

1. **Lazy model loading**: Load WhisperKit model on first use, not app launch
2. **Model warm-up**: After first transcription, keep model in memory for instant subsequent use
3. **Pipeline early-exit**: If Stage 1 punctuation output looks clean (no grammar issues detected), skip Stage 2 LLM
4. **Streaming STT**: Process audio in chunks during recording for partial results
5. **Async processing**: Start punctuation correction while STT is still finalizing last segment
6. **Model quantization**: Use 4-bit quantized models for fastest inference with minimal quality loss

---

## Appendix A: Remote API Reference

### Grok API (xAI)
- Base URL: `https://api.x.ai/v1`
- Auth: `Authorization: Bearer YOUR_API_KEY`
- Format: OpenAI-compatible (chat/completions)
- Best model for this use case: `grok-4.1-fast` ($0.20/M input, $0.50/M output)
- Console: `console.x.ai`

### Groq API
- Base URL: `https://api.groq.com/openai/v1`
- Auth: `Authorization: Bearer YOUR_API_KEY`
- Format: OpenAI-compatible
- Best model: `llama-3.1-8b-instant` (~$0.05/M input, $0.08/M output)
- Console: `console.groq.com`

### OpenAI API
- Base URL: `https://api.openai.com/v1`
- Auth: `Authorization: Bearer YOUR_API_KEY`
- Best model: `gpt-4o-mini` ($0.15/M input, $0.60/M output)
- Console: `platform.openai.com`

### Deepgram (Cloud STT)
- Base URL: `https://api.deepgram.com/v1`
- Auth: `Authorization: Token YOUR_API_KEY`
- Best model: `nova-3` ($0.0043/min batch, $0.0077/min streaming)
- Console: `console.deepgram.com`

## Appendix B: Supported Languages

Whisper (used for STT) supports 99+ languages. The app auto-detects between English and Polish without any user intervention. The language detection result is passed to the post-processing pipeline so it can apply language-specific rules.

Polish-specific considerations:
- Polish diacritical characters (ą, ć, ę, ł, ń, ó, ś, ź, ż) are handled by both the punctuation model and the LLM
- The `sdadas/byt5-text-correction` model has native Polish support (prefix: `<pl>`)
- Whisper's Polish WER with large-v3-turbo is ~5% (very good)
- For best Polish quality in LLM correction, use Bielik-11B-v3.0-Instruct (outperforms 70B models on Polish benchmarks)

---

## Appendix C: Implementation Changes (2026-03-18)

### C.1 LM Studio replaces Ollama

Ollama has been replaced by **LM Studio** as the local LLM provider:
- LM Studio server runs on `http://localhost:1234/v1` (OpenAI-compatible API)
- `LMStudioProvider.swift` replaces `OllamaProvider.swift`
- `LLMProvider` enum: `.localLMStudio` replaces `.localOllama`
- LM Studio supports both GGUF and MLX model formats
- MLX backend is 20-50% faster than GGUF on Apple Silicon

### C.2 Bielik-11B for Polish

**Bielik-11B-v3.0-Instruct** (by SpeakLeash/Polish NLP) is the recommended model:
- Purpose-built for Polish - outperforms Qwen2-72B and Llama-3-70B on Polish benchmarks
- 11B parameters, Q4_K_M quantization = 6.72 GB
- Tested response time on M5 Max: **0.87s** (English), **1.2s** (Polish)
- Excellent diacritics restoration: `swiecie` → `świecie`, `sie` → `się`, `pracuje` → `pracuję`
- Also handles English well

### C.3 Fn Key Toggle Mode

Changed from hold-to-talk to **toggle mode**:
- **Press Fn once** → recording starts (overlay appears)
- **Press Fn again** → recording stops, processing begins
- Uses `NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged)` because CGEvent tap cannot capture Fn/Globe key when macOS has it set to emoji/dictation mode
- Fallback: CGEvent tap still works for non-Fn keys (F5, Right Option, etc.)

### C.4 Recording Overlay Visualizer

New floating window (`RecordingOverlay.swift` + `RecordingOverlayWindow`):
- Small semi-transparent window centered on screen
- Pulsing red mic icon during recording
- Animated dots showing recording is active
- Status text: "Listening..." → "Processing..." → "Done!"
- Auto-hides 1.5s after processing completes
- `NSWindow` level `.floating`, ignores mouse events, borderless

### C.5 Settings Window Fix

Settings button was not working because SPM-built apps need `NSApp.activate(ignoringOtherApps: true)` before sending the settings action. Fixed in `MySTTApp.swift`.

### C.6 Recommended Models for M5 Max 128GB

| Model | Size | Speed (M5 Max) | Best for |
|---|---|---|---|
| **Bielik-11B-v3.0** (Q4_K_M) | 6.7 GB | ~60 tok/s | **Polish** (primary choice) |
| Qwen3.5-4B-Instruct (MLX FP16) | ~8 GB | ~150 tok/s | English (ultra-fast) |
| Qwen2.5-7B-Instruct (MLX 8bit) | 8.1 GB | ~90 tok/s | Universal EN+PL |
| Qwen2.5-14B-Instruct (MLX 8bit) | ~15 GB | ~55 tok/s | Highest quality |

All 4 loaded simultaneously = ~38 GB of 128 GB RAM.

### C.7 Build System

Project uses **Swift Package Manager** (not Xcode project) for building:
```bash
cd MySTT && swift build && .build/arm64-apple-macosx/debug/MySTT
```
No Xcode installation required. Dependencies resolved via SPM (WhisperKit).

---

## Appendix D: Implementation Changes (2026-03-18, batch 2)

### D.1 WhisperKit Model Name Fix

The STT model name was incorrect (`large-v3-turbo` does not exist in the WhisperKit repo).
Fixed to use exact repo names from `argmaxinc/whisperkit-coreml`:

| UI Name | Actual Model ID | Size |
|---|---|---|
| **Large V3 Turbo 632MB (default)** | `openai_whisper-large-v3-v20240930_turbo_632MB` | 632 MB |
| Large V3 Turbo 954MB | `openai_whisper-large-v3_turbo_954MB` | 954 MB |
| Large V3 947MB | `openai_whisper-large-v3_947MB` | 947 MB |
| Small 216MB | `openai_whisper-small_216MB` | 216 MB |
| Base | `openai_whisper-base` | ~140 MB |

### D.2 Settings Window Fix (final)

Previous approaches (`NSApp.sendAction(showSettingsWindow:)`, `NSPanel` with `.floating`) did not work for SPM-built menu bar apps.

Working solution: `NSApp.setActivationPolicy(.regular)` before opening the window. This temporarily promotes the app from menu-bar-only to a normal app with window focus. When the settings window closes, reverts to `.accessory` via `NSWindowDelegate.windowWillClose`.

Implementation: `SettingsWindowManager` singleton with `NSWindowDelegate`.

### D.3 LLM Test Connection Button

The "Test Connection" button in LLM Settings tab now actually works:
- Sends a test request to the configured LLM provider
- Shows spinner during test
- Displays result: "OK: response (latency)" in green or "FAIL: error" in red
- Works for all providers: LM Studio, MLX, Grok, Groq, OpenAI

### D.4 Hotkey Tab: Tap-to-Speak Mode

Added recording mode selection in Hotkey settings:
- **Tap to speak** (default): Press Fn once to start, press again to stop
- **Hold to speak**: Hold Fn while speaking, release to stop
- Radio group picker with description text for each mode

### D.5 Model Status in General Settings

New "Model Status" section at the top of General settings tab:
- **STT Model**: green checkmark "Ready" / orange spinner "Downloading..." / red "Not loaded" + "Download Now" button
- **LLM Model**: green checkmark "Ready" / red "Not available"
- STT model auto-downloads on app launch (not on first Fn press)
- LLM status checks if Bielik responds on `127.0.0.1:1234`

### D.6 Recording Overlay Redesign

Changed from large centered overlay to small capsule at bottom center:
- Black capsule with status dot + text: "Listening..." / "Processing..." / "Done!"
- Positioned 40px from bottom of screen, centered horizontally
- `@MainActor` class to prevent cross-thread NSWindow crashes
- Stateless view (no `@EnvironmentObject`) - receives status enum directly

### D.7 Dictionary: Delete Functionality + Empty Default

- Each dictionary term now has a red trash icon button for deletion
- "Remove All" button to clear entire dictionary
- "Reset to Defaults" button to restore bundled defaults
- Default dictionary shipped empty (no pre-populated terms)
- User adds their own terms through Settings → Dictionary tab

### D.8 LM Studio Integration (127.0.0.1)

- All LM Studio URLs use `127.0.0.1` (not `localhost`) for reliability
- Default model: `bielik-11b-v3.0-instruct`
- API key: `lm-studio` (dummy, required by OpenAI-compatible format)
- Context: 4096 tokens (GGUF)
