# Sessions for Plan Tasks - MySTT

## Informacje ogolne
- **Projekt**: MySTT - macOS Speech-to-Text Application
- **Zrodlo**: implementation-plan.md + architecture.md
- **Data utworzenia**: 2026-03-17
- **Laczna liczba sesji**: 18 (9 rund dzieki rownoleglosci)
- **Maksymalna rownoleglosc**: 4 sesje jednoczesnie

## Jak korzystac z tego pliku

1. Uruchamiaj sesje w kolejnosci rund (Runda 1 -> 2 -> 3 -> ... -> 9)
2. Sesje w tej samej rundzie oznaczone PARALLEL moga byc uruchamiane jednoczesnie
3. Sesje oznaczone SEQUENTIAL musza czekac na zakonczenie zaleznosci
4. Kazda sesja zawiera kompletny prompt - skopiuj go i wklej do nowej sesji Claude Code
5. Po wykonaniu kazdej sesji sprawdz Kryteria DONE
6. Nie rozpoczynaj kolejnej rundy dopoki wszystkie sesje w biezacej rundzie nie sa DONE

## Podsumowanie rund

| Runda | Sesje | Typ | Opis |
|-------|-------|-----|------|
| 1 | A | SEQ | Inicjalizacja Xcode |
| 2 | B, C, D, E | PAR | Fundamenty (Models, Audio, Hotkey, Paste) |
| 3 | F, G, H | PAR | Silniki (WhisperKit, LLM x5, Deepgram) |
| 4 | I, J, K | PAR | Integracja (Pipeline, Dictionary, Utilities) |
| 5 | L, M | PAR | UI (MenuBar, Settings) |
| 6 | N | SEQ | Pipeline end-to-end (AppState) |
| 7 | O | SEQ | Skrypty Python + modele |
| 8 | P, Q | SEQ | Testy (Unit -> Integration) |
| 9 | R | SEQ | Build + DMG |

## Status tracker

| Sesja | Zadanie | Status | Uwagi |
|-------|---------|--------|-------|
| A | 0.1 Xcode Init | TODO | |
| B | 1.1 Models | TODO | |
| C | 1.2 Audio | TODO | |
| D | 1.3 Hotkey | TODO | |
| E | 1.4 Paste | TODO | |
| F | 2.1 WhisperKit | TODO | |
| G | 2.2 LLM x5 | TODO | |
| H | 2.3 Deepgram | TODO | |
| I | 3.1 Pipeline | TODO | |
| J | 3.2 Dictionary | TODO | |
| K | 3.3 Utilities | TODO | |
| L | 4.1 MenuBar UI | TODO | |
| M | 4.2 Settings UI | TODO | |
| N | 5.1 AppState | TODO | |
| O | 6.1 Python Scripts | TODO | |
| P | 7.1 Unit Tests | TODO | |
| Q | 7.2 Integration Tests | TODO | |
| R | 8.1 Build + DMG | TODO | |

---


# RUNDY 1-3: Inicjalizacja + Fundamenty + Silniki



# ROUND 1 — Initialization

---

### Sesja A: Xcode Project Init
**Runda**: 1 | **Typ**: SEQUENTIAL | **Faza**: 0
**Agent**: `software-architect`
**Zależności**: Brak
**Pliki wyjściowe**: Kompletny projekt Xcode w `/Users/igor.3.wolak.external/Downloads/MySTT/MySTT/`

#### Prompt dla sesji Claude Code:

