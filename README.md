# MySTT — Local Speech-to-Text for macOS

<p align="center">
  <img src="MySTT/MySTT/Assets.xcassets/AppIcon.appiconset/icon_256x256.png" width="128" height="128" alt="MySTT Icon">
</p>

MySTT is a privacy-focused, offline-first speech-to-text application for macOS. Press a hotkey, speak in **Polish** or **English**, and get corrected, properly formatted text pasted directly into any app.

## Features

- **Fully Offline STT** — Uses [WhisperKit](https://github.com/argmaxinc/WhisperKit) with CoreML for on-device speech recognition. No internet required.
- **Bilingual** — Automatic Polish/English detection. Speaks Polish? Gets Polish. Speaks English? Gets English.
- **LLM Text Correction** — Optional grammar/punctuation correction via local LLM (LM Studio, Bielik-11B) or cloud APIs (Groq, OpenAI).
- **4-Stage Post-Processing** — Dictionary pre-processing → punctuation correction → LLM grammar fix → dictionary post-processing.
- **Auto-Paste** — Transcribed text is automatically pasted into the active application.
- **Custom Dictionary** — Add your own terms, abbreviations, and formatting rules.
- **Hotkey Modes** — Tap-to-speak (press once, press again to stop) or hold-to-speak (push-to-talk).
- **Menu Bar App** — Lives in your menu bar, always ready.

## Quick Start (Download)

1. Download `MySTT.dmg` from [`MySTT/build/MySTT.dmg`](MySTT/build/MySTT.dmg)
2. Open the DMG and drag **MySTT.app** to `/Applications`
3. Launch MySTT — it will appear in your menu bar
4. Grant permissions when prompted (Microphone, Accessibility, Automation)
5. Wait for the WhisperKit model to download and compile (~2 min on first launch)
6. Press **Fn** and start speaking

## Requirements

- **macOS 14.0+** (Sonoma or later)
- **Apple Silicon** (M1/M2/M3/M4/M5) — required for WhisperKit CoreML inference
- ~700 MB disk space for the default WhisperKit model (large-v3-turbo)
- Microphone access

## Build from Source

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/MySTT.git
cd MySTT/MySTT

# Build and install (requires Xcode Command Line Tools)
swift build -c release

# Or use the build script (builds, signs, installs to /Applications, creates DMG)
bash Scripts/build_and_install.sh
```

### Build Script

The `Scripts/build_and_install.sh` script:
1. Builds a release binary with `swift build -c release`
2. Creates a proper `.app` bundle with icon and Info.plist
3. Signs with a stable identity (preserves permissions across rebuilds)
4. Installs to `/Applications/MySTT.app`
5. Creates `build/MySTT.dmg` for distribution

> **Note:** For code signing, create a self-signed certificate named "MySTT Developer" in Keychain Access, or modify the `SIGNING_IDENTITY` variable in the script.

## Configuration

### STT (Speech-to-Text)

| Provider | Type | Model | Notes |
|----------|------|-------|-------|
| **WhisperKit** (default) | Local | large-v3-turbo (632MB) | Fully offline, auto-selected by RAM |
| Groq STT | Cloud | whisper-large-v3-turbo | Requires API key |

### LLM Correction (Optional)

| Provider | Type | Model | Notes |
|----------|------|-------|-------|
| **LM Studio** (default) | Local | qwen3-4b-2507 | Runs locally via LM Studio, fully offline |
| Groq | Cloud | llama-3.1-8b-instant | Requires API key |

### Hotkey Options

| Key | Description |
|-----|-------------|
| **Fn / Globe** (default) | Best for most users |
| Right/Left Option | Alternative modifier keys |
| Right Command | Alternative modifier key |
| F5, F6, F9 | Function keys |

## Permissions

MySTT needs these macOS permissions:

| Permission | Why |
|-----------|-----|
| **Microphone** | To capture your speech |
| **Accessibility** | For keyboard simulation (paste fallback) |
| **Automation → System Events** | To paste text into other apps via Cmd+V |

All permissions are requested on first launch. If something stops working after an update, check **System Settings → Privacy & Security**.

## Architecture

```
┌─────────────────────────────────────────────────┐
│                    MySTT App                     │
│                                                  │
│  Fn Key → AudioCapture → WhisperKit STT          │
│              ↓                                   │
│  Dictionary Pre-process → LLM Correction          │
│              ↓                                   │
│  Dictionary Post-process → Auto-Paste             │
└─────────────────────────────────────────────────┘
```

- **Protocol-driven** — `STTEngineProtocol`, `LLMProviderProtocol` make it easy to swap implementations
- **Language detection** — Transcribes as Polish first, detects if English, re-transcribes if needed
- **Safety guards** — Detects and rejects LLM hallucination, language switching, and text corruption

## Project Structure

```
MySTT/
├── Package.swift              # Dependencies (WhisperKit)
├── Scripts/
│   └── build_and_install.sh   # Build, sign, install, create DMG
└── MySTT/
    ├── App/                   # AppState, AppDelegate, entry point
    ├── Audio/                 # Microphone capture (AVAudioEngine)
    ├── STT/                   # WhisperKit engine, Groq STT
    ├── LLM/                   # LM Studio, Groq, OpenAI providers
    ├── PostProcessing/        # 4-stage text correction pipeline
    ├── Paste/                 # Auto-paste via AppleScript
    ├── Hotkey/                # Fn key monitoring (tap/hold modes)
    ├── Models/                # Data models, settings, enums
    ├── UI/                    # SwiftUI settings views
    ├── Utilities/             # Keychain, permissions, sound
    └── Resources/             # Assets, dictionary
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Dziękuję" every time | Your microphone is delivering silence. Check **System Settings → Sound → Input** — switch to a working mic. |
| Paste not working | Check **System Settings → Privacy → Automation** — enable System Events for MySTT. |
| Model takes long to load | First launch compiles CoreML models (~2 min). Subsequent launches use cached compilation. |
| LLM shows "Not available" | Ensure LM Studio is running with a model loaded, or add a cloud API key in Settings. |

## License

MIT

## Acknowledgments

- [WhisperKit](https://github.com/argmaxinc/WhisperKit) by Argmax — On-device speech recognition
- [Bielik](https://huggingface.co/speakleash/Bielik-11B-v3.0-Instruct) by SpeakLeash — Polish language model