> **Cel**: Utworzenie projektu Xcode dla aplikacji macOS 14.0+ typu menu bar (MySTT) w katalogu `/Users/igor.3.wolak.external/Downloads/MySTT`.
>
> **KROK 1: Utwórz strukturę katalogów**
>
> Utwórz kompletną strukturę projektu:
> ```
> /Users/igor.3.wolak.external/Downloads/MySTT/
> └── MySTT/
>     ├── MySTT/
>     │   ├── App/
>     │   │   └── MySTTApp.swift
>     │   ├── Audio/
>     │   │   └── .gitkeep
>     │   ├── STT/
>     │   │   └── .gitkeep
>     │   ├── PostProcessing/
>     │   │   └── .gitkeep
>     │   ├── LLM/
>     │   │   └── .gitkeep
>     │   ├── Hotkey/
>     │   │   └── .gitkeep
>     │   ├── Paste/
>     │   │   └── .gitkeep
>     │   ├── UI/
>     │   │   └── .gitkeep
>     │   ├── Models/
>     │   │   └── .gitkeep
>     │   ├── Utilities/
>     │   │   └── .gitkeep
>     │   ├── Resources/
>     │   │   └── .gitkeep
>     │   ├── Info.plist
>     │   ├── MySTT.entitlements
>     │   └── Assets.xcassets/
>     │       ├── Contents.json
>     │       └── AppIcon.appiconset/
>     │           └── Contents.json
>     └── MySTT.xcodeproj/
>         └── project.pbxproj
> ```
>
> **KROK 2: Plik `MySTTApp.swift`**
>
> Utwórz `/Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/App/MySTTApp.swift` z nastepujaca zawartocia:
>
> ```swift
> import SwiftUI
>
> @main
> struct MySTTApp: App {
>     var body: some Scene {
>         MenuBarExtra("MySTT", systemImage: "mic.fill") {
>             VStack(spacing: 8) {
>                 Text("MySTT - Speech to Text")
>                     .font(.headline)
>                 Divider()
>                 Button("Ustawienia...") {
>                     NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
>                 }
>                 .keyboardShortcut(",", modifiers: .command)
>                 Button("Zakoncz") {
>                     NSApplication.shared.terminate(nil)
>                 }
>                 .keyboardShortcut("q", modifiers: .command)
>             }
>             .padding()
>         }
>
>         Settings {
>             Text("Ustawienia MySTT")
>                 .frame(width: 450, height: 300)
>         }
>     }
> }
> ```
>
> **KROK 3: Plik `Info.plist`**
>
> Utwórz `/Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Info.plist`:
>
> ```xml
> <?xml version="1.0" encoding="UTF-8"?>
> <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
> <plist version="1.0">
> <dict>
>     <key>LSUIElement</key>
>     <true/>
>     <key>NSMicrophoneUsageDescription</key>
>     <string>MySTT requires microphone access to capture speech for transcription.</string>
>     <key>NSSpeechRecognitionUsageDescription</key>
>     <string>MySTT uses speech recognition to convert your speech to text.</string>
>     <key>CFBundleName</key>
>     <string>MySTT</string>
>     <key>CFBundleDisplayName</key>
>     <string>MySTT</string>
>     <key>CFBundleIdentifier</key>
>     <string>com.mystt.app</string>
>     <key>CFBundleVersion</key>
>     <string>1</string>
>     <key>CFBundleShortVersionString</key>
>     <string>1.0.0</string>
>     <key>CFBundlePackageType</key>
>     <string>APPL</string>
>     <key>CFBundleExecutable</key>
>     <string>MySTT</string>
>     <key>LSMinimumSystemVersion</key>
>     <string>14.0</string>
> </dict>
> </plist>
> ```
>
> **KROK 4: Plik `MySTT.entitlements`**
>
> Utwórz `/Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/MySTT.entitlements`:
>
> ```xml
> <?xml version="1.0" encoding="UTF-8"?>
> <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
> <plist version="1.0">
> <dict>
>     <key>com.apple.security.app-sandbox</key>
>     <false/>
>     <key>com.apple.security.device.audio-input</key>
>     <true/>
>     <key>com.apple.security.files.user-selected.read-write</key>
>     <true/>
> </dict>
> </plist>
> ```
>
> **KROK 5: Plik `Package.swift` (SPM)**
>
> Utwórz `/Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Package.swift` -- NIE. Zamiast tego SPM jest konfigurowany bezposrednio w `project.pbxproj`. Pakiety SPM do dodania:
> - WhisperKit: `https://github.com/argmaxinc/WhisperKit`, from: `"0.9.0"`
> - KeyboardShortcuts: `https://github.com/sindresorhus/KeyboardShortcuts`, from: `"2.0.0"`
>
> **KROK 6: Plik `project.pbxproj`**
>
> Wygeneruj kompletny `project.pbxproj` w `/Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT.xcodeproj/project.pbxproj`. Plik musi:
> - Ustawic deployment target na macOS 14.0
> - Ustawic SWIFT_VERSION na 5.9
> - Dodac wszystkie pliki zrodlowe (MySTTApp.swift i .gitkeep z kazdego podkatalogu) do targetu
> - Skonfigurowac entitlements: `MySTT/MySTT.entitlements`
> - Skonfigurowac Info.plist: `MySTT/Info.plist`
> - Dodac SPM dependencies: WhisperKit (https://github.com/argmaxinc/WhisperKit, minVersion 0.9.0), KeyboardShortcuts (https://github.com/sindresorhus/KeyboardShortcuts, minVersion 2.0.0)
> - Ustawic PRODUCT_BUNDLE_IDENTIFIER na `com.mystt.app`
> - Ustawic CODE_SIGN_IDENTITY na "-" (sign to run locally)
> - Ustawic INFOPLIST_FILE na `MySTT/Info.plist`
> - Ustawic CODE_SIGN_ENTITLEMENTS na `MySTT/MySTT.entitlements`
> - Ustawic PRODUCT_NAME na `MySTT`
> - Ustawic COMBINE_HIDPI_IMAGES na YES
> - Wylczyc sandbox: ENABLE_APP_SANDBOX = NO
>
> Uzyj formatu pbxproj z poprawnymi UUID (wygeneruj 24-znakowe hex). Kazdy plik musi miec unikalne UUID dla PBXFileReference i PBXBuildFile. Wszystkie pliki .swift musza byc w Sources build phase. Struktura grup musi odpowiadac strukturze katalogow (App, Audio, STT, PostProcessing, LLM, Hotkey, Paste, UI, Models, Utilities, Resources).
>
> **KROK 7: Assets.xcassets**
>
> Utwórz `/Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Assets.xcassets/Contents.json`:
> ```json
> {
>   "info" : {
>     "author" : "xcode",
>     "version" : 1
>   }
> }
> ```
>
> Utwórz `/Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Assets.xcassets/AppIcon.appiconset/Contents.json`:
> ```json
> {
>   "images" : [
>     {
>       "idiom" : "mac",
>       "scale" : "1x",
>       "size" : "16x16"
>     },
>     {
>       "idiom" : "mac",
>       "scale" : "2x",
>       "size" : "16x16"
>     },
>     {
>       "idiom" : "mac",
>       "scale" : "1x",
>       "size" : "32x32"
>     },
>     {
>       "idiom" : "mac",
>       "scale" : "2x",
>       "size" : "32x32"
>     },
>     {
>       "idiom" : "mac",
>       "scale" : "1x",
>       "size" : "128x128"
>     },
>     {
>       "idiom" : "mac",
>       "scale" : "2x",
>       "size" : "128x128"
>     },
>     {
>       "idiom" : "mac",
>       "scale" : "1x",
>       "size" : "256x256"
>     },
>     {
>       "idiom" : "mac",
>       "scale" : "2x",
>       "size" : "256x256"
>     },
>     {
>       "idiom" : "mac",
>       "scale" : "1x",
>       "size" : "512x512"
>     },
>     {
>       "idiom" : "mac",
>       "scale" : "2x",
>       "size" : "512x512"
>     }
>   ],
>   "info" : {
>     "author" : "xcode",
>     "version" : 1
>   }
> }
> ```
>
> **WAZNE**: Nie usuwaj zadnych plików .gitkeep -- one sluza jako placeholdery. Pliki .gitkeep NIE powinny byc dodawane do pbxproj (nie sa plikami zrodlowymi).
>
> **ALTERNATYWNE PODEJSCIE (preferowane)**: Zamiast recznego tworzenia project.pbxproj (co jest skomplikowane i podatne na bledy), mozesz:
> 1. Sprawdzic czy `xcodebuild` jest dostepne
> 2. Jesli tak, uzyj `swift package init` z `Package.swift` aby zarzadzac zaleznosciami, ALBO wygeneruj projekt za pomoca narzedzia `xcodegen` jesli jest dostepne (`brew list xcodegen`)
> 3. Jesli xcodegen nie jest dostepny, utworz recznie poprawny pbxproj
>
> Jesli uzywasz xcodegen, utworz `/Users/igor.3.wolak.external/Downloads/MySTT/MySTT/project.yml`:
> ```yaml
> name: MySTT
> options:
>   bundleIdPrefix: com.mystt
>   deploymentTarget:
>     macOS: "14.0"
>   xcodeVersion: "15.0"
> packages:
>   WhisperKit:
>     url: https://github.com/argmaxinc/WhisperKit
>     from: "0.9.0"
>   KeyboardShortcuts:
>     url: https://github.com/sindresorhus/KeyboardShortcuts
>     from: "2.0.0"
> targets:
>   MySTT:
>     type: application
>     platform: macOS
>     sources:
>       - path: MySTT
>         excludes:
>           - "**/.gitkeep"
>     settings:
>       base:
>         INFOPLIST_FILE: MySTT/Info.plist
>         CODE_SIGN_ENTITLEMENTS: MySTT/MySTT.entitlements
>         CODE_SIGN_IDENTITY: "-"
>         ENABLE_APP_SANDBOX: NO
>         PRODUCT_BUNDLE_IDENTIFIER: com.mystt.app
>         SWIFT_VERSION: "5.9"
>         COMBINE_HIDPI_IMAGES: YES
>         PRODUCT_NAME: MySTT
>     dependencies:
>       - package: WhisperKit
>       - package: KeyboardShortcuts
>     info:
>       path: MySTT/Info.plist
>     entitlements:
>       path: MySTT/MySTT.entitlements
> ```
> Nastepnie uruchom `cd /Users/igor.3.wolak.external/Downloads/MySTT/MySTT && xcodegen generate`.
>
> **Jesli xcodegen nie jest dostepny**, utworz recznie poprawny pbxproj. Jest to dlugi plik -- upewnij sie ze:
> - Wszystkie sekcje sa obecne: PBXBuildFile, PBXFileReference, PBXGroup, PBXNativeTarget, PBXProject, PBXResourcesBuildPhase, PBXSourcesBuildPhase, PBXFrameworksBuildPhase, XCBuildConfiguration, XCConfigurationList, XCRemoteSwiftPackageReference, XCSwiftPackageProductDependency
> - archiveVersion = 1, objectVersion = 56 (Xcode 14+)
> - rootObject wskazuje na PBXProject
>
> Po wykonaniu uruchom weryfikacje. Jesli jakiekolwiek kryterium FAIL -- napraw -- ponowna weryfikacja -- powtarzaj max 5 razy -- jesli nadal FAIL -- zglos problem.

#### Weryfikacja (automatyczna po wykonaniu):

```bash
# 1. Sprawdz strukture katalogow
echo "=== Directory Structure ==="
find /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT -type d | sort
# Oczekiwane: App, Audio, STT, PostProcessing, LLM, Hotkey, Paste, UI, Models, Utilities, Resources, Assets.xcassets

# 2. Sprawdz kluczowe pliki
echo "=== Key Files ==="
ls -la /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/App/MySTTApp.swift
ls -la /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Info.plist
ls -la /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/MySTT.entitlements
ls -la /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT.xcodeproj/project.pbxproj

# 3. Sprawdz LSUIElement
echo "=== LSUIElement ==="
grep -c "LSUIElement" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Info.plist
# Oczekiwane: 1

# 4. Sprawdz entitlements
echo "=== Entitlements ==="
grep "app-sandbox" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/MySTT.entitlements
grep "audio-input" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/MySTT.entitlements
# Oczekiwane: false dla sandbox, true dla audio-input

# 5. Sprawdz SPM w pbxproj
echo "=== SPM Packages ==="
grep -c "WhisperKit" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT.xcodeproj/project.pbxproj
grep -c "KeyboardShortcuts" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT.xcodeproj/project.pbxproj
# Oczekiwane: >=1 dla kazdego

# 6. Sprawdz deployment target
echo "=== Deployment Target ==="
grep "MACOSX_DEPLOYMENT_TARGET" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT.xcodeproj/project.pbxproj | head -1
# Oczekiwane: 14.0

# 7. Sprawdz @main w MySTTApp
echo "=== App Entry Point ==="
grep "@main" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/App/MySTTApp.swift
grep "MenuBarExtra" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/App/MySTTApp.swift
# Oczekiwane: oba obecne

# 8. Sprawdz placeholdery
echo "=== Placeholder Files ==="
find /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT -name ".gitkeep" | wc -l
# Oczekiwane: >= 10

# 9. Proba kompilacji (moze wymagac SPM resolve)
echo "=== Build Check ==="
cd /Users/igor.3.wolak.external/Downloads/MySTT/MySTT && xcodebuild -project MySTT.xcodeproj -scheme MySTT -destination 'platform=macOS' -resolvePackageDependencies 2>&1 | tail -5
cd /Users/igor.3.wolak.external/Downloads/MySTT/MySTT && xcodebuild -project MySTT.xcodeproj -scheme MySTT -destination 'platform=macOS' build 2>&1 | tail -5
# Oczekiwane: BUILD SUCCEEDED (lub resolve succeeded)
```

#### Kryteria DONE:
- [ ] Katalog `/Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT.xcodeproj/project.pbxproj` istnieje i jest poprawnym plikiem pbxproj
- [ ] Wszystkie 11 podkatalogow istnieje (App, Audio, STT, PostProcessing, LLM, Hotkey, Paste, UI, Models, Utilities, Resources)
- [ ] `MySTTApp.swift` zawiera `@main`, `MenuBarExtra`, i `Settings` scene
- [ ] `Info.plist` zawiera `LSUIElement=true`, `NSMicrophoneUsageDescription`, `NSSpeechRecognitionUsageDescription`
- [ ] `MySTT.entitlements` zawiera sandbox=false, audio-input=true, files-rw=true
- [ ] SPM pakiety WhisperKit i KeyboardShortcuts sa skonfigurowane w projekcie
- [ ] Deployment target ustawiony na macOS 14.0
- [ ] Placeholdery `.gitkeep` istnieja we wszystkich podkatalogach
- [ ] Projekt kompiluje sie bez bledow (xcodebuild build SUCCEEDED)

---

# ROUND 2 — Core Foundations (4 sesje rownolegle)

---

### Sesja B: Models + Protocols
**Runda**: 2 | **Typ**: PARALLEL | **Faza**: 1
**Agent**: `swift-developer`
**Zależności**: Sesja A (projekt Xcode)
**Pliki wyjściowe**:
- `MySTT/MySTT/Models/Language.swift`
- `MySTT/MySTT/Models/STTResult.swift`
- `MySTT/MySTT/Models/TranscriptionSegment.swift`
- `MySTT/MySTT/Models/AppSettings.swift`
- `MySTT/MySTT/Models/LLMProvider.swift`
- `MySTT/MySTT/Models/STTProvider.swift`
- `MySTT/MySTT/Models/Errors.swift`
- `MySTT/MySTT/STT/STTEngineProtocol.swift`
- `MySTT/MySTT/LLM/LLMProviderProtocol.swift`
- `MySTT/MySTT/PostProcessing/PostProcessorProtocol.swift`

#### Prompt dla sesji Claude Code:

> **Cel**: Utworzenie wszystkich modeli danych i protokolow dla projektu MySTT -- macOS menu bar app do speech-to-text z korekcja LLM.
>
> **Kontekst projektu**: MySTT to aplikacja macOS 14.0+ (SwiftUI, menu bar) ktora nasluchuje mowy, transkrybuje ja (WhisperKit lub Deepgram), a nastepnie opcjonalnie poprawia tekst za pomoca LLM (lokalny MLX/Ollama lub chmurowy Grok/Groq/OpenAI). Wynik jest wklejany do aktywnej aplikacji.
>
> **Katalog roboczy projektu Xcode**: `/Users/igor.3.wolak.external/Downloads/MySTT/MySTT`
> **Katalog zrodlowy**: `/Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT`
>
> Utworz nastepujace 10 plikow. Kazdy plik musi byc kompletny, kompilowalny i gotowy do uzycia.
>
> ---
>
> **PLIK 1: `/Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Models/Language.swift`**
>
> ```swift
> import Foundation
>
> enum Language: String, CaseIterable, Codable, Identifiable {
>     case english = "en"
>     case polish = "pl"
>     case unknown = "unknown"
>
>     var id: String { rawValue }
>
>     var displayName: String {
>         switch self {
>         case .english: return "English"
>         case .polish: return "Polski"
>         case .unknown: return "Unknown"
>         }
>     }
>
>     /// Initialize from Whisper language code (handles variants like "en-US", "pl-PL")
>     init(whisperCode: String) {
>         let normalized = whisperCode.lowercased().trimmingCharacters(in: .whitespaces)
>         switch normalized {
>         case "en", "en-us", "en-gb", "en-au", "en-ca", "en-nz", "en-ie", "en-za", "english":
>             self = .english
>         case "pl", "pl-pl", "polish":
>             self = .polish
>         default:
>             if normalized.hasPrefix("en") {
>                 self = .english
>             } else if normalized.hasPrefix("pl") {
>                 self = .polish
>             } else {
>                 self = .unknown
>             }
>         }
>     }
> }
> ```
>
> ---
>
> **PLIK 2: `/Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Models/TranscriptionSegment.swift`**
>
> ```swift
> import Foundation
>
> struct TranscriptionSegment: Codable, Identifiable, Sendable {
>     let id: UUID
>     let text: String
>     let start: TimeInterval
>     let end: TimeInterval
>     let confidence: Float
>
>     init(text: String, start: TimeInterval, end: TimeInterval, confidence: Float) {
>         self.id = UUID()
>         self.text = text
>         self.start = start
>         self.end = end
>         self.confidence = confidence
>     }
>
>     var duration: TimeInterval {
>         end - start
>     }
> }
> ```
>
> ---
>
> **PLIK 3: `/Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Models/STTResult.swift`**
>
> ```swift
> import Foundation
>
> struct STTResult: Sendable {
>     let text: String
>     let language: Language
>     let confidence: Float
>     let segments: [TranscriptionSegment]
>
>     /// Convenience for empty/failed results
>     static let empty = STTResult(text: "", language: .unknown, confidence: 0.0, segments: [])
>
>     var isEmpty: Bool {
>         text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
>     }
> }
> ```
>
> ---
>
> **PLIK 4: `/Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Models/STTProvider.swift`**
>
> ```swift
> import Foundation
>
> enum STTProvider: String, CaseIterable, Codable, Identifiable {
>     case whisperKit = "whisperKit"
>     case deepgram = "deepgram"
>
>     var id: String { rawValue }
>
>     var displayName: String {
>         switch self {
>         case .whisperKit: return "WhisperKit (Local)"
>         case .deepgram: return "Deepgram (Cloud)"
>         }
>     }
>
>     var isLocal: Bool {
>         switch self {
>         case .whisperKit: return true
>         case .deepgram: return false
>         }
>     }
> }
> ```
>
> ---
>
> **PLIK 5: `/Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Models/LLMProvider.swift`**
>
> ```swift
> import Foundation
>
> enum LLMProvider: String, CaseIterable, Codable, Identifiable {
>     case localMLX = "localMLX"
>     case localOllama = "localOllama"
>     case grok = "grok"
>     case groq = "groq"
>     case openai = "openai"
>
>     var id: String { rawValue }
>
>     var displayName: String {
>         switch self {
>         case .localMLX: return "MLX (Local)"
>         case .localOllama: return "Ollama (Local)"
>         case .grok: return "Grok (xAI)"
>         case .groq: return "Groq Cloud"
>         case .openai: return "OpenAI"
>         }
>     }
>
>     var isLocal: Bool {
>         switch self {
>         case .localMLX, .localOllama: return true
>         case .grok, .groq, .openai: return false
>         }
>     }
>
>     var requiresAPIKey: Bool {
>         !isLocal
>     }
> }
> ```
>
> ---
>
> **PLIK 6: `/Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Models/AppSettings.swift`**
>
> ```swift
> import Foundation
>
> struct AppSettings: Codable {
>     // MARK: - STT Settings
>     var sttProvider: STTProvider = .whisperKit
>     var whisperModelName: String = "large-v3-turbo"
>     var deepgramAPIKey: String = ""
>
>     // MARK: - LLM Settings
>     var llmProvider: LLMProvider = .grok
>     var mlxModelName: String = "mlx-community/Qwen2.5-7B-Instruct-4bit"
>     var ollamaModelName: String = "llama3.1:8b"
>     var ollamaURL: String = "http://localhost:11434"
>     var grokAPIKey: String = ""
>     var groqAPIKey: String = ""
>     var openaiAPIKey: String = ""
>
>     // MARK: - Processing Settings
>     var punctuationEnabled: Bool = true
>     var llmCorrectionEnabled: Bool = true
>     var dictionaryEnabled: Bool = false
>     var customDictionary: [String: String] = [:]
>
>     // MARK: - Hotkey Settings
>     var hotkeyKeyCode: UInt16 = 0x3D  // Right Option key
>     var hotkeyModifiers: UInt32 = 0
>
>     // MARK: - Behavior Settings
>     var autoPaste: Bool = true
>     var showNotification: Bool = true
>     var playSound: Bool = false
>     var launchAtLogin: Bool = false
>
>     // MARK: - Persistence
>     private static let storageKey = "MySTTAppSettings"
>
>     static func load() -> AppSettings {
>         guard let data = UserDefaults.standard.data(forKey: storageKey),
>               let settings = try? JSONDecoder().decode(AppSettings.self, from: data) else {
>             return AppSettings()
>         }
>         return settings
>     }
>
>     func save() {
>         if let data = try? JSONEncoder().encode(self) {
>             UserDefaults.standard.set(data, forKey: storageKey)
>         }
>     }
> }
> ```
>
> ---
>
> **PLIK 7: `/Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Models/Errors.swift`**
>
> ```swift
> import Foundation
>
> enum STTError: LocalizedError {
>     case notInitialized
>     case emptyAudio
>     case transcriptionFailed(underlying: Error?)
>     case modelNotFound(name: String)
>     case timeout
>
>     var errorDescription: String? {
>         switch self {
>         case .notInitialized:
>             return "STT engine is not initialized."
>         case .emptyAudio:
>             return "Audio buffer is empty - no audio data to transcribe."
>         case .transcriptionFailed(let underlying):
>             return "Transcription failed: \(underlying?.localizedDescription ?? "unknown error")"
>         case .modelNotFound(let name):
>             return "STT model '\(name)' was not found."
>         case .timeout:
>             return "STT transcription timed out."
>         }
>     }
> }
>
> enum LLMError: LocalizedError {
>     case providerUnavailable(provider: String)
>     case apiKeyMissing(provider: String)
>     case requestFailed(statusCode: Int, message: String)
>     case timeout
>     case invalidResponse(details: String)
>
>     var errorDescription: String? {
>         switch self {
>         case .providerUnavailable(let provider):
>             return "LLM provider '\(provider)' is not available."
>         case .apiKeyMissing(let provider):
>             return "API key for '\(provider)' is missing. Please configure it in Settings."
>         case .requestFailed(let statusCode, let message):
>             return "LLM request failed with status \(statusCode): \(message)"
>         case .timeout:
>             return "LLM request timed out."
>         case .invalidResponse(let details):
>             return "Invalid LLM response: \(details)"
>         }
>     }
> }
>
> enum PasteError: LocalizedError {
>     case accessibilityDenied
>     case pasteFailed(underlying: Error?)
>
>     var errorDescription: String? {
>         switch self {
>         case .accessibilityDenied:
>             return "Accessibility permission is required for auto-paste. Please grant access in System Settings > Privacy & Security > Accessibility."
>         case .pasteFailed(let underlying):
>             return "Paste operation failed: \(underlying?.localizedDescription ?? "unknown error")"
>         }
>     }
> }
> ```
>
> ---
>
> **PLIK 8: `/Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/STT/STTEngineProtocol.swift`**
>
> ```swift
> import AVFoundation
>
> protocol STTEngineProtocol {
>     /// Transcribe audio buffer to text with language detection
>     func transcribe(audioBuffer: AVAudioPCMBuffer) async throws -> STTResult
>
>     /// Whether the engine is ready to transcribe
>     var isReady: Bool { get }
>
>     /// Prepare/warm up the engine (load models, etc.)
>     func prepare() async throws
> }
> ```
>
> ---
>
> **PLIK 9: `/Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/LLM/LLMProviderProtocol.swift`**
>
> ```swift
> import Foundation
>
> protocol LLMProviderProtocol {
>     /// Correct/improve transcribed text using LLM
>     /// - Parameters:
>     ///   - text: Raw transcribed text
>     ///   - language: Detected language of the text
>     ///   - dictionary: Custom dictionary for domain-specific term replacement (key=wrong, value=correct)
>     /// - Returns: Corrected text
>     func correctText(_ text: String, language: Language, dictionary: [String: String]) async throws -> String
>
>     /// Display name of this provider
>     var providerName: String { get }
>
>     /// Whether the provider is currently available (model loaded, API reachable, etc.)
>     func isAvailable() async -> Bool
> }
> ```
>
> ---
>
> **PLIK 10: `/Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/PostProcessing/PostProcessorProtocol.swift`**
>
> ```swift
> import Foundation
>
> protocol PostProcessorProtocol {
>     /// Process raw transcribed text (punctuation, formatting, corrections)
>     /// - Parameters:
>     ///   - rawText: The raw text from STT engine
>     ///   - language: Detected language
>     /// - Returns: Processed text
>     func process(_ rawText: String, language: Language) async throws -> String
> }
> ```
>
> ---
>
> **Po utworzeniu wszystkich plikow**: Usun pliki `.gitkeep` z katalogow `Models/`, `STT/`, `LLM/`, `PostProcessing/` (bo maja teraz prawdziwe pliki). Upewnij sie ze plik `.gitkeep` w pozostalych pustych katalogach (Audio, Hotkey, Paste, UI, Utilities, Resources) pozostaje.
>
> **WAZNE**: Wszystkie pliki musza kompilowac sie razem. Sprawdz ze:
> - `STTResult` uzywa `Language` i `TranscriptionSegment` -- oba zdefiniowane
> - `AppSettings` uzywa `STTProvider` i `LLMProvider` -- oba zdefiniowane
> - `STTEngineProtocol` uzywa `AVAudioPCMBuffer` (import AVFoundation) i `STTResult`
> - `LLMProviderProtocol` uzywa `Language`
> - `PostProcessorProtocol` uzywa `Language`
>
> Po wykonaniu uruchom weryfikacje. Jesli jakiekolwiek kryterium FAIL -- napraw -- ponowna weryfikacja -- powtarzaj max 5 razy -- jesli nadal FAIL -- zglos problem.

#### Weryfikacja (automatyczna po wykonaniu):

```bash
# 1. Sprawdz czy wszystkie 10 plikow istnieje
echo "=== File Existence ==="
for f in \
  /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Models/Language.swift \
  /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Models/STTResult.swift \
  /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Models/TranscriptionSegment.swift \
  /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Models/AppSettings.swift \
  /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Models/LLMProvider.swift \
  /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Models/STTProvider.swift \
  /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Models/Errors.swift \
  /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/STT/STTEngineProtocol.swift \
  /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/LLM/LLMProviderProtocol.swift \
  /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/PostProcessing/PostProcessorProtocol.swift; do
  if [ -f "$f" ]; then echo "OK: $f"; else echo "FAIL: $f"; fi
done

# 2. Sprawdz kluczowe elementy w plikach
echo "=== Key Elements ==="
grep -c "enum Language" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Models/Language.swift
grep -c "init(whisperCode:" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Models/Language.swift
grep -c "struct STTResult" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Models/STTResult.swift
grep -c "struct TranscriptionSegment" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Models/TranscriptionSegment.swift
grep -c "struct AppSettings" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Models/AppSettings.swift
grep -c "hotkeyKeyCode" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Models/AppSettings.swift
grep -c "enum LLMProvider" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Models/LLMProvider.swift
grep -c "localMLX" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Models/LLMProvider.swift
grep -c "enum STTProvider" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Models/STTProvider.swift
grep -c "enum STTError" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Models/Errors.swift
grep -c "enum LLMError" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Models/Errors.swift
grep -c "enum PasteError" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Models/Errors.swift
grep -c "protocol STTEngineProtocol" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/STT/STTEngineProtocol.swift
grep -c "func transcribe" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/STT/STTEngineProtocol.swift
grep -c "protocol LLMProviderProtocol" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/LLM/LLMProviderProtocol.swift
grep -c "func correctText" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/LLM/LLMProviderProtocol.swift
grep -c "protocol PostProcessorProtocol" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/PostProcessing/PostProcessorProtocol.swift
# Oczekiwane: kazdy grep zwraca 1

# 3. Sprawdz kompilacje (syntax check)
echo "=== Swift Syntax Check ==="
cd /Users/igor.3.wolak.external/Downloads/MySTT/MySTT && \
  xcrun swiftc -typecheck \
  MySTT/Models/Language.swift \
  MySTT/Models/TranscriptionSegment.swift \
  MySTT/Models/STTResult.swift \
  MySTT/Models/STTProvider.swift \
  MySTT/Models/LLMProvider.swift \
  MySTT/Models/AppSettings.swift \
  MySTT/Models/Errors.swift \
  -sdk $(xcrun --show-sdk-path --sdk macosx) \
  -target arm64-apple-macosx14.0 \
  2>&1
# Oczekiwane: brak bledow
```

#### Kryteria DONE:
- [ ] Wszystkie 10 plikow istnieje we wlasciwych katalogach
- [ ] `Language` enum ma case english, polish, unknown oraz `init(whisperCode:)` obslugujacy warianty
- [ ] `STTResult` struct ma pola text, language, confidence, segments
- [ ] `TranscriptionSegment` struct ma pola text, start, end, confidence
- [ ] `AppSettings` struct ma WSZYSTKIE pola: sttProvider, whisperModelName, deepgramAPIKey, llmProvider, mlxModelName, ollamaModelName, ollamaURL, grokAPIKey, groqAPIKey, openaiAPIKey, punctuationEnabled, llmCorrectionEnabled, dictionaryEnabled, customDictionary, hotkeyKeyCode, hotkeyModifiers, autoPaste, showNotification, playSound, launchAtLogin
- [ ] `AppSettings` ma metody `load()` i `save()` z UserDefaults
- [ ] `LLMProvider` enum ma case localMLX, localOllama, grok, groq, openai z computed `isLocal`
- [ ] `STTProvider` enum ma case whisperKit, deepgram
- [ ] `Errors.swift` definiuje STTError, LLMError, PasteError z wszystkimi case'ami
- [ ] `STTEngineProtocol` ma `func transcribe(audioBuffer: AVAudioPCMBuffer) async throws -> STTResult`
- [ ] `LLMProviderProtocol` ma `func correctText(_:language:dictionary:) async throws -> String`
- [ ] `PostProcessorProtocol` ma `func process(_:language:) async throws -> String`
- [ ] Pliki Models kompiluja sie bez bledow (swift typecheck)

---

### Sesja C: Audio Capture Engine
**Runda**: 2 | **Typ**: PARALLEL | **Faza**: 1
**Agent**: `swift-developer`
**Zależności**: Sesja A (projekt Xcode)
**Pliki wyjściowe**:
- `MySTT/MySTT/Audio/AudioCaptureEngine.swift`
- `MySTT/MySTT/Audio/AudioBuffer+Extensions.swift`

#### Prompt dla sesji Claude Code:

> **Cel**: Utworzenie systemu przechwytywania audio z mikrofonu dla aplikacji MySTT -- macOS 14.0+ SwiftUI menu bar app do speech-to-text.
>
> **Kontekst**: Aplikacja nasluchuje mowy uzytkownika przez mikrofon (przytrzymanie klawisza hotkey), a nastepnie transkrybuje nagranie za pomoca WhisperKit lub Deepgram. Audio musi byc w formacie 16kHz, mono, Float32 -- wymaganym przez WhisperKit.
>
> **Katalog zrodlowy**: `/Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT`
>
> Utworz dokladnie 2 pliki:
>
> ---
>
> **PLIK 1: `/Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Audio/AudioCaptureEngine.swift`**
>
> ```swift
> import AVFoundation
> import Combine
>
> /// Captures audio from the default input device at 16kHz mono Float32
> /// (format required by WhisperKit).
> final class AudioCaptureEngine: ObservableObject {
>     @Published private(set) var isRecording = false
>
>     private let audioEngine = AVAudioEngine()
>     private var audioBufferList: [AVAudioPCMBuffer] = []
>     private let bufferLock = NSLock()
>
>     /// Target format: 16 kHz, mono, Float32
>     private let targetFormat = AVAudioFormat(
>         commonFormat: .pcmFormatFloat32,
>         sampleRate: 16000,
>         channels: 1,
>         interleaved: false
>     )!
>
>     /// Start recording from the default input device.
>     /// Audio data is accumulated internally until `stopRecording()` is called.
>     func startRecording() throws {
>         guard !isRecording else { return }
>
>         bufferLock.lock()
>         audioBufferList.removeAll()
>         bufferLock.unlock()
>
>         let inputNode = audioEngine.inputNode
>         let inputFormat = inputNode.outputFormat(forBus: 0)
>
>         guard inputFormat.sampleRate > 0 else {
>             throw NSError(domain: "AudioCaptureEngine", code: -1,
>                           userInfo: [NSLocalizedDescriptionKey: "No audio input device available."])
>         }
>
>         // Install tap on input node -- capture raw audio
>         inputNode.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { [weak self] buffer, _ in
>             guard let self = self else { return }
>
>             // Convert to target format (16kHz mono Float32) if needed
>             if let converted = self.convert(buffer: buffer, from: inputFormat) {
>                 self.bufferLock.lock()
>                 self.audioBufferList.append(converted)
>                 self.bufferLock.unlock()
>             }
>         }
>
>         audioEngine.prepare()
>         try audioEngine.start()
>
>         DispatchQueue.main.async {
>             self.isRecording = true
>         }
>     }
>
>     /// Stop recording and return the captured audio as a single buffer.
>     /// - Returns: Combined audio buffer in 16kHz mono Float32 format
>     func stopRecording() -> AVAudioPCMBuffer? {
>         guard isRecording else { return nil }
>
>         audioEngine.inputNode.removeTap(onBus: 0)
>         audioEngine.stop()
>
>         DispatchQueue.main.async {
>             self.isRecording = false
>         }
>
>         bufferLock.lock()
>         let buffers = audioBufferList
>         audioBufferList.removeAll()
>         bufferLock.unlock()
>
>         return mergeBuffers(buffers)
>     }
>
>     // MARK: - Private
>
>     /// Convert audio buffer to target 16kHz mono Float32 format
>     private func convert(buffer: AVAudioPCMBuffer, from sourceFormat: AVAudioFormat) -> AVAudioPCMBuffer? {
>         guard let targetFormat = self.targetFormat as AVAudioFormat?,
>               sourceFormat != targetFormat else {
>             // Already in correct format
>             return buffer
>         }
>
>         guard let converter = AVAudioConverter(from: sourceFormat, to: targetFormat) else {
>             return nil
>         }
>
>         let ratio = targetFormat.sampleRate / sourceFormat.sampleRate
>         let outputFrameCount = AVAudioFrameCount(Double(buffer.frameLength) * ratio)
>
>         guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat,
>                                                    frameCapacity: outputFrameCount) else {
>             return nil
>         }
>
>         var error: NSError?
>         var consumedAll = false
>
>         converter.convert(to: outputBuffer, error: &error) { _, outStatus in
>             if consumedAll {
>                 outStatus.pointee = .noDataNow
>                 return nil
>             }
>             outStatus.pointee = .haveData
>             consumedAll = true
>             return buffer
>         }
>
>         if let error = error {
>             print("[AudioCaptureEngine] Conversion error: \(error)")
>             return nil
>         }
>
>         return outputBuffer
>     }
>
>     /// Merge multiple audio buffers into a single continuous buffer
>     private func mergeBuffers(_ buffers: [AVAudioPCMBuffer]) -> AVAudioPCMBuffer? {
>         guard !buffers.isEmpty else { return nil }
>
>         let totalFrames = buffers.reduce(0) { $0 + $1.frameLength }
>         guard totalFrames > 0 else { return nil }
>
>         guard let mergedBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat,
>                                                    frameCapacity: totalFrames) else {
>             return nil
>         }
>
>         var offset: AVAudioFrameCount = 0
>         for buffer in buffers {
>             guard let srcData = buffer.floatChannelData?[0],
>                   let dstData = mergedBuffer.floatChannelData?[0] else { continue }
>
>             let frameCount = buffer.frameLength
>             dstData.advanced(by: Int(offset)).update(from: srcData, count: Int(frameCount))
>             offset += frameCount
>         }
>
>         mergedBuffer.frameLength = totalFrames
>         return mergedBuffer
>     }
>
>     deinit {
>         if isRecording {
>             audioEngine.inputNode.removeTap(onBus: 0)
>             audioEngine.stop()
>         }
>     }
> }
> ```
>
> ---
>
> **PLIK 2: `/Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Audio/AudioBuffer+Extensions.swift`**
>
> ```swift
> import AVFoundation
>
> extension AVAudioPCMBuffer {
>     /// Convert buffer to a flat Float array (channel 0 only)
>     var floatArray: [Float] {
>         guard let channelData = floatChannelData else { return [] }
>         let count = Int(frameLength)
>         return Array(UnsafeBufferPointer(start: channelData[0], count: count))
>     }
>
>     /// Convert buffer to WAV file data with proper 44-byte header
>     /// Format: RIFF/WAVE, PCM Float32, mono, 16kHz
>     func toWAVData() -> Data? {
>         guard let channelData = floatChannelData else { return nil }
>         let channelCount: UInt16 = 1
>         let sampleRate = UInt32(format.sampleRate)
>         let bitsPerSample: UInt16 = 32
>         let bytesPerSample = bitsPerSample / 8
>         let dataSize = UInt32(frameLength) * UInt32(channelCount) * UInt32(bytesPerSample)
>         let fileSize = 36 + dataSize  // total file size minus 8 bytes for RIFF header
>
>         var data = Data()
>         data.reserveCapacity(44 + Int(dataSize))
>
>         // RIFF header (12 bytes)
>         data.append(contentsOf: "RIFF".utf8)                       // ChunkID
>         data.append(contentsOf: withUnsafeBytes(of: fileSize.littleEndian) { Array($0) }) // ChunkSize
>         data.append(contentsOf: "WAVE".utf8)                       // Format
>
>         // fmt sub-chunk (24 bytes)
>         data.append(contentsOf: "fmt ".utf8)                       // Subchunk1ID
>         let fmtSize: UInt32 = 16
>         data.append(contentsOf: withUnsafeBytes(of: fmtSize.littleEndian) { Array($0) })  // Subchunk1Size
>         let audioFormat: UInt16 = 3  // IEEE Float
>         data.append(contentsOf: withUnsafeBytes(of: audioFormat.littleEndian) { Array($0) }) // AudioFormat
>         data.append(contentsOf: withUnsafeBytes(of: channelCount.littleEndian) { Array($0) }) // NumChannels
>         data.append(contentsOf: withUnsafeBytes(of: sampleRate.littleEndian) { Array($0) })   // SampleRate
>         let byteRate = sampleRate * UInt32(channelCount) * UInt32(bytesPerSample)
>         data.append(contentsOf: withUnsafeBytes(of: byteRate.littleEndian) { Array($0) })     // ByteRate
>         let blockAlign = channelCount * bytesPerSample
>         data.append(contentsOf: withUnsafeBytes(of: blockAlign.littleEndian) { Array($0) })   // BlockAlign
>         data.append(contentsOf: withUnsafeBytes(of: bitsPerSample.littleEndian) { Array($0) }) // BitsPerSample
>
>         // data sub-chunk (8 + dataSize bytes)
>         data.append(contentsOf: "data".utf8)                       // Subchunk2ID
>         data.append(contentsOf: withUnsafeBytes(of: dataSize.littleEndian) { Array($0) })  // Subchunk2Size
>
>         // Audio data -- Float32 samples from channel 0
>         let floatPtr = channelData[0]
>         let count = Int(frameLength)
>         let rawPtr = UnsafeRawBufferPointer(start: floatPtr, count: count * MemoryLayout<Float>.size)
>         data.append(contentsOf: rawPtr)
>
>         return data
>     }
> }
> ```
>
> ---
>
> **Po utworzeniu plikow**: Usun plik `.gitkeep` z katalogu `Audio/` (bo ma teraz prawdziwe pliki).
>
> Po wykonaniu uruchom weryfikacje. Jesli jakiekolwiek kryterium FAIL -- napraw -- ponowna weryfikacja -- powtarzaj max 5 razy -- jesli nadal FAIL -- zglos problem.

#### Weryfikacja (automatyczna po wykonaniu):

```bash
# 1. Sprawdz pliki
echo "=== File Existence ==="
ls -la /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Audio/AudioCaptureEngine.swift
ls -la /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Audio/AudioBuffer+Extensions.swift

# 2. Sprawdz kluczowe elementy
echo "=== Key Elements ==="
grep -c "class AudioCaptureEngine" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Audio/AudioCaptureEngine.swift
grep -c "@Published" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Audio/AudioCaptureEngine.swift
grep -c "func startRecording" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Audio/AudioCaptureEngine.swift
grep -c "func stopRecording" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Audio/AudioCaptureEngine.swift
grep -c "16000" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Audio/AudioCaptureEngine.swift
grep -c "pcmFormatFloat32" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Audio/AudioCaptureEngine.swift
grep -c "installTap" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Audio/AudioCaptureEngine.swift
grep -c "var floatArray" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Audio/AudioBuffer+Extensions.swift
grep -c "func toWAVData" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Audio/AudioBuffer+Extensions.swift
grep -c "RIFF" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Audio/AudioBuffer+Extensions.swift
# Oczekiwane: kazdy grep zwraca >= 1

# 3. Sprawdz WAV header size (44 bytes)
echo "=== WAV Header ==="
grep "44" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Audio/AudioBuffer+Extensions.swift
grep "fmt " /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Audio/AudioBuffer+Extensions.swift
grep "data" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Audio/AudioBuffer+Extensions.swift | head -3
# Oczekiwane: obecnosc RIFF, fmt, data chunks
```

#### Kryteria DONE:
- [ ] `AudioCaptureEngine.swift` istnieje i zawiera klase `AudioCaptureEngine`
- [ ] `AudioCaptureEngine` ma `@Published var isRecording`
- [ ] `startRecording()` konfiguruje tap na inputNode z konwersja do 16kHz mono Float32
- [ ] `stopRecording()` zwraca `AVAudioPCMBuffer?` z polaczonymi buforami
- [ ] Format docelowy to 16kHz, mono, Float32 (wymagany przez WhisperKit)
- [ ] Konwersja formatu (z natywnego formatu mikrofonu do 16kHz) jest zaimplementowana
- [ ] Thread safety: buforowanie chronione NSLock
- [ ] `deinit` poprawnie czysci zasoby (removeTap, stop)
- [ ] `AudioBuffer+Extensions.swift` istnieje z `floatArray` i `toWAVData()`
- [ ] `toWAVData()` generuje poprawny 44-bajtowy header WAV (RIFF, fmt, data chunks)
- [ ] WAV format: IEEE Float (audioFormat=3), mono, 16kHz, 32-bit

---

### Sesja D: Hotkey Manager
**Runda**: 2 | **Typ**: PARALLEL | **Faza**: 1
**Agent**: `swift-developer`
**Zależności**: Sesja A (projekt Xcode)
**Pliki wyjściowe**:
- `MySTT/MySTT/Hotkey/HotkeyManager.swift`
- `MySTT/MySTT/Hotkey/KeyCodes.swift`

#### Prompt dla sesji Claude Code:

> **Cel**: Utworzenie systemu globalnego hotkey (push-to-talk) dla aplikacji MySTT -- macOS 14.0+ menu bar app do speech-to-text.
>
> **Kontekst**: Uzytkownik przytrzymuje klawisz (domyslnie Right Option, keyCode 0x3D) zeby nagrywac mowe. Puszczenie klawisza konczy nagrywanie i uruchamia transkrypcje. System musi dzialac globalnie (nawet gdy aplikacja nie jest w focusie) za pomoca CGEvent tap. Wymaga uprawnien Accessibility.
>
> **Katalog zrodlowy**: `/Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT`
>
> Utworz dokladnie 2 pliki:
>
> ---
>
> **PLIK 1: `/Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Hotkey/HotkeyManager.swift`**
>
> ```swift
> import Cocoa
> import Carbon
>
> /// Manages global keyboard event monitoring for push-to-talk functionality.
> /// Uses CGEvent tap to intercept keyDown/keyUp events system-wide.
> /// Requires Accessibility permission.
> final class HotkeyManager: ObservableObject {
>     @Published private(set) var isListening = false
>     @Published var isEnabled = true
>
>     /// Called when the configured hotkey is pressed down (start recording)
>     var onRecordingStart: (() -> Void)?
>     /// Called when the configured hotkey is released (stop recording)
>     var onRecordingStop: (() -> Void)?
>
>     /// The key code to monitor (default: Right Option = 0x3D)
>     var keyCode: UInt16 = 0x3D
>     /// Optional modifier flags (default: 0 = no modifiers required)
>     var modifierFlags: UInt32 = 0
>
>     private var eventTap: CFMachPort?
>     private var runLoopSource: CFRunLoopSource?
>     private var isKeyDown = false
>
>     init() {}
>
>     /// Start listening for global keyboard events.
>     /// - Throws: Error if Accessibility permission is not granted
>     func startListening() throws {
>         guard !isListening else { return }
>
>         guard checkAccessibilityPermission() else {
>             throw NSError(
>                 domain: "HotkeyManager",
>                 code: -1,
>                 userInfo: [NSLocalizedDescriptionKey:
>                     "Accessibility permission is required. Please grant access in System Settings > Privacy & Security > Accessibility."]
>             )
>         }
>
>         let eventMask = (1 << CGEventType.keyDown.rawValue) |
>                         (1 << CGEventType.keyUp.rawValue) |
>                         (1 << CGEventType.flagsChanged.rawValue)
>
>         // Store self as a pointer for the callback
>         let selfPtr = Unmanaged.passUnretained(self).toOpaque()
>
>         guard let tap = CGEvent.tapCreate(
>             tap: .cgSessionEventTap,
>             place: .headInsertEventTap,
>             options: .defaultTap,
>             eventsOfInterest: CGEventMask(eventMask),
>             callback: hotkeyEventCallback,
>             userInfo: selfPtr
>         ) else {
>             throw NSError(
>                 domain: "HotkeyManager",
>                 code: -2,
>                 userInfo: [NSLocalizedDescriptionKey: "Failed to create CGEvent tap. Check Accessibility permissions."]
>             )
>         }
>
>         eventTap = tap
>         runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
>
>         if let source = runLoopSource {
>             CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
>         }
>
>         CGEvent.tapEnable(tap: tap, enable: true)
>
>         DispatchQueue.main.async {
>             self.isListening = true
>         }
>     }
>
>     /// Stop listening for keyboard events and clean up resources.
>     func stopListening() {
>         guard isListening else { return }
>
>         if let tap = eventTap {
>             CGEvent.tapEnable(tap: tap, enable: false)
>         }
>
>         if let source = runLoopSource {
>             CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
>         }
>
>         eventTap = nil
>         runLoopSource = nil
>         isKeyDown = false
>
>         DispatchQueue.main.async {
>             self.isListening = false
>         }
>     }
>
>     /// Check if Accessibility permission is granted
>     func checkAccessibilityPermission() -> Bool {
>         let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): true] as CFDictionary
>         return AXIsProcessTrustedWithOptions(options)
>     }
>
>     /// Handle a key event. Called from the C callback.
>     fileprivate func handleEvent(_ proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
>         guard isEnabled else { return Unmanaged.passUnretained(event) }
>
>         let code = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
>
>         // Handle modifier keys via flagsChanged
>         if type == .flagsChanged {
>             if code == keyCode {
>                 // Check if the modifier key is pressed or released
>                 let flags = event.flags
>                 let isModifierDown: Bool
>
>                 switch code {
>                 case 0x3A, 0x3D: // Left/Right Option
>                     isModifierDown = flags.contains(.maskAlternate)
>                 case 0x3B, 0x3E: // Left/Right Control
>                     isModifierDown = flags.contains(.maskControl)
>                 case 0x38, 0x3C: // Left/Right Shift
>                     isModifierDown = flags.contains(.maskShift)
>                 case 0x37, 0x36: // Left/Right Command
>                     isModifierDown = flags.contains(.maskCommand)
>                 default:
>                     isModifierDown = false
>                 }
>
>                 if isModifierDown && !isKeyDown {
>                     isKeyDown = true
>                     onRecordingStart?()
>                 } else if !isModifierDown && isKeyDown {
>                     isKeyDown = false
>                     onRecordingStop?()
>                 }
>             }
>             return Unmanaged.passUnretained(event)
>         }
>
>         // Handle regular keys via keyDown/keyUp
>         if type == .keyDown && code == keyCode && !isKeyDown {
>             isKeyDown = true
>             onRecordingStart?()
>             return nil  // Consume the event
>         }
>
>         if type == .keyUp && code == keyCode && isKeyDown {
>             isKeyDown = false
>             onRecordingStop?()
>             return nil  // Consume the event
>         }
>
>         return Unmanaged.passUnretained(event)
>     }
>
>     deinit {
>         stopListening()
>     }
> }
>
> // MARK: - CGEvent Callback (C function)
>
> private func hotkeyEventCallback(
>     proxy: CGEventTapProxy,
>     type: CGEventType,
>     event: CGEvent,
>     userInfo: UnsafeMutableRawPointer?
> ) -> Unmanaged<CGEvent>? {
>     // Re-enable tap if it was disabled by the system
>     if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
>         if let userInfo = userInfo {
>             let manager = Unmanaged<HotkeyManager>.fromOpaque(userInfo).takeUnretainedValue()
>             if let tap = manager.eventTap {
>                 CGEvent.tapEnable(tap: tap, enable: true)
>             }
>         }
>         return Unmanaged.passUnretained(event)
>     }
>
>     guard let userInfo = userInfo else {
>         return Unmanaged.passUnretained(event)
>     }
>
>     let manager = Unmanaged<HotkeyManager>.fromOpaque(userInfo).takeUnretainedValue()
>     return manager.handleEvent(proxy, type: type, event: event)
> }
> ```
>
> ---
>
> **PLIK 2: `/Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Hotkey/KeyCodes.swift`**
>
> ```swift
> import Foundation
>
> /// Virtual key codes for macOS keyboard events (Carbon/IOKit)
> struct KeyCodes {
>     // MARK: - Letters
>     static let a: UInt16 = 0x00
>     static let s: UInt16 = 0x01
>     static let d: UInt16 = 0x02
>     static let f: UInt16 = 0x03
>     static let h: UInt16 = 0x04
>     static let g: UInt16 = 0x05
>     static let z: UInt16 = 0x06
>     static let x: UInt16 = 0x07
>     static let c: UInt16 = 0x08
>     static let v: UInt16 = 0x09
>     static let b: UInt16 = 0x0B
>     static let q: UInt16 = 0x0C
>     static let w: UInt16 = 0x0D
>     static let e: UInt16 = 0x0E
>     static let r: UInt16 = 0x0F
>     static let y: UInt16 = 0x10
>     static let t: UInt16 = 0x11
>     static let o: UInt16 = 0x1F
>     static let u: UInt16 = 0x20
>     static let i: UInt16 = 0x22
>     static let p: UInt16 = 0x23
>     static let l: UInt16 = 0x25
>     static let j: UInt16 = 0x26
>     static let k: UInt16 = 0x28
>     static let n: UInt16 = 0x2D
>     static let m: UInt16 = 0x2E
>
>     // MARK: - Modifiers
>     static let leftShift: UInt16 = 0x38
>     static let leftControl: UInt16 = 0x3B
>     static let leftOption: UInt16 = 0x3A
>     static let leftCommand: UInt16 = 0x37
>     static let rightShift: UInt16 = 0x3C
>     static let rightControl: UInt16 = 0x3E
>     static let rightOption: UInt16 = 0x3D
>     static let rightCommand: UInt16 = 0x36
>     static let capsLock: UInt16 = 0x39
>     static let fn: UInt16 = 0x3F
>
>     // MARK: - Function Keys
>     static let f1: UInt16 = 0x7A
>     static let f2: UInt16 = 0x78
>     static let f3: UInt16 = 0x63
>     static let f4: UInt16 = 0x76
>     static let f5: UInt16 = 0x60
>     static let f6: UInt16 = 0x61
>     static let f7: UInt16 = 0x62
>     static let f8: UInt16 = 0x64
>     static let f9: UInt16 = 0x65
>     static let f10: UInt16 = 0x6D
>     static let f11: UInt16 = 0x67
>     static let f12: UInt16 = 0x6F
>
>     // MARK: - Special Keys
>     static let `return`: UInt16 = 0x24
>     static let tab: UInt16 = 0x30
>     static let space: UInt16 = 0x31
>     static let delete: UInt16 = 0x33
>     static let escape: UInt16 = 0x35
>     static let forwardDelete: UInt16 = 0x75
>
>     // MARK: - Arrow Keys
>     static let leftArrow: UInt16 = 0x7B
>     static let rightArrow: UInt16 = 0x7C
>     static let downArrow: UInt16 = 0x7D
>     static let upArrow: UInt16 = 0x7E
>
>     // MARK: - Code to Name mapping
>     static let codeToName: [UInt16: String] = [
>         0x00: "A", 0x01: "S", 0x02: "D", 0x03: "F",
>         0x04: "H", 0x05: "G", 0x06: "Z", 0x07: "X",
>         0x08: "C", 0x09: "V", 0x0B: "B", 0x0C: "Q",
>         0x0D: "W", 0x0E: "E", 0x0F: "R", 0x10: "Y",
>         0x11: "T", 0x1F: "O", 0x20: "U", 0x22: "I",
>         0x23: "P", 0x25: "L", 0x26: "J", 0x28: "K",
>         0x2D: "N", 0x2E: "M",
>         0x38: "Left Shift", 0x3B: "Left Control",
>         0x3A: "Left Option", 0x37: "Left Command",
>         0x3C: "Right Shift", 0x3E: "Right Control",
>         0x3D: "Right Option", 0x36: "Right Command",
>         0x39: "Caps Lock", 0x3F: "Fn",
>         0x7A: "F1", 0x78: "F2", 0x63: "F3", 0x76: "F4",
>         0x60: "F5", 0x61: "F6", 0x62: "F7", 0x64: "F8",
>         0x65: "F9", 0x6D: "F10", 0x67: "F11", 0x6F: "F12",
>         0x24: "Return", 0x30: "Tab", 0x31: "Space",
>         0x33: "Delete", 0x35: "Escape", 0x75: "Forward Delete",
>         0x7B: "Left Arrow", 0x7C: "Right Arrow",
>         0x7D: "Down Arrow", 0x7E: "Up Arrow",
>     ]
>
>     /// Get human-readable name for a key code
>     static func name(for code: UInt16) -> String {
>         codeToName[code] ?? "Key \(String(format: "0x%02X", code))"
>     }
> }
> ```
>
> ---
>
> **Po utworzeniu plikow**: Usun plik `.gitkeep` z katalogu `Hotkey/` (bo ma teraz prawdziwe pliki).
>
> **WAZNE uwagi dotyczace implementacji**:
> - `eventTap` musi byc `fileprivate` dostepny z poziomu callbacka -- uzyj `Unmanaged` do przekazania `self` jako userInfo
> - Callback musi byc wolna funkcja (nie closure) bo CGEvent tap wymaga C function pointer
> - Obsluga modifier keys (Option, Shift, etc.) wymaga `flagsChanged` event type, nie `keyDown/keyUp`
> - Re-enable tap jezeli system go wylaczyl (tapDisabledByTimeout)
>
> Po wykonaniu uruchom weryfikacje. Jesli jakiekolwiek kryterium FAIL -- napraw -- ponowna weryfikacja -- powtarzaj max 5 razy -- jesli nadal FAIL -- zglos problem.

#### Weryfikacja (automatyczna po wykonaniu):

```bash
# 1. Sprawdz pliki
echo "=== File Existence ==="
ls -la /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Hotkey/HotkeyManager.swift
ls -la /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Hotkey/KeyCodes.swift

# 2. Sprawdz kluczowe elementy HotkeyManager
echo "=== HotkeyManager Elements ==="
grep -c "class HotkeyManager" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Hotkey/HotkeyManager.swift
grep -c "CGEvent" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Hotkey/HotkeyManager.swift
grep -c "onRecordingStart" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Hotkey/HotkeyManager.swift
grep -c "onRecordingStop" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Hotkey/HotkeyManager.swift
grep -c "0x3D" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Hotkey/HotkeyManager.swift
grep -c "AXIsProcessTrustedWithOptions" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Hotkey/HotkeyManager.swift
grep -c "flagsChanged" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Hotkey/HotkeyManager.swift
grep -c "tapDisabledByTimeout" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Hotkey/HotkeyManager.swift
grep -c "deinit" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Hotkey/HotkeyManager.swift
# Oczekiwane: >= 1 dla kazdego

# 3. Sprawdz KeyCodes
echo "=== KeyCodes Elements ==="
grep -c "struct KeyCodes" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Hotkey/KeyCodes.swift
grep -c "rightOption" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Hotkey/KeyCodes.swift
grep -c "codeToName" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Hotkey/KeyCodes.swift
wc -l < /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Hotkey/KeyCodes.swift
# Oczekiwane: struct obecny, rightOption obecny, codeToName obecny, >= 80 linii
```

#### Kryteria DONE:
- [ ] `HotkeyManager.swift` istnieje z klasa `HotkeyManager: ObservableObject`
- [ ] CGEvent tap tworzony przez `CGEvent.tapCreate` z obsluga keyDown, keyUp, flagsChanged
- [ ] Domyslny keyCode to 0x3D (Right Option)
- [ ] Callbacki `onRecordingStart` i `onRecordingStop` sa wywolywalnym closures
- [ ] `isEnabled` property pozwala wlaczyc/wylaczyc nasluchianie
- [ ] Obsluga modifier keys przez `flagsChanged` event type (nie keyDown/keyUp)
- [ ] Re-enable tap po `tapDisabledByTimeout`
- [ ] `checkAccessibilityPermission()` uzywa `AXIsProcessTrustedWithOptions`
- [ ] `deinit` wywoluje `stopListening()` do czyszczenia zasobow
- [ ] `KeyCodes.swift` zawiera 20+ virtual key codes z `codeToName` dictionary
- [ ] Callback jest wolna funkcja C (nie closure) -- wymagane przez CGEvent tap API

---

### Sesja E: Auto-Paste System
**Runda**: 2 | **Typ**: PARALLEL | **Faza**: 1
**Agent**: `swift-developer`
**Zależności**: Sesja A (projekt Xcode)
**Pliki wyjściowe**:
- `MySTT/MySTT/Paste/AutoPaster.swift`
- `MySTT/MySTT/Utilities/PermissionChecker.swift`

#### Prompt dla sesji Claude Code:

> **Cel**: Utworzenie systemu automatycznego wklejania tekstu i sprawdzania uprawnien dla aplikacji MySTT -- macOS 14.0+ menu bar app do speech-to-text.
>
> **Kontekst**: Po transkrypcji i korekcji LLM, tekst jest automatycznie wklejany do aktywnej aplikacji. Metoda: zapisz biezacy clipboard, wstaw tekst do clipboard, symuluj Cmd+V (CGEvent), poczekaj, przywroc oryginalny clipboard. Wymaga uprawnien Accessibility.
>
> **Katalog zrodlowy**: `/Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT`
>
> Utworz dokladnie 2 pliki:
>
> ---
>
> **PLIK 1: `/Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Paste/AutoPaster.swift`**
>
> ```swift
> import Cocoa
> import Carbon
>
> /// Pastes text into the currently focused application by:
> /// 1. Saving the current clipboard content
> /// 2. Setting the transcribed text on the clipboard
> /// 3. Simulating Cmd+V keystroke via CGEvent
> /// 4. Restoring the original clipboard content after a delay
> final class AutoPaster {
>
>     /// Paste the given text into the currently active application.
>     /// - Parameter text: The text to paste
>     /// - Throws: `PasteError` if Accessibility is not granted or paste fails
>     func paste(_ text: String) async throws {
>         // Check accessibility permission
>         guard AXIsProcessTrusted() else {
>             throw PasteError.accessibilityDenied
>         }
>
>         let pasteboard = NSPasteboard.general
>
>         // 1. Save current clipboard content
>         let savedItems = savePasteboard(pasteboard)
>
>         // 2. Set our text on the clipboard
>         pasteboard.clearContents()
>         pasteboard.setString(text, forType: .string)
>
>         // 3. Small delay before simulating keystroke (let pasteboard settle)
>         try await Task.sleep(nanoseconds: 50_000_000) // 50ms
>
>         // 4. Simulate Cmd+V
>         simulatePaste()
>
>         // 5. Wait for the paste to complete, then restore clipboard
>         try await Task.sleep(nanoseconds: 200_000_000) // 200ms
>
>         // 6. Restore original clipboard
>         restorePasteboard(pasteboard, items: savedItems)
>     }
>
>     // MARK: - Private
>
>     /// Simulate Cmd+V keystroke using CGEvent
>     private func simulatePaste() {
>         let vKeyCode: CGKeyCode = 0x09  // 'V' key
>
>         let source = CGEventSource(stateID: .hidSystemState)
>
>         // Key down with Command modifier
>         let keyDown = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true)
>         keyDown?.flags = .maskCommand
>
>         // Key up with Command modifier
>         let keyUp = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false)
>         keyUp?.flags = .maskCommand
>
>         // Post events to the HID system
>         keyDown?.post(tap: .cghidEventTap)
>         keyUp?.post(tap: .cghidEventTap)
>     }
>
>     /// Save all items from the pasteboard for later restoration
>     private func savePasteboard(_ pasteboard: NSPasteboard) -> [(NSPasteboard.PasteboardType, Data)] {
>         var saved: [(NSPasteboard.PasteboardType, Data)] = []
>         guard let items = pasteboard.pasteboardItems else { return saved }
>
>         for item in items {
>             for type in item.types {
>                 if let data = item.data(forType: type) {
>                     saved.append((type, data))
>                 }
>             }
>         }
>         return saved
>     }
>
>     /// Restore previously saved items to the pasteboard
>     private func restorePasteboard(_ pasteboard: NSPasteboard, items: [(NSPasteboard.PasteboardType, Data)]) {
>         guard !items.isEmpty else { return }
>         pasteboard.clearContents()
>
>         let pasteboardItem = NSPasteboardItem()
>         for (type, data) in items {
>             pasteboardItem.setData(data, forType: type)
>         }
>         pasteboard.writeObjects([pasteboardItem])
>     }
> }
> ```
>
> ---
>
> **PLIK 2: `/Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Utilities/PermissionChecker.swift`**
>
> ```swift
> import AVFoundation
> import Cocoa
>
> /// Centralized permission checking for all system permissions required by MySTT.
> struct PermissionChecker {
>
>     // MARK: - Accessibility Permission
>
>     /// Check if Accessibility permission is granted.
>     /// - Parameter prompt: If true, shows the system prompt to grant access.
>     /// - Returns: True if permission is granted.
>     static func checkAccessibilityPermission(prompt: Bool = false) -> Bool {
>         if prompt {
>             let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): true] as CFDictionary
>             return AXIsProcessTrustedWithOptions(options)
>         }
>         return AXIsProcessTrusted()
>     }
>
>     // MARK: - Microphone Permission
>
>     /// Check if microphone permission is granted.
>     /// - Returns: True if permission is granted.
>     static func checkMicrophonePermission() -> Bool {
>         return AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
>     }
>
>     /// Request microphone permission asynchronously.
>     /// - Returns: True if permission was granted.
>     static func requestMicrophonePermission() async -> Bool {
>         let status = AVCaptureDevice.authorizationStatus(for: .audio)
>         switch status {
>         case .authorized:
>             return true
>         case .notDetermined:
>             return await AVCaptureDevice.requestAccess(for: .audio)
>         case .denied, .restricted:
>             return false
>         @unknown default:
>             return false
>         }
>     }
>
>     // MARK: - Combined Check
>
>     /// Check all required permissions and return a summary.
>     /// - Returns: Tuple with status for each permission.
>     static func checkAllPermissions() -> (microphone: Bool, accessibility: Bool) {
>         return (
>             microphone: checkMicrophonePermission(),
>             accessibility: checkAccessibilityPermission(prompt: false)
>         )
>     }
>
>     /// Open System Settings to the Accessibility pane.
>     static func openAccessibilitySettings() {
>         if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
>             NSWorkspace.shared.open(url)
>         }
>     }
>
>     /// Open System Settings to the Microphone pane.
>     static func openMicrophoneSettings() {
>         if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") {
>             NSWorkspace.shared.open(url)
>         }
>     }
> }
> ```
>
> ---
>
> **Po utworzeniu plikow**: Usun plik `.gitkeep` z katalogow `Paste/` i `Utilities/` (bo maja teraz prawdziwe pliki).
>
> Po wykonaniu uruchom weryfikacje. Jesli jakiekolwiek kryterium FAIL -- napraw -- ponowna weryfikacja -- powtarzaj max 5 razy -- jesli nadal FAIL -- zglos problem.

#### Weryfikacja (automatyczna po wykonaniu):

```bash
# 1. Sprawdz pliki
echo "=== File Existence ==="
ls -la /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Paste/AutoPaster.swift
ls -la /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Utilities/PermissionChecker.swift

# 2. Sprawdz AutoPaster
echo "=== AutoPaster Elements ==="
grep -c "class AutoPaster" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Paste/AutoPaster.swift
grep -c "func paste" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Paste/AutoPaster.swift
grep -c "NSPasteboard" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Paste/AutoPaster.swift
grep -c "CGEvent" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Paste/AutoPaster.swift
grep -c "0x09" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Paste/AutoPaster.swift
grep -c "maskCommand" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Paste/AutoPaster.swift
grep -c "50_000_000" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Paste/AutoPaster.swift
grep -c "200_000_000" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Paste/AutoPaster.swift
grep -c "savePasteboard" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Paste/AutoPaster.swift
grep -c "restorePasteboard" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Paste/AutoPaster.swift
# Oczekiwane: >= 1 dla kazdego

# 3. Sprawdz PermissionChecker
echo "=== PermissionChecker Elements ==="
grep -c "struct PermissionChecker" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Utilities/PermissionChecker.swift
grep -c "checkAccessibilityPermission" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Utilities/PermissionChecker.swift
grep -c "checkMicrophonePermission" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Utilities/PermissionChecker.swift
grep -c "AXIsProcessTrustedWithOptions" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Utilities/PermissionChecker.swift
grep -c "AVCaptureDevice" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Utilities/PermissionChecker.swift
grep -c "requestMicrophonePermission" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Utilities/PermissionChecker.swift
# Oczekiwane: >= 1 dla kazdego
```

#### Kryteria DONE:
- [ ] `AutoPaster.swift` istnieje z klasa `AutoPaster`
- [ ] `paste(_:)` jest async throws i wykonuje: save clipboard, set text, 50ms delay, simulate Cmd+V, 200ms delay, restore clipboard
- [ ] Symulacja Cmd+V uzywa CGEvent z keyCode 0x09 i `.maskCommand`
- [ ] Clipboard save/restore zachowuje wszystkie typy danych
- [ ] Sprawdzanie `AXIsProcessTrusted()` przed operacja paste
- [ ] `PermissionChecker.swift` istnieje z struct `PermissionChecker`
- [ ] `checkAccessibilityPermission()` uzywa `AXIsProcessTrustedWithOptions`
- [ ] `checkMicrophonePermission()` uzywa `AVCaptureDevice.authorizationStatus(for: .audio)`
- [ ] `requestMicrophonePermission()` jest async i uzywa `AVCaptureDevice.requestAccess`
- [ ] Metody pomocnicze `openAccessibilitySettings()` i `openMicrophoneSettings()` otwieraja odpowiednie panele System Settings

---

# ROUND 3 — STT + LLM Engines (3 sesje rownolegle)

---

### Sesja F: WhisperKit STT Engine
**Runda**: 3 | **Typ**: PARALLEL | **Faza**: 2
**Agent**: `swift-developer`
**Zależności**: Sesja B (STTEngineProtocol, STTResult, Language, TranscriptionSegment)
**Pliki wyjściowe**:
- `MySTT/MySTT/STT/WhisperKitEngine.swift`

#### Prompt dla sesji Claude Code:

> **Cel**: Implementacja silnika STT opartego na WhisperKit dla aplikacji MySTT -- macOS 14.0+ menu bar app.
>
> **Kontekst**: WhisperKit to biblioteka Swift do uruchamiania Whisper locally na Apple Silicon. Aplikacja uzywa go jako domyslnego providera STT. Model jest wybierany automatycznie na podstawie ilosci RAM: < 12GB -> "openai_whisper-small", >= 12GB -> "openai_whisper-large-v3-turbo". Audio wejsciowe to AVAudioPCMBuffer w formacie 16kHz mono Float32.
>
> **Katalog zrodlowy**: `/Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT`
>
> **Zaleznosci juz istnieja** (z Sesji B):
> - `STT/STTEngineProtocol.swift` -- protocol z `func transcribe(audioBuffer:) async throws -> STTResult`, `var isReady: Bool`, `func prepare() async throws`
> - `Models/STTResult.swift` -- struct z text, language, confidence, segments
> - `Models/Language.swift` -- enum z `init(whisperCode:)`
> - `Models/TranscriptionSegment.swift` -- struct z text, start, end, confidence
> - `Models/Errors.swift` -- STTError enum
>
> **SPM dependency**: WhisperKit (https://github.com/argmaxinc/WhisperKit, from: "0.9.0") -- juz dodany do projektu w Sesji A.
>
> Utworz dokladnie 1 plik:
>
> ---
>
> **PLIK 1: `/Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/STT/WhisperKitEngine.swift`**
>
> ```swift
> import AVFoundation
> import WhisperKit
>
> /// WhisperKit-based local STT engine.
> /// Automatically selects model size based on available RAM.
> /// Uses Apple Neural Engine + GPU for inference.
> final class WhisperKitEngine: STTEngineProtocol {
>     private var whisperKit: WhisperKit?
>     private var modelName: String
>     private(set) var isReady = false
>
>     init(modelName: String? = nil) {
>         self.modelName = modelName ?? Self.selectModel()
>     }
>
>     /// Select model based on available system RAM.
>     /// < 12 GB RAM -> "openai_whisper-small" (fast, lower quality)
>     /// >= 12 GB RAM -> "openai_whisper-large-v3-turbo" (best quality for Apple Silicon)
>     static func selectModel() -> String {
>         let totalRAM = ProcessInfo.processInfo.physicalMemory
>         let totalRAMGB = Double(totalRAM) / (1024 * 1024 * 1024)
>
>         if totalRAMGB < 12 {
>             return "openai_whisper-small"
>         } else {
>             return "openai_whisper-large-v3-turbo"
>         }
>     }
>
>     /// Prepare the engine: download model if needed, load into memory.
>     func prepare() async throws {
>         guard !isReady else { return }
>
>         do {
>             let config = WhisperKitConfig(
>                 model: modelName,
>                 computeOptions: ModelComputeOptions(
>                     audioEncoderCompute: .cpuAndNeuralEngine,
>                     textDecoderCompute: .cpuAndNeuralEngine
>                 ),
>                 verbose: false,
>                 prewarm: true
>             )
>             whisperKit = try await WhisperKit(config)
>             isReady = true
>         } catch {
>             throw STTError.modelNotFound(name: modelName)
>         }
>     }
>
>     /// Transcribe an audio buffer to text with language detection.
>     /// - Parameter audioBuffer: Audio in 16kHz mono Float32 format
>     /// - Returns: STTResult with transcribed text, detected language, and segments
>     func transcribe(audioBuffer: AVAudioPCMBuffer) async throws -> STTResult {
>         guard let whisperKit = whisperKit, isReady else {
>             throw STTError.notInitialized
>         }
>
>         // Convert AVAudioPCMBuffer to [Float] array
>         guard let channelData = audioBuffer.floatChannelData else {
>             throw STTError.emptyAudio
>         }
>         let frameCount = Int(audioBuffer.frameLength)
>         guard frameCount > 0 else {
>             throw STTError.emptyAudio
>         }
>
>         let floatArray = Array(UnsafeBufferPointer(start: channelData[0], count: frameCount))
>
>         // Configure decoding options
>         let options = DecodingOptions(
>             verbose: false,
>             task: .transcribe,
>             language: nil,  // Auto-detect language
>             temperature: 0.0,
>             temperatureFallbackCount: 3,
>             topK: 5,
>             usePrefillPrompt: true,
>             detectLanguage: true
>         )
>
>         do {
>             let results = try await whisperKit.transcribe(
>                 audioArray: floatArray,
>                 decodeOptions: options
>             )
>
>             guard let result = results.first else {
>                 return STTResult.empty
>             }
>
>             // Extract detected language
>             let detectedLanguage: Language
>             if let langCode = result.language {
>                 detectedLanguage = Language(whisperCode: langCode)
>             } else {
>                 detectedLanguage = .unknown
>             }
>
>             // Build segments from WhisperKit result
>             let segments: [TranscriptionSegment] = result.segments.map { segment in
>                 TranscriptionSegment(
>                     text: segment.text.trimmingCharacters(in: .whitespaces),
>                     start: segment.start,
>                     end: segment.end,
>                     confidence: segment.avgLogprob
>                 )
>             }
>
>             // Calculate overall confidence
>             let avgConfidence: Float
>             if !result.segments.isEmpty {
>                 avgConfidence = result.segments.reduce(0) { $0 + $1.avgLogprob } / Float(result.segments.count)
>             } else {
>                 avgConfidence = 0.0
>             }
>
>             let fullText = result.text.trimmingCharacters(in: .whitespacesAndNewlines)
>
>             return STTResult(
>                 text: fullText,
>                 language: detectedLanguage,
>                 confidence: avgConfidence,
>                 segments: segments
>             )
>         } catch {
>             throw STTError.transcriptionFailed(underlying: error)
>         }
>     }
> }
> ```
>
> **WAZNE**: WhisperKit API moze sie roznic miedzy wersjami. Powyzszy kod jest oparty na WhisperKit 0.9.x. Jesli API sie rozni:
> - Sprawdz importy: `import WhisperKit`
> - WhisperKit init moze przyjmowac `WhisperKitConfig` lub bezposrednie parametry
> - `DecodingOptions` moze miec inne nazwy pol
> - `TranscriptionResult` moze miec inna strukture
>
> Jesli kompilacja nie przechodzi z powodu zmian API WhisperKit, dostosuj kod do aktualnego API biblioteki. Mozesz sprawdzic API uruchamiajac:
> ```bash
> cd /Users/igor.3.wolak.external/Downloads/MySTT/MySTT
> xcodebuild -resolvePackageDependencies -project MySTT.xcodeproj -scheme MySTT 2>&1 | tail -20
> find ~/Library/Developer/Xcode/DerivedData -path "*/WhisperKit/Sources" -type d 2>/dev/null | head -1
> ```
> i czytajac zrodla WhisperKit aby dopasowac API.
>
> Usun `.gitkeep` z `STT/` jesli jeszcze istnieje (moze juz nie istniec po Sesji B).
>
> Po wykonaniu uruchom weryfikacje. Jesli jakiekolwiek kryterium FAIL -- napraw -- ponowna weryfikacja -- powtarzaj max 5 razy -- jesli nadal FAIL -- zglos problem.

#### Weryfikacja (automatyczna po wykonaniu):

```bash
# 1. Sprawdz plik
echo "=== File Existence ==="
ls -la /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/STT/WhisperKitEngine.swift

# 2. Sprawdz kluczowe elementy
echo "=== Key Elements ==="
grep -c "class WhisperKitEngine" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/STT/WhisperKitEngine.swift
grep -c "STTEngineProtocol" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/STT/WhisperKitEngine.swift
grep -c "import WhisperKit" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/STT/WhisperKitEngine.swift
grep -c "func transcribe" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/STT/WhisperKitEngine.swift
grep -c "func prepare" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/STT/WhisperKitEngine.swift
grep -c "selectModel" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/STT/WhisperKitEngine.swift
grep -c "physicalMemory" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/STT/WhisperKitEngine.swift
grep -c "whisper-small" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/STT/WhisperKitEngine.swift
grep -c "large-v3-turbo" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/STT/WhisperKitEngine.swift
grep -c "Language(whisperCode:" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/STT/WhisperKitEngine.swift
grep -c "detectLanguage" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/STT/WhisperKitEngine.swift
# Oczekiwane: >= 1 dla kazdego

# 3. Sprawdz model selection logic
echo "=== Model Selection ==="
grep "12" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/STT/WhisperKitEngine.swift | head -3
# Oczekiwane: warunek < 12 GB

# 4. Proba kompilacji (moze wymagac SPM resolve)
echo "=== Build Check ==="
cd /Users/igor.3.wolak.external/Downloads/MySTT/MySTT && xcodebuild -project MySTT.xcodeproj -scheme MySTT -destination 'platform=macOS' build 2>&1 | tail -10
# Oczekiwane: BUILD SUCCEEDED
```

#### Kryteria DONE:
- [ ] `WhisperKitEngine.swift` istnieje i importuje WhisperKit
- [ ] Klasa implementuje `STTEngineProtocol` (transcribe, isReady, prepare)
- [ ] `selectModel()` zwraca "openai_whisper-small" dla < 12GB RAM, "openai_whisper-large-v3-turbo" dla >= 12GB
- [ ] `prepare()` inicjalizuje WhisperKit z wybranym modelem i compute options (cpuAndNeuralEngine)
- [ ] `transcribe()` konwertuje AVAudioPCMBuffer do [Float] i wywoluje WhisperKit
- [ ] Wykrywanie jezyka jest wlaczone (detectLanguage: true) z mapowaniem na enum Language
- [ ] Segmenty transkrypcji sa mapowane na TranscriptionSegment
- [ ] Obsluga bledow: STTError.notInitialized, emptyAudio, transcriptionFailed, modelNotFound
- [ ] Warm-up pattern: prewarm=true w konfiguracji
- [ ] Kod kompiluje sie z WhisperKit SPM (lub bledy API sa rozwiazane)

---

### Sesja G: LLM Providers x5
**Runda**: 3 | **Typ**: PARALLEL | **Faza**: 2
**Agent**: `swift-developer`
**Zależności**: Sesja B (LLMProviderProtocol, Language, LLMError)
**Pliki wyjściowe**:
- `MySTT/MySTT/LLM/OpenAICompatibleClient.swift`
- `MySTT/MySTT/LLM/LLMPromptBuilder.swift`
- `MySTT/MySTT/LLM/MLXProvider.swift`
- `MySTT/MySTT/LLM/OllamaProvider.swift`
- `MySTT/MySTT/LLM/GrokProvider.swift`
- `MySTT/MySTT/LLM/GroqProvider.swift`
- `MySTT/MySTT/LLM/OpenAIProvider.swift`

#### Prompt dla sesji Claude Code:

> **Cel**: Implementacja 5 providerow LLM (MLX, Ollama, Grok, Groq, OpenAI) plus wspolny klient HTTP i builder promptow dla aplikacji MySTT.
>
> **Kontekst**: MySTT po transkrypcji mowy moze opcjonalnie poprawic tekst za pomoca LLM. Uzytkownik wybiera providera w ustawieniach. Trzy providery chmurowe (Grok, Groq, OpenAI) uzywaja kompatybilnego API OpenAI. Dwa lokalne: MLX (subprocess Python) i Ollama (HTTP localhost).
>
> **Katalog zrodlowy**: `/Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT`
>
> **Zaleznosci juz istnieja** (z Sesji B):
> - `LLM/LLMProviderProtocol.swift` -- protocol z `func correctText(_:language:dictionary:) async throws -> String`, `var providerName: String`, `func isAvailable() async -> Bool`
> - `Models/Language.swift` -- enum Language (.english, .polish, .unknown)
> - `Models/Errors.swift` -- LLMError enum (providerUnavailable, apiKeyMissing, requestFailed, timeout, invalidResponse)
>
> Utworz dokladnie 7 plikow:
>
> ---
>
> **PLIK 1: `/Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/LLM/OpenAICompatibleClient.swift`**
>
> ```swift
> import Foundation
>
> /// Shared HTTP client for OpenAI-compatible chat completion APIs.
> /// Used by GrokProvider, GroqProvider, and OpenAIProvider.
> final class OpenAICompatibleClient {
>     let baseURL: String
>     let apiKey: String
>     let model: String
>     let timeoutSeconds: TimeInterval
>
>     init(baseURL: String, apiKey: String, model: String, timeoutSeconds: TimeInterval = 10) {
>         self.baseURL = baseURL.hasSuffix("/") ? String(baseURL.dropLast()) : baseURL
>         self.apiKey = apiKey
>         self.model = model
>         self.timeoutSeconds = timeoutSeconds
>     }
>
>     // MARK: - Request/Response Models
>
>     struct ChatMessage: Codable {
>         let role: String
>         let content: String
>     }
>
>     struct ChatCompletionRequest: Codable {
>         let model: String
>         let messages: [ChatMessage]
>         let temperature: Double
>         let max_tokens: Int
>     }
>
>     struct ChatCompletionResponse: Codable {
>         struct Choice: Codable {
>             struct Message: Codable {
>                 let role: String
>                 let content: String
>             }
>             let message: Message
>             let finish_reason: String?
>         }
>         let choices: [Choice]
>     }
>
>     struct ErrorResponse: Codable {
>         struct ErrorDetail: Codable {
>             let message: String
>             let type: String?
>         }
>         let error: ErrorDetail
>     }
>
>     // MARK: - API Call
>
>     /// Send a chat completion request.
>     /// - Parameters:
>     ///   - systemPrompt: The system prompt
>     ///   - userMessage: The user message (text to correct)
>     ///   - temperature: Sampling temperature (default 0.1)
>     ///   - maxTokens: Maximum tokens in response (default 512)
>     /// - Returns: The assistant's response text
>     func chatCompletion(
>         systemPrompt: String,
>         userMessage: String,
>         temperature: Double = 0.1,
>         maxTokens: Int = 512
>     ) async throws -> String {
>         guard !apiKey.isEmpty else {
>             throw LLMError.apiKeyMissing(provider: model)
>         }
>
>         let url = URL(string: "\(baseURL)/chat/completions")!
>
>         var request = URLRequest(url: url)
>         request.httpMethod = "POST"
>         request.setValue("application/json", forHTTPHeaderField: "Content-Type")
>         request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
>         request.timeoutInterval = timeoutSeconds
>
>         let body = ChatCompletionRequest(
>             model: model,
>             messages: [
>                 ChatMessage(role: "system", content: systemPrompt),
>                 ChatMessage(role: "user", content: userMessage)
>             ],
>             temperature: temperature,
>             max_tokens: maxTokens
>         )
>
>         request.httpBody = try JSONEncoder().encode(body)
>
>         let (data, response): (Data, URLResponse)
>         do {
>             (data, response) = try await URLSession.shared.data(for: request)
>         } catch let error as URLError where error.code == .timedOut {
>             throw LLMError.timeout
>         } catch {
>             throw LLMError.requestFailed(statusCode: 0, message: error.localizedDescription)
>         }
>
>         guard let httpResponse = response as? HTTPURLResponse else {
>             throw LLMError.invalidResponse(details: "Not an HTTP response")
>         }
>
>         let statusCode = httpResponse.statusCode
>
>         guard (200...299).contains(statusCode) else {
>             let errorMessage: String
>             if let errorResp = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
>                 errorMessage = errorResp.error.message
>             } else {
>                 errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
>             }
>
>             switch statusCode {
>             case 401:
>                 throw LLMError.apiKeyMissing(provider: model)
>             case 429:
>                 throw LLMError.requestFailed(statusCode: 429, message: "Rate limit exceeded: \(errorMessage)")
>             default:
>                 throw LLMError.requestFailed(statusCode: statusCode, message: errorMessage)
>             }
>         }
>
>         let completionResponse = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
>
>         guard let firstChoice = completionResponse.choices.first else {
>             throw LLMError.invalidResponse(details: "No choices in response")
>         }
>
>         return firstChoice.message.content.trimmingCharacters(in: .whitespacesAndNewlines)
>     }
> }
> ```
>
> ---
>
> **PLIK 2: `/Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/LLM/LLMPromptBuilder.swift`**
>
> ```swift
> import Foundation
>
> /// Builds system and user prompts for LLM text correction.
> struct LLMPromptBuilder {
>
>     /// Build the system prompt for text correction.
>     /// Template from architecture spec section 6.2:
>     /// - Fix punctuation and grammar
>     /// - Preserve original meaning and style
>     /// - Handle Polish diacritics when language is Polish
>     /// - Inject dictionary terms for domain-specific corrections
>     static func buildSystemPrompt(language: Language, dictionary: [String: String]) -> String {
>         var prompt = """
>         You are a text correction assistant. Your task is to fix the transcribed speech text.
>
>         Rules:
>         1. Fix punctuation, capitalization, and grammar errors.
>         2. Preserve the original meaning, tone, and style exactly.
>         3. Do NOT add, remove, or rephrase content.
>         4. Do NOT add explanations or commentary.
>         5. Return ONLY the corrected text, nothing else.
>         """
>
>         // Add language-specific instructions
>         switch language {
>         case .polish:
>             prompt += """
>
>
>         Polish-specific rules:
>         6. Ensure correct Polish diacritics (a, e, o, s, l, z, z, c, n → ą, ę, ó, ś, ł, ź, ż, ć, ń where appropriate).
>         7. Fix Polish grammar and declension if incorrect.
>         8. Preserve Polish colloquialisms if they appear intentional.
>         """
>         case .english:
>             prompt += """
>
>
>         English-specific rules:
>         6. Fix common speech-to-text errors (homophones, contractions).
>         7. Ensure proper English punctuation conventions.
>         """
>         case .unknown:
>             prompt += """
>
>
>         Auto-detect the language and apply appropriate corrections.
>         """
>         }
>
>         // Inject custom dictionary terms
>         if !dictionary.isEmpty {
>             prompt += "\n\nDomain-specific dictionary (replace left term with right term):\n"
>             for (wrong, correct) in dictionary.sorted(by: { $0.key < $1.key }) {
>                 prompt += "- \"\(wrong)\" → \"\(correct)\"\n"
>             }
>         }
>
>         return prompt
>     }
>
>     /// Build the user message (just the raw text to correct)
>     static func buildUserMessage(text: String) -> String {
>         return text
>     }
>
>     /// Default temperature for text correction (low = more deterministic)
>     static let defaultTemperature: Double = 0.1
>
>     /// Default max tokens for response
>     static let defaultMaxTokens: Int = 512
> }
> ```
>
> ---
>
> **PLIK 3: `/Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/LLM/MLXProvider.swift`**
>
> ```swift
> import Foundation
>
> /// LLM provider using Apple MLX framework via Python subprocess.
> /// Calls an external Python script (mlx_infer.py) that runs MLX models locally.
> final class MLXProvider: LLMProviderProtocol {
>     let providerName = "MLX (Local)"
>
>     private let modelName: String
>     private let pythonPath: String
>     private let scriptPath: String
>     private let timeoutSeconds: TimeInterval
>
>     /// Initialize MLX provider.
>     /// - Parameters:
>     ///   - modelName: MLX model identifier (e.g., "mlx-community/Qwen2.5-7B-Instruct-4bit")
>     ///   - pythonPath: Path to python3 executable (default: "/usr/bin/python3")
>     ///   - scriptPath: Path to mlx_infer.py script
>     ///   - timeoutSeconds: Timeout for inference (default: 30s)
>     init(
>         modelName: String = "mlx-community/Qwen2.5-7B-Instruct-4bit",
>         pythonPath: String = "/usr/bin/python3",
>         scriptPath: String? = nil,
>         timeoutSeconds: TimeInterval = 30
>     ) {
>         self.modelName = modelName
>         self.pythonPath = pythonPath
>         self.scriptPath = scriptPath ?? Bundle.main.path(forResource: "mlx_infer", ofType: "py")
>             ?? "\(Bundle.main.bundlePath)/Contents/Resources/mlx_infer.py"
>         self.timeoutSeconds = timeoutSeconds
>     }
>
>     func isAvailable() async -> Bool {
>         // Check if python3 exists and mlx is installed
>         let process = Process()
>         process.executableURL = URL(fileURLWithPath: pythonPath)
>         process.arguments = ["-c", "import mlx; print('ok')"]
>
>         let pipe = Pipe()
>         process.standardOutput = pipe
>         process.standardError = Pipe()
>
>         do {
>             try process.run()
>             process.waitUntilExit()
>             return process.terminationStatus == 0
>         } catch {
>             return false
>         }
>     }
>
>     func correctText(_ text: String, language: Language, dictionary: [String: String]) async throws -> String {
>         let systemPrompt = LLMPromptBuilder.buildSystemPrompt(language: language, dictionary: dictionary)
>         let userMessage = LLMPromptBuilder.buildUserMessage(text: text)
>
>         // Build the full prompt for the script
>         let fullPrompt = "<|system|>\n\(systemPrompt)\n<|user|>\n\(userMessage)\n<|assistant|>\n"
>
>         let process = Process()
>         process.executableURL = URL(fileURLWithPath: pythonPath)
>         process.arguments = [
>             scriptPath,
>             "--model", modelName,
>             "--prompt", fullPrompt,
>             "--max-tokens", String(LLMPromptBuilder.defaultMaxTokens),
>             "--temp", String(LLMPromptBuilder.defaultTemperature)
>         ]
>
>         let outputPipe = Pipe()
>         let errorPipe = Pipe()
>         process.standardOutput = outputPipe
>         process.standardError = errorPipe
>
>         do {
>             try process.run()
>         } catch {
>             throw LLMError.providerUnavailable(provider: providerName)
>         }
>
>         // Timeout handling
>         let deadline = DispatchTime.now() + timeoutSeconds
>         let completed = await withCheckedContinuation { continuation in
>             DispatchQueue.global().async {
>                 process.waitUntilExit()
>                 continuation.resume(returning: true)
>             }
>             DispatchQueue.global().asyncAfter(deadline: deadline) {
>                 if process.isRunning {
>                     process.terminate()
>                     continuation.resume(returning: false)
>                 }
>             }
>         }
>
>         guard completed else {
>             throw LLMError.timeout
>         }
>
>         guard process.terminationStatus == 0 else {
>             let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
>             let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
>             throw LLMError.requestFailed(statusCode: Int(process.terminationStatus), message: errorMessage)
>         }
>
>         let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
>         guard let output = String(data: outputData, encoding: .utf8)?
>             .trimmingCharacters(in: .whitespacesAndNewlines),
>               !output.isEmpty else {
>             throw LLMError.invalidResponse(details: "Empty output from MLX")
>         }
>
>         return output
>     }
> }
> ```
>
> ---
>
> **PLIK 4: `/Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/LLM/OllamaProvider.swift`**
>
> ```swift
> import Foundation
>
> /// LLM provider using locally-running Ollama server.
> /// Communicates via HTTP to localhost:11434.
> final class OllamaProvider: LLMProviderProtocol {
>     let providerName = "Ollama (Local)"
>
>     private let baseURL: String
>     private let modelName: String
>     private let timeoutSeconds: TimeInterval
>
>     init(
>         baseURL: String = "http://localhost:11434",
>         modelName: String = "llama3.1:8b",
>         timeoutSeconds: TimeInterval = 30
>     ) {
>         self.baseURL = baseURL.hasSuffix("/") ? String(baseURL.dropLast()) : baseURL
>         self.modelName = modelName
>         self.timeoutSeconds = timeoutSeconds
>     }
>
>     // MARK: - Ollama API Models
>
>     private struct GenerateRequest: Codable {
>         let model: String
>         let prompt: String
>         let system: String
>         let stream: Bool
>         let options: Options?
>
>         struct Options: Codable {
>             let temperature: Double
>             let num_predict: Int
>         }
>     }
>
>     private struct GenerateResponse: Codable {
>         let response: String
>         let done: Bool
>     }
>
>     private struct TagsResponse: Codable {
>         struct Model: Codable {
>             let name: String
>         }
>         let models: [Model]
>     }
>
>     // MARK: - LLMProviderProtocol
>
>     func isAvailable() async -> Bool {
>         // Health check: GET /api/tags
>         guard let url = URL(string: "\(baseURL)/api/tags") else { return false }
>
>         var request = URLRequest(url: url)
>         request.timeoutInterval = 5
>
>         do {
>             let (data, response) = try await URLSession.shared.data(for: request)
>             guard let httpResponse = response as? HTTPURLResponse,
>                   (200...299).contains(httpResponse.statusCode) else {
>                 return false
>             }
>             // Optionally check if our model is available
>             if let tags = try? JSONDecoder().decode(TagsResponse.self, from: data) {
>                 return tags.models.contains { $0.name.hasPrefix(modelName.split(separator: ":").first.map(String.init) ?? modelName) }
>             }
>             return true
>         } catch {
>             return false
>         }
>     }
>
>     func correctText(_ text: String, language: Language, dictionary: [String: String]) async throws -> String {
>         let systemPrompt = LLMPromptBuilder.buildSystemPrompt(language: language, dictionary: dictionary)
>         let userMessage = LLMPromptBuilder.buildUserMessage(text: text)
>
>         guard let url = URL(string: "\(baseURL)/api/generate") else {
>             throw LLMError.providerUnavailable(provider: providerName)
>         }
>
>         var request = URLRequest(url: url)
>         request.httpMethod = "POST"
>         request.setValue("application/json", forHTTPHeaderField: "Content-Type")
>         request.timeoutInterval = timeoutSeconds
>
>         let body = GenerateRequest(
>             model: modelName,
>             prompt: userMessage,
>             system: systemPrompt,
>             stream: false,
>             options: .init(
>                 temperature: LLMPromptBuilder.defaultTemperature,
>                 num_predict: LLMPromptBuilder.defaultMaxTokens
>             )
>         )
>
>         request.httpBody = try JSONEncoder().encode(body)
>
>         let (data, response): (Data, URLResponse)
>         do {
>             (data, response) = try await URLSession.shared.data(for: request)
>         } catch let error as URLError where error.code == .timedOut {
>             throw LLMError.timeout
>         } catch let error as URLError where error.code == .cannotConnectToHost {
>             throw LLMError.providerUnavailable(provider: providerName)
>         } catch {
>             throw LLMError.requestFailed(statusCode: 0, message: error.localizedDescription)
>         }
>
>         guard let httpResponse = response as? HTTPURLResponse,
>               (200...299).contains(httpResponse.statusCode) else {
>             let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
>             let message = String(data: data, encoding: .utf8) ?? "Unknown error"
>             throw LLMError.requestFailed(statusCode: statusCode, message: message)
>         }
>
>         let generateResponse = try JSONDecoder().decode(GenerateResponse.self, from: data)
>
>         let result = generateResponse.response.trimmingCharacters(in: .whitespacesAndNewlines)
>         guard !result.isEmpty else {
>             throw LLMError.invalidResponse(details: "Empty response from Ollama")
>         }
>
>         return result
>     }
> }
> ```
>
> ---
>
> **PLIK 5: `/Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/LLM/GrokProvider.swift`**
>
> ```swift
> import Foundation
>
> /// LLM provider using xAI's Grok API (OpenAI-compatible).
> /// Base URL: https://api.x.ai/v1
> /// Model: grok-4.1-fast
> final class GrokProvider: LLMProviderProtocol {
>     let providerName = "Grok (xAI)"
>
>     private let client: OpenAICompatibleClient
>
>     init(apiKey: String) {
>         self.client = OpenAICompatibleClient(
>             baseURL: "https://api.x.ai/v1",
>             apiKey: apiKey,
>             model: "grok-4.1-fast",
>             timeoutSeconds: 10
>         )
>     }
>
>     func isAvailable() async -> Bool {
>         return !client.apiKey.isEmpty
>     }
>
>     func correctText(_ text: String, language: Language, dictionary: [String: String]) async throws -> String {
>         let systemPrompt = LLMPromptBuilder.buildSystemPrompt(language: language, dictionary: dictionary)
>         let userMessage = LLMPromptBuilder.buildUserMessage(text: text)
>
>         return try await client.chatCompletion(
>             systemPrompt: systemPrompt,
>             userMessage: userMessage,
>             temperature: LLMPromptBuilder.defaultTemperature,
>             maxTokens: LLMPromptBuilder.defaultMaxTokens
>         )
>     }
> }
> ```
>
> ---
>
> **PLIK 6: `/Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/LLM/GroqProvider.swift`**
>
> ```swift
> import Foundation
>
> /// LLM provider using Groq Cloud API (OpenAI-compatible).
> /// Base URL: https://api.groq.com/openai/v1
> /// Model: llama-3.1-8b-instant
> final class GroqProvider: LLMProviderProtocol {
>     let providerName = "Groq Cloud"
>
>     private let client: OpenAICompatibleClient
>
>     init(apiKey: String) {
>         self.client = OpenAICompatibleClient(
>             baseURL: "https://api.groq.com/openai/v1",
>             apiKey: apiKey,
>             model: "llama-3.1-8b-instant",
>             timeoutSeconds: 10
>         )
>     }
>
>     func isAvailable() async -> Bool {
>         return !client.apiKey.isEmpty
>     }
>
>     func correctText(_ text: String, language: Language, dictionary: [String: String]) async throws -> String {
>         let systemPrompt = LLMPromptBuilder.buildSystemPrompt(language: language, dictionary: dictionary)
>         let userMessage = LLMPromptBuilder.buildUserMessage(text: text)
>
>         return try await client.chatCompletion(
>             systemPrompt: systemPrompt,
>             userMessage: userMessage,
>             temperature: LLMPromptBuilder.defaultTemperature,
>             maxTokens: LLMPromptBuilder.defaultMaxTokens
>         )
>     }
> }
> ```
>
> ---
>
> **PLIK 7: `/Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/LLM/OpenAIProvider.swift`**
>
> ```swift
> import Foundation
>
> /// LLM provider using OpenAI API.
> /// Base URL: https://api.openai.com/v1
> /// Model: gpt-4o-mini
> final class OpenAIProvider: LLMProviderProtocol {
>     let providerName = "OpenAI"
>
>     private let client: OpenAICompatibleClient
>
>     init(apiKey: String) {
>         self.client = OpenAICompatibleClient(
>             baseURL: "https://api.openai.com/v1",
>             apiKey: apiKey,
>             model: "gpt-4o-mini",
>             timeoutSeconds: 10
>         )
>     }
>
>     func isAvailable() async -> Bool {
>         return !client.apiKey.isEmpty
>     }
>
>     func correctText(_ text: String, language: Language, dictionary: [String: String]) async throws -> String {
>         let systemPrompt = LLMPromptBuilder.buildSystemPrompt(language: language, dictionary: dictionary)
>         let userMessage = LLMPromptBuilder.buildUserMessage(text: text)
>
>         return try await client.chatCompletion(
>             systemPrompt: systemPrompt,
>             userMessage: userMessage,
>             temperature: LLMPromptBuilder.defaultTemperature,
>             maxTokens: LLMPromptBuilder.defaultMaxTokens
>         )
>     }
> }
> ```
>
> ---
>
> **Po utworzeniu plikow**: Usun `.gitkeep` z katalogu `LLM/` jesli jeszcze istnieje.
>
> Po wykonaniu uruchom weryfikacje. Jesli jakiekolwiek kryterium FAIL -- napraw -- ponowna weryfikacja -- powtarzaj max 5 razy -- jesli nadal FAIL -- zglos problem.

#### Weryfikacja (automatyczna po wykonaniu):

```bash
# 1. Sprawdz wszystkie 7 plikow
echo "=== File Existence ==="
for f in \
  /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/LLM/OpenAICompatibleClient.swift \
  /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/LLM/LLMPromptBuilder.swift \
  /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/LLM/MLXProvider.swift \
  /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/LLM/OllamaProvider.swift \
  /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/LLM/GrokProvider.swift \
  /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/LLM/GroqProvider.swift \
  /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/LLM/OpenAIProvider.swift; do
  if [ -f "$f" ]; then echo "OK: $(basename $f)"; else echo "FAIL: $(basename $f)"; fi
done

# 2. Sprawdz OpenAICompatibleClient
echo "=== OpenAICompatibleClient ==="
grep -c "class OpenAICompatibleClient" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/LLM/OpenAICompatibleClient.swift
grep -c "chat/completions" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/LLM/OpenAICompatibleClient.swift
grep -c "Bearer" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/LLM/OpenAICompatibleClient.swift
grep -c "ChatCompletionRequest" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/LLM/OpenAICompatibleClient.swift
grep -c "ChatCompletionResponse" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/LLM/OpenAICompatibleClient.swift
grep -c "401" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/LLM/OpenAICompatibleClient.swift
grep -c "429" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/LLM/OpenAICompatibleClient.swift

# 3. Sprawdz LLMPromptBuilder
echo "=== LLMPromptBuilder ==="
grep -c "struct LLMPromptBuilder" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/LLM/LLMPromptBuilder.swift
grep -c "Polish diacritics" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/LLM/LLMPromptBuilder.swift
grep -c "temperature" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/LLM/LLMPromptBuilder.swift
grep -c "dictionary" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/LLM/LLMPromptBuilder.swift

# 4. Sprawdz providery
echo "=== Providers ==="
grep -c "api.x.ai" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/LLM/GrokProvider.swift
grep -c "grok-4.1-fast" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/LLM/GrokProvider.swift
grep -c "api.groq.com" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/LLM/GroqProvider.swift
grep -c "llama-3.1-8b-instant" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/LLM/GroqProvider.swift
grep -c "api.openai.com" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/LLM/OpenAIProvider.swift
grep -c "gpt-4o-mini" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/LLM/OpenAIProvider.swift
grep -c "localhost:11434" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/LLM/OllamaProvider.swift
grep -c "/api/generate" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/LLM/OllamaProvider.swift
grep -c "/api/tags" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/LLM/OllamaProvider.swift
grep -c "mlx_infer" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/LLM/MLXProvider.swift
grep -c "Process()" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/LLM/MLXProvider.swift

# 5. Sprawdz ze kazdy provider implementuje protokol
echo "=== Protocol Conformance ==="
grep "LLMProviderProtocol" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/LLM/MLXProvider.swift
grep "LLMProviderProtocol" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/LLM/OllamaProvider.swift
grep "LLMProviderProtocol" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/LLM/GrokProvider.swift
grep "LLMProviderProtocol" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/LLM/GroqProvider.swift
grep "LLMProviderProtocol" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/LLM/OpenAIProvider.swift
# Oczekiwane: kazdy grep zwraca linie z LLMProviderProtocol
```

#### Kryteria DONE:
- [ ] Wszystkie 7 plikow istnieja w katalogu LLM/
- [ ] `OpenAICompatibleClient` ma metode `chatCompletion()` z POST do /chat/completions, Bearer auth, 10s timeout
- [ ] `OpenAICompatibleClient` obsluguje bledy HTTP 401, 429, 500+ z parsowaniem ErrorResponse
- [ ] `OpenAICompatibleClient` ma struktury ChatCompletionRequest i ChatCompletionResponse
- [ ] `LLMPromptBuilder` generuje prompt z regulami: punctuation, grammar, preserve meaning, Polish diacritics, dictionary injection
- [ ] `LLMPromptBuilder` ma temperature=0.1, max_tokens=512
- [ ] `MLXProvider` wywoluje subprocess Python z parametrami --model, --prompt, --max-tokens, --temp i ma 30s timeout
- [ ] `OllamaProvider` komunikuje sie z localhost:11434/api/generate (stream:false) i sprawdza dostepnosc przez GET /api/tags
- [ ] `GrokProvider` uzywa OpenAICompatibleClient z baseURL https://api.x.ai/v1, model "grok-4.1-fast"
- [ ] `GroqProvider` uzywa OpenAICompatibleClient z baseURL https://api.groq.com/openai/v1, model "llama-3.1-8b-instant"
- [ ] `OpenAIProvider` uzywa OpenAICompatibleClient z baseURL https://api.openai.com/v1, model "gpt-4o-mini"
- [ ] Wszystkie 5 providerow implementuja `LLMProviderProtocol` (correctText, providerName, isAvailable)

---

### Sesja H: Deepgram Cloud STT
**Runda**: 3 | **Typ**: PARALLEL | **Faza**: 2
**Agent**: `swift-developer`
**Zależności**: Sesja B (STTEngineProtocol, STTResult, Language, TranscriptionSegment), Sesja C (AudioBuffer+Extensions dla toWAVData)
**Pliki wyjściowe**:
- `MySTT/MySTT/STT/DeepgramEngine.swift`

#### Prompt dla sesji Claude Code:

> **Cel**: Implementacja silnika STT opartego na Deepgram Cloud API dla aplikacji MySTT -- macOS 14.0+ menu bar app.
>
> **Kontekst**: Deepgram to alternatywny (chmurowy) provider STT. Audio jest wysylane jako WAV do REST API. Uzywamy modelu Nova-3 z automatycznym wykrywaniem jezyka i interpunkcja.
>
> **Katalog zrodlowy**: `/Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT`
>
> **Zaleznosci juz istnieja** (z Sesji B i C):
> - `STT/STTEngineProtocol.swift` -- protocol z transcribe, isReady, prepare
> - `Models/STTResult.swift` -- struct z text, language, confidence, segments
> - `Models/Language.swift` -- enum z init(whisperCode:)
> - `Models/TranscriptionSegment.swift` -- struct
> - `Models/Errors.swift` -- STTError enum
> - `Audio/AudioBuffer+Extensions.swift` -- extension z `toWAVData()` na AVAudioPCMBuffer
>
> Utworz dokladnie 1 plik:
>
> ---
>
> **PLIK 1: `/Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/STT/DeepgramEngine.swift`**
>
> ```swift
> import AVFoundation
>
> /// Deepgram Cloud STT engine.
> /// Sends audio as WAV to Deepgram REST API for transcription.
> /// Uses Nova-3 model with automatic language detection and punctuation.
> final class DeepgramEngine: STTEngineProtocol {
>     private let apiKey: String
>     private let timeoutSeconds: TimeInterval
>     private(set) var isReady: Bool
>
>     /// Base URL for Deepgram API
>     private let baseURL = "https://api.deepgram.com/v1/listen"
>
>     /// Query parameters for the API request
>     private let queryParams = "model=nova-3&detect_language=true&punctuate=true"
>
>     init(apiKey: String, timeoutSeconds: TimeInterval = 15) {
>         self.apiKey = apiKey
>         self.timeoutSeconds = timeoutSeconds
>         self.isReady = !apiKey.isEmpty
>     }
>
>     func prepare() async throws {
>         guard !apiKey.isEmpty else {
>             throw STTError.notInitialized
>         }
>         isReady = true
>     }
>
>     func transcribe(audioBuffer: AVAudioPCMBuffer) async throws -> STTResult {
>         guard isReady else {
>             throw STTError.notInitialized
>         }
>
>         // Convert audio buffer to WAV data
>         guard let wavData = audioBuffer.toWAVData(), !wavData.isEmpty else {
>             throw STTError.emptyAudio
>         }
>
>         // Build request URL
>         guard let url = URL(string: "\(baseURL)?\(queryParams)") else {
>             throw STTError.transcriptionFailed(underlying: nil)
>         }
>
>         var request = URLRequest(url: url)
>         request.httpMethod = "POST"
>         request.setValue("Token \(apiKey)", forHTTPHeaderField: "Authorization")
>         request.setValue("audio/wav", forHTTPHeaderField: "Content-Type")
>         request.timeoutInterval = timeoutSeconds
>         request.httpBody = wavData
>
>         // Send request
>         let (data, response): (Data, URLResponse)
>         do {
>             (data, response) = try await URLSession.shared.data(for: request)
>         } catch let error as URLError where error.code == .timedOut {
>             throw STTError.timeout
>         } catch {
>             throw STTError.transcriptionFailed(underlying: error)
>         }
>
>         guard let httpResponse = response as? HTTPURLResponse else {
>             throw STTError.transcriptionFailed(underlying: nil)
>         }
>
>         guard (200...299).contains(httpResponse.statusCode) else {
>             let errorMessage = String(data: data, encoding: .utf8) ?? "HTTP \(httpResponse.statusCode)"
>             throw STTError.transcriptionFailed(
>                 underlying: NSError(domain: "DeepgramEngine", code: httpResponse.statusCode,
>                                     userInfo: [NSLocalizedDescriptionKey: errorMessage])
>             )
>         }
>
>         // Parse response
>         return try parseResponse(data)
>     }
>
>     // MARK: - Response Parsing
>
>     /// Deepgram API response structure
>     private struct DeepgramResponse: Codable {
>         struct Results: Codable {
>             struct Channel: Codable {
>                 struct Alternative: Codable {
>                     let transcript: String
>                     let confidence: Double
>                     let words: [Word]?
>
>                     struct Word: Codable {
>                         let word: String
>                         let start: Double
>                         let end: Double
>                         let confidence: Double
>                     }
>                 }
>                 let alternatives: [Alternative]
>                 let detected_language: String?
>             }
>             let channels: [Channel]
>         }
>         let results: Results
>     }
>
>     private func parseResponse(_ data: Data) throws -> STTResult {
>         let deepgramResponse: DeepgramResponse
>         do {
>             deepgramResponse = try JSONDecoder().decode(DeepgramResponse.self, from: data)
>         } catch {
>             throw STTError.transcriptionFailed(
>                 underlying: NSError(domain: "DeepgramEngine", code: -1,
>                                     userInfo: [NSLocalizedDescriptionKey: "Failed to parse Deepgram response: \(error.localizedDescription)"])
>             )
>         }
>
>         // Extract first channel, first alternative
>         guard let channel = deepgramResponse.results.channels.first,
>               let alternative = channel.alternatives.first else {
>             return STTResult.empty
>         }
>
>         let text = alternative.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
>         guard !text.isEmpty else {
>             return STTResult.empty
>         }
>
>         // Detect language
>         let language: Language
>         if let detectedLang = channel.detected_language {
>             language = Language(whisperCode: detectedLang)
>         } else {
>             language = .unknown
>         }
>
>         // Build segments from words
>         let segments: [TranscriptionSegment]
>         if let words = alternative.words, !words.isEmpty {
>             // Group words into sentence-like segments (by punctuation or every ~10 words)
>             segments = buildSegments(from: words)
>         } else {
>             // Single segment for the whole transcript
>             segments = [
>                 TranscriptionSegment(
>                     text: text,
>                     start: 0,
>                     end: 0,
>                     confidence: Float(alternative.confidence)
>                 )
>             ]
>         }
>
>         return STTResult(
>             text: text,
>             language: language,
>             confidence: Float(alternative.confidence),
>             segments: segments
>         )
>     }
>
>     /// Group words into segments (split on sentence-ending punctuation or every ~10 words)
>     private func buildSegments(from words: [DeepgramResponse.Results.Channel.Alternative.Word]) -> [TranscriptionSegment] {
>         var segments: [TranscriptionSegment] = []
>         var currentWords: [DeepgramResponse.Results.Channel.Alternative.Word] = []
>
>         for word in words {
>             currentWords.append(word)
>
>             let endsWithPunctuation = word.word.hasSuffix(".") || word.word.hasSuffix("?") || word.word.hasSuffix("!")
>
>             if endsWithPunctuation || currentWords.count >= 10 {
>                 let segmentText = currentWords.map(\.word).joined(separator: " ")
>                 let avgConfidence = currentWords.reduce(0.0) { $0 + $1.confidence } / Double(currentWords.count)
>
>                 segments.append(TranscriptionSegment(
>                     text: segmentText,
>                     start: currentWords.first?.start ?? 0,
>                     end: currentWords.last?.end ?? 0,
>                     confidence: Float(avgConfidence)
>                 ))
>                 currentWords.removeAll()
>             }
>         }
>
>         // Remaining words
>         if !currentWords.isEmpty {
>             let segmentText = currentWords.map(\.word).joined(separator: " ")
>             let avgConfidence = currentWords.reduce(0.0) { $0 + $1.confidence } / Double(currentWords.count)
>
>             segments.append(TranscriptionSegment(
>                 text: segmentText,
>                 start: currentWords.first?.start ?? 0,
>                 end: currentWords.last?.end ?? 0,
>                 confidence: Float(avgConfidence)
>             ))
>         }
>
>         return segments
>     }
> }
> ```
>
> ---
>
> Po wykonaniu uruchom weryfikacje. Jesli jakiekolwiek kryterium FAIL -- napraw -- ponowna weryfikacja -- powtarzaj max 5 razy -- jesli nadal FAIL -- zglos problem.

#### Weryfikacja (automatyczna po wykonaniu):

```bash
# 1. Sprawdz plik
echo "=== File Existence ==="
ls -la /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/STT/DeepgramEngine.swift

# 2. Sprawdz kluczowe elementy
echo "=== Key Elements ==="
grep -c "class DeepgramEngine" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/STT/DeepgramEngine.swift
grep -c "STTEngineProtocol" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/STT/DeepgramEngine.swift
grep -c "api.deepgram.com/v1/listen" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/STT/DeepgramEngine.swift
grep -c "nova-3" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/STT/DeepgramEngine.swift
grep -c "detect_language=true" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/STT/DeepgramEngine.swift
grep -c "punctuate=true" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/STT/DeepgramEngine.swift
grep -c "Token" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/STT/DeepgramEngine.swift
grep -c "audio/wav" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/STT/DeepgramEngine.swift
grep -c "toWAVData" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/STT/DeepgramEngine.swift
grep -c "func transcribe" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/STT/DeepgramEngine.swift
grep -c "func prepare" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/STT/DeepgramEngine.swift
grep -c "DeepgramResponse" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/STT/DeepgramEngine.swift
grep -c "Language(whisperCode:" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/STT/DeepgramEngine.swift
grep -c "15" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/STT/DeepgramEngine.swift
# Oczekiwane: >= 1 dla kazdego

# 3. Sprawdz timeout
echo "=== Timeout ==="
grep "timeoutSeconds" /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/STT/DeepgramEngine.swift | head -2
# Oczekiwane: 15 jako default
```

#### Kryteria DONE:
- [ ] `DeepgramEngine.swift` istnieje i implementuje `STTEngineProtocol`
- [ ] POST do `https://api.deepgram.com/v1/listen?model=nova-3&detect_language=true&punctuate=true`
- [ ] Authorization header: `Token <apiKey>` (NIE Bearer)
- [ ] Content-Type: `audio/wav`
- [ ] Audio konwertowane do WAV za pomoca `toWAVData()` z AudioBuffer+Extensions
- [ ] Timeout ustawiony na 15 sekund
- [ ] Parsowanie odpowiedzi JSON: channels[0].alternatives[0].transcript, detected_language, confidence, words
- [ ] Segmenty budowane z words (grupowanie po interpunkcji lub co ~10 slow)
- [ ] Jezyk wykrywany z `detected_language` i mapowany przez `Language(whisperCode:)`
- [ ] Obsluga bledow: STTError.notInitialized, emptyAudio, transcriptionFailed, timeout
- [ ] `isReady` zalezy od niepustego apiKey
- [ ] `prepare()` sprawdza czy apiKey nie jest pusty

# RUNDY 4-6: Integracja + UI + Pipeline

## RUNDA 4 (Sesje I, J, K) - Post-Processing, Dictionary, Utilities

---

### Sesja I: Post-Processing Pipeline
**Runda**: 4 | **Typ**: PARALLEL | **Faza**: 3
**Agent**: `software-architect`
**Zaleznosci**: Task 1.1 (Protocols), Task 2.2 (LLM Providers)
**Pliki wyjsciowe**:
- `MySTT/MySTT/PostProcessing/PostProcessor.swift`
- `MySTT/MySTT/PostProcessing/PunctuationCorrector.swift`

#### Prompt dla sesji Claude Code:

> Pracujesz w katalogu: `/Users/igor.3.wolak.external/Downloads/MySTT`
>
> Projekt: MySTT - macOS menu bar app do speech-to-text z post-processingiem. Swift, SwiftUI, macOS 14+.
>
> **Twoim zadaniem jest stworzenie dwoch plikow post-processingu.**
>
> ---
>
> **PLIK 1: `MySTT/MySTT/PostProcessing/PostProcessor.swift`**
>
> Implementuje `PostProcessorProtocol` (zdefiniowany w `MySTT/MySTT/Protocols/PostProcessorProtocol.swift`). Najpierw przeczytaj ten plik protokolu, aby poznac wymagany interfejs.
>
> Przeczytaj takze `MySTT/MySTT/Models/AppSettings.swift` aby poznac flagi konfiguracyjne.
>
> Przeczytaj takze `MySTT/MySTT/Protocols/LLMProviderProtocol.swift` aby poznac interfejs LLM.
>
> Klasa `PostProcessor` powinna:
> - Byc oznaczona `@MainActor` jesli protokol tego wymaga, lub dzialac jako zwykla klasa z async metodami.
> - Przechowywac referencje do: `DictionaryEngine`, `PunctuationCorrector`, opcjonalnego `LLMProviderProtocol`.
> - Miec initializer: `init(dictionaryEngine: DictionaryEngine, punctuationCorrector: PunctuationCorrector, llmProvider: (any LLMProviderProtocol)? = nil)`
> - Implementowac metode `func process(text: String, language: Language) async throws -> String` (lub zgodna z protokolem).
>
> Pipeline orkiestracji (kazdy etap opcjonalny, kontrolowany przez `AppSettings`):
> 1. `DictionaryEngine.preProcess(text:)` - zamiana terminow (jesli `AppSettings.shared.enableDictionary`)
> 2. `PunctuationCorrector.correct(text:language:)` - korekcja interpunkcji przez Python (jesli `AppSettings.shared.enablePunctuationModel`)
> 3. `LLMProvider.correctText(text:language:dictionaryTerms:)` - korekcja przez LLM (jesli `AppSettings.shared.enableLLMCorrection` i llmProvider != nil)
> 4. `DictionaryEngine.postProcess(text:)` - regex rules (jesli `AppSettings.shared.enableDictionary`)
>
> Jesli LLM rzuci blad -> graceful degradation: zwroc wynik z etapu 2 (lub 1 jesli etap 2 wylaczony). Nie rzucaj bledu dalej.
>
> Loguj czas kazdego etapu uzywajac `os_log` lub `print`:
> ```swift
> import os
> private let logger = Logger(subsystem: "com.mystt.app", category: "PostProcessor")
> // w kazdym etapie:
> let start = CFAbsoluteTimeGetCurrent()
> // ... wykonaj etap ...
> let elapsed = CFAbsoluteTimeGetCurrent() - start
> logger.info("Stage X completed in \(elapsed, format: .fixed(precision: 3))s")
> ```
>
> System prompt template dla LLM (przekazywany do llmProvider):
> ```
> You are a speech-to-text post-processor. Correct the transcription output. Rules:
> 1. Fix remaining punctuation errors (periods, commas, question marks, exclamation marks)
> 2. Fix grammar errors while preserving original meaning exactly
> 3. Do NOT rephrase, add, or remove content
> 4. If text is Polish, apply Polish grammar and punctuation rules
> 5. Restore Polish diacritical characters where missing (a->ą, e->ę, c->ć, s->ś, z->ż/ź, o->ó, l->ł, n->ń)
> 6. Apply these domain-specific terms (use exact spelling):
> {DICTIONARY_TERMS}
>
> Return ONLY the corrected text. No explanations.
> ```
>
> Ten template powinien byc stala `static let systemPromptTemplate` w PostProcessor. Przed wyslaniem do LLM zamien `{DICTIONARY_TERMS}` na wynik `dictionaryEngine.getDictionaryTermsForPrompt()`.
>
> ---
>
> **PLIK 2: `MySTT/MySTT/PostProcessing/PunctuationCorrector.swift`**
>
> Klasa `PunctuationCorrector`:
> - Metoda: `func correct(text: String, language: Language) async -> String`
> - Wywoluje subprocess Python: `Scripts/punctuation_correct.py`
> - Przeczytaj `MySTT/MySTT/Models/Language.swift` lub `AppSettings.swift` aby sprawdzic jak wyglada enum `Language`.
> - Prefix jezyka: jesli language == .polish -> `"<pl>"`, jesli language == .english -> `"<en>"`
> - Pelny tekst wysylany do Python: `"{prefix} {text}"`
> - Uzyj `Process()` (Foundation) do uruchomienia subprocess:
>   ```swift
>   let process = Process()
>   process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
>   process.arguments = ["python3", scriptPath, inputText]
>   // lub przekaz tekst przez stdin pipe
>   ```
> - Timeout 10 sekund - jesli subprocess nie skonczy w 10s, zabij go i zwroc oryginalny tekst.
> - Jesli Python niedostepny lub skrypt nie istnieje -> zwroc tekst bez zmian (fallback, NIE rzucaj bledu).
> - `scriptPath` powinien byc relatywny do bundle lub do katalogu projektu: `Bundle.main.path(forResource: "punctuation_correct", ofType: "py")` lub fallback na `"Scripts/punctuation_correct.py"` wzgledem working directory.
>
> Importy potrzebne:
> ```swift
> import Foundation
> import os
> ```
>
> ---
>
> **WAZNE**: Jesli jakis plik protokolu lub modelu nie istnieje (bo to jest sesja rownolegla), stworz minimalny stub komentarzem `// STUB - will be provided by dependency task` i kontynuuj. Ale NAJPIERW probuj przeczytac istniejace pliki.
>
> Stworz katalog jesli nie istnieje: `mkdir -p MySTT/MySTT/PostProcessing`
>
> Po wykonaniu uruchom weryfikacje. Jesli jakiekolwiek kryterium FAIL -> napraw -> ponowna weryfikacja -> powtarzaj max 5 razy -> jesli nadal FAIL -> zglos problem.

#### Weryfikacja (automatyczna po wykonaniu):

```bash
cd /Users/igor.3.wolak.external/Downloads/MySTT

echo "=== WERYFIKACJA SESJI I ==="

echo "--- Test 1: Plik PostProcessor.swift istnieje ---"
test -f MySTT/MySTT/PostProcessing/PostProcessor.swift && echo "PASS" || echo "FAIL"

echo "--- Test 2: Plik PunctuationCorrector.swift istnieje ---"
test -f MySTT/MySTT/PostProcessing/PunctuationCorrector.swift && echo "PASS" || echo "FAIL"

echo "--- Test 3: PostProcessor implementuje PostProcessorProtocol ---"
grep -q "PostProcessorProtocol" MySTT/MySTT/PostProcessing/PostProcessor.swift && echo "PASS" || echo "FAIL"

echo "--- Test 4: PostProcessor zawiera pipeline stages (DictionaryEngine, PunctuationCorrector, LLM) ---"
grep -q "DictionaryEngine" MySTT/MySTT/PostProcessing/PostProcessor.swift && \
grep -q "PunctuationCorrector" MySTT/MySTT/PostProcessing/PostProcessor.swift && \
grep -q "LLMProvider\|llmProvider" MySTT/MySTT/PostProcessing/PostProcessor.swift && echo "PASS" || echo "FAIL"

echo "--- Test 5: PostProcessor zawiera system prompt template ---"
grep -q "speech-to-text post-processor" MySTT/MySTT/PostProcessing/PostProcessor.swift && echo "PASS" || echo "FAIL"

echo "--- Test 6: PostProcessor loguje timing (os_log lub CFAbsoluteTime) ---"
grep -q "CFAbsoluteTimeGetCurrent\|logger\.\|os_log" MySTT/MySTT/PostProcessing/PostProcessor.swift && echo "PASS" || echo "FAIL"

echo "--- Test 7: PostProcessor graceful degradation (LLM failure) ---"
grep -q "catch\|fallback\|degradation\|stage.*output\|result.*before" MySTT/MySTT/PostProcessing/PostProcessor.swift && echo "PASS" || echo "FAIL"

echo "--- Test 8: PunctuationCorrector uzywa Process() subprocess ---"
grep -q "Process()" MySTT/MySTT/PostProcessing/PunctuationCorrector.swift && echo "PASS" || echo "FAIL"

echo "--- Test 9: PunctuationCorrector ma 10s timeout ---"
grep -q "10" MySTT/MySTT/PostProcessing/PunctuationCorrector.swift && echo "PASS" || echo "FAIL"

echo "--- Test 10: PunctuationCorrector obsluguje prefix jezyka ---"
grep -q "<pl>\|<en>" MySTT/MySTT/PostProcessing/PunctuationCorrector.swift && echo "PASS" || echo "FAIL"

echo "--- Test 11: AppSettings flagi sprawdzane w PostProcessor ---"
grep -q "enablePunctuationModel\|enableLLMCorrection\|enableDictionary\|AppSettings" MySTT/MySTT/PostProcessing/PostProcessor.swift && echo "PASS" || echo "FAIL"

echo "--- Test 12: Kompilacja skladni Swift (swiftc parse check) ---"
xcrun swiftc -parse MySTT/MySTT/PostProcessing/PostProcessor.swift 2>&1 | head -5 || echo "INFO: Parse check wymaga kontekstu projektu - sprawdz recznie"

echo "=== KONIEC WERYFIKACJI SESJI I ==="
```

#### Kryteria DONE:
- [ ] Plik `PostProcessor.swift` istnieje w `MySTT/MySTT/PostProcessing/`
- [ ] Plik `PunctuationCorrector.swift` istnieje w `MySTT/MySTT/PostProcessing/`
- [ ] `PostProcessor` implementuje `PostProcessorProtocol`
- [ ] Pipeline 4-etapowy: DictionaryEngine.preProcess -> PunctuationCorrector -> LLM -> DictionaryEngine.postProcess
- [ ] Kazdy etap opcjonalny (kontrolowany przez AppSettings)
- [ ] Graceful degradation przy bledzie LLM (zwraca wynik wczesniejszego etapu)
- [ ] Timing kazdego etapu logowany przez os_log/Logger
- [ ] System prompt template zawiera wszystkie 6 regul
- [ ] `{DICTIONARY_TERMS}` podmieniane dynamicznie
- [ ] PunctuationCorrector uzywa subprocess Python z Process()
- [ ] Timeout 10s na subprocess Python
- [ ] Fallback przy braku Pythona (zwraca tekst bez zmian)
- [ ] Prefix jezyka `<pl>` / `<en>` dodawany do tekstu

---

### Sesja J: Dictionary & Rules Engine
**Runda**: 4 | **Typ**: PARALLEL | **Faza**: 3
**Agent**: `software-architect`
**Zaleznosci**: Task 1.1 (Protocols)
**Pliki wyjsciowe**:
- `MySTT/MySTT/PostProcessing/DictionaryEngine.swift`
- `MySTT/MySTT/Resources/default_dictionary.json`

#### Prompt dla sesji Claude Code:

> Pracujesz w katalogu: `/Users/igor.3.wolak.external/Downloads/MySTT`
>
> Projekt: MySTT - macOS menu bar app do speech-to-text. Swift, SwiftUI, macOS 14+.
>
> **Twoim zadaniem jest stworzenie silnika slownikowego i pliku domyslnego slownika.**
>
> ---
>
> **PLIK 1: `MySTT/MySTT/PostProcessing/DictionaryEngine.swift`**
>
> Najpierw przeczytaj istniejace pliki protokolow w `MySTT/MySTT/Protocols/` aby poznac interfejsy.
>
> Klasa `DictionaryEngine`:
>
> ```swift
> import Foundation
> import os
>
> class DictionaryEngine {
>
>     struct DictionaryData: Codable {
>         var terms: [String: String]
>         var abbreviations: [String: String]
>         var polish_terms: [String: String]  // snake_case dla JSON compatibility
>         var rules: [RegexRule]
>     }
>
>     struct RegexRule: Codable {
>         let pattern: String
>         let replacement: String
>     }
>
>     private var dictionaryData: DictionaryData
>     private let userDictionaryPath: String
>     private let logger = Logger(subsystem: "com.mystt.app", category: "DictionaryEngine")
>
>     // ... metody ponizej
> }
> ```
>
> **Metody do zaimplementowania:**
>
> 1. `init()` - Laduje slownik: najpierw probuje `~/.mystt/dictionary.json`, jesli nie istnieje -> laduje bundled `default_dictionary.json` z `Bundle.main`. Jesli oba niedostepne -> inicjalizuje pusty DictionaryData.
>    - `userDictionaryPath = NSHomeDirectory() + "/.mystt/dictionary.json"`
>
> 2. `func loadDictionary()` - Logika ladowania:
>    - Sprawdz czy plik uzytkownika istnieje w `~/.mystt/dictionary.json`
>    - Jesli tak -> dekoduj JSON
>    - Jesli nie -> sprobuj `Bundle.main.url(forResource: "default_dictionary", withExtension: "json")`
>    - Jesli oba fail -> logger.warning i uzyj pustego slownika
>
> 3. `func saveDictionary()` - Zapisz aktualny slownik do `~/.mystt/dictionary.json`:
>    - Stworz katalog `~/.mystt/` jesli nie istnieje (`FileManager.default.createDirectory`)
>    - Zapisz jako pretty-printed JSON (`encoder.outputFormatting = [.prettyPrinted, .sortedKeys]`)
>
> 4. `func addTerm(key: String, value: String)` - Dodaj term do `dictionaryData.terms`, wywolaj `saveDictionary()`
>
> 5. `func removeTerm(key: String)` - Usun term z `dictionaryData.terms`, wywolaj `saveDictionary()`
>
> 6. `func preProcess(text: String) -> String` - Case-insensitive zamiana terminow:
>    - Iteruj przez `terms`, `abbreviations`, `polish_terms`
>    - Dla kazdego klucza: znajdz case-insensitive w tekscie i zamien na wartosc
>    - Uzyj `text.replacingOccurrences(of: key, with: value, options: .caseInsensitive)`
>    - WAZNE: Przetwarzaj dluzsze klucze najpierw (sortuj po dlugosci klucza malejaco) aby uniknac czesciowych zamian
>
> 7. `func postProcess(text: String) -> String` - Regex rules:
>    - Zastosuj kazda regule z `dictionaryData.rules` uzywajac `NSRegularExpression`
>    - Dodatkowo (hardcoded): capitalize po `.`, `!`, `?` (poczatek zdania)
>    - Usun podwojne spacje
>    - Usun spacje przed interpunkcja
>    - Capitalize pierwsza litere tekstu
>
> 8. `func getDictionaryTermsForPrompt() -> String` - Formatuj terminy dla LLM promptu:
>    - Polacz wszystkie terminy (terms + abbreviations + polish_terms) w format: `"kubernetes -> Kubernetes, react -> React, ..."`
>    - Kazdy term w nowej linii: `"- kubernetes -> Kubernetes"`
>
> ---
>
> **PLIK 2: `MySTT/MySTT/Resources/default_dictionary.json`**
>
> Stworz plik JSON z dokladnie ta zawartoscia:
> ```json
> {
>     "terms": {
>         "kubernetes": "Kubernetes",
>         "react": "React",
>         "typescript": "TypeScript",
>         "javascript": "JavaScript",
>         "python": "Python",
>         "swift": "Swift",
>         "xcode": "Xcode",
>         "claude": "Claude",
>         "grok": "Grok",
>         "mac os": "macOS",
>         "iphone": "iPhone",
>         "my s t t": "MySTT",
>         "whisper kit": "WhisperKit",
>         "chat g p t": "ChatGPT",
>         "open a i": "OpenAI",
>         "wolak": "Wolak"
>     },
>     "abbreviations": {
>         "btw": "by the way",
>         "asap": "ASAP",
>         "eta": "ETA",
>         "api": "API",
>         "url": "URL",
>         "ui": "UI"
>     },
>     "polish_terms": {
>         "klod": "Claude",
>         "grok": "Grok",
>         "ajfon": "iPhone",
>         "majkrosoft": "Microsoft",
>         "gugle": "Google"
>     },
>     "rules": [
>         {"pattern": "\\s+([.,!?;:])", "replacement": "$1"},
>         {"pattern": "\\s{2,}", "replacement": " "}
>     ]
> }
> ```
>
> ---
>
> Stworz katalogi jesli nie istnieja:
> ```bash
> mkdir -p MySTT/MySTT/PostProcessing
> mkdir -p MySTT/MySTT/Resources
> ```
>
> Po wykonaniu uruchom weryfikacje. Jesli jakiekolwiek kryterium FAIL -> napraw -> ponowna weryfikacja -> powtarzaj max 5 razy -> jesli nadal FAIL -> zglos problem.

#### Weryfikacja (automatyczna po wykonaniu):

```bash
cd /Users/igor.3.wolak.external/Downloads/MySTT

echo "=== WERYFIKACJA SESJI J ==="

echo "--- Test 1: Plik DictionaryEngine.swift istnieje ---"
test -f MySTT/MySTT/PostProcessing/DictionaryEngine.swift && echo "PASS" || echo "FAIL"

echo "--- Test 2: Plik default_dictionary.json istnieje ---"
test -f MySTT/MySTT/Resources/default_dictionary.json && echo "PASS" || echo "FAIL"

echo "--- Test 3: default_dictionary.json jest poprawnym JSON ---"
python3 -c "import json; json.load(open('MySTT/MySTT/Resources/default_dictionary.json'))" 2>&1 && echo "PASS" || echo "FAIL"

echo "--- Test 4: JSON zawiera wymagane klucze ---"
python3 -c "
import json
d = json.load(open('MySTT/MySTT/Resources/default_dictionary.json'))
assert 'terms' in d, 'Missing terms'
assert 'abbreviations' in d, 'Missing abbreviations'
assert 'polish_terms' in d, 'Missing polish_terms'
assert 'rules' in d, 'Missing rules'
assert len(d['terms']) >= 16, f'Expected >=16 terms, got {len(d[\"terms\"])}'
assert len(d['abbreviations']) >= 6, f'Expected >=6 abbreviations, got {len(d[\"abbreviations\"])}'
assert len(d['polish_terms']) >= 5, f'Expected >=5 polish_terms, got {len(d[\"polish_terms\"])}'
assert len(d['rules']) >= 2, f'Expected >=2 rules, got {len(d[\"rules\"])}'
print('PASS')
" 2>&1 || echo "FAIL"

echo "--- Test 5: DictionaryEngine ma metode preProcess ---"
grep -q "func preProcess" MySTT/MySTT/PostProcessing/DictionaryEngine.swift && echo "PASS" || echo "FAIL"

echo "--- Test 6: DictionaryEngine ma metode postProcess ---"
grep -q "func postProcess" MySTT/MySTT/PostProcessing/DictionaryEngine.swift && echo "PASS" || echo "FAIL"

echo "--- Test 7: DictionaryEngine ma metode loadDictionary ---"
grep -q "func loadDictionary" MySTT/MySTT/PostProcessing/DictionaryEngine.swift && echo "PASS" || echo "FAIL"

echo "--- Test 8: DictionaryEngine ma metode saveDictionary ---"
grep -q "func saveDictionary" MySTT/MySTT/PostProcessing/DictionaryEngine.swift && echo "PASS" || echo "FAIL"

echo "--- Test 9: DictionaryEngine ma metode addTerm ---"
grep -q "func addTerm" MySTT/MySTT/PostProcessing/DictionaryEngine.swift && echo "PASS" || echo "FAIL"

echo "--- Test 10: DictionaryEngine ma metode removeTerm ---"
grep -q "func removeTerm" MySTT/MySTT/PostProcessing/DictionaryEngine.swift && echo "PASS" || echo "FAIL"

echo "--- Test 11: DictionaryEngine ma metode getDictionaryTermsForPrompt ---"
grep -q "func getDictionaryTermsForPrompt" MySTT/MySTT/PostProcessing/DictionaryEngine.swift && echo "PASS" || echo "FAIL"

echo "--- Test 12: DictionaryEngine laduje z ~/.mystt/dictionary.json ---"
grep -q "\.mystt/dictionary\.json\|mystt.*dictionary" MySTT/MySTT/PostProcessing/DictionaryEngine.swift && echo "PASS" || echo "FAIL"

echo "--- Test 13: DictionaryEngine uzywa caseInsensitive ---"
grep -q "caseInsensitive\|.caseInsensitive" MySTT/MySTT/PostProcessing/DictionaryEngine.swift && echo "PASS" || echo "FAIL"

echo "--- Test 14: DictionaryEngine uzywa NSRegularExpression ---"
grep -q "NSRegularExpression\|regularExpression" MySTT/MySTT/PostProcessing/DictionaryEngine.swift && echo "PASS" || echo "FAIL"

echo "--- Test 15: DictionaryData jest Codable ---"
grep -q "Codable" MySTT/MySTT/PostProcessing/DictionaryEngine.swift && echo "PASS" || echo "FAIL"

echo "=== KONIEC WERYFIKACJI SESJI J ==="
```

#### Kryteria DONE:
- [ ] Plik `DictionaryEngine.swift` istnieje w `MySTT/MySTT/PostProcessing/`
- [ ] Plik `default_dictionary.json` istnieje w `MySTT/MySTT/Resources/`
- [ ] JSON jest poprawny i zawiera klucze: terms (16+), abbreviations (6+), polish_terms (5+), rules (2+)
- [ ] `DictionaryData` i `RegexRule` sa `Codable`
- [ ] `loadDictionary()` najpierw probuje `~/.mystt/dictionary.json`, potem bundled
- [ ] `saveDictionary()` zapisuje pretty-printed JSON do `~/.mystt/dictionary.json`
- [ ] `addTerm()` i `removeTerm()` modyfikuja slownik i zapisuja
- [ ] `preProcess()` robi case-insensitive zamiane, dluzsze klucze najpierw
- [ ] `postProcess()` stosuje regex rules + capitalize po zdaniu + usuwa podwojne spacje
- [ ] `getDictionaryTermsForPrompt()` zwraca sformatowany string dla LLM

---

### Sesja K: Keychain Manager + Sound Player
**Runda**: 4 | **Typ**: PARALLEL | **Faza**: 3
**Agent**: `software-architect`
**Zaleznosci**: Task 0.1 (Project Setup)
**Pliki wyjsciowe**:
- `MySTT/MySTT/Utilities/KeychainManager.swift`
- `MySTT/MySTT/Utilities/SoundPlayer.swift`

#### Prompt dla sesji Claude Code:

> Pracujesz w katalogu: `/Users/igor.3.wolak.external/Downloads/MySTT`
>
> Projekt: MySTT - macOS menu bar app do speech-to-text. Swift, SwiftUI, macOS 14+.
>
> **Twoim zadaniem jest stworzenie dwoch plikow utilities: KeychainManager i SoundPlayer.**
>
> Stworz katalog jesli nie istnieje: `mkdir -p MySTT/MySTT/Utilities`
>
> ---
>
> **PLIK 1: `MySTT/MySTT/Utilities/KeychainManager.swift`**
>
> Singleton manager do bezpiecznego przechowywania kluczy API w macOS Keychain.
>
> ```swift
> import Foundation
> import Security
> import os
>
> final class KeychainManager {
>     static let shared = KeychainManager()
>
>     private let service = "com.mystt.apikeys"
>     private let logger = Logger(subsystem: "com.mystt.app", category: "KeychainManager")
>
>     private init() {}
>
>     // Metody ponizej
> }
> ```
>
> **Metody:**
>
> 1. `func save(key: String, value: String) throws`:
>    - Konwertuj `value` na `Data` (utf8)
>    - Query dictionary: `[kSecClass: kSecClassGenericPassword, kSecAttrService: service, kSecAttrAccount: key, kSecValueData: data]`
>    - Najpierw probuj `SecItemAdd`
>    - Jesli `errSecDuplicateItem` -> uzyj `SecItemUpdate` z query (bez kSecValueData) i attributes `[kSecValueData: data]`
>    - Jesli inny blad -> throw `KeychainError.saveFailed(status)`
>    - Loguj sukces: `logger.info("Saved key: \(key)")`
>
> 2. `func load(key: String) -> String?`:
>    - Query: `[kSecClass: kSecClassGenericPassword, kSecAttrService: service, kSecAttrAccount: key, kSecReturnData: true, kSecMatchLimit: kSecMatchLimitOne]`
>    - `SecItemCopyMatching` -> cast result do `Data` -> `String(data:encoding:.utf8)`
>    - Jesli `errSecItemNotFound` -> return nil (nie loguj jako blad)
>    - Jesli inny blad -> logger.error i return nil
>
> 3. `func delete(key: String) throws`:
>    - Query: `[kSecClass: kSecClassGenericPassword, kSecAttrService: service, kSecAttrAccount: key]`
>    - `SecItemDelete`
>    - Jesli `errSecItemNotFound` -> OK (nie rzucaj bledu, item juz nie istnieje)
>    - Jesli inny blad -> throw `KeychainError.deleteFailed(status)`
>
> **Enum bledow:**
> ```swift
> enum KeychainError: LocalizedError {
>     case saveFailed(OSStatus)
>     case deleteFailed(OSStatus)
>
>     var errorDescription: String? {
>         switch self {
>         case .saveFailed(let status):
>             return "Keychain save failed with status: \(status)"
>         case .deleteFailed(let status):
>             return "Keychain delete failed with status: \(status)"
>         }
>     }
> }
> ```
>
> Dodaj convenience properties dla czesto uzywanych kluczy:
> ```swift
> // Convenience accessors
> var openAIKey: String? {
>     get { load(key: "openai_api_key") }
>     set {
>         if let value = newValue {
>             try? save(key: "openai_api_key", value: value)
>         } else {
>             try? delete(key: "openai_api_key")
>         }
>     }
> }
>
> var deepgramKey: String? {
>     get { load(key: "deepgram_api_key") }
>     set { /* analogicznie */ }
> }
>
> var groqKey: String? {
>     get { load(key: "groq_api_key") }
>     set { /* analogicznie */ }
> }
> ```
>
> ---
>
> **PLIK 2: `MySTT/MySTT/Utilities/SoundPlayer.swift`**
>
> Player dzwiekow systemowych dla feedbacku uzytkownika.
>
> ```swift
> import AppKit
> import os
>
> final class SoundPlayer {
>     static let shared = SoundPlayer()
>
>     private let logger = Logger(subsystem: "com.mystt.app", category: "SoundPlayer")
>
>     private init() {}
> }
> ```
>
> **Metody:**
>
> 1. `func playStartRecording()`:
>    - Sprawdz `AppSettings.shared.playSound` - jesli false, return
>    - Odtworz `NSSound(named: "Tink")?.play()` (dzwiek rozpoczecia nagrywania)
>
> 2. `func playStopRecording()`:
>    - Sprawdz `AppSettings.shared.playSound`
>    - `NSSound(named: "Pop")?.play()`
>
> 3. `func playSuccess()`:
>    - Sprawdz `AppSettings.shared.playSound`
>    - `NSSound(named: "Glass")?.play()`
>
> 4. `func playError()`:
>    - Sprawdz `AppSettings.shared.playSound`
>    - `NSSound(named: "Basso")?.play()`
>
> Przeczytaj `MySTT/MySTT/Models/AppSettings.swift` aby upewnic sie ze `playSound` property istnieje. Jesli nie istnieje, dodaj komentarz `// TODO: AppSettings.playSound needs to be added`.
>
> Dodaj prywatna helper metode aby uniknac duplikacji:
> ```swift
> private func play(_ soundName: String) {
>     guard AppSettings.shared.playSound else { return }
>     guard let sound = NSSound(named: soundName) else {
>         logger.warning("System sound '\(soundName)' not found")
>         return
>     }
>     sound.play()
> }
> ```
>
> Wtedy publiczne metody po prostu wywoluja: `play("Tink")`, `play("Pop")`, itd.
>
> ---
>
> Po wykonaniu uruchom weryfikacje. Jesli jakiekolwiek kryterium FAIL -> napraw -> ponowna weryfikacja -> powtarzaj max 5 razy -> jesli nadal FAIL -> zglos problem.

#### Weryfikacja (automatyczna po wykonaniu):

```bash
cd /Users/igor.3.wolak.external/Downloads/MySTT

echo "=== WERYFIKACJA SESJI K ==="

echo "--- Test 1: Plik KeychainManager.swift istnieje ---"
test -f MySTT/MySTT/Utilities/KeychainManager.swift && echo "PASS" || echo "FAIL"

echo "--- Test 2: Plik SoundPlayer.swift istnieje ---"
test -f MySTT/MySTT/Utilities/SoundPlayer.swift && echo "PASS" || echo "FAIL"

echo "--- Test 3: KeychainManager ma metode save ---"
grep -q "func save(key.*value" MySTT/MySTT/Utilities/KeychainManager.swift && echo "PASS" || echo "FAIL"

echo "--- Test 4: KeychainManager ma metode load ---"
grep -q "func load(key" MySTT/MySTT/Utilities/KeychainManager.swift && echo "PASS" || echo "FAIL"

echo "--- Test 5: KeychainManager ma metode delete ---"
grep -q "func delete(key" MySTT/MySTT/Utilities/KeychainManager.swift && echo "PASS" || echo "FAIL"

echo "--- Test 6: KeychainManager uzywa service com.mystt.apikeys ---"
grep -q "com.mystt.apikeys" MySTT/MySTT/Utilities/KeychainManager.swift && echo "PASS" || echo "FAIL"

echo "--- Test 7: KeychainManager obsluguje errSecDuplicateItem ---"
grep -q "errSecDuplicateItem" MySTT/MySTT/Utilities/KeychainManager.swift && echo "PASS" || echo "FAIL"

echo "--- Test 8: KeychainManager obsluguje errSecItemNotFound ---"
grep -q "errSecItemNotFound" MySTT/MySTT/Utilities/KeychainManager.swift && echo "PASS" || echo "FAIL"

echo "--- Test 9: KeychainManager importuje Security ---"
grep -q "import Security" MySTT/MySTT/Utilities/KeychainManager.swift && echo "PASS" || echo "FAIL"

echo "--- Test 10: KeychainManager ma convenience properties (openAIKey, deepgramKey, groqKey) ---"
grep -q "openAIKey\|openai_api_key" MySTT/MySTT/Utilities/KeychainManager.swift && \
grep -q "deepgramKey\|deepgram_api_key" MySTT/MySTT/Utilities/KeychainManager.swift && \
grep -q "groqKey\|groq_api_key" MySTT/MySTT/Utilities/KeychainManager.swift && echo "PASS" || echo "FAIL"

echo "--- Test 11: SoundPlayer ma 4 metody play ---"
grep -q "func playStartRecording" MySTT/MySTT/Utilities/SoundPlayer.swift && \
grep -q "func playStopRecording" MySTT/MySTT/Utilities/SoundPlayer.swift && \
grep -q "func playSuccess" MySTT/MySTT/Utilities/SoundPlayer.swift && \
grep -q "func playError" MySTT/MySTT/Utilities/SoundPlayer.swift && echo "PASS" || echo "FAIL"

echo "--- Test 12: SoundPlayer uzywa NSSound z poprawnymi nazwami ---"
grep -q "Tink" MySTT/MySTT/Utilities/SoundPlayer.swift && \
grep -q "Pop" MySTT/MySTT/Utilities/SoundPlayer.swift && \
grep -q "Glass" MySTT/MySTT/Utilities/SoundPlayer.swift && \
grep -q "Basso" MySTT/MySTT/Utilities/SoundPlayer.swift && echo "PASS" || echo "FAIL"

echo "--- Test 13: SoundPlayer respektuje AppSettings.playSound ---"
grep -q "playSound\|AppSettings" MySTT/MySTT/Utilities/SoundPlayer.swift && echo "PASS" || echo "FAIL"

echo "--- Test 14: KeychainManager jest Singleton ---"
grep -q "static let shared" MySTT/MySTT/Utilities/KeychainManager.swift && \
grep -q "private init" MySTT/MySTT/Utilities/KeychainManager.swift && echo "PASS" || echo "FAIL"

echo "--- Test 15: SoundPlayer jest Singleton ---"
grep -q "static let shared" MySTT/MySTT/Utilities/SoundPlayer.swift && \
grep -q "private init" MySTT/MySTT/Utilities/SoundPlayer.swift && echo "PASS" || echo "FAIL"

echo "=== KONIEC WERYFIKACJI SESJI K ==="
```

#### Kryteria DONE:
- [ ] Plik `KeychainManager.swift` istnieje w `MySTT/MySTT/Utilities/`
- [ ] Plik `SoundPlayer.swift` istnieje w `MySTT/MySTT/Utilities/`
- [ ] `KeychainManager` jest singletonem z `private init()`
- [ ] `save()` obsluguje `errSecDuplicateItem` (update zamiast insert)
- [ ] `load()` obsluguje `errSecItemNotFound` (return nil)
- [ ] `delete()` obsluguje `errSecItemNotFound` (nie rzuca bledu)
- [ ] Service name: `com.mystt.apikeys`
- [ ] Convenience properties: `openAIKey`, `deepgramKey`, `groqKey`
- [ ] `KeychainError` enum z `saveFailed` i `deleteFailed`
- [ ] `SoundPlayer` jest singletonem z `private init()`
- [ ] 4 metody: `playStartRecording` (Tink), `playStopRecording` (Pop), `playSuccess` (Glass), `playError` (Basso)
- [ ] Kazda metoda sprawdza `AppSettings.shared.playSound` przed odtworzeniem

---

## RUNDA 5 (Sesja L) - UI

---

### Sesja L: Menu Bar View + Onboarding
**Runda**: 5 | **Typ**: PARALLEL | **Faza**: 4
**Agent**: `react-specialist`
**Zaleznosci**: Task 0.1 (Project Setup), Task 1.1 (Protocols)
**Pliki wyjsciowe**:
- `MySTT/MySTT/UI/MenuBarView.swift`
- `MySTT/MySTT/UI/OnboardingView.swift`

#### Prompt dla sesji Claude Code:

> Pracujesz w katalogu: `/Users/igor.3.wolak.external/Downloads/MySTT`
>
> Projekt: MySTT - macOS menu bar app do speech-to-text. Swift, SwiftUI, macOS 14+.
>
> **Twoim zadaniem jest stworzenie dwoch widokow SwiftUI: MenuBarView i OnboardingView.**
>
> Najpierw przeczytaj istniejace pliki, aby poznac modele i stany:
> - `MySTT/MySTT/Models/AppSettings.swift`
> - `MySTT/MySTT/Models/Language.swift`
> - `MySTT/MySTT/Protocols/` (wszystkie pliki)
> - `MySTT/MySTT/App/MySTTApp.swift` (jesli istnieje)
>
> Stworz katalog jesli nie istnieje: `mkdir -p MySTT/MySTT/UI`
>
> ---
>
> **PLIK 1: `MySTT/MySTT/UI/MenuBarView.swift`**
>
> SwiftUI view wyswietlany w menu bar dropdown (uzywany w `MenuBarExtra`).
>
> ```swift
> import SwiftUI
>
> struct MenuBarView: View {
>     @EnvironmentObject var appState: AppState
>
>     var body: some View {
>         VStack(alignment: .leading, spacing: 8) {
>             // ... zawartość
>         }
>         .padding()
>         .frame(width: 300)
>     }
> }
> ```
>
> **Elementy widoku (od gory do dolu):**
>
> 1. **Status indicator** - Horizontal stack:
>    - Kolorowe kolko (`Circle().fill(statusColor).frame(width: 10, height: 10)`)
>    - Tekst statusu: "Ready" / "Recording..." / "Processing..." / "Done" / "Error"
>    - Kolory: Ready=zielony, Recording=czerwony, Processing=pomaranczowy, Done=niebieski, Error=czerwony
>    - Status pochodzi z `appState` (np. `appState.isRecording`, `appState.isProcessing`, `appState.statusMessage`)
>
> 2. **Divider**
>
> 3. **Last transcription** - Jesli `appState.lastTranscription` nie jest pusty:
>    - Label "Last transcription:"
>    - Text z truncated do 100 znakow (`appState.lastTranscription.prefix(100)`)
>    - Maly font, szary kolor
>
> 4. **Detected language badge** - Jesli dostepny:
>    - HStack z Label "Language:" i badge "EN" lub "PL"
>    - Badge: `Text("EN").padding(.horizontal, 6).padding(.vertical, 2).background(Capsule().fill(.blue.opacity(0.2)))`
>
> 5. **Provider info** - Dwie linie:
>    - "STT: \(appState.selectedSTTProvider ?? "WhisperKit")"
>    - "LLM: \(appState.selectedLLMProvider ?? "None")"
>    - Maly font
>
> 6. **Divider**
>
> 7. **Enable/Disable toggle**:
>    - `Toggle("Enabled", isOn: $appState.isEnabled)` lub podobny binding
>
> 8. **Buttons section**:
>    - `Button("Settings...") { NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil) }` - otwiera okno Settings
>      - Alternatywa dla macOS 14+: `SettingsLink { Text("Settings...") }` jesli dostepne
>    - `Divider()`
>    - `Button("Quit MySTT") { NSApplication.shared.terminate(nil) }`
>
> **WAZNE**: `AppState` moze jeszcze nie istniec (bedzie w Sesji N). Stworz minimalny stub `AppState` w tym samym pliku pod `#if DEBUG` lub w osobnym pliku `AppState+Stub.swift` TYLKO jesli AppState nie istnieje. Stub powinien miec:
> ```swift
> // Jesli AppState nie istnieje, uzyj tego stubu tymczasowo:
> // class AppState: ObservableObject {
> //     @Published var isRecording = false
> //     @Published var isProcessing = false
> //     @Published var lastTranscription = ""
> //     @Published var detectedLanguage: String? = nil
> //     @Published var statusMessage = "Ready"
> //     @Published var isEnabled = true
> //     @Published var selectedSTTProvider: String? = "WhisperKit"
> //     @Published var selectedLLMProvider: String? = nil
> // }
> ```
>
> Dodaj `#Preview` macro na koncu pliku:
> ```swift
> #Preview {
>     MenuBarView()
>         .environmentObject(AppState())
> }
> ```
>
> ---
>
> **PLIK 2: `MySTT/MySTT/UI/OnboardingView.swift`**
>
> 5-krokowy wizard onboarding wyswietlany przy pierwszym uruchomieniu.
>
> ```swift
> import SwiftUI
> import AVFoundation
>
> struct OnboardingView: View {
>     @State private var currentStep = 0
>     @State private var micPermissionGranted = false
>     @State private var accessibilityGranted = false
>     @State private var selectedHotkey = "Right Option"
>     @State private var selectedProvider = "local"  // "local" or "remote"
>     @Environment(\.dismiss) var dismiss
>
>     private let totalSteps = 5
>
>     var body: some View {
>         VStack(spacing: 20) {
>             // Progress dots
>             progressDots
>
>             // Current step content
>             stepContent
>
>             // Navigation buttons
>             navigationButtons
>         }
>         .padding(30)
>         .frame(width: 500, height: 400)
>     }
> }
> ```
>
> **Kroki wizarda:**
>
> **Step 1 - Microphone Permission:**
> - Tytul: "Microphone Access"
> - Ikona: `Image(systemName: "mic.fill").font(.system(size: 50)).foregroundColor(.blue)`
> - Opis: "MySTT needs access to your microphone to transcribe speech."
> - Przycisk "Request Permission" -> `AVCaptureDevice.requestAccess(for: .audio)`
> - Status: zielona checkmark jesli granted, czerwony X jesli denied
> - Sprawdzanie: `AVCaptureDevice.authorizationStatus(for: .audio)`
>
> **Step 2 - Accessibility Permission:**
> - Tytul: "Accessibility Access"
> - Ikona: `Image(systemName: "hand.raised.fill").font(.system(size: 50)).foregroundColor(.orange)`
> - Opis: "MySTT needs Accessibility access to paste transcriptions and detect hotkeys."
> - Instrukcja: "Go to System Settings > Privacy & Security > Accessibility and enable MySTT"
> - Przycisk "Open System Settings" -> `NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)`
> - Przycisk "Check Status" -> `AXIsProcessTrusted()`
> - Status indicator jak w Step 1
>
> **Step 3 - Hotkey Selection:**
> - Tytul: "Choose Hotkey"
> - Ikona: `Image(systemName: "keyboard.fill").font(.system(size: 50)).foregroundColor(.purple)`
> - Opis: "Press and hold the hotkey to record, release to transcribe."
> - Picker z opcjami: "Right Option", "Right Command", "F18", "F19"
> - `Picker("Hotkey", selection: $selectedHotkey) { ... }.pickerStyle(.radioGroup)`
> - Informacja: "Default: Right Option key"
>
> **Step 4 - LLM Provider:**
> - Tytul: "AI Processing"
> - Ikona: `Image(systemName: "brain.fill").font(.system(size: 50)).foregroundColor(.green)`
> - Opis: "Choose how to process transcriptions:"
> - Opcje radio:
>   - "Local (Ollama)" - "Free, private, requires Ollama installed"
>   - "Remote (Groq/OpenAI)" - "Faster, requires API key"
>   - "None" - "Basic post-processing only"
> - `Picker("Provider", selection: $selectedProvider) { ... }.pickerStyle(.radioGroup)`
>
> **Step 5 - Ready:**
> - Tytul: "You're All Set!"
> - Ikona: `Image(systemName: "checkmark.circle.fill").font(.system(size: 50)).foregroundColor(.green)`
> - Podsumowanie wybranych ustawien
> - Przycisk "Start Using MySTT" -> zapisz ustawienia do `UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")`, zapisz wybory do `AppSettings`, dismiss
>
> **Progress dots:**
> ```swift
> var progressDots: some View {
>     HStack(spacing: 8) {
>         ForEach(0..<totalSteps, id: \.self) { step in
>             Circle()
>                 .fill(step == currentStep ? Color.accentColor : Color.gray.opacity(0.3))
>                 .frame(width: 8, height: 8)
>         }
>     }
> }
> ```
>
> **Navigation buttons:**
> - "Back" (jesli currentStep > 0): `currentStep -= 1`
> - "Next" (jesli currentStep < totalSteps - 1): `currentStep += 1`
> - Na ostatnim kroku zamiast "Next" -> "Start Using MySTT"
> - `Spacer()` miedzy Back i Next
> - Back: `.buttonStyle(.bordered)`, Next: `.buttonStyle(.borderedProminent)`
>
> **Sprawdzanie pierwszego uruchomienia** (uzyj w miejscu wywolania, nie w samym widoku):
> ```swift
> // W AppDelegate lub MySTTApp:
> if !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") {
>     // show OnboardingView
> }
> ```
>
> Dodaj `#Preview`:
> ```swift
> #Preview {
>     OnboardingView()
> }
> ```
>
> ---
>
> Po wykonaniu uruchom weryfikacje. Jesli jakiekolwiek kryterium FAIL -> napraw -> ponowna weryfikacja -> powtarzaj max 5 razy -> jesli nadal FAIL -> zglos problem.

#### Weryfikacja (automatyczna po wykonaniu):

```bash
cd /Users/igor.3.wolak.external/Downloads/MySTT

echo "=== WERYFIKACJA SESJI L ==="

echo "--- Test 1: Plik MenuBarView.swift istnieje ---"
test -f MySTT/MySTT/UI/MenuBarView.swift && echo "PASS" || echo "FAIL"

echo "--- Test 2: Plik OnboardingView.swift istnieje ---"
test -f MySTT/MySTT/UI/OnboardingView.swift && echo "PASS" || echo "FAIL"

echo "--- Test 3: MenuBarView jest SwiftUI View ---"
grep -q "struct MenuBarView.*View" MySTT/MySTT/UI/MenuBarView.swift && echo "PASS" || echo "FAIL"

echo "--- Test 4: MenuBarView uzywa EnvironmentObject AppState ---"
grep -q "@EnvironmentObject.*appState\|@EnvironmentObject.*AppState" MySTT/MySTT/UI/MenuBarView.swift && echo "PASS" || echo "FAIL"

echo "--- Test 5: MenuBarView zawiera status indicator z kolorami ---"
grep -q "Circle()" MySTT/MySTT/UI/MenuBarView.swift && \
grep -q "Recording\|Processing\|Ready\|Error" MySTT/MySTT/UI/MenuBarView.swift && echo "PASS" || echo "FAIL"

echo "--- Test 6: MenuBarView zawiera truncated transcription (100 chars) ---"
grep -q "prefix(100)\|100" MySTT/MySTT/UI/MenuBarView.swift && echo "PASS" || echo "FAIL"

echo "--- Test 7: MenuBarView zawiera language badge ---"
grep -q "EN\|PL\|language\|Language" MySTT/MySTT/UI/MenuBarView.swift && echo "PASS" || echo "FAIL"

echo "--- Test 8: MenuBarView zawiera Settings button ---"
grep -q "Settings\|showSettingsWindow\|SettingsLink" MySTT/MySTT/UI/MenuBarView.swift && echo "PASS" || echo "FAIL"

echo "--- Test 9: MenuBarView zawiera Quit button ---"
grep -q "Quit\|terminate" MySTT/MySTT/UI/MenuBarView.swift && echo "PASS" || echo "FAIL"

echo "--- Test 10: MenuBarView zawiera Enable/Disable toggle ---"
grep -q "Toggle\|isEnabled\|Enabled" MySTT/MySTT/UI/MenuBarView.swift && echo "PASS" || echo "FAIL"

echo "--- Test 11: OnboardingView jest SwiftUI View ---"
grep -q "struct OnboardingView.*View" MySTT/MySTT/UI/OnboardingView.swift && echo "PASS" || echo "FAIL"

echo "--- Test 12: OnboardingView ma 5 krokow ---"
grep -q "totalSteps.*=.*5\|5.*step" MySTT/MySTT/UI/OnboardingView.swift && echo "PASS" || echo "FAIL"

echo "--- Test 13: OnboardingView - Step 1 microphone permission ---"
grep -q "mic\|Microphone\|requestAccess\|AVCaptureDevice" MySTT/MySTT/UI/OnboardingView.swift && echo "PASS" || echo "FAIL"

echo "--- Test 14: OnboardingView - Step 2 accessibility ---"
grep -q "Accessibility\|AXIsProcessTrusted\|hand.raised" MySTT/MySTT/UI/OnboardingView.swift && echo "PASS" || echo "FAIL"

echo "--- Test 15: OnboardingView - Step 3 hotkey ---"
grep -q "Hotkey\|hotkey\|Right Option\|keyboard" MySTT/MySTT/UI/OnboardingView.swift && echo "PASS" || echo "FAIL"

echo "--- Test 16: OnboardingView - Step 4 LLM provider ---"
grep -q "Ollama\|local\|remote\|Provider\|brain" MySTT/MySTT/UI/OnboardingView.swift && echo "PASS" || echo "FAIL"

echo "--- Test 17: OnboardingView - Step 5 ready ---"
grep -q "Ready\|All Set\|checkmark\|Start" MySTT/MySTT/UI/OnboardingView.swift && echo "PASS" || echo "FAIL"

echo "--- Test 18: OnboardingView - progress dots ---"
grep -q "progressDots\|ForEach.*totalSteps\|Circle" MySTT/MySTT/UI/OnboardingView.swift && echo "PASS" || echo "FAIL"

echo "--- Test 19: OnboardingView - navigation (Back/Next) ---"
grep -q "Back\|Next\|currentStep" MySTT/MySTT/UI/OnboardingView.swift && echo "PASS" || echo "FAIL"

echo "--- Test 20: OnboardingView - hasCompletedOnboarding UserDefaults ---"
grep -q "hasCompletedOnboarding" MySTT/MySTT/UI/OnboardingView.swift && echo "PASS" || echo "FAIL"

echo "--- Test 21: Preview macros ---"
grep -q "#Preview" MySTT/MySTT/UI/MenuBarView.swift && \
grep -q "#Preview" MySTT/MySTT/UI/OnboardingView.swift && echo "PASS" || echo "FAIL"

echo "=== KONIEC WERYFIKACJI SESJI L ==="
```

#### Kryteria DONE:
- [ ] Plik `MenuBarView.swift` istnieje w `MySTT/MySTT/UI/`
- [ ] Plik `OnboardingView.swift` istnieje w `MySTT/MySTT/UI/`
- [ ] `MenuBarView` uzywa `@EnvironmentObject AppState`
- [ ] Status indicator z kolorowymi kolkami (Ready/Recording/Processing/Done/Error)
- [ ] Last transcription truncated do 100 znakow
- [ ] Language badge (EN/PL)
- [ ] STT i LLM provider info
- [ ] Enable/Disable toggle
- [ ] Settings button (otwiera okno ustawien)
- [ ] Quit button (`NSApplication.shared.terminate`)
- [ ] `OnboardingView` ma 5 krokow z progress dots
- [ ] Step 1: Microphone permission request + status
- [ ] Step 2: Accessibility permission instruction + check + Open System Settings
- [ ] Step 3: Hotkey selection (radio group, default Right Option)
- [ ] Step 4: LLM provider choice (local/remote/none)
- [ ] Step 5: Ready z podsumowaniem i przyciskiem Start
- [ ] Nawigacja Back/Next z poprawnym sterowaniem
- [ ] `hasCompletedOnboarding` w UserDefaults
- [ ] `#Preview` macro w obu plikach

---

## RUNDA 6 (Sesja N) - Integration

---

### Sesja N: AppState + Pipeline Integration
**Runda**: 6 | **Typ**: SEQUENTIAL | **Faza**: 5
**Agent**: `software-architect`
**Zaleznosci**: WSZYSTKIE poprzednie taski (0.1, 1.1-1.4, 2.1-2.3, 3.1-3.3, 4.1-4.2)
**Pliki wyjsciowe**:
- `MySTT/MySTT/App/AppState.swift`
- `MySTT/MySTT/App/AppDelegate.swift`
- `MySTT/MySTT/App/MySTTApp.swift` (UPDATE)

#### Prompt dla sesji Claude Code:

> Pracujesz w katalogu: `/Users/igor.3.wolak.external/Downloads/MySTT`
>
> Projekt: MySTT - macOS menu bar app do speech-to-text. Swift, SwiftUI, macOS 14+.
>
> **To jest sesja integracyjna - laczy WSZYSTKIE wczesniej stworzone komponenty w dzialajaca aplikacje.**
>
> **KROK 0: Przeczytaj wszystkie istniejace pliki projektu.** To jest krytyczne. Musisz poznac dokladne sygnatury, typy i interfejsy kazdego komponentu.
>
> Przeczytaj nastepujace pliki (jesli istnieja):
> ```
> MySTT/MySTT/Protocols/STTEngineProtocol.swift
> MySTT/MySTT/Protocols/LLMProviderProtocol.swift
> MySTT/MySTT/Protocols/PostProcessorProtocol.swift
> MySTT/MySTT/Protocols/AudioCaptureProtocol.swift
> MySTT/MySTT/Models/AppSettings.swift
> MySTT/MySTT/Models/Language.swift
> MySTT/MySTT/Audio/AudioCaptureEngine.swift
> MySTT/MySTT/STT/WhisperKitEngine.swift
> MySTT/MySTT/STT/DeepgramEngine.swift
> MySTT/MySTT/LLM/OllamaProvider.swift
> MySTT/MySTT/LLM/GroqProvider.swift
> MySTT/MySTT/LLM/OpenAIProvider.swift
> MySTT/MySTT/PostProcessing/PostProcessor.swift
> MySTT/MySTT/PostProcessing/DictionaryEngine.swift
> MySTT/MySTT/PostProcessing/PunctuationCorrector.swift
> MySTT/MySTT/Utilities/KeychainManager.swift
> MySTT/MySTT/Utilities/SoundPlayer.swift
> MySTT/MySTT/Utilities/AutoPaster.swift
> MySTT/MySTT/Utilities/PermissionChecker.swift
> MySTT/MySTT/Utilities/HotkeyManager.swift
> MySTT/MySTT/UI/MenuBarView.swift
> MySTT/MySTT/UI/OnboardingView.swift
> MySTT/MySTT/UI/SettingsView.swift
> MySTT/MySTT/App/MySTTApp.swift
> ```
>
> Jesli jakis plik nie istnieje, zanotuj to i stworz odpowiedni stub lub adapter.
>
> ---
>
> **PLIK 1: `MySTT/MySTT/App/AppState.swift`**
>
> Glowny stan aplikacji, laczacy wszystkie komponenty.
>
> ```swift
> import SwiftUI
> import Combine
> import os
>
> @MainActor
> class AppState: ObservableObject {
>     // MARK: - Published Properties
>     @Published var isRecording = false
>     @Published var isProcessing = false
>     @Published var lastTranscription = ""
>     @Published var detectedLanguage: Language? = nil
>     @Published var statusMessage = "Ready"
>     @Published var isEnabled = true
>     @Published var errorMessage: String? = nil
>
>     // MARK: - Components
>     private var audioEngine: AudioCaptureEngine?
>     private var sttEngine: (any STTEngineProtocol)?
>     private var postProcessor: PostProcessor?
>     private var autoPaster: AutoPaster?
>     private var hotkeyManager: HotkeyManager?
>     private var dictionaryEngine: DictionaryEngine?
>     private var punctuationCorrector: PunctuationCorrector?
>     private var llmProvider: (any LLMProviderProtocol)?
>
>     private let logger = Logger(subsystem: "com.mystt.app", category: "AppState")
>     private var cancellables = Set<AnyCancellable>()
>
>     // MARK: - Computed Properties
>     var selectedSTTProvider: String {
>         // Zwroc nazwe z AppSettings (np. "WhisperKit", "Deepgram")
>     }
>     var selectedLLMProvider: String? {
>         // Zwroc nazwe z AppSettings lub nil jesli wylaczony
>     }
> }
> ```
>
> **init():**
> - Inicjalizuj `DictionaryEngine()`
> - Inicjalizuj `PunctuationCorrector()`
> - Inicjalizuj `AudioCaptureEngine()` (lub zgodnie z sygnatora z przeczytanego pliku)
> - Inicjalizuj `AutoPaster()` (jesli dostepny) lub `AutoPaster.shared`
> - Wywolaj `setupSTTEngine()` - tworzy WhisperKitEngine lub DeepgramEngine na podstawie `AppSettings.shared`
> - Wywolaj `setupLLMProvider()` - tworzy OllamaProvider, GroqProvider, lub OpenAIProvider na podstawie AppSettings
> - Wywolaj `setupPostProcessor()` - tworzy PostProcessor z dictionaryEngine, punctuationCorrector, llmProvider
> - Wywolaj `setupHotkey()` - konfiguruje HotkeyManager z callbackami
> - Obserwuj zmiany AppSettings (Combine) aby przebudowac providery gdy uzytkownik zmieni ustawienia
>
> **setupSTTEngine():**
> ```swift
> private func setupSTTEngine() {
>     switch AppSettings.shared.sttProvider {
>     case .whisperKit:
>         // Lazy loading - nie laduj modelu od razu
>         sttEngine = WhisperKitEngine()
>     case .deepgram:
>         sttEngine = DeepgramEngine()
>     }
>     logger.info("STT engine set to: \(AppSettings.shared.sttProvider.rawValue)")
> }
> ```
> UWAGA: Dopasuj enum cases do tego co faktycznie istnieje w AppSettings. Przeczytaj plik!
>
> **setupLLMProvider():**
> ```swift
> private func setupLLMProvider() {
>     guard AppSettings.shared.enableLLMCorrection else {
>         llmProvider = nil
>         return
>     }
>     switch AppSettings.shared.llmProvider {
>     case .ollama:
>         llmProvider = OllamaProvider()
>     case .groq:
>         llmProvider = GroqProvider()
>     case .openai:
>         llmProvider = OpenAIProvider()
>     case .none:
>         llmProvider = nil
>     }
> }
> ```
> UWAGA: Dopasuj do faktycznych enum cases.
>
> **setupPostProcessor():**
> ```swift
> private func setupPostProcessor() {
>     postProcessor = PostProcessor(
>         dictionaryEngine: dictionaryEngine ?? DictionaryEngine(),
>         punctuationCorrector: punctuationCorrector ?? PunctuationCorrector(),
>         llmProvider: llmProvider
>     )
> }
> ```
>
> **setupHotkey():**
> ```swift
> private func setupHotkey() {
>     hotkeyManager = HotkeyManager()  // lub z parametrami z AppSettings
>     hotkeyManager?.onKeyDown = { [weak self] in
>         Task { @MainActor in
>             self?.startRecording()
>         }
>     }
>     hotkeyManager?.onKeyUp = { [weak self] in
>         Task { @MainActor in
>             self?.stopRecordingAndProcess()
>         }
>     }
>     hotkeyManager?.start()  // lub register() - dopasuj do faktycznego API
> }
> ```
> UWAGA: Dopasuj do faktycznego API HotkeyManager z przeczytanego pliku!
>
> **startRecording():**
> ```swift
> func startRecording() {
>     guard isEnabled, !isRecording else { return }
>
>     logger.info("Starting recording")
>     isRecording = true
>     statusMessage = "Recording..."
>     errorMessage = nil
>
>     SoundPlayer.shared.playStartRecording()
>
>     do {
>         try audioEngine?.startCapture()  // dopasuj do faktycznego API
>     } catch {
>         logger.error("Failed to start recording: \(error.localizedDescription)")
>         isRecording = false
>         statusMessage = "Error"
>         errorMessage = error.localizedDescription
>         SoundPlayer.shared.playError()
>     }
> }
> ```
>
> **stopRecordingAndProcess():**
> ```swift
> func stopRecordingAndProcess() {
>     guard isRecording else { return }
>
>     logger.info("Stopping recording, starting processing")
>     isRecording = false
>     isProcessing = true
>     statusMessage = "Processing..."
>
>     SoundPlayer.shared.playStopRecording()
>
>     Task {
>         do {
>             // 1. Stop audio and get buffer
>             let audioBuffer = try audioEngine?.stopCapture()  // dopasuj do API
>             guard let buffer = audioBuffer else {
>                 throw AppError.noAudioData
>             }
>
>             // 2. STT transcribe
>             guard let engine = sttEngine else {
>                 throw AppError.noSTTEngine
>             }
>             let result = try await engine.transcribe(buffer: buffer)  // dopasuj do API
>             // result powinien zawierac text i opcjonalnie language
>
>             let rawText = result.text  // dopasuj do faktycznego typu wyniku
>             let language = result.language ?? AppSettings.shared.defaultLanguage  // dopasuj
>             detectedLanguage = language
>
>             logger.info("STT result: \(rawText.prefix(50))...")
>
>             // 3. Post-process
>             var processedText = rawText
>             if let processor = postProcessor {
>                 processedText = try await processor.process(text: rawText, language: language)
>             }
>
>             // 4. Update state
>             lastTranscription = processedText
>             statusMessage = "Done"
>
>             // 5. Auto-paste
>             autoPaster?.paste(text: processedText)  // dopasuj do API
>
>             SoundPlayer.shared.playSuccess()
>             logger.info("Pipeline completed successfully")
>
>         } catch {
>             logger.error("Pipeline failed: \(error.localizedDescription)")
>             statusMessage = "Error"
>             errorMessage = error.localizedDescription
>             SoundPlayer.shared.playError()
>         }
>
>         isProcessing = false
>     }
> }
> ```
>
> **AppError enum:**
> ```swift
> enum AppError: LocalizedError {
>     case noAudioData
>     case noSTTEngine
>     case transcriptionFailed(String)
>     case postProcessingFailed(String)
>
>     var errorDescription: String? {
>         switch self {
>         case .noAudioData: return "No audio data captured"
>         case .noSTTEngine: return "No STT engine configured"
>         case .transcriptionFailed(let msg): return "Transcription failed: \(msg)"
>         case .postProcessingFailed(let msg): return "Post-processing failed: \(msg)"
>         }
>     }
> }
> ```
>
> **Settings observation:**
> ```swift
> private func observeSettings() {
>     // Obserwuj zmiany w AppSettings i przebuduj providery
>     // Jesli AppSettings uzywa @Published, uzyj Combine sink
>     // Jesli AppSettings uzywa UserDefaults, uzyj NotificationCenter
>     NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
>         .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
>         .sink { [weak self] _ in
>             self?.setupSTTEngine()
>             self?.setupLLMProvider()
>             self?.setupPostProcessor()
>         }
>         .store(in: &cancellables)
> }
> ```
>
> ---
>
> **PLIK 2: `MySTT/MySTT/App/AppDelegate.swift`**
>
> ```swift
> import AppKit
> import os
>
> class AppDelegate: NSObject, NSApplicationDelegate {
>     private let logger = Logger(subsystem: "com.mystt.app", category: "AppDelegate")
>
>     func applicationDidFinishLaunching(_ notification: Notification) {
>         logger.info("MySTT launched")
>
>         // Check permissions
>         let permissionChecker = PermissionChecker()  // lub .shared - dopasuj
>         permissionChecker.checkMicrophonePermission()  // dopasuj do API
>         permissionChecker.checkAccessibilityPermission()  // dopasuj do API
>
>         // Show onboarding if first launch
>         if !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") {
>             showOnboarding()
>         }
>     }
>
>     func applicationWillTerminate(_ notification: Notification) {
>         logger.info("MySTT terminating")
>         // Cleanup - audioEngine stop, hotkey manager cleanup
>         // Te cleanups beda w AppState.deinit lub tutaj
>     }
>
>     private func showOnboarding() {
>         let window = NSWindow(
>             contentRect: NSRect(x: 0, y: 0, width: 500, height: 400),
>             styleMask: [.titled, .closable],
>             backing: .buffered,
>             defer: false
>         )
>         window.title = "Welcome to MySTT"
>         window.contentView = NSHostingView(rootView: OnboardingView())
>         window.center()
>         window.makeKeyAndOrderFront(nil)
>         // Zachowaj referencje do window
>         NSApp.activate(ignoringAllPolicies: true)
>     }
> }
> ```
> UWAGA: Dopasuj API PermissionChecker do faktycznego pliku. Przeczytaj go!
>
> ---
>
> **PLIK 3: `MySTT/MySTT/App/MySTTApp.swift` (UPDATE)**
>
> Przeczytaj istniejacy plik `MySTTApp.swift` i zaktualizuj go. NIE nadpisuj calkowicie - zachowaj istniejaca strukture i dodaj brakujace elementy.
>
> Docelowa struktura:
> ```swift
> import SwiftUI
>
> @main
> struct MySTTApp: App {
>     @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
>     @StateObject private var appState = AppState()
>
>     var body: some Scene {
>         // Menu bar app
>         MenuBarExtra {
>             MenuBarView()
>                 .environmentObject(appState)
>         } label: {
>             Image(systemName: appState.isRecording ? "mic.fill" : "mic")
>         }
>         .menuBarExtraStyle(.window)
>
>         // Settings window
>         Settings {
>             SettingsView()
>                 .environmentObject(appState)
>         }
>     }
> }
> ```
>
> Kluczowe elementy:
> - `@NSApplicationDelegateAdaptor(AppDelegate.self)` - integracja z AppDelegate
> - `@StateObject private var appState = AppState()` - glowny stan
> - `MenuBarExtra` z dynamiczna ikona: `mic.fill` gdy nagrywanie, `mic` gdy idle
> - `.menuBarExtraStyle(.window)` - okienko dropdown (nie menu)
> - `Settings` scene z pelnym `SettingsView`
> - `environmentObject(appState)` na obu widokach
>
> Jesli `SettingsView` nie istnieje, dodaj placeholder:
> ```swift
> // Placeholder jesli SettingsView nie istnieje jeszcze
> // struct SettingsView: View {
> //     var body: some View { Text("Settings") }
> // }
> ```
>
> ---
>
> **BARDZO WAZNE**: Ta sesja musi DOPASOWAC sygnatury do faktycznych plikow. Nie zakladaj API - PRZECZYTAJ pliki. Jesli sygnatura w moim opisie rozni sie od faktycznego pliku, uzyj faktycznej sygnatury. Jesli plik nie istnieje, uzyj sygnatury z mojego opisu i dodaj komentarz `// NOTE: Assumes API from task description, file not found`.
>
> Stworz katalog jesli nie istnieje: `mkdir -p MySTT/MySTT/App`
>
> Po wykonaniu uruchom weryfikacje. Jesli jakiekolwiek kryterium FAIL -> napraw -> ponowna weryfikacja -> powtarzaj max 5 razy -> jesli nadal FAIL -> zglos problem.

#### Weryfikacja (automatyczna po wykonaniu):

```bash
cd /Users/igor.3.wolak.external/Downloads/MySTT

echo "=== WERYFIKACJA SESJI N ==="

echo "--- Test 1: Plik AppState.swift istnieje ---"
test -f MySTT/MySTT/App/AppState.swift && echo "PASS" || echo "FAIL"

echo "--- Test 2: Plik AppDelegate.swift istnieje ---"
test -f MySTT/MySTT/App/AppDelegate.swift && echo "PASS" || echo "FAIL"

echo "--- Test 3: Plik MySTTApp.swift istnieje ---"
test -f MySTT/MySTT/App/MySTTApp.swift && echo "PASS" || echo "FAIL"

echo "--- Test 4: AppState jest @MainActor ObservableObject ---"
grep -q "@MainActor" MySTT/MySTT/App/AppState.swift && \
grep -q "ObservableObject" MySTT/MySTT/App/AppState.swift && echo "PASS" || echo "FAIL"

echo "--- Test 5: AppState ma Published properties ---"
grep -q "@Published var isRecording" MySTT/MySTT/App/AppState.swift && \
grep -q "@Published var isProcessing" MySTT/MySTT/App/AppState.swift && \
grep -q "@Published var lastTranscription" MySTT/MySTT/App/AppState.swift && \
grep -q "@Published var statusMessage" MySTT/MySTT/App/AppState.swift && echo "PASS" || echo "FAIL"

echo "--- Test 6: AppState ma detectedLanguage ---"
grep -q "detectedLanguage" MySTT/MySTT/App/AppState.swift && echo "PASS" || echo "FAIL"

echo "--- Test 7: AppState inicjalizuje AudioCaptureEngine ---"
grep -q "AudioCaptureEngine" MySTT/MySTT/App/AppState.swift && echo "PASS" || echo "FAIL"

echo "--- Test 8: AppState inicjalizuje STT engine (WhisperKit/Deepgram) ---"
grep -q "WhisperKitEngine\|WhisperKit" MySTT/MySTT/App/AppState.swift && \
grep -q "DeepgramEngine\|Deepgram" MySTT/MySTT/App/AppState.swift && echo "PASS" || echo "FAIL"

echo "--- Test 9: AppState inicjalizuje LLM providers ---"
grep -q "OllamaProvider\|Ollama" MySTT/MySTT/App/AppState.swift && \
grep -q "GroqProvider\|Groq" MySTT/MySTT/App/AppState.swift && echo "PASS" || echo "FAIL"

echo "--- Test 10: AppState inicjalizuje PostProcessor ---"
grep -q "PostProcessor" MySTT/MySTT/App/AppState.swift && echo "PASS" || echo "FAIL"

echo "--- Test 11: AppState ma startRecording() ---"
grep -q "func startRecording" MySTT/MySTT/App/AppState.swift && echo "PASS" || echo "FAIL"

echo "--- Test 12: AppState ma stopRecordingAndProcess() ---"
grep -q "func stopRecordingAndProcess" MySTT/MySTT/App/AppState.swift && echo "PASS" || echo "FAIL"

echo "--- Test 13: AppState pipeline: audio -> STT -> PostProcess -> paste ---"
grep -q "startCapture\|stopCapture\|audioEngine" MySTT/MySTT/App/AppState.swift && \
grep -q "transcribe" MySTT/MySTT/App/AppState.swift && \
grep -q "process\|postProcessor\|PostProcessor" MySTT/MySTT/App/AppState.swift && \
grep -q "paste\|autoPaster\|AutoPaster" MySTT/MySTT/App/AppState.swift && echo "PASS" || echo "FAIL"

echo "--- Test 14: AppState uzywa SoundPlayer ---"
grep -q "SoundPlayer" MySTT/MySTT/App/AppState.swift && echo "PASS" || echo "FAIL"

echo "--- Test 15: AppState ma error handling ---"
grep -q "catch\|AppError\|errorMessage" MySTT/MySTT/App/AppState.swift && echo "PASS" || echo "FAIL"

echo "--- Test 16: AppState obsluguje HotkeyManager ---"
grep -q "HotkeyManager\|hotkeyManager\|hotkey" MySTT/MySTT/App/AppState.swift && echo "PASS" || echo "FAIL"

echo "--- Test 17: AppState obserwuje zmiany settings ---"
grep -q "observeSettings\|didChangeNotification\|Combine\|cancellables\|sink" MySTT/MySTT/App/AppState.swift && echo "PASS" || echo "FAIL"

echo "--- Test 18: AppDelegate obsluguje applicationDidFinishLaunching ---"
grep -q "applicationDidFinishLaunching" MySTT/MySTT/App/AppDelegate.swift && echo "PASS" || echo "FAIL"

echo "--- Test 19: AppDelegate sprawdza permissions ---"
grep -q "PermissionChecker\|permission\|Permission" MySTT/MySTT/App/AppDelegate.swift && echo "PASS" || echo "FAIL"

echo "--- Test 20: AppDelegate sprawdza hasCompletedOnboarding ---"
grep -q "hasCompletedOnboarding" MySTT/MySTT/App/AppDelegate.swift && echo "PASS" || echo "FAIL"

echo "--- Test 21: AppDelegate obsluguje applicationWillTerminate ---"
grep -q "applicationWillTerminate" MySTT/MySTT/App/AppDelegate.swift && echo "PASS" || echo "FAIL"

echo "--- Test 22: MySTTApp ma MenuBarExtra ---"
grep -q "MenuBarExtra" MySTT/MySTT/App/MySTTApp.swift && echo "PASS" || echo "FAIL"

echo "--- Test 23: MySTTApp ma dynamiczna ikone mic ---"
grep -q "mic.fill\|mic" MySTT/MySTT/App/MySTTApp.swift && \
grep -q "isRecording" MySTT/MySTT/App/MySTTApp.swift && echo "PASS" || echo "FAIL"

echo "--- Test 24: MySTTApp ma NSApplicationDelegateAdaptor ---"
grep -q "NSApplicationDelegateAdaptor\|AppDelegate" MySTT/MySTT/App/MySTTApp.swift && echo "PASS" || echo "FAIL"

echo "--- Test 25: MySTTApp ma Settings scene ---"
grep -q "Settings" MySTT/MySTT/App/MySTTApp.swift && echo "PASS" || echo "FAIL"

echo "--- Test 26: MySTTApp przekazuje environmentObject ---"
grep -q "environmentObject" MySTT/MySTT/App/MySTTApp.swift && echo "PASS" || echo "FAIL"

echo "--- Test 27: MySTTApp ma @StateObject appState ---"
grep -q "@StateObject.*appState\|@StateObject.*AppState" MySTT/MySTT/App/MySTTApp.swift && echo "PASS" || echo "FAIL"

echo "--- Test 28: AppState lazy model loading ---"
grep -q "lazy\|setupSTTEngine\|setupLLMProvider" MySTT/MySTT/App/AppState.swift && echo "PASS" || echo "FAIL"

echo "=== KONIEC WERYFIKACJI SESJI N ==="
```

#### Kryteria DONE:
- [ ] Plik `AppState.swift` istnieje w `MySTT/MySTT/App/`
- [ ] Plik `AppDelegate.swift` istnieje w `MySTT/MySTT/App/`
- [ ] Plik `MySTTApp.swift` zaktualizowany w `MySTT/MySTT/App/`
- [ ] `AppState` jest `@MainActor ObservableObject`
- [ ] Published properties: `isRecording`, `isProcessing`, `lastTranscription`, `detectedLanguage`, `statusMessage`
- [ ] `AppState.init()` inicjalizuje wszystkie komponenty: AudioCaptureEngine, STT, LLM, PostProcessor, AutoPaster, HotkeyManager
- [ ] `setupSTTEngine()` tworzy WhisperKitEngine lub DeepgramEngine na podstawie AppSettings
- [ ] `setupLLMProvider()` tworzy OllamaProvider, GroqProvider, lub OpenAIProvider
- [ ] `setupPostProcessor()` laczy DictionaryEngine + PunctuationCorrector + LLMProvider
- [ ] `setupHotkey()` konfiguruje HotkeyManager z onKeyDown=startRecording, onKeyUp=stopRecordingAndProcess
- [ ] `startRecording()` - start audio, update state, play sound
- [ ] `stopRecordingAndProcess()` - pipeline: stop audio -> STT -> PostProcess -> AutoPaste
- [ ] Error handling na kazdym etapie pipeline z user-facing statusMessage
- [ ] SoundPlayer integracja (start, stop, success, error)
- [ ] Settings observation - przebudowa providerow przy zmianie ustawien
- [ ] Lazy model loading (nie laduj modeli STT w init)
- [ ] `AppDelegate.applicationDidFinishLaunching` sprawdza permissions i onboarding
- [ ] `AppDelegate.applicationWillTerminate` cleanup
- [ ] `MySTTApp` ma `MenuBarExtra` z dynamiczna ikona (mic.fill/mic)
- [ ] `MySTTApp` ma `@NSApplicationDelegateAdaptor(AppDelegate.self)`
- [ ] `MySTTApp` ma `@StateObject appState` przekazywany jako environmentObject
- [ ] `MySTTApp` ma `Settings` scene z `SettingsView`
- [ ] Wszystkie sygnatury dopasowane do faktycznych plikow projektu



## RUNDA 5 (Sesja M) - Settings UI

---

### Sesja M: Settings View (5 tabow)
**Runda**: 5 | **Typ**: PARALLEL | **Faza**: 4
**Agent**: `software-architect`
**Zaleznosci**: Sesja A (0.1 Xcode Init), Sesja B (1.1 Models)
**Pliki wyjsciowe**: 6 plikow UI w `MySTT/MySTT/UI/`

#### Prompt dla sesji Claude Code:

```
Jestes doswiadczonym Swift/SwiftUI developerem. Pracujesz nad projektem MySTT w katalogu /Users/igor.3.wolak.external/Downloads/MySTT.

ZADANIE: Stworz kompletny panel ustawien (Settings) z 5 tabami dla aplikacji MySTT.

KONTEKST:
MySTT to aplikacja menu bar na macOS do speech-to-text. Ustawienia pozwalaja konfigurowasc:
- Ogolne (launch at login, dzwieki, powiadomienia)
- STT provider (WhisperKit local / Deepgram cloud)
- LLM provider (Local MLX / Local Ollama / Grok / Groq / OpenAI) z API keys
- Slownik (edytor terminow, rules)
- Hotkey (wybor klawisza)

KROK 1: Przeczytaj istniejace pliki:
- MySTT/MySTT/Models/AppSettings.swift (struktura ustawien)
- MySTT/MySTT/Models/LLMProvider.swift (enum providerow)
- MySTT/MySTT/Models/STTProvider.swift (enum STT providerow)
- MySTT/MySTT/Utilities/KeychainManager.swift (przechowywanie API keys)

KROK 2: Stworz nastepujace pliki:

1. MySTT/MySTT/UI/SettingsView.swift:
```swift
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        TabView {
            GeneralSettingsTab()
                .tabItem { Label("General", systemImage: "gear") }
            STTSettingsTab()
                .tabItem { Label("Speech", systemImage: "mic") }
            LLMSettingsTab()
                .tabItem { Label("LLM", systemImage: "brain") }
            DictionarySettingsTab()
                .tabItem { Label("Dictionary", systemImage: "book") }
            HotkeySettingsTab()
                .tabItem { Label("Hotkey", systemImage: "keyboard") }
        }
        .frame(width: 520, height: 420)
        .padding()
    }
}
```

2. MySTT/MySTT/UI/GeneralSettingsTab.swift:
- Toggle: Launch at Login (uzyj SMAppService do rejestracji)
- Toggle: Play Sounds (bind do AppSettings.playSound)
- Toggle: Show Notifications (bind do AppSettings.showNotification)
- Toggle: Auto-Paste (bind do AppSettings.autoPaste)
- Sekcja "About" z wersja aplikacji

3. MySTT/MySTT/UI/STTSettingsTab.swift:
- Picker: STT Provider (WhisperKit Local / Deepgram Cloud)
- Gdy WhisperKit:
  - Picker: Model (Auto / small / large-v3-turbo)
  - Label z info o rozmiarze modelu i RAM
  - Przycisk "Download Model" z progress
- Gdy Deepgram:
  - SecureField: Deepgram API Key
  - Przycisk "Test Connection"

4. MySTT/MySTT/UI/LLMSettingsTab.swift:
- Picker: LLM Provider (5 opcji z enum LLMProvider)
- Dynamiczne pola zalezne od wybranego providera:
  - localMLX: TextField model path (default "mlx-community/Qwen2.5-3B-Instruct-4bit"), TextField Python path
  - localOllama: TextField model name (default "qwen2.5:3b"), TextField Ollama URL (default "http://localhost:11434")
  - grok: SecureField API Key (przechowywany w Keychain via KeychainManager)
  - groq: SecureField API Key
  - openai: SecureField API Key
- Toggle: Enable LLM Correction (bind do AppSettings.enableLLMCorrection)
- Toggle: Enable Punctuation Model (bind do AppSettings.enablePunctuationModel)
- Przycisk "Test Connection" z wynikiem (success/fail + latency w ms)
- WAZNE: API keys MUSZA uzywac SecureField, NIE TextField

5. MySTT/MySTT/UI/DictionarySettingsTab.swift:
- List/Table z terminami slownikowymi (key → value)
- Przycisk "+" do dodawania terminu (alert z dwoma polami)
- Przycisk "-" do usuwania zaznaczonego terminu
- Sekcja "Polish Terms" z osobna lista
- Sekcja "Abbreviations" z osobna lista
- Przycisk "Import JSON..." z file picker
- Przycisk "Export JSON..." z save dialog
- Przycisk "Reset to Defaults"
- Bind do DictionaryEngine (load/save)

6. MySTT/MySTT/UI/HotkeySettingsTab.swift:
- Import KeyboardShortcuts
- KeyboardShortcuts.Recorder do nagrywania skrotu
- Label z aktualnie ustawionym hotkeyem
- Przycisk "Reset to Default" (Right Option)
- Informacja tekstowa: "Hold the hotkey to start recording, release to stop and process."
- Definicja KeyboardShortcuts.Name.toggleRecording

KROK 3: Weryfikacja - upewnij sie ze:
- Wszystkie pliki kompiluja sie bez bledow
- Jest dokladnie 5 tabow w SettingsView
- LLMSettingsTab dynamicznie zmienia pola
- API keys uzywaja SecureField
- KeyboardShortcuts.Recorder jest uzyte w HotkeySettingsTab
```

#### Weryfikacja (automatyczna po wykonaniu):
```bash
cd /Users/igor.3.wolak.external/Downloads/MySTT

echo "=== WERYFIKACJA SESJI M: Settings View ==="

echo "--- Test 1: SettingsView.swift istnieje ---"
test -f MySTT/MySTT/UI/SettingsView.swift && echo "PASS" || echo "FAIL"

echo "--- Test 2: GeneralSettingsTab.swift istnieje ---"
test -f MySTT/MySTT/UI/GeneralSettingsTab.swift && echo "PASS" || echo "FAIL"

echo "--- Test 3: STTSettingsTab.swift istnieje ---"
test -f MySTT/MySTT/UI/STTSettingsTab.swift && echo "PASS" || echo "FAIL"

echo "--- Test 4: LLMSettingsTab.swift istnieje ---"
test -f MySTT/MySTT/UI/LLMSettingsTab.swift && echo "PASS" || echo "FAIL"

echo "--- Test 5: DictionarySettingsTab.swift istnieje ---"
test -f MySTT/MySTT/UI/DictionarySettingsTab.swift && echo "PASS" || echo "FAIL"

echo "--- Test 6: HotkeySettingsTab.swift istnieje ---"
test -f MySTT/MySTT/UI/HotkeySettingsTab.swift && echo "PASS" || echo "FAIL"

echo "--- Test 7: 5 tabow w SettingsView ---"
count=$(grep -c "tabItem" MySTT/MySTT/UI/SettingsView.swift 2>/dev/null)
[ "$count" -eq 5 ] && echo "PASS (5 tabs)" || echo "FAIL (found $count tabs)"

echo "--- Test 8: SecureField w LLMSettingsTab ---"
grep -q "SecureField" MySTT/MySTT/UI/LLMSettingsTab.swift && echo "PASS" || echo "FAIL"

echo "--- Test 9: KeyboardShortcuts w HotkeySettingsTab ---"
grep -q "KeyboardShortcuts" MySTT/MySTT/UI/HotkeySettingsTab.swift && echo "PASS" || echo "FAIL"

echo "--- Test 10: LLMProvider picker ---"
grep -q "LLMProvider" MySTT/MySTT/UI/LLMSettingsTab.swift && echo "PASS" || echo "FAIL"

echo "--- Test 11: Kompilacja ---"
xcodebuild -scheme MySTT -configuration Debug build 2>&1 | tail -3

echo "=== KONIEC WERYFIKACJI ==="
```

#### Kryteria DONE:
- [ ] 6 plikow UI utworzonych
- [ ] SettingsView ma dokladnie 5 tabow
- [ ] LLMSettingsTab dynamicznie zmienia pola na podstawie providera
- [ ] API keys uzywaja SecureField (nie TextField)
- [ ] HotkeySettingsTab uzywa KeyboardShortcuts.Recorder
- [ ] DictionarySettingsTab ma add/remove/import/export
- [ ] Kompilacja projektu bez bledow

Po wykonaniu uruchom weryfikacje. Jesli jakiekolwiek kryterium FAIL -> napraw -> ponowna weryfikacja -> powtarzaj max 5 razy -> jesli nadal FAIL -> zglos problem.



# RUNDY 7-9: Python + Testy + Build

## RUNDA 7 - Sesja O: Python Scripts + Models (Zadanie 6.1)

**Typ**: SEQUENTIAL
**Zaleznosci**: Sesja G (2.2 LLM Providers), Sesja I (3.1 Pipeline)
**Czas**: ~20 min

### Prompt dla Claude Code

```
Jestes doswiadczonym Python developerem pracujacym nad projektem MySTT - macOS Speech-to-Text Application.

WORKING DIRECTORY: /Users/igor.3.wolak.external/Downloads/MySTT

KONTEKST PROJEKTU:
Przeczytaj pliki zrodlowe dla kontekstu:
- /Users/igor.3.wolak.external/Downloads/MySTT/architecture.md (sekcje 6.1, 6.2, 10.1)
- /Users/igor.3.wolak.external/Downloads/MySTT/implementation-plan.md (Zadanie 6.1)

ZADANIE: Utworz skrypty Python dla MLX inference i punctuation correction + script do pobierania modeli + testy.

ZALEZNOSCI DO SPRAWDZENIA:
Przed rozpoczeciem sprawdz czy istnieja pliki z poprzednich sesji:
- /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/LLM/MLXProvider.swift (z Sesji G - LLM Providers)
- /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/PostProcessing/PunctuationCorrector.swift (z Sesji I - Pipeline)
Jesli ktorys brakuje, kontynuuj mimo to - skrypty Python sa niezalezne, ale odnotuj brak w raporcie.

PLIKI DO UTWORZENIA (6 plikow):

=== PLIK 1: Scripts/mlx_infer.py ===
Skrypt CLI do inference MLX-LM.

Wymagania:
- argparse z argumentami: --model (wymagany), --prompt (wymagany), --max-tokens (domyslnie 512), --temp (domyslnie 0.1)
- Uzywa mlx_lm.load() do zaladowania modelu
- Uzywa mlx_lm.generate() do generowania odpowiedzi
- Wypisuje TYLKO tekst wyniku na stdout (bez logow, bez debugow, bez prefiksow)
- Error handling:
  - Brak pakietu mlx-lm: wypisz na stderr "Error: mlx-lm package not installed. Run: pip3 install mlx-lm" i exit(1)
  - Model nie znaleziony: wypisz na stderr "Error: Model not found: <model_path>" i exit(1)
  - Ogolne bledy: wypisz na stderr i exit(1)
- Shebang: #!/usr/bin/env python3
- Encoding: utf-8

Wzorzec kodu:
```python
#!/usr/bin/env python3
"""MLX-LM inference helper for MySTT."""
import argparse
import sys

def main():
    parser = argparse.ArgumentParser(description="MLX-LM inference for text correction")
    parser.add_argument("--model", required=True, help="Model path or HuggingFace ID")
    parser.add_argument("--prompt", required=True, help="Input prompt text")
    parser.add_argument("--max-tokens", type=int, default=512, help="Maximum tokens to generate")
    parser.add_argument("--temp", type=float, default=0.1, help="Temperature for generation")
    args = parser.parse_args()

    try:
        from mlx_lm import load, generate
    except ImportError:
        print("Error: mlx-lm package not installed. Run: pip3 install mlx-lm", file=sys.stderr)
        sys.exit(1)

    try:
        model, tokenizer = load(args.model)
    except Exception as e:
        print(f"Error: Model not found: {args.model} ({e})", file=sys.stderr)
        sys.exit(1)

    try:
        response = generate(
            model,
            tokenizer,
            prompt=args.prompt,
            max_tokens=args.max_tokens,
            temp=args.temp
        )
        print(response)
    except Exception as e:
        print(f"Error: Generation failed: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
```

=== PLIK 2: Scripts/punctuation_correct.py ===
Skrypt do korekcji interpunkcji z uzyciem deepmultilingualpunctuation.

Wymagania:
- Przyjmuje jeden argument: "<lang> text" gdzie <lang> to <pl> lub <en>
- Stripuje prefix <pl>/<en> z tekstu
- Uzywa PunctuationModel z deepmultilingualpunctuation do restore_punctuation()
- Wypisuje poprawiony tekst na stdout
- Fallback: jesli pakiet deepmultilingualpunctuation niedostepny, uzyj prostego regex:
  - Capitalize first letter
  - Add period at end if missing
  - Wypisz na stderr ostrzezenie "Warning: deepmultilingualpunctuation not available, using simple fallback"
- Shebang: #!/usr/bin/env python3

Wzorzec kodu:
```python
#!/usr/bin/env python3
"""Punctuation correction helper for MySTT."""
import re
import sys

def simple_fallback(text):
    """Simple regex-based punctuation when model unavailable."""
    text = text.strip()
    if text:
        text = text[0].upper() + text[1:]
        if text[-1] not in ".!?":
            text += "."
    return text

def main():
    if len(sys.argv) < 2:
        print("Usage: punctuation_correct.py '<lang> text to correct'", file=sys.stderr)
        sys.exit(1)

    raw_input = " ".join(sys.argv[1:])

    # Strip language prefix
    lang_match = re.match(r"^<(pl|en)>\s*", raw_input)
    if lang_match:
        text = raw_input[lang_match.end():]
    else:
        text = raw_input

    try:
        from deepmultilingualpunctuation import PunctuationModel
        model = PunctuationModel()
        result = model.restore_punctuation(text)
        print(result)
    except ImportError:
        print("Warning: deepmultilingualpunctuation not available, using simple fallback", file=sys.stderr)
        print(simple_fallback(text))
    except Exception as e:
        print(f"Warning: Punctuation model error ({e}), using fallback", file=sys.stderr)
        print(simple_fallback(text))

if __name__ == "__main__":
    main()
```

=== PLIK 3: Scripts/setup_models.sh ===
Script do instalacji zaleznosci i pobierania modeli.

Wymagania:
- Sprawdza czy python3 i pip3 sa dostepne (jesli nie - exit z instrukcja)
- Instaluje requirements.txt: pip3 install -r Scripts/requirements.txt
- Pobiera model MLX: python3 -c "from mlx_lm import load; load('mlx-community/Qwen2.5-3B-Instruct-4bit')"
- Pobiera model punctuation: python3 -c "from deepmultilingualpunctuation import PunctuationModel; PunctuationModel()"
- Opcjonalnie instaluje ollama (pytanie y/n) i pulluje qwen2.5:3b
- Na koncu wypisuje podsumowanie: co zainstalowano, sciezki do modeli, rozmiary
- Shebang: #!/bin/bash, set -e
- Chmod +x

Wzorzec kodu:
```bash
#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "======================================"
echo "  MySTT - Model Setup Script"
echo "======================================"
echo ""

# Check Python3
if ! command -v python3 &> /dev/null; then
    echo "ERROR: python3 not found. Install via: brew install python3"
    exit 1
fi
echo "[OK] python3 found: $(python3 --version)"

# Check pip3
if ! command -v pip3 &> /dev/null; then
    echo "ERROR: pip3 not found. Install via: brew install python3"
    exit 1
fi
echo "[OK] pip3 found: $(pip3 --version)"

# Install Python dependencies
echo ""
echo "--- Installing Python dependencies ---"
pip3 install -r "$SCRIPT_DIR/requirements.txt"
echo "[OK] Python dependencies installed"

# Download MLX model
echo ""
echo "--- Downloading MLX model (Qwen2.5-3B-Instruct-4bit) ---"
echo "    This may take several minutes on first run..."
python3 -c "from mlx_lm import load; load('mlx-community/Qwen2.5-3B-Instruct-4bit'); print('[OK] MLX model downloaded')"

# Download punctuation model
echo ""
echo "--- Downloading punctuation model ---"
python3 -c "from deepmultilingualpunctuation import PunctuationModel; PunctuationModel(); print('[OK] Punctuation model downloaded')"

# Optional: Ollama
echo ""
read -p "Install Ollama and pull qwen2.5:3b? (y/n): " install_ollama
if [ "$install_ollama" = "y" ] || [ "$install_ollama" = "Y" ]; then
    if ! command -v ollama &> /dev/null; then
        echo "Installing Ollama via brew..."
        brew install ollama
    fi
    echo "Pulling qwen2.5:3b model..."
    ollama pull qwen2.5:3b
    echo "[OK] Ollama + qwen2.5:3b ready"
else
    echo "[SKIP] Ollama installation skipped"
fi

# Summary
echo ""
echo "======================================"
echo "  Setup Summary"
echo "======================================"
echo ""
echo "Python packages:"
pip3 list 2>/dev/null | grep -E "mlx-lm|deepmultilingualpunctuation|transformers" || true
echo ""
echo "MLX model cache: ~/.cache/huggingface/hub/"
if [ -d ~/.cache/huggingface/hub ]; then
    du -sh ~/.cache/huggingface/hub/ 2>/dev/null || true
fi
echo ""
echo "Setup complete! You can now use MySTT with local models."
```

=== PLIK 4: Scripts/requirements.txt ===
Dokladna zawartosc:
```
mlx-lm>=0.19.0
deepmultilingualpunctuation>=1.0
transformers>=4.40.0
```

=== PLIK 5: Scripts/test_mlx.py ===
Test script dla mlx_infer.py.

Wymagania:
- Testuje ze mlx_infer.py parsuje argumenty poprawnie
- Testuje error handling (brak --model, brak --prompt)
- Jesli mlx-lm jest zainstalowany: testuje prawdziwe wywolanie z malym promptem
- Jesli mlx-lm NIE jest zainstalowany: mockuje import i testuje logike
- Uzywa unittest
- Uruchamianie: python3 Scripts/test_mlx.py

Wzorzec kodu:
```python
#!/usr/bin/env python3
"""Tests for mlx_infer.py"""
import subprocess
import sys
import unittest
import os

SCRIPT_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "mlx_infer.py")

class TestMLXInfer(unittest.TestCase):

    def test_missing_model_argument(self):
        """Should fail when --model is missing."""
        result = subprocess.run(
            [sys.executable, SCRIPT_PATH, "--prompt", "test"],
            capture_output=True, text=True
        )
        self.assertNotEqual(result.returncode, 0)

    def test_missing_prompt_argument(self):
        """Should fail when --prompt is missing."""
        result = subprocess.run(
            [sys.executable, SCRIPT_PATH, "--model", "test-model"],
            capture_output=True, text=True
        )
        self.assertNotEqual(result.returncode, 0)

    def test_help_flag(self):
        """Should print help text."""
        result = subprocess.run(
            [sys.executable, SCRIPT_PATH, "--help"],
            capture_output=True, text=True
        )
        self.assertEqual(result.returncode, 0)
        self.assertIn("MLX-LM inference", result.stdout)

    def test_syntax_valid(self):
        """Script should have valid Python syntax."""
        result = subprocess.run(
            [sys.executable, "-m", "py_compile", SCRIPT_PATH],
            capture_output=True, text=True
        )
        self.assertEqual(result.returncode, 0, f"Syntax error: {result.stderr}")

    def test_nonexistent_model_returns_error(self):
        """Should exit with error for non-existent model."""
        result = subprocess.run(
            [sys.executable, SCRIPT_PATH,
             "--model", "nonexistent/model-that-does-not-exist-12345",
             "--prompt", "test"],
            capture_output=True, text=True,
            timeout=30
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Error", result.stderr)

if __name__ == "__main__":
    unittest.main()
```

=== PLIK 6: Scripts/test_punctuation.py ===
Test script dla punctuation_correct.py.

Wymagania:
- Testuje z prefiksem <en> i <pl>
- Testuje fallback (gdy brak deepmultilingualpunctuation)
- Testuje znane wejscia/wyjscia
- Uzywa unittest
- Uruchamianie: python3 Scripts/test_punctuation.py

Wzorzec kodu:
```python
#!/usr/bin/env python3
"""Tests for punctuation_correct.py"""
import subprocess
import sys
import unittest
import os

SCRIPT_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "punctuation_correct.py")

class TestPunctuationCorrect(unittest.TestCase):

    def test_syntax_valid(self):
        """Script should have valid Python syntax."""
        result = subprocess.run(
            [sys.executable, "-m", "py_compile", SCRIPT_PATH],
            capture_output=True, text=True
        )
        self.assertEqual(result.returncode, 0, f"Syntax error: {result.stderr}")

    def test_no_arguments_shows_usage(self):
        """Should show usage when no arguments provided."""
        result = subprocess.run(
            [sys.executable, SCRIPT_PATH],
            capture_output=True, text=True
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Usage", result.stderr)

    def test_english_input_produces_output(self):
        """Should produce non-empty output for English input."""
        result = subprocess.run(
            [sys.executable, SCRIPT_PATH, "<en> hello world how are you today"],
            capture_output=True, text=True,
            timeout=60
        )
        self.assertEqual(result.returncode, 0)
        output = result.stdout.strip()
        self.assertTrue(len(output) > 0, "Output should not be empty")
        self.assertTrue(output[0].isupper(), f"Output should start with capital: '{output}'")

    def test_polish_input_produces_output(self):
        """Should produce non-empty output for Polish input."""
        result = subprocess.run(
            [sys.executable, SCRIPT_PATH, "<pl> witaj swiecie jak sie masz"],
            capture_output=True, text=True,
            timeout=60
        )
        self.assertEqual(result.returncode, 0)
        output = result.stdout.strip()
        self.assertTrue(len(output) > 0, "Output should not be empty")

    def test_output_ends_with_punctuation(self):
        """Output should end with punctuation mark (from model or fallback)."""
        result = subprocess.run(
            [sys.executable, SCRIPT_PATH, "<en> this is a test sentence"],
            capture_output=True, text=True,
            timeout=60
        )
        self.assertEqual(result.returncode, 0)
        output = result.stdout.strip()
        self.assertTrue(
            output[-1] in ".!?",
            f"Output should end with punctuation: '{output}'"
        )

    def test_no_language_prefix(self):
        """Should handle input without language prefix."""
        result = subprocess.run(
            [sys.executable, SCRIPT_PATH, "hello world test"],
            capture_output=True, text=True,
            timeout=60
        )
        self.assertEqual(result.returncode, 0)
        output = result.stdout.strip()
        self.assertTrue(len(output) > 0)

if __name__ == "__main__":
    unittest.main()
```

WERYFIKACJA - uruchom te komendy po zakonczeniu:

```bash
# 1. Sprawdz ze wszystkie pliki istnieja
echo "=== Sprawdzanie plikow ==="
test -f /Users/igor.3.wolak.external/Downloads/MySTT/Scripts/mlx_infer.py && echo "PASS: mlx_infer.py" || echo "FAIL: mlx_infer.py"
test -f /Users/igor.3.wolak.external/Downloads/MySTT/Scripts/punctuation_correct.py && echo "PASS: punctuation_correct.py" || echo "FAIL: punctuation_correct.py"
test -f /Users/igor.3.wolak.external/Downloads/MySTT/Scripts/setup_models.sh && echo "PASS: setup_models.sh" || echo "FAIL: setup_models.sh"
test -f /Users/igor.3.wolak.external/Downloads/MySTT/Scripts/requirements.txt && echo "PASS: requirements.txt" || echo "FAIL: requirements.txt"
test -f /Users/igor.3.wolak.external/Downloads/MySTT/Scripts/test_mlx.py && echo "PASS: test_mlx.py" || echo "FAIL: test_mlx.py"
test -f /Users/igor.3.wolak.external/Downloads/MySTT/Scripts/test_punctuation.py && echo "PASS: test_punctuation.py" || echo "FAIL: test_punctuation.py"

# 2. Sprawdz skladnie Python
echo ""
echo "=== Sprawdzanie skladni Python ==="
python3 -m py_compile /Users/igor.3.wolak.external/Downloads/MySTT/Scripts/mlx_infer.py && echo "PASS: mlx_infer.py syntax" || echo "FAIL: mlx_infer.py syntax"
python3 -m py_compile /Users/igor.3.wolak.external/Downloads/MySTT/Scripts/punctuation_correct.py && echo "PASS: punctuation_correct.py syntax" || echo "FAIL: punctuation_correct.py syntax"
python3 -m py_compile /Users/igor.3.wolak.external/Downloads/MySTT/Scripts/test_mlx.py && echo "PASS: test_mlx.py syntax" || echo "FAIL: test_mlx.py syntax"
python3 -m py_compile /Users/igor.3.wolak.external/Downloads/MySTT/Scripts/test_punctuation.py && echo "PASS: test_punctuation.py syntax" || echo "FAIL: test_punctuation.py syntax"

# 3. Sprawdz bash script
echo ""
echo "=== Sprawdzanie bash script ==="
bash -n /Users/igor.3.wolak.external/Downloads/MySTT/Scripts/setup_models.sh && echo "PASS: setup_models.sh syntax" || echo "FAIL: setup_models.sh syntax"

# 4. Sprawdz chmod +x na setup_models.sh
echo ""
echo "=== Sprawdzanie uprawnien ==="
test -x /Users/igor.3.wolak.external/Downloads/MySTT/Scripts/setup_models.sh && echo "PASS: setup_models.sh executable" || echo "FAIL: setup_models.sh not executable"

# 5. Sprawdz requirements.txt
echo ""
echo "=== Sprawdzanie requirements.txt ==="
grep -q "mlx-lm" /Users/igor.3.wolak.external/Downloads/MySTT/Scripts/requirements.txt && echo "PASS: mlx-lm in requirements" || echo "FAIL: mlx-lm missing"
grep -q "deepmultilingualpunctuation" /Users/igor.3.wolak.external/Downloads/MySTT/Scripts/requirements.txt && echo "PASS: deepmultilingualpunctuation in requirements" || echo "FAIL: deepmultilingualpunctuation missing"
grep -q "transformers" /Users/igor.3.wolak.external/Downloads/MySTT/Scripts/requirements.txt && echo "PASS: transformers in requirements" || echo "FAIL: transformers missing"

# 6. Uruchom testy Python (test_mlx i test_punctuation)
echo ""
echo "=== Uruchamianie testow ==="
cd /Users/igor.3.wolak.external/Downloads/MySTT
python3 -m pytest Scripts/test_mlx.py -v 2>/dev/null || python3 Scripts/test_mlx.py -v
python3 -m pytest Scripts/test_punctuation.py -v 2>/dev/null || python3 Scripts/test_punctuation.py -v

# 7. Sprawdz argparse w mlx_infer.py
echo ""
echo "=== Sprawdzanie argparse ==="
python3 /Users/igor.3.wolak.external/Downloads/MySTT/Scripts/mlx_infer.py --help | head -3
# Oczekiwany: "usage: mlx_infer.py" z opisem argumentow
```

Oczekiwane wyniki:
- Wszystkie 6 plikow istnieja: PASS
- Wszystkie 4 pliki Python maja poprawna skladnie: PASS
- setup_models.sh ma poprawna skladnie bash: PASS
- setup_models.sh jest executable: PASS
- requirements.txt zawiera 3 pakiety: PASS
- test_mlx.py: minimum 4 testy PASS (5 z nonexistent model moze byc wolny)
- test_punctuation.py: minimum 5 testow PASS

Po wykonaniu uruchom weryfikacje. Jesli jakiekolwiek kryterium FAIL -> napraw -> ponowna weryfikacja -> powtarzaj max 5 razy -> jesli nadal FAIL -> zglos problem.

KRYTERIA DONE:
- [ ] Wszystkie 6 plikow utworzone w /Users/igor.3.wolak.external/Downloads/MySTT/Scripts/
- [ ] mlx_infer.py: poprawna skladnia, argparse z 4 argumentami, error handling
- [ ] punctuation_correct.py: poprawna skladnia, obsluga <pl>/<en>, fallback regex
- [ ] setup_models.sh: poprawna skladnia bash, chmod +x, sprawdza python3/pip3
- [ ] requirements.txt: zawiera mlx-lm, deepmultilingualpunctuation, transformers
- [ ] test_mlx.py: minimum 4 testy PASS
- [ ] test_punctuation.py: minimum 5 testow PASS

RAPORT KONCOWY: Po zakonczeniu podaj:
- Status: DONE/FAIL
- Lista utworzonych plikow (pelne sciezki)
- Wyniki testow (ile passed/failed)
- Problemy napotkane (jesli jakies)
```

---

## RUNDA 8 - Sesja P: Unit Tests (Zadanie 7.1)

**Typ**: SEQUENTIAL
**Zaleznosci**: Fazy 1-5 (Sesje B-N)
**Czas**: ~30 min

### Prompt dla Claude Code

```
Jestes doswiadczonym test engineerem pracujacym nad projektem MySTT - macOS Speech-to-Text Application.

WORKING DIRECTORY: /Users/igor.3.wolak.external/Downloads/MySTT

KONTEKST PROJEKTU:
Przeczytaj pliki zrodlowe dla kontekstu:
- /Users/igor.3.wolak.external/Downloads/MySTT/architecture.md
- /Users/igor.3.wolak.external/Downloads/MySTT/implementation-plan.md (Zadanie 7.1)

ZADANIE: Utworz testy jednostkowe dla kluczowych komponentow MySTT. Minimum 15 test cases, wszystkie musza przechodzic.

ZALEZNOSCI DO SPRAWDZENIA:
Przed rozpoczeciem sprawdz i przeczytaj nastepujace pliki z poprzednich sesji (potrzebujesz znac dokladne sygnatury metod, nazwy typow i structur):
- /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/Models/Language.swift
- /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/Models/AppSettings.swift
- /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/Models/LLMProvider.swift
- /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/PostProcessing/DictionaryEngine.swift
- /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/PostProcessing/PostProcessor.swift
- /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/LLM/LLMPromptBuilder.swift
- /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/LLM/OpenAICompatibleClient.swift
- /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/LLM/LLMProviderProtocol.swift
- /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/PostProcessing/PostProcessorProtocol.swift
- /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/Models/Errors.swift
- /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/Resources/default_dictionary.json

WAZNE: Przeczytaj WSZYSTKIE powyzsze pliki przed pisaniem testow! Testy musza odpowiadac faktycznym sygnaturom metod i nazw typow. Nie zakladaj nazw - sprawdz je w kodzie zrodlowym.

PLIKI DO UTWORZENIA (6 plikow):

Upewnij sie ze pliki testow sa dodane do test target w Xcode. Sprawdz czy w projekcie istnieje test target MySTTTests. Jesli nie, poinformuj o koniecznosci dodania.

=== PLIK 1: Tests/ModelsTests/LanguageTests.swift ===

```swift
import XCTest
@testable import MySTT

final class LanguageTests: XCTestCase {

    func test_initFromWhisperCode_english() {
        // Language.init(whisperCode: "en") powinien zwrocic .english
        let lang = Language(whisperCode: "en")
        XCTAssertEqual(lang, .english)
    }

    func test_initFromWhisperCode_polish() {
        // Language.init(whisperCode: "pl") powinien zwrocic .polish
        let lang = Language(whisperCode: "pl")
        XCTAssertEqual(lang, .polish)
    }

    func test_initFromWhisperCode_unknown() {
        // Nieznany kod powinien zwrocic .unknown
        let lang = Language(whisperCode: "xx")
        XCTAssertEqual(lang, .unknown)
    }

    func test_initFromWhisperCode_enUS() {
        // "en_US" lub warianty powinny mapowac na .english
        // Sprawdz faktyczna implementacje w Language.swift
        let lang = Language(whisperCode: "en_US")
        XCTAssertEqual(lang, .english)
    }
}
```

UWAGA: Dopasuj init i nazwy case do faktycznej implementacji w Language.swift. Sprawdz czy init przyjmuje whisperCode jako label parametru.

=== PLIK 2: Tests/ModelsTests/AppSettingsTests.swift ===

```swift
import XCTest
@testable import MySTT

final class AppSettingsTests: XCTestCase {

    func test_codable_roundtrip() {
        // Encode AppSettings do JSON i zdekoduj z powrotem - powinny byc rowne
        let original = AppSettings()
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try! encoder.encode(original)
        let decoded = try! decoder.decode(AppSettings.self, from: data)

        // Porownaj kluczowe pola (AppSettings musi byc Equatable lub porownaj recznie)
        XCTAssertEqual(original.llmProvider, decoded.llmProvider)
        XCTAssertEqual(original.sttProvider, decoded.sttProvider)
        XCTAssertEqual(original.enableLLMCorrection, decoded.enableLLMCorrection)
        XCTAssertEqual(original.autoPaste, decoded.autoPaste)
    }

    func test_defaultValues() {
        // Sprawdz domyslne wartosci AppSettings
        let settings = AppSettings()
        XCTAssertEqual(settings.sttProvider, .whisperKit)
        XCTAssertTrue(settings.enableLLMCorrection)
        XCTAssertTrue(settings.autoPaste)
        XCTAssertTrue(settings.playSound)
    }

    func test_llmProvider_isLocal() {
        // localMLX i localOllama powinny byc local, reszta nie
        XCTAssertTrue(LLMProvider.localMLX.isLocal)
        XCTAssertTrue(LLMProvider.localOllama.isLocal)
        XCTAssertFalse(LLMProvider.grok.isLocal)
        XCTAssertFalse(LLMProvider.groq.isLocal)
        XCTAssertFalse(LLMProvider.openai.isLocal)
    }
}
```

UWAGA: Dopasuj nazwy property do faktycznej implementacji w AppSettings.swift i LLMProvider.swift.

=== PLIK 3: Tests/PostProcessingTests/DictionaryEngineTests.swift ===

```swift
import XCTest
@testable import MySTT

final class DictionaryEngineTests: XCTestCase {

    func test_preProcess_caseInsensitive() {
        // "kubernetes" powinien byc zamieniony na "Kubernetes" (case-insensitive)
        let engine = DictionaryEngine()
        // Zaladuj domyslny slownik ktory zawiera "kubernetes" -> "Kubernetes"
        let result = engine.preProcess("I love kubernetes")
        XCTAssertTrue(result.contains("Kubernetes"), "Expected 'Kubernetes' but got: \(result)")
    }

    func test_preProcess_multipleTerms() {
        // Zamiana kilku terminow w jednym tekscie
        let engine = DictionaryEngine()
        let result = engine.preProcess("using react and typescript")
        XCTAssertTrue(result.contains("React"), "Expected 'React' but got: \(result)")
        XCTAssertTrue(result.contains("TypeScript"), "Expected 'TypeScript' but got: \(result)")
    }

    func test_postProcess_doubleSpaces() {
        // Podwojne spacje powinny byc usuwane
        let engine = DictionaryEngine()
        let result = engine.postProcess("hello  world")
        XCTAssertFalse(result.contains("  "), "Double spaces should be removed: \(result)")
    }

    func test_loadDefaultDictionary() {
        // Domyslny slownik powinien sie zaladowac bez bledow
        let engine = DictionaryEngine()
        // Po inicjalizacji slownik powinien miec termy
        let terms = engine.getDictionaryTermsForPrompt()
        XCTAssertFalse(terms.isEmpty, "Default dictionary should have terms")
    }

    func test_getDictionaryTermsForPrompt() {
        // Powinien zwrocic sformatowany string z termami do wstrzykniecia w prompt LLM
        let engine = DictionaryEngine()
        let terms = engine.getDictionaryTermsForPrompt()
        XCTAssertTrue(terms.contains("Kubernetes"), "Should contain Kubernetes term")
    }
}
```

UWAGA: Sprawdz faktyczna API DictionaryEngine - czy konstruktor laduje domyslny slownik, czy trzeba wywolac loadDictionary() osobno. Dopasuj odpowiednio.

=== PLIK 4: Tests/PostProcessingTests/PostProcessorTests.swift ===

```swift
import XCTest
@testable import MySTT

// Mock LLM provider do testow
class MockLLMProviderForUnit: LLMProviderProtocol {
    var shouldFail = false
    var correctedText = "Corrected text."

    func correctText(_ text: String, language: Language, dictionary: [String: String]) async throws -> String {
        if shouldFail {
            throw LLMError.connectionFailed("Mock error")
        }
        return correctedText
    }
}

final class PostProcessorTests: XCTestCase {

    func test_processWithLLMDisabled() async throws {
        // Gdy LLM jest wylaczony, Stage 2 powinien byc pominienty
        // Wynik powinien byc z Stage 1 (punctuation) lub raw text
        var settings = AppSettings()
        settings.enableLLMCorrection = false

        let processor = PostProcessor(settings: settings)
        let result = try await processor.process("hello world", language: .english)

        // Powinien zwrocic tekst (przynajmniej niepusty)
        XCTAssertFalse(result.isEmpty, "Result should not be empty even without LLM")
    }

    func test_processWithLLMFail() async throws {
        // Gdy LLM rzuca blad, powinien gracefully degradowac do Stage 1
        let mock = MockLLMProviderForUnit()
        mock.shouldFail = true

        var settings = AppSettings()
        settings.enableLLMCorrection = true

        let processor = PostProcessor(settings: settings, llmProvider: mock)
        let result = try await processor.process("hello world", language: .english)

        // Nie powinien rzucac bledu - graceful degradation
        XCTAssertFalse(result.isEmpty, "Should return Stage 1 result on LLM failure")
    }

    func test_fullPipeline() async throws {
        // Pelny pipeline: Stage 1 (punctuation) + Stage 2 (mock LLM)
        let mock = MockLLMProviderForUnit()
        mock.correctedText = "Hello world, how are you?"

        var settings = AppSettings()
        settings.enableLLMCorrection = true

        let processor = PostProcessor(settings: settings, llmProvider: mock)
        let result = try await processor.process("hello world how are you", language: .english)

        XCTAssertFalse(result.isEmpty)
    }
}
```

UWAGA: Dopasuj PostProcessor constructor i process() sygnature do faktycznej implementacji. Sprawdz czy PostProcessor przyjmuje settings i llmProvider w konstruktorze. Jesli nie, zmodyfikuj testy aby wstrzyknac mocka w inny sposob.

=== PLIK 5: Tests/LLMProviderTests/LLMPromptBuilderTests.swift ===

```swift
import XCTest
@testable import MySTT

final class LLMPromptBuilderTests: XCTestCase {

    func test_buildSystemPrompt_english() {
        // Prompt dla angielskiego powinien zawierac "English"
        let prompt = LLMPromptBuilder.buildSystemPrompt(language: .english, dictionaryTerms: "")
        XCTAssertTrue(prompt.contains("English") || prompt.contains("english"),
                      "English prompt should mention English: \(prompt)")
    }

    func test_buildSystemPrompt_polish() {
        // Prompt dla polskiego powinien zawierac "Polish" i "diacritical"
        let prompt = LLMPromptBuilder.buildSystemPrompt(language: .polish, dictionaryTerms: "")
        XCTAssertTrue(prompt.contains("Polish"), "Polish prompt should mention Polish")
        XCTAssertTrue(prompt.contains("diacritical") || prompt.contains("diacrit"),
                      "Polish prompt should mention diacritical characters")
    }

    func test_buildSystemPrompt_withDictionary() {
        // Prompt z dictionary terms powinien zawierac te termy
        let terms = "kubernetes -> Kubernetes\nreact -> React"
        let prompt = LLMPromptBuilder.buildSystemPrompt(language: .english, dictionaryTerms: terms)
        XCTAssertTrue(prompt.contains("Kubernetes"), "Prompt should contain dictionary terms")
    }
}
```

UWAGA: Sprawdz faktyczna API LLMPromptBuilder - czy to metoda statyczna, czy instancyjna, czy parametry sa inne. Dopasuj.

=== PLIK 6: Tests/LLMProviderTests/OpenAICompatibleClientTests.swift ===

```swift
import XCTest
@testable import MySTT

final class OpenAICompatibleClientTests: XCTestCase {

    func test_requestEncoding() throws {
        // ChatCompletionRequest powinien sie poprawnie serializowac do JSON
        // Sprawdz faktyczne nazwy struktur w OpenAICompatibleClient.swift
        let request = ChatCompletionRequest(
            model: "gpt-4o-mini",
            messages: [
                ChatMessage(role: "system", content: "You are helpful."),
                ChatMessage(role: "user", content: "Hello")
            ],
            temperature: 0.1,
            max_tokens: 512
        )

        let data = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(json["model"] as? String, "gpt-4o-mini")
        XCTAssertEqual((json["messages"] as? [[String: Any]])?.count, 2)
        XCTAssertEqual(json["temperature"] as? Double, 0.1)
    }

    func test_responseDecoding() throws {
        // Symulacja JSON response od OpenAI API
        let jsonString = """
        {
            "id": "chatcmpl-123",
            "object": "chat.completion",
            "choices": [{
                "index": 0,
                "message": {
                    "role": "assistant",
                    "content": "Hello, world!"
                },
                "finish_reason": "stop"
            }]
        }
        """
        let data = jsonString.data(using: .utf8)!
        let response = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)

        XCTAssertEqual(response.choices.first?.message.content, "Hello, world!")
    }

    func test_errorHandling401() async {
        // Test z nieprawidlowym API key powinien zwrocic czytelny blad
        let client = OpenAICompatibleClient(
            baseURL: "https://api.openai.com/v1/chat/completions",
            apiKey: "invalid-key-12345"
        )

        do {
            let _ = try await client.complete(
                model: "gpt-4o-mini",
                messages: [ChatMessage(role: "user", content: "test")],
                temperature: 0.1,
                maxTokens: 10
            )
            XCTFail("Should have thrown an error for invalid API key")
        } catch {
            // Oczekujemy bledu - OK
            XCTAssertTrue(true, "Error thrown as expected: \(error)")
        }
    }
}
```

UWAGA KRYTYCZNA: Nazwy typow (ChatCompletionRequest, ChatCompletionResponse, ChatMessage, OpenAICompatibleClient) MUSZA odpowiadac faktycznym nazwom w /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/LLM/OpenAICompatibleClient.swift. Przeczytaj ten plik i dopasuj!

INSTRUKCJE DODATKOWE:
1. Przeczytaj KAZDY plik zrodlowy z ZALEZNOSCI zanim napiszesz testy
2. Dopasuj WSZYSTKIE nazwy typow, metod, parametrow do faktycznej implementacji
3. Jesli jakis plik zrodlowy nie istnieje, napisz test z komentarzem "// TODO: Depends on missing file"
4. Upewnij sie ze test target MySTTTests istnieje w Xcode project
5. Dodaj nowe pliki testow do odpowiedniego targetu

WERYFIKACJA - uruchom te komendy po zakonczeniu:

```bash
# 1. Sprawdz ze wszystkie pliki testow istnieja
echo "=== Sprawdzanie plikow testow ==="
test -f /Users/igor.3.wolak.external/Downloads/MySTT/Tests/ModelsTests/LanguageTests.swift && echo "PASS: LanguageTests.swift" || echo "FAIL: LanguageTests.swift"
test -f /Users/igor.3.wolak.external/Downloads/MySTT/Tests/ModelsTests/AppSettingsTests.swift && echo "PASS: AppSettingsTests.swift" || echo "FAIL: AppSettingsTests.swift"
test -f /Users/igor.3.wolak.external/Downloads/MySTT/Tests/PostProcessingTests/DictionaryEngineTests.swift && echo "PASS: DictionaryEngineTests.swift" || echo "FAIL: DictionaryEngineTests.swift"
test -f /Users/igor.3.wolak.external/Downloads/MySTT/Tests/PostProcessingTests/PostProcessorTests.swift && echo "PASS: PostProcessorTests.swift" || echo "FAIL: PostProcessorTests.swift"
test -f /Users/igor.3.wolak.external/Downloads/MySTT/Tests/LLMProviderTests/LLMPromptBuilderTests.swift && echo "PASS: LLMPromptBuilderTests.swift" || echo "FAIL: LLMPromptBuilderTests.swift"
test -f /Users/igor.3.wolak.external/Downloads/MySTT/Tests/LLMProviderTests/OpenAICompatibleClientTests.swift && echo "PASS: OpenAICompatibleClientTests.swift" || echo "FAIL: OpenAICompatibleClientTests.swift"

# 2. Policz test cases
echo ""
echo "=== Liczba test cases ==="
grep -r "func test_" /Users/igor.3.wolak.external/Downloads/MySTT/Tests/ --include="*.swift" | wc -l
# Oczekiwany: >= 15

# 3. Kompilacja testow
echo ""
echo "=== Kompilacja ==="
cd /Users/igor.3.wolak.external/Downloads/MySTT
xcodebuild build-for-testing -scheme MySTT -destination 'platform=macOS' 2>&1 | tail -10
# Oczekiwany: BUILD SUCCEEDED

# 4. Uruchom testy
echo ""
echo "=== Uruchamianie testow ==="
xcodebuild test -scheme MySTT -destination 'platform=macOS' 2>&1 | grep -E "Test Suite|Tests|passed|failed|error:"
# Oczekiwany: All tests passed

# 5. Szczegolowy raport testow
echo ""
echo "=== Szczegoly ==="
xcodebuild test -scheme MySTT -destination 'platform=macOS' 2>&1 | grep -E "Test Case.*passed|Test Case.*failed"
```

Oczekiwane wyniki:
- Wszystkie 6 plikow testow istnieja: PASS
- Minimum 15 test cases: PASS
- Kompilacja testow: BUILD SUCCEEDED
- Wszystkie testy: PASS (zielone)
- Zero failures

Po wykonaniu uruchom weryfikacje. Jesli jakiekolwiek kryterium FAIL -> napraw -> ponowna weryfikacja -> powtarzaj max 5 razy -> jesli nadal FAIL -> zglos problem.

KRYTERIA DONE:
- [ ] 6 plikow testow utworzonych
- [ ] Minimum 15 test cases (liczenie grep "func test_")
- [ ] Testy kompiluja sie bez bledow
- [ ] Wszystkie testy PASS (zero failures)
- [ ] Testy odpowiadaja faktycznym sygnaturom metod w kodzie zrodlowym

RAPORT KONCOWY: Po zakonczeniu podaj:
- Status: DONE/FAIL
- Lista utworzonych plikow (pelne sciezki)
- Liczba test cases: X passed, Y failed
- Problemy napotkane (szczegolnie: brakujace pliki zrodlowe, niezgodnosci API)
```

---

## RUNDA 8 - Sesja Q: Integration Tests (Zadanie 7.2)

**Typ**: SEQUENTIAL (po Sesji P)
**Zaleznosci**: Sesja P (Unit Tests) + Sesja N (AppState)
**Czas**: ~20 min

### Prompt dla Claude Code

```
Jestes doswiadczonym test engineerem pracujacym nad projektem MySTT - macOS Speech-to-Text Application.

WORKING DIRECTORY: /Users/igor.3.wolak.external/Downloads/MySTT

KONTEKST PROJEKTU:
Przeczytaj pliki zrodlowe dla kontekstu:
- /Users/igor.3.wolak.external/Downloads/MySTT/architecture.md (sekcja 4, 11)
- /Users/igor.3.wolak.external/Downloads/MySTT/implementation-plan.md (Zadanie 7.2)

ZADANIE: Utworz testy integracyjne pelnego pipeline MySTT (bez prawdziwego mikrofonu - uzyj mockow).

ZALEZNOSCI DO SPRAWDZENIA:
Przed rozpoczeciem sprawdz i przeczytaj:
- /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/App/AppState.swift (centralny state manager)
- /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/STT/STTEngineProtocol.swift (protokol STT)
- /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/LLM/LLMProviderProtocol.swift (protokol LLM)
- /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/PostProcessing/PostProcessorProtocol.swift (protokol PostProcessor)
- /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/PostProcessing/PostProcessor.swift (implementacja)
- /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/Models/Language.swift
- /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/Models/STTResult.swift
- /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/Models/AppSettings.swift
- /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/Models/Errors.swift
- /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/Audio/AudioCaptureEngine.swift

Sprawdz tez czy unit testy z Sesji P istnieja i przechodza:
- /Users/igor.3.wolak.external/Downloads/MySTT/Tests/ModelsTests/LanguageTests.swift

WAZNE: Przeczytaj WSZYSTKIE powyzsze pliki zanim zaczniesz pisac testy! Musisz znac dokladne sygnatury protokolow, nazwy typow i struktury danych.

PLIKI DO UTWORZENIA (4 pliki):

=== PLIK 1: Tests/IntegrationTests/MockAudioProvider.swift ===
Mock ktory symuluje AudioCaptureEngine bez prawdziwego mikrofonu.

```swift
import AVFoundation
@testable import MySTT

/// Mock audio provider that returns pre-built audio buffer without real microphone.
class MockAudioProvider {
    var isRecording = false
    private var mockBuffer: AVAudioPCMBuffer?

    init() {
        // Create a mock audio buffer: 16kHz, mono, Float32, 1 second of silence
        let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: 16000,
            channels: 1,
            interleaved: false
        )!
        let frameCount = AVAudioFrameCount(16000) // 1 second at 16kHz
        mockBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)
        mockBuffer?.frameLength = frameCount

        // Fill with near-silence (small random values to simulate real audio)
        if let channelData = mockBuffer?.floatChannelData?[0] {
            for i in 0..<Int(frameCount) {
                channelData[i] = Float.random(in: -0.001...0.001)
            }
        }
    }

    func startRecording() {
        isRecording = true
    }

    func stopRecording() -> AVAudioPCMBuffer? {
        isRecording = false
        return mockBuffer
    }
}
```

UWAGA: Dopasuj interfejs do faktycznego AudioCaptureEngine - sprawdz czy startRecording()/stopRecording() maja takie same sygnatury. Jesli AudioCaptureEngine uzywa async/throws, dodaj odpowiednio.

=== PLIK 2: Tests/IntegrationTests/MockSTTEngine.swift ===
Mock STT engine ktory zwraca ustalony wynik.

```swift
import AVFoundation
@testable import MySTT

/// Mock STT engine that returns fixed transcription results.
class MockSTTEngine: STTEngineProtocol {
    var mockResult: STTResult
    var shouldFail = false

    init(text: String = "hello world how are you", language: Language = .english) {
        self.mockResult = STTResult(
            text: text,
            language: language,
            confidence: 0.95,
            segments: []
        )
    }

    func transcribe(audioBuffer: AVAudioPCMBuffer) async throws -> STTResult {
        if shouldFail {
            throw STTError.transcriptionFailed("Mock STT failure")
        }
        return mockResult
    }
}
```

UWAGA: Dopasuj STTResult constructor i STTEngineProtocol sygnature do faktycznej implementacji. Sprawdz Errors.swift dla dokladnych nazw bledow.

=== PLIK 3: Tests/IntegrationTests/MockLLMProvider.swift ===
Mock LLM provider ktory zwraca ustalony tekst lub rzuca blad.

```swift
@testable import MySTT

/// Mock LLM provider for integration tests.
class MockLLMProvider: LLMProviderProtocol {
    var correctedText: String
    var shouldFail = false
    var callCount = 0

    init(correctedText: String = "Hello world, how are you?") {
        self.correctedText = correctedText
    }

    func correctText(_ text: String, language: Language, dictionary: [String: String]) async throws -> String {
        callCount += 1
        if shouldFail {
            throw LLMError.connectionFailed("Mock LLM failure")
        }
        return correctedText
    }
}
```

UWAGA: Dopasuj LLMProviderProtocol sygnature i LLMError do faktycznej implementacji.

=== PLIK 4: Tests/IntegrationTests/PipelineIntegrationTests.swift ===
Testy integracyjne pelnego pipeline.

```swift
import XCTest
import AVFoundation
@testable import MySTT

final class PipelineIntegrationTests: XCTestCase {

    func test_fullPipeline_english() async throws {
        // Full pipeline: mock audio -> mock STT (English) -> postprocess -> wynik
        let mockSTT = MockSTTEngine(text: "hello world how are you today", language: .english)
        let mockLLM = MockLLMProvider(correctedText: "Hello world, how are you today?")
        let mockAudio = MockAudioProvider()

        // Symuluj pipeline
        mockAudio.startRecording()
        let buffer = mockAudio.stopRecording()!

        let sttResult = try await mockSTT.transcribe(audioBuffer: buffer)
        XCTAssertEqual(sttResult.language, .english)
        XCTAssertEqual(sttResult.text, "hello world how are you today")

        // PostProcess z mock LLM
        var settings = AppSettings()
        settings.enableLLMCorrection = true
        let processor = PostProcessor(settings: settings, llmProvider: mockLLM)
        let finalText = try await processor.process(sttResult.text, language: sttResult.language)

        XCTAssertFalse(finalText.isEmpty, "Final text should not be empty")
    }

    func test_fullPipeline_polish() async throws {
        // Full pipeline: mock audio -> mock STT (Polish) -> postprocess -> wynik
        let mockSTT = MockSTTEngine(text: "witaj swiecie jak sie masz", language: .polish)
        let mockLLM = MockLLMProvider(correctedText: "Witaj swiecie, jak sie masz?")
        let mockAudio = MockAudioProvider()

        mockAudio.startRecording()
        let buffer = mockAudio.stopRecording()!

        let sttResult = try await mockSTT.transcribe(audioBuffer: buffer)
        XCTAssertEqual(sttResult.language, .polish)

        var settings = AppSettings()
        settings.enableLLMCorrection = true
        let processor = PostProcessor(settings: settings, llmProvider: mockLLM)
        let finalText = try await processor.process(sttResult.text, language: sttResult.language)

        XCTAssertFalse(finalText.isEmpty)
    }

    func test_pipeline_llmFallback() async throws {
        // LLM fails -> graceful degradation do Stage 1 output
        let mockSTT = MockSTTEngine(text: "hello world test", language: .english)
        let mockLLM = MockLLMProvider()
        mockLLM.shouldFail = true

        let mockAudio = MockAudioProvider()
        mockAudio.startRecording()
        let buffer = mockAudio.stopRecording()!

        let sttResult = try await mockSTT.transcribe(audioBuffer: buffer)

        var settings = AppSettings()
        settings.enableLLMCorrection = true
        let processor = PostProcessor(settings: settings, llmProvider: mockLLM)

        // Nie powinien rzucac bledu - graceful degradation
        let finalText = try await processor.process(sttResult.text, language: sttResult.language)
        XCTAssertFalse(finalText.isEmpty, "Should fallback to Stage 1 when LLM fails")
    }

    func test_pipeline_noPostprocessing() async throws {
        // All post-processing disabled -> raw STT output
        let rawText = "raw stt output without any processing"
        let mockSTT = MockSTTEngine(text: rawText, language: .english)

        let mockAudio = MockAudioProvider()
        mockAudio.startRecording()
        let buffer = mockAudio.stopRecording()!

        let sttResult = try await mockSTT.transcribe(audioBuffer: buffer)

        var settings = AppSettings()
        settings.enableLLMCorrection = false
        settings.enablePunctuationModel = false
        settings.enableDictionary = false

        let processor = PostProcessor(settings: settings)
        let finalText = try await processor.process(sttResult.text, language: sttResult.language)

        // Z wylaczonym postprocessingiem, tekst powinien byc (prawie) identyczny
        XCTAssertTrue(finalText.contains("raw") || finalText.contains("stt"),
                      "With all processing disabled, text should be close to raw: \(finalText)")
    }

    func test_settingsChange_switchProvider() async throws {
        // Zmiana LLM providera -> nowy provider powinien byc uzyty
        let mockLLM1 = MockLLMProvider(correctedText: "From provider 1.")
        let mockLLM2 = MockLLMProvider(correctedText: "From provider 2.")

        var settings = AppSettings()
        settings.enableLLMCorrection = true

        // Pierwszy provider
        let processor1 = PostProcessor(settings: settings, llmProvider: mockLLM1)
        let result1 = try await processor1.process("test text", language: .english)

        // Drugi provider (symulacja zmiany)
        let processor2 = PostProcessor(settings: settings, llmProvider: mockLLM2)
        let result2 = try await processor2.process("test text", language: .english)

        // Oba powinny dac rozne wyniki jesli LLM jest aktywny
        XCTAssertTrue(mockLLM1.callCount > 0 || mockLLM2.callCount > 0,
                      "At least one LLM provider should have been called")
    }
}
```

UWAGA KRYTYCZNA:
1. Przeczytaj PostProcessor.swift i sprawdz dokladnie constructor - czy przyjmuje (settings:, llmProvider:)?
2. Przeczytaj PostProcessorProtocol.swift i sprawdz sygnature process()
3. Jesli PostProcessor nie przyjmuje llmProvider w konstruktorze, znajdz inny sposob wstrzykniecia mocka
4. Dopasuj WSZYSTKIE nazwy do faktycznego kodu

INSTRUKCJE DODATKOWE:
1. Przeczytaj KAZDY plik zrodlowy z ZALEZNOSCI zanim napiszesz testy
2. Jesli PostProcessor ma inna sygnature niz zakladana - dopasuj
3. Upewnij sie ze mock files sa w tym samym test target co integration tests
4. Jesli brakuje jakichs plikow zrodlowych, napisz testy z komentarzem

WERYFIKACJA - uruchom te komendy po zakonczeniu:

```bash
# 1. Sprawdz pliki
echo "=== Sprawdzanie plikow ==="
test -f /Users/igor.3.wolak.external/Downloads/MySTT/Tests/IntegrationTests/PipelineIntegrationTests.swift && echo "PASS: PipelineIntegrationTests.swift" || echo "FAIL: PipelineIntegrationTests.swift"
test -f /Users/igor.3.wolak.external/Downloads/MySTT/Tests/IntegrationTests/MockAudioProvider.swift && echo "PASS: MockAudioProvider.swift" || echo "FAIL: MockAudioProvider.swift"
test -f /Users/igor.3.wolak.external/Downloads/MySTT/Tests/IntegrationTests/MockSTTEngine.swift && echo "PASS: MockSTTEngine.swift" || echo "FAIL: MockSTTEngine.swift"
test -f /Users/igor.3.wolak.external/Downloads/MySTT/Tests/IntegrationTests/MockLLMProvider.swift && echo "PASS: MockLLMProvider.swift" || echo "FAIL: MockLLMProvider.swift"

# 2. Policz integration test cases
echo ""
echo "=== Liczba integration test cases ==="
grep -c "func test_" /Users/igor.3.wolak.external/Downloads/MySTT/Tests/IntegrationTests/PipelineIntegrationTests.swift
# Oczekiwany: >= 5

# 3. Kompilacja
echo ""
echo "=== Kompilacja ==="
cd /Users/igor.3.wolak.external/Downloads/MySTT
xcodebuild build-for-testing -scheme MySTT -destination 'platform=macOS' 2>&1 | tail -10
# Oczekiwany: BUILD SUCCEEDED

# 4. Uruchom WSZYSTKIE testy (unit + integration)
echo ""
echo "=== Uruchamianie wszystkich testow ==="
xcodebuild test -scheme MySTT -destination 'platform=macOS' 2>&1 | grep -E "Test Suite|Tests|passed|failed|error:"
# Oczekiwany: All tests passed

# 5. Szczegoly integration testow
echo ""
echo "=== Szczegoly integration tests ==="
xcodebuild test -scheme MySTT -destination 'platform=macOS' 2>&1 | grep -E "PipelineIntegration.*passed|PipelineIntegration.*failed"
# Oczekiwany: 5 passed, 0 failed

# 6. Laczna liczba testow (unit + integration)
echo ""
echo "=== Laczna liczba testow ==="
grep -r "func test_" /Users/igor.3.wolak.external/Downloads/MySTT/Tests/ --include="*.swift" | wc -l
# Oczekiwany: >= 20 (15 unit + 5 integration)
```

Oczekiwane wyniki:
- 4 pliki utworzone: PASS
- 5 integration test cases: PASS
- Kompilacja: BUILD SUCCEEDED
- Wszystkie testy (unit + integration): PASS
- Laczna liczba testow >= 20

Po wykonaniu uruchom weryfikacje. Jesli jakiekolwiek kryterium FAIL -> napraw -> ponowna weryfikacja -> powtarzaj max 5 razy -> jesli nadal FAIL -> zglos problem.

KRYTERIA DONE:
- [ ] 4 pliki utworzone w Tests/IntegrationTests/
- [ ] 5 integration test cases w PipelineIntegrationTests
- [ ] 3 mock files (MockAudioProvider, MockSTTEngine, MockLLMProvider) dzialaja
- [ ] Kompilacja BUILD SUCCEEDED
- [ ] Wszystkie integration testy PASS
- [ ] Unit testy z Sesji P nadal PASS (brak regresji)

RAPORT KONCOWY: Po zakonczeniu podaj:
- Status: DONE/FAIL
- Lista utworzonych plikow (pelne sciezki)
- Wyniki: unit tests X passed / integration tests Y passed
- Laczna liczba testow
- Problemy napotkane (brakujace pliki, niezgodnosci API)
```

---

## RUNDA 9 - Sesja R: Build + DMG (Zadanie 8.1)

**Typ**: SEQUENTIAL
**Zaleznosci**: Wszystkie fazy 1-7 (Sesje A-Q)
**Czas**: ~15 min

### Prompt dla Claude Code

```
Jestes doswiadczonym build/release engineerem pracujacym nad projektem MySTT - macOS Speech-to-Text Application.

WORKING DIRECTORY: /Users/igor.3.wolak.external/Downloads/MySTT

KONTEKST PROJEKTU:
Przeczytaj pliki zrodlowe dla kontekstu:
- /Users/igor.3.wolak.external/Downloads/MySTT/architecture.md (sekcja 14)
- /Users/igor.3.wolak.external/Downloads/MySTT/implementation-plan.md (Zadanie 8.1)

ZADANIE: Utworz skrypty do release build i tworzenia DMG.

ZALEZNOSCI DO SPRAWDZENIA:
Przed rozpoczeciem sprawdz czy projekt kompiluje sie poprawnie:
```bash
cd /Users/igor.3.wolak.external/Downloads/MySTT
xcodebuild -scheme MySTT -configuration Debug build 2>&1 | tail -5
# Powinno byc BUILD SUCCEEDED
```

Sprawdz tez czy testy przechodza:
```bash
xcodebuild test -scheme MySTT -destination 'platform=macOS' 2>&1 | tail -5
```

Jesli kompilacja lub testy failuja - odnotuj to w raporcie ale kontynuuj tworzenie skryptow.

PLIKI DO UTWORZENIA (2 pliki):

=== PLIK 1: Scripts/build_release.sh ===
Skrypt do automatycznego release build.

Wymagania:
- Shebang: #!/bin/bash, set -e
- Chmod +x
- Konfiguracja:
  - SCHEME="MySTT"
  - CONFIGURATION="Release"
  - BUILD_DIR="build"
  - ARCHIVE_PATH="build/MySTT.xcarchive"
  - EXPORT_PATH="build/Release"
- Kroki:
  1. Wyczysc poprzedni build (rm -rf build/)
  2. xcodebuild archive:
     - -scheme MySTT
     - -configuration Release
     - -archivePath build/MySTT.xcarchive
     - SWIFT_OPTIMIZATION_LEVEL=-O
     - GCC_OPTIMIZATION_LEVEL=s
     - STRIP_INSTALLED_PRODUCT=YES
     - COPY_PHASE_STRIP=YES
     - DEBUG_INFORMATION_FORMAT=dwarf (bez dSYM dla release)
  3. Eksportuj app z archive:
     - Kopiuj MySTT.app z archive do build/Release/
  4. Ad-hoc code signing:
     - codesign --force --deep --sign - build/Release/MySTT.app
  5. Weryfikacja:
     - codesign --verify build/Release/MySTT.app
     - Sprawdz rozmiar
  6. Wyswietl podsumowanie:
     - Sciezka do .app
     - Rozmiar
     - Architektura (lipo -info)
     - Podpis (codesign -d)

Wzorzec kodu:
```bash
#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build"
SCHEME="MySTT"
CONFIGURATION="Release"
ARCHIVE_PATH="$BUILD_DIR/MySTT.xcarchive"
APP_NAME="MySTT.app"

echo "======================================"
echo "  MySTT - Release Build"
echo "======================================"
echo ""

# Clean previous build
echo "--- Cleaning previous build ---"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Find Xcode project or workspace
XCODE_PROJECT=""
if [ -f "$PROJECT_DIR/MySTT.xcworkspace/contents.xcworkspacedata" ]; then
    XCODE_PROJECT="-workspace $PROJECT_DIR/MySTT.xcworkspace"
elif [ -d "$PROJECT_DIR/MySTT.xcodeproj" ]; then
    XCODE_PROJECT="-project $PROJECT_DIR/MySTT.xcodeproj"
else
    echo "ERROR: No Xcode project or workspace found in $PROJECT_DIR"
    exit 1
fi

# Archive
echo "--- Archiving (Release configuration) ---"
xcodebuild archive \
    $XCODE_PROJECT \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -archivePath "$ARCHIVE_PATH" \
    SWIFT_OPTIMIZATION_LEVEL="-O" \
    GCC_OPTIMIZATION_LEVEL=s \
    STRIP_INSTALLED_PRODUCT=YES \
    COPY_PHASE_STRIP=YES \
    DEBUG_INFORMATION_FORMAT="dwarf" \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGNING_ALLOWED=YES \
    2>&1 | tail -20

if [ ! -d "$ARCHIVE_PATH" ]; then
    echo "ERROR: Archive failed - $ARCHIVE_PATH not created"
    exit 1
fi
echo "[OK] Archive created"

# Export app from archive
echo ""
echo "--- Extracting app from archive ---"
mkdir -p "$BUILD_DIR/Release"
cp -R "$ARCHIVE_PATH/Products/Applications/$APP_NAME" "$BUILD_DIR/Release/$APP_NAME" 2>/dev/null || \
cp -R "$ARCHIVE_PATH/Products/usr/local/bin/$APP_NAME" "$BUILD_DIR/Release/$APP_NAME" 2>/dev/null || {
    # Fallback: find the .app inside archive
    APP_FOUND=$(find "$ARCHIVE_PATH" -name "$APP_NAME" -type d | head -1)
    if [ -n "$APP_FOUND" ]; then
        cp -R "$APP_FOUND" "$BUILD_DIR/Release/$APP_NAME"
    else
        echo "ERROR: Could not find $APP_NAME in archive"
        exit 1
    fi
}
echo "[OK] App extracted to $BUILD_DIR/Release/$APP_NAME"

# Ad-hoc code signing
echo ""
echo "--- Code signing (ad-hoc) ---"
codesign --force --deep --sign - "$BUILD_DIR/Release/$APP_NAME"
echo "[OK] Code signed"

# Verify
echo ""
echo "--- Verification ---"
codesign --verify "$BUILD_DIR/Release/$APP_NAME" && echo "[OK] Signature valid" || echo "[WARN] Signature verification failed"

# Summary
echo ""
echo "======================================"
echo "  Build Summary"
echo "======================================"
echo ""
echo "App:          $BUILD_DIR/Release/$APP_NAME"
echo "Size:         $(du -sh "$BUILD_DIR/Release/$APP_NAME" | cut -f1)"
echo "Architecture: $(lipo -info "$BUILD_DIR/Release/$APP_NAME/Contents/MacOS/MySTT" 2>/dev/null || echo "unknown")"
echo ""
echo "Codesign info:"
codesign -d "$BUILD_DIR/Release/$APP_NAME" 2>&1 | head -5
echo ""
echo "Build complete!"
```

=== PLIK 2: Scripts/create_dmg.sh ===
Skrypt do tworzenia DMG z drag-to-Applications layout.

Wymagania:
- Shebang: #!/bin/bash, set -e
- Chmod +x
- Sprawdz czy build/Release/MySTT.app istnieje
- Utworz tymczasowy katalog DMG z:
  - MySTT.app (skopiowany)
  - Symlink do /Applications (dla drag-to-Applications)
  - README.txt z instrukcjami setup
- Uzyj hdiutil do utworzenia DMG:
  - hdiutil create (temporary RW image)
  - hdiutil convert (do compressed read-only)
- Nazwa DMG: MySTT-<version>.dmg (wersja z Info.plist lub "1.0.0")
- README.txt w DMG:
  - Krotki opis MySTT
  - Instrukcja: przeciagnij do Applications
  - Wymagania: macOS 14.0+, uprawnienia Accessibility + Microphone
  - Pierwsze uruchomienie: python3 Scripts/setup_models.sh

Wzorzec kodu:
```bash
#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build"
APP_PATH="$BUILD_DIR/Release/MySTT.app"
DMG_DIR="$BUILD_DIR/dmg"
VERSION="1.0.0"
DMG_NAME="MySTT-${VERSION}"
DMG_PATH="$BUILD_DIR/${DMG_NAME}.dmg"

echo "======================================"
echo "  MySTT - Create DMG"
echo "======================================"
echo ""

# Check if app exists
if [ ! -d "$APP_PATH" ]; then
    echo "ERROR: MySTT.app not found at $APP_PATH"
    echo "Run Scripts/build_release.sh first."
    exit 1
fi

# Try to get version from Info.plist
PLIST_VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP_PATH/Contents/Info.plist" 2>/dev/null || echo "")
if [ -n "$PLIST_VERSION" ]; then
    VERSION="$PLIST_VERSION"
    DMG_NAME="MySTT-${VERSION}"
    DMG_PATH="$BUILD_DIR/${DMG_NAME}.dmg"
fi

echo "Version: $VERSION"
echo "DMG: $DMG_PATH"
echo ""

# Clean previous DMG artifacts
rm -rf "$DMG_DIR"
rm -f "$DMG_PATH"
rm -f "$BUILD_DIR/${DMG_NAME}-temp.dmg"
mkdir -p "$DMG_DIR"

# Copy app
echo "--- Copying MySTT.app ---"
cp -R "$APP_PATH" "$DMG_DIR/MySTT.app"
echo "[OK] App copied"

# Create Applications symlink
echo "--- Creating Applications symlink ---"
ln -s /Applications "$DMG_DIR/Applications"
echo "[OK] Symlink created"

# Create README
echo "--- Creating README ---"
cat > "$DMG_DIR/README.txt" << 'READMEEOF'
MySTT - macOS Speech-to-Text Application
==========================================

Installation:
1. Drag MySTT.app to the Applications folder
2. Launch MySTT from Applications
3. Grant required permissions when prompted:
   - Microphone access (for speech recording)
   - Accessibility access (for global hotkey and auto-paste)
     System Settings > Privacy & Security > Accessibility > Add MySTT

First-time Setup:
- On first launch, the onboarding wizard will guide you through setup
- To install local AI models, run in Terminal:
  /Applications/MySTT.app/Contents/Resources/Scripts/setup_models.sh
  (Or download models through the Settings panel)

Requirements:
- macOS 14.0 (Sonoma) or later
- Apple Silicon recommended (Intel supported with reduced performance)
- 8 GB RAM minimum (16 GB recommended for local models)

Usage:
- Hold the configured hotkey (default: Right Option) to record
- Release to process and auto-paste the transcription
- Access Settings via the menu bar icon

For more information, visit the project documentation.
READMEEOF
echo "[OK] README created"

# Create DMG
echo ""
echo "--- Creating DMG ---"

# Create temporary RW image
hdiutil create \
    -volname "$DMG_NAME" \
    -srcfolder "$DMG_DIR" \
    -ov \
    -format UDRW \
    "$BUILD_DIR/${DMG_NAME}-temp.dmg"

# Convert to compressed read-only
hdiutil convert \
    "$BUILD_DIR/${DMG_NAME}-temp.dmg" \
    -format UDZO \
    -imagekey zlib-level=9 \
    -o "$DMG_PATH"

# Clean up
rm -f "$BUILD_DIR/${DMG_NAME}-temp.dmg"
rm -rf "$DMG_DIR"

echo ""
echo "[OK] DMG created: $DMG_PATH"

# Summary
echo ""
echo "======================================"
echo "  DMG Summary"
echo "======================================"
echo ""
echo "DMG:    $DMG_PATH"
echo "Size:   $(du -sh "$DMG_PATH" | cut -f1)"
echo ""

# Verify DMG
echo "--- Verifying DMG ---"
hdiutil verify "$DMG_PATH" && echo "[OK] DMG verified" || echo "[WARN] DMG verification issue"

echo ""
echo "Done! Distribute $DMG_PATH to users."
```

INSTRUKCJE DODATKOWE:
1. Ustaw chmod +x na obu skryptach po utworzeniu
2. Sprawdz czy sciezka do Xcode project jest poprawna (MySTT.xcodeproj)
3. Jesli workspace istnieje (po SPM resolve), uzyj -workspace zamiast -project

WERYFIKACJA - uruchom te komendy po zakonczeniu:

```bash
# 1. Sprawdz pliki
echo "=== Sprawdzanie plikow ==="
test -f /Users/igor.3.wolak.external/Downloads/MySTT/Scripts/build_release.sh && echo "PASS: build_release.sh" || echo "FAIL: build_release.sh"
test -f /Users/igor.3.wolak.external/Downloads/MySTT/Scripts/create_dmg.sh && echo "PASS: create_dmg.sh" || echo "FAIL: create_dmg.sh"

# 2. Sprawdz uprawnienia
echo ""
echo "=== Sprawdzanie uprawnien ==="
test -x /Users/igor.3.wolak.external/Downloads/MySTT/Scripts/build_release.sh && echo "PASS: build_release.sh executable" || echo "FAIL: build_release.sh not executable"
test -x /Users/igor.3.wolak.external/Downloads/MySTT/Scripts/create_dmg.sh && echo "PASS: create_dmg.sh executable" || echo "FAIL: create_dmg.sh not executable"

# 3. Sprawdz skladnie bash
echo ""
echo "=== Sprawdzanie skladni ==="
bash -n /Users/igor.3.wolak.external/Downloads/MySTT/Scripts/build_release.sh && echo "PASS: build_release.sh syntax" || echo "FAIL: build_release.sh syntax"
bash -n /Users/igor.3.wolak.external/Downloads/MySTT/Scripts/create_dmg.sh && echo "PASS: create_dmg.sh syntax" || echo "FAIL: create_dmg.sh syntax"

# 4. Sprawdz kluczowe komendy w skryptach
echo ""
echo "=== Sprawdzanie zawartosci ==="
grep -q "xcodebuild archive" /Users/igor.3.wolak.external/Downloads/MySTT/Scripts/build_release.sh && echo "PASS: xcodebuild archive found" || echo "FAIL: xcodebuild archive missing"
grep -q "codesign" /Users/igor.3.wolak.external/Downloads/MySTT/Scripts/build_release.sh && echo "PASS: codesign found" || echo "FAIL: codesign missing"
grep -q "STRIP_INSTALLED_PRODUCT" /Users/igor.3.wolak.external/Downloads/MySTT/Scripts/build_release.sh && echo "PASS: strip symbols flag found" || echo "FAIL: strip symbols flag missing"
grep -q "hdiutil" /Users/igor.3.wolak.external/Downloads/MySTT/Scripts/create_dmg.sh && echo "PASS: hdiutil found" || echo "FAIL: hdiutil missing"
grep -q "Applications" /Users/igor.3.wolak.external/Downloads/MySTT/Scripts/create_dmg.sh && echo "PASS: Applications symlink found" || echo "FAIL: Applications symlink missing"

# 5. Proba uruchomienia build (moze sie nie udac jesli brak zaleznosci - to OK)
echo ""
echo "=== Proba build release ==="
cd /Users/igor.3.wolak.external/Downloads/MySTT
bash Scripts/build_release.sh 2>&1 | tail -10

# 6. Jesli build sie powiodl, sprawdz rozmiar
echo ""
echo "=== Sprawdzanie wynikow ==="
if [ -d /Users/igor.3.wolak.external/Downloads/MySTT/build/Release/MySTT.app ]; then
    SIZE=$(du -sm /Users/igor.3.wolak.external/Downloads/MySTT/build/Release/MySTT.app | cut -f1)
    echo "App size: ${SIZE} MB"
    if [ "$SIZE" -lt 60 ]; then
        echo "PASS: App size < 60 MB"
    else
        echo "WARN: App size >= 60 MB (${SIZE} MB)"
    fi
    codesign --verify /Users/igor.3.wolak.external/Downloads/MySTT/build/Release/MySTT.app && echo "PASS: Codesign valid" || echo "WARN: Codesign issue"
else
    echo "INFO: MySTT.app not found (build may have failed - check errors above)"
fi

# 7. Jesli app istnieje, utworz DMG
if [ -d /Users/igor.3.wolak.external/Downloads/MySTT/build/Release/MySTT.app ]; then
    echo ""
    echo "=== Tworzenie DMG ==="
    bash /Users/igor.3.wolak.external/Downloads/MySTT/Scripts/create_dmg.sh 2>&1 | tail -10

    if ls /Users/igor.3.wolak.external/Downloads/MySTT/build/MySTT-*.dmg 1>/dev/null 2>&1; then
        echo "PASS: DMG created"
        ls -la /Users/igor.3.wolak.external/Downloads/MySTT/build/MySTT-*.dmg
    else
        echo "WARN: DMG not created"
    fi
fi
```

Oczekiwane wyniki:
- 2 pliki utworzone: PASS
- Oba executable: PASS
- Oba poprawna skladnia bash: PASS
- Kluczowe komendy obecne (xcodebuild, codesign, hdiutil): PASS
- Build release: BUILD SUCCEEDED (moze wymagac rozwiazanych SPM dependencies)
- App size < 60 MB: PASS
- DMG utworzony: PASS

UWAGA: Jesli build failuje z powodu bledow kompilacji w kodzie zrodlowym - to NIE jest problem tej sesji. Skrypty powinny byc poprawne. Odnotuj bledy kompilacji w raporcie.

Po wykonaniu uruchom weryfikacje. Jesli jakiekolwiek kryterium FAIL -> napraw -> ponowna weryfikacja -> powtarzaj max 5 razy -> jesli nadal FAIL -> zglos problem.

KRYTERIA DONE:
- [ ] Scripts/build_release.sh utworzony, executable, poprawna skladnia
- [ ] Scripts/create_dmg.sh utworzony, executable, poprawna skladnia
- [ ] build_release.sh zawiera: xcodebuild archive, -O optimization, strip symbols, codesign
- [ ] create_dmg.sh zawiera: hdiutil create/convert, Applications symlink, README.txt
- [ ] Proba build: BUILD SUCCEEDED (lub udokumentowane bledy z kodem zrodlowym)
- [ ] App size < 60 MB (jesli build sie powiodl)
- [ ] DMG utworzony poprawnie (jesli build sie powiodl)

RAPORT KONCOWY: Po zakonczeniu podaj:
- Status: DONE/FAIL
- Lista utworzonych plikow (pelne sciezki)
- Wynik build: SUCCEEDED/FAILED (z przyczyna)
- Rozmiar app (jesli build sie powiodl)
- DMG utworzony: TAK/NIE
- Problemy napotkane
```

---

## FOOTER - Informacje globalne

### Globalna macierz ryzyk

| # | Ryzyko | Prawdopodobienstwo | Wplyw | Mitigacja |
|---|---|---|---|---|
| R1 | WhisperKit API zmienia sie miedzy wersjami | Srednie | Wysoki | Pin konkretna wersje w SPM; sprawdz changelog przed update |
| R2 | Python subprocess wolny przy pierwszym wywolaniu (ladowanie modelu) | Wysokie | Sredni | Warm-up przy starcie app; cache zaladowanego modelu w background |
| R3 | CGEvent tap nie dziala bez Accessibility | Pewne | Krytyczny | Onboarding z jasna instrukcja; check permission na starcie |
| R4 | Brak mikrofonu / uprawnienia odrzucone | Srednie | Krytyczny | Graceful error message; re-request permission button |
| R5 | Ollama nie uruchomione gdy local LLM wybrany | Wysokie | Sredni | Auto-detect; notification z instrukcja "ollama serve" |
| R6 | Duze modele nie mieszcza sie w RAM (8GB Mac) | Srednie | Wysoki | Auto-detect RAM; wybierz mniejszy model; warning w UI |
| R7 | Symulacja Cmd+V nie dziala w niektorych app | Niskie | Sredni | Fallback do AXUIElement; manual copy z notification |
| R8 | Rate limiting na remote APIs | Niskie | Niski | Exponential backoff; cache ostatnich wynikow |
| R9 | Python nie zainstalowany na systemie uzytkownika | Srednie | Wysoki | Bundled Python env; lub pomin Stage 1 punctuation |
| R10 | WhisperKit model download fail (brak internetu) | Srednie | Wysoki | Retry z progress UI; offline fallback do mniejszego modelu |

### Procedury awaryjne

**Jesli sesja nie moze sie zakonczyc po 5 iteracjach napraw:**

1. **Zatrzymaj sesje** - nie kontynuuj napraw w nieskonczonosc
2. **Udokumentuj problem**:
   - Ktore kryterium DONE nie jest spelnione
   - Dokladny komunikat bledu
   - Co zostalo probowane (5 iteracji)
   - Ktore pliki zostaly zmodyfikowane
3. **Sprawdz zaleznosci** - czesto problem wynika z brakujacego/blednego kodu z poprzedniej sesji
4. **Eskaluj** - przekaz raport uzytkownikowi z pelnym kontekstem

**Typowe problemy i rozwiazania:**

| Problem | Przyczyna | Rozwiazanie |
|---|---|---|
| BUILD FAILED - brak modulu | SPM dependencies nie resolved | `xcodebuild -resolvePackageDependencies` |
| BUILD FAILED - brak pliku | Poprzednia sesja nie utworzyla pliku | Sprawdz status tracker; uruchom brakujaca sesje |
| Tests FAILED - wrong API | Testy nie odpowiadaja implementacji | Przeczytaj kod zrodlowy; dopasuj sygnatury |
| Scripts FAILED - permission | Brak chmod +x | `chmod +x Scripts/*.sh` |
| DMG FAILED - no app | Build nie utworzyl .app | Napraw build najpierw |

### Kontakt i eskalacja

- **Architektura**: Sprawdz `/Users/igor.3.wolak.external/Downloads/MySTT/architecture.md`
- **Plan implementacji**: Sprawdz `/Users/igor.3.wolak.external/Downloads/MySTT/implementation-plan.md`
- **Status sesji**: Aktualizuj tabele "Status tracker" na gorze tego dokumentu po kazdej zakonconej sesji
- **Kolejnosc**: ZAWSZE przestrzegaj kolejnosci rund - nie przeskakuj

### Protokol zakonczenia sesji

Po zakonczeniu KAZDEJ sesji:
1. Zaktualizuj status w tabeli tracker (TODO -> DONE lub FAIL)
2. Zapisz raport z sesji:
   - Pliki utworzone/zmodyfikowane
   - Wyniki weryfikacji
   - Czas wykonania
   - Problemy napotkane
3. Sprawdz czy mozna rozpoczac kolejna runde (wszystkie sesje w biezacej rundzie DONE)

---

*Dokument wygenerowany: 2026-03-17*
*Projekt: MySTT - macOS Speech-to-Text Application*
*Zrodlo: implementation-plan.md + architecture.md*
