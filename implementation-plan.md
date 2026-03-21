# MySTT - Szczegółowy Plan Wdrożenia

## Informacje ogólne

- **Projekt**: MySTT - macOS Speech-to-Text Application
- **Źródło**: architecture.md
- **Data utworzenia**: 2026-03-17
- **Metodologia**: Zadania podzielone na fale (waves) - równoległe i sekwencyjne
- **Weryfikacja**: Każde zadanie zawiera pętlę weryfikacji: sprawdź → napraw → ponownie sprawdź → powtarzaj aż do sukcesu

---

## Legenda

```
🟢 PARALLEL  - Zadania mogą być uruchamiane jednocześnie (niezależne od siebie)
🔵 SEQUENTIAL - Zadania muszą być wykonane po kolei (zależność od poprzedniego)
⏱️ Szacowany czas sesji Claude Code
🔗 Zależności od innych zadań
✅ Kryteria sukcesu
🔍 Weryfikacja
⚠️ Ryzyka
🛡️ Mitigacja ryzyk
```

---

## Przegląd faz wdrożenia

```
FAZA 0: Inicjalizacja projektu Xcode          ─── SEKWENCYJNA (fundament)
   │
FAZA 1: Warstwa fundamentów (4 zadania)       ─── RÓWNOLEGŁA
   │
FAZA 2: Warstwa silników (3 zadania)          ─── RÓWNOLEGŁA
   │
FAZA 3: Warstwa integracji (3 zadania)        ─── RÓWNOLEGŁA
   │
FAZA 4: Warstwa UI (2 zadania)               ─── RÓWNOLEGŁA
   │
FAZA 5: Pipeline end-to-end                   ─── SEKWENCYJNA
   │
FAZA 6: Skrypty Python + modele               ─── SEKWENCYJNA
   │
FAZA 7: Testy + QA                            ─── SEKWENCYJNA
   │
FAZA 8: Build + dystrybucja                   ─── SEKWENCYJNA
```

---

## FAZA 0: Inicjalizacja projektu Xcode

### Zadanie 0.1: Utworzenie projektu Xcode + struktura katalogów

**Typ**: 🔵 SEQUENTIAL (punkt startowy, wszystko od tego zależy)
**Czas**: ⏱️ ~15 min
**Zależności**: 🔗 Brak
**Agent**: `software-architect`

**Cel**: Utworzenie kompletnego projektu Xcode z poprawną konfiguracją dla menu bar app, SPM dependencies, entitlements i Info.plist.

**Wymagania**:
1. Xcode project z target macOS 14.0+ (Sonoma)
2. SwiftUI App lifecycle z `MenuBarExtra`
3. `LSUIElement = true` w Info.plist (brak ikony w Dock)
4. Entitlements: sandbox wyłączony, audio-input, files read-write
5. Info.plist: NSMicrophoneUsageDescription, NSSpeechRecognitionUsageDescription
6. Swift Package Manager dependencies:
   - WhisperKit (https://github.com/argmaxinc/WhisperKit, from: "0.9.0")
   - KeyboardShortcuts (https://github.com/sindresorhus/KeyboardShortcuts, from: "2.0.0")
7. Kompletna struktura katalogów wg architecture.md sekcja 12
8. Puste pliki placeholder we wszystkich katalogach
9. Podstawowy `MySTTApp.swift` z `MenuBarExtra` i `Settings` scene

**Kryteria sukcesu** ✅:
- [ ] Projekt kompiluje się w Xcode bez błędów
- [ ] WhisperKit i KeyboardShortcuts rozwiązane przez SPM
- [ ] Menu bar icon pojawia się po uruchomieniu
- [ ] Brak ikony w Dock
- [ ] Wszystkie katalogi z architecture.md istnieją
- [ ] Info.plist zawiera wymagane klucze
- [ ] Entitlements poprawnie skonfigurowane

**Weryfikacja** 🔍:
```bash
# 1. Sprawdź kompilację
xcodebuild -scheme MySTT -configuration Debug build 2>&1 | tail -5
# Oczekiwany wynik: ** BUILD SUCCEEDED **

# 2. Sprawdź strukturę katalogów
find MySTT/MySTT -type d | sort
# Oczekiwany wynik: App/, Audio/, STT/, PostProcessing/, LLM/, Hotkey/, Paste/, UI/, Models/, Utilities/, Resources/

# 3. Sprawdź SPM dependencies
xcodebuild -showBuildSettings | grep -i whisper
# Oczekiwany wynik: ścieżka do WhisperKit

# 4. Sprawdź Info.plist
/usr/libexec/PlistBuddy -c "Print :LSUIElement" MySTT/Info.plist
# Oczekiwany wynik: true

# 5. Sprawdź entitlements
/usr/libexec/PlistBuddy -c "Print :com.apple.security.app-sandbox" MySTT/MySTT.entitlements
# Oczekiwany wynik: false
```

**Pętla weryfikacji**: Jeśli kompilacja failuje → napraw błędy SPM/konfiguracji → ponowna kompilacja → powtarzaj.

**Ryzyka** ⚠️:
- WhisperKit SPM może wymagać konkretnej wersji Xcode
- **Mitigacja** 🛡️: Sprawdź kompatybilność WhisperKit z zainstalowaną wersją Xcode przed rozpoczęciem

---

## FAZA 1: Warstwa fundamentów (RÓWNOLEGŁA)

> Wszystkie 4 zadania w tej fazie mogą być uruchamiane jednocześnie w osobnych sesjach Claude Code.

### Zadanie 1.1: Models + Protokoły + AppSettings

**Typ**: 🟢 PARALLEL
**Czas**: ⏱️ ~20 min
**Zależności**: 🔗 Zadanie 0.1
**Agent**: `typescript-pro` (Swift patterns similar)

**Cel**: Implementacja wszystkich typów danych, protokołów i konfiguracji.

**Pliki do utworzenia**:
1. `MySTT/Models/Language.swift` - enum Language (.english, .polish, .unknown) z init(whisperCode:)
2. `MySTT/Models/STTResult.swift` - struct z text, language, confidence, segments
3. `MySTT/Models/AppSettings.swift` - struct Codable ze wszystkimi ustawieniami (patrz architecture.md §9.1)
4. `MySTT/Models/TranscriptionSegment.swift` - struct z text, start, end, confidence
5. `MySTT/STT/STTEngineProtocol.swift` - protocol z func transcribe()
6. `MySTT/LLM/LLMProviderProtocol.swift` - protocol z func correctText()
7. `MySTT/PostProcessing/PostProcessorProtocol.swift` - protocol z func process()
8. `MySTT/Models/LLMProvider.swift` - enum z case localMLX, localOllama, grok, groq, openai + factory
9. `MySTT/Models/STTProvider.swift` - enum z case whisperKit, deepgram
10. `MySTT/Models/Errors.swift` - STTError, LLMError, PasteError enums

**Kryteria sukcesu** ✅:
- [ ] Wszystkie modele kompilują się bez błędów
- [ ] AppSettings jest Codable (serializacja/deserializacja JSON działa)
- [ ] Language.init(whisperCode: "pl") zwraca .polish
- [ ] Language.init(whisperCode: "en") zwraca .english
- [ ] LLMProvider.allCases zwraca 5 przypadków
- [ ] Protokoły mają poprawne sygnatury async throws

**Weryfikacja** 🔍:
```bash
# Kompilacja projektu
xcodebuild -scheme MySTT -configuration Debug build 2>&1 | tail -5
# Oczekiwany: BUILD SUCCEEDED

# Sprawdź że wszystkie pliki istnieją
ls -la MySTT/MySTT/Models/*.swift
ls -la MySTT/MySTT/STT/STTEngineProtocol.swift
ls -la MySTT/MySTT/LLM/LLMProviderProtocol.swift
```

---

### Zadanie 1.2: Audio Capture Engine

**Typ**: 🟢 PARALLEL
**Czas**: ⏱️ ~25 min
**Zależności**: 🔗 Zadanie 0.1
**Agent**: `software-architect`

**Cel**: Implementacja przechwytywania audio z mikrofonu via AVAudioEngine.

**Pliki do utworzenia**:
1. `MySTT/Audio/AudioCaptureEngine.swift`
2. `MySTT/Audio/AudioBuffer+Extensions.swift`

**Wymagania funkcjonalne**:
1. `startRecording()` - rozpoczyna nagrywanie z mikrofonu
2. `stopRecording() -> AVAudioPCMBuffer` - zatrzymuje i zwraca bufor audio
3. Tap na input node z format: 16kHz, mono, Float32 (wymagane przez Whisper)
4. Automatyczna konwersja formatu jeśli mikrofon używa innego
5. Obsługa błędów: brak mikrofonu, brak uprawnień, awaria silnika
6. `isRecording` published property do bindowania z UI
7. Extension na AVAudioPCMBuffer: `floatArray` -> [Float], `toWAVData()` -> Data

**Kryteria sukcesu** ✅:
- [ ] Kompilacja bez błędów
- [ ] AVAudioEngine inicjalizuje się bez crash
- [ ] startRecording() nie rzuca wyjątku gdy mikrofon dostępny
- [ ] stopRecording() zwraca niepusty bufor
- [ ] Format wyjściowy: 16kHz, mono, Float32
- [ ] floatArray extension zwraca [Float] z poprawnymi danymi
- [ ] toWAVData() generuje poprawny WAV header + dane

**Weryfikacja** 🔍:
```bash
# Kompilacja
xcodebuild -scheme MySTT -configuration Debug build 2>&1 | tail -5

# Sprawdź istnienie plików
test -f MySTT/MySTT/Audio/AudioCaptureEngine.swift && echo "OK" || echo "FAIL"
test -f MySTT/MySTT/Audio/AudioBuffer+Extensions.swift && echo "OK" || echo "FAIL"
```

**Ryzyka** ⚠️:
- Mikrofon może nie być dostępny w środowisku CI/testowym
- **Mitigacja** 🛡️: Dodaj MockAudioCaptureEngine do testów; sprawdzaj `AVCaptureDevice.authorizationStatus(for: .audio)` przed użyciem

---

### Zadanie 1.3: Hotkey Manager (CGEvent Tap)

**Typ**: 🟢 PARALLEL
**Czas**: ⏱️ ~25 min
**Zależności**: 🔗 Zadanie 0.1
**Agent**: `software-architect`

**Cel**: Globalny hotkey push-to-talk via CGEvent tap.

**Pliki do utworzenia**:
1. `MySTT/Hotkey/HotkeyManager.swift`
2. `MySTT/Hotkey/KeyCodes.swift`

**Wymagania funkcjonalne**:
1. CGEvent tap nasłuchujący globalnie na keyDown/keyUp
2. Konfigurowalny klawisz (domyślnie: Right Option / 0x3D, lub Fn / 0x3F)
3. Callback `onRecordingStart` wywoływany przy keyDown
4. Callback `onRecordingStop` wywoływany przy keyUp
5. Obsługa braku uprawnień Accessibility (graceful degradation)
6. `isEnabled` property do włączania/wyłączania
7. KeyCodes.swift z mapą virtual key codes -> nazwy klawiszy

**Kryteria sukcesu** ✅:
- [ ] Kompilacja bez błędów
- [ ] CGEvent tap tworzy się bez crash (z uprawnieniami Accessibility)
- [ ] keyDown wywołuje onRecordingStart callback
- [ ] keyUp wywołuje onRecordingStop callback
- [ ] Brak memory leaks (tap jest poprawnie usuwany w deinit)
- [ ] KeyCodes zawiera przynajmniej 20 popularnych klawiszy

**Weryfikacja** 🔍:
```bash
# Kompilacja
xcodebuild -scheme MySTT -configuration Debug build 2>&1 | tail -5

# Sprawdź że CGEvent tap API jest użyte
grep -r "CGEvent.tapCreate\|tapCreate" MySTT/MySTT/Hotkey/
# Oczekiwany: znaleziony w HotkeyManager.swift
```

**Ryzyka** ⚠️:
- CGEvent tap wymaga uprawnień Accessibility - bez nich nie działa
- Na niektórych klawiaturach Fn key nie generuje CGEvent
- **Mitigacja** 🛡️: Użyj Right Option (0x3D) jako domyślny, Fn jako alternatywę. Dodaj PermissionChecker z instrukcją dla użytkownika.

---

### Zadanie 1.4: Auto-Paste System

**Typ**: 🟢 PARALLEL
**Czas**: ⏱️ ~20 min
**Zależności**: 🔗 Zadanie 0.1
**Agent**: `software-architect`

**Cel**: Automatyczne wklejanie tekstu do aktywnego okna.

**Pliki do utworzenia**:
1. `MySTT/Paste/AutoPaster.swift`
2. `MySTT/Utilities/PermissionChecker.swift`

**Wymagania funkcjonalne**:
1. `paste(_ text: String)` - wkleja tekst do aktywnego okna
2. Zapisanie i przywrócenie poprzedniej zawartości schowka
3. Symulacja Cmd+V via CGEvent (keyCode 0x09)
4. Delay 50ms między ustawieniem schowka a paste
5. Delay 200ms przed przywróceniem schowka
6. PermissionChecker: `checkAccessibilityPermission()` z automatycznym promptem
7. PermissionChecker: `checkMicrophonePermission()` z request

**Kryteria sukcesu** ✅:
- [ ] Kompilacja bez błędów
- [ ] paste() ustawia tekst w NSPasteboard
- [ ] CGEvent Cmd+V jest generowane poprawnie
- [ ] Schowek jest przywracany po wklejeniu
- [ ] PermissionChecker poprawnie wykrywa brak uprawnień
- [ ] AXIsProcessTrustedWithOptions jest wywoływane

**Weryfikacja** 🔍:
```bash
# Kompilacja
xcodebuild -scheme MySTT -configuration Debug build 2>&1 | tail -5

# Sprawdź API usage
grep -r "NSPasteboard\|CGEvent\|AXIsProcessTrusted" MySTT/MySTT/Paste/ MySTT/MySTT/Utilities/
```

---

## FAZA 2: Warstwa silników (RÓWNOLEGŁA)

> Wszystkie 3 zadania mogą być uruchamiane jednocześnie. Wymagają ukończenia FAZY 1 (przynajmniej zadania 1.1 z protokołami).

### Zadanie 2.1: WhisperKit STT Engine

**Typ**: 🟢 PARALLEL
**Czas**: ⏱️ ~30 min
**Zależności**: 🔗 Zadania 0.1, 1.1 (protokoły), 1.2 (audio)
**Agent**: `software-architect`

**Cel**: Integracja WhisperKit jako głównego silnika STT.

**Pliki do utworzenia**:
1. `MySTT/STT/WhisperKitEngine.swift`

**Wymagania funkcjonalne**:
1. Implementacja `STTEngineProtocol`
2. `initialize()` - lazy loading modelu WhisperKit
3. Automatyczny dobór modelu na podstawie RAM (architecture.md §5.2):
   - <12 GB RAM → "small"
   - ≥12 GB RAM → "large-v3-turbo"
4. `transcribe(audioBuffer:)` → STTResult z text, language, confidence
5. Detekcja języka (Whisper auto-detect) → mapowanie na Language enum
6. Obsługa błędów: model nie załadowany, puste audio, timeout
7. ComputeOptions: cpuAndGPU dla encoder i decoder
8. Warm-up: po pierwszej transkrypcji model zostaje w pamięci

**Kryteria sukcesu** ✅:
- [ ] Kompilacja bez błędów
- [ ] WhisperKitEngine implementuje STTEngineProtocol
- [ ] selectModel() zwraca "small" dla <12GB i "large-v3-turbo" dla ≥12GB
- [ ] initialize() nie crashuje (model download może potrwać)
- [ ] Mapowanie language codes działa (en→.english, pl→.polish)

**Weryfikacja** 🔍:
```bash
xcodebuild -scheme MySTT -configuration Debug build 2>&1 | tail -5

# Sprawdź implementację protokołu
grep -r "STTEngineProtocol" MySTT/MySTT/STT/WhisperKitEngine.swift
# Oczekiwany: "class WhisperKitEngine: STTEngineProtocol" lub similar
```

**Ryzyka** ⚠️:
- Pobranie modelu WhisperKit wymaga internetu i może trwać kilka minut
- WhisperKit API mogło się zmienić między wersjami
- **Mitigacja** 🛡️: Dodaj progress callback podczas pobierania. Sprawdź aktualną dokumentację WhisperKit API.

---

### Zadanie 2.2: LLM Providers (5 providerów)

**Typ**: 🟢 PARALLEL
**Czas**: ⏱️ ~40 min
**Zależności**: 🔗 Zadania 0.1, 1.1 (protokoły)
**Agent**: `software-architect`

**Cel**: Implementacja 5 providerów LLM z jednolitym interfejsem.

**Pliki do utworzenia**:
1. `MySTT/LLM/MLXProvider.swift` - lokalny MLX via Python subprocess
2. `MySTT/LLM/OllamaProvider.swift` - lokalny Ollama via HTTP REST
3. `MySTT/LLM/GrokProvider.swift` - zdalny xAI Grok API
4. `MySTT/LLM/GroqProvider.swift` - zdalny Groq API
5. `MySTT/LLM/OpenAIProvider.swift` - zdalny OpenAI API
6. `MySTT/LLM/LLMPromptBuilder.swift` - budowanie system prompt + user prompt
7. `MySTT/LLM/OpenAICompatibleClient.swift` - wspólny klient HTTP dla OpenAI-compatible APIs

**Wymagania funkcjonalne**:

**OpenAICompatibleClient** (współdzielony przez Grok, Groq, OpenAI):
1. POST do /chat/completions z Bearer token
2. JSON encode/decode ChatCompletionRequest/Response
3. Timeout: 10s domyślnie
4. Error handling: HTTP 401, 429 (rate limit), 500, timeout

**MLXProvider**:
1. Wywołanie Python subprocess z mlx_infer.py
2. Przekazanie model path, prompt, max_tokens, temperature
3. Parsowanie stdout jako wynik
4. Timeout: 30s (pierwsze wywołanie ładuje model)

**OllamaProvider**:
1. POST do http://localhost:11434/api/generate
2. stream: false
3. Sprawdzenie czy Ollama działa (GET /api/tags)
4. Graceful error gdy Ollama nie jest uruchomione

**LLMPromptBuilder**:
1. Budowanie system prompt z architecture.md §6.2 (template)
2. Wstrzyknięcie dictionary terms do promptu
3. Language-aware prompt (Polish diacritics restoration)
4. Temperature: 0.1, max_tokens: 512

**Kryteria sukcesu** ✅:
- [ ] Wszystkie 5 providerów kompiluje się bez błędów
- [ ] Każdy implementuje LLMProviderProtocol
- [ ] OpenAICompatibleClient obsługuje HTTP errors gracefully
- [ ] OllamaProvider sprawdza dostępność serwera
- [ ] LLMPromptBuilder generuje poprawny prompt z dictionary
- [ ] MLXProvider poprawnie wywołuje subprocess

**Weryfikacja** 🔍:
```bash
xcodebuild -scheme MySTT -configuration Debug build 2>&1 | tail -5

# Sprawdź że wszystkie providery implementują protokół
grep -rl "LLMProviderProtocol" MySTT/MySTT/LLM/
# Oczekiwany: 5+ plików

# Sprawdź URLs
grep -r "api.x.ai\|api.groq.com\|api.openai.com\|localhost:11434" MySTT/MySTT/LLM/
```

---

### Zadanie 2.3: Deepgram Cloud STT (Fallback)

**Typ**: 🟢 PARALLEL
**Czas**: ⏱️ ~15 min
**Zależności**: 🔗 Zadania 0.1, 1.1 (protokoły)
**Agent**: `software-architect`

**Cel**: Cloud STT fallback via Deepgram API.

**Pliki do utworzenia**:
1. `MySTT/STT/DeepgramEngine.swift`

**Wymagania funkcjonalne**:
1. Implementacja STTEngineProtocol
2. POST audio jako WAV do Deepgram API
3. Parameters: model=nova-3, detect_language=true, punctuate=true
4. Parsowanie JSON response (transcript + detected language)
5. Obsługa błędów: brak API key, brak internetu, timeout
6. Timeout: 15s

**Kryteria sukcesu** ✅:
- [ ] Kompilacja bez błędów
- [ ] DeepgramEngine implementuje STTEngineProtocol
- [ ] URL zawiera poprawne query parameters
- [ ] JSON response jest parsowany do STTResult
- [ ] Brak API key → czytelny błąd

**Weryfikacja** 🔍:
```bash
xcodebuild -scheme MySTT -configuration Debug build 2>&1 | tail -5
grep -r "deepgram.com" MySTT/MySTT/STT/DeepgramEngine.swift
```

---

## FAZA 3: Warstwa integracji (RÓWNOLEGŁA)

> Wymaga ukończenia FAZY 2. Wszystkie 3 zadania mogą być uruchamiane jednocześnie.

### Zadanie 3.1: Post-Processing Pipeline

**Typ**: 🟢 PARALLEL
**Czas**: ⏱️ ~25 min
**Zależności**: 🔗 Zadania 1.1, 2.2
**Agent**: `software-architect`

**Cel**: Orkiestracja dwuetapowego przetwarzania tekstu (punctuation + LLM).

**Pliki do utworzenia**:
1. `MySTT/PostProcessing/PostProcessor.swift`
2. `MySTT/PostProcessing/PunctuationCorrector.swift`

**Wymagania funkcjonalne**:

**PostProcessor** (orkiestrator):
1. Implementacja PostProcessorProtocol
2. Sekwencja: Dictionary preProcess → Stage 1 Punctuation → Stage 2 LLM → Dictionary postProcess
3. Opcjonalne etapy (kontrolowane przez AppSettings): punctuation on/off, LLM on/off, dictionary on/off
4. Early-exit: jeśli Stage 1 wystarczy (LLM wyłączony), zwróć wynik Stage 1
5. Error handling: jeśli LLM fail → zwróć wynik Stage 1 (graceful degradation)
6. Timing: loguj czas każdego etapu do console

**PunctuationCorrector**:
1. Wywołanie Python subprocess z punctuation_correct.py
2. Prefix <pl> lub <en> na podstawie Language
3. Timeout: 10s
4. Fallback: jeśli Python niedostępny, zwróć tekst bez zmian

**Kryteria sukcesu** ✅:
- [ ] Kompilacja bez błędów
- [ ] PostProcessor wykonuje etapy w prawidłowej kolejności
- [ ] Gdy LLM wyłączony → Stage 2 pominięte
- [ ] Gdy LLM fail → graceful degradation do Stage 1 output
- [ ] PunctuationCorrector dodaje prefix <pl>/<en> poprawnie
- [ ] Timing jest logowany

**Weryfikacja** 🔍:
```bash
xcodebuild -scheme MySTT -configuration Debug build 2>&1 | tail -5
grep -r "PostProcessorProtocol" MySTT/MySTT/PostProcessing/PostProcessor.swift
```

---

### Zadanie 3.2: Dictionary & Rules Engine

**Typ**: 🟢 PARALLEL
**Czas**: ⏱️ ~20 min
**Zależności**: 🔗 Zadanie 1.1
**Agent**: `software-architect`

**Cel**: Silnik słownikowy z regex rules i term replacements.

**Pliki do utworzenia**:
1. `MySTT/PostProcessing/DictionaryEngine.swift`
2. `MySTT/Resources/default_dictionary.json`

**Wymagania funkcjonalne**:

**DictionaryEngine**:
1. Ładowanie dictionary z ~/.mystt/dictionary.json (jeśli istnieje) lub z bundled default
2. `preProcess(_ text:)` - case-insensitive term replacement
3. `postProcess(_ text:)` - regex-based rules (spacing, capitalization)
4. `loadDictionary()` - ładowanie z pliku JSON
5. `saveDictionary()` - zapisywanie zmian (dla UI edytora)
6. `addTerm(key:value:)`, `removeTerm(key:)`
7. `getDictionaryTermsForPrompt() -> String` - formatowanie termów dla LLM prompt

**default_dictionary.json**:
1. Struktura z architecture.md §7.1 (terms, abbreviations, polish_terms)
2. Przynajmniej 15 termów technicznych
3. Przynajmniej 5 skrótów
4. Przynajmniej 5 polskich termów

**Kryteria sukcesu** ✅:
- [ ] Kompilacja bez błędów
- [ ] preProcess zamienia "kubernetes" na "Kubernetes" (case-insensitive)
- [ ] postProcess usuwa podwójne spacje
- [ ] default_dictionary.json jest poprawnym JSON
- [ ] Ładowanie z ~/.mystt/dictionary.json działa
- [ ] Fallback do bundled dictionary gdy user file nie istnieje

**Weryfikacja** 🔍:
```bash
xcodebuild -scheme MySTT -configuration Debug build 2>&1 | tail -5
python3 -c "import json; json.load(open('MySTT/MySTT/Resources/default_dictionary.json')); print('JSON OK')"
```

---

### Zadanie 3.3: Keychain Manager + Sound Player + Utilities

**Typ**: 🟢 PARALLEL
**Czas**: ⏱️ ~15 min
**Zależności**: 🔗 Zadanie 0.1
**Agent**: `software-architect`

**Cel**: Narzędzia pomocnicze: bezpieczne przechowywanie API keys, dźwięki.

**Pliki do utworzenia**:
1. `MySTT/Utilities/KeychainManager.swift`
2. `MySTT/Utilities/SoundPlayer.swift`

**Wymagania funkcjonalne**:

**KeychainManager**:
1. `save(key:value:)` - zapisanie API key w Keychain
2. `load(key:) -> String?` - odczytanie API key
3. `delete(key:)` - usunięcie API key
4. Service name: "com.mystt.apikeys"
5. Obsługa błędów Keychain (errSecItemNotFound, errSecDuplicateItem)

**SoundPlayer**:
1. `playStartRecording()` - krótki dźwięk rozpoczęcia nagrywania
2. `playStopRecording()` - krótki dźwięk zakończenia
3. `playSuccess()` - dźwięk sukcesu
4. `playError()` - dźwięk błędu
5. Użycie NSSound lub AudioServicesPlaySystemSound
6. Opcjonalne wyłączenie dźwięków (AppSettings.playSound)

**Kryteria sukcesu** ✅:
- [ ] Kompilacja bez błędów
- [ ] KeychainManager save/load/delete działa bez crash
- [ ] SoundPlayer nie crashuje gdy dźwięk niedostępny
- [ ] Obsługa errSecItemNotFound jest graceful

**Weryfikacja** 🔍:
```bash
xcodebuild -scheme MySTT -configuration Debug build 2>&1 | tail -5
grep -r "SecItemAdd\|SecItemCopyMatching\|SecItemDelete" MySTT/MySTT/Utilities/KeychainManager.swift
```

---

## FAZA 4: Warstwa UI (RÓWNOLEGŁA)

> Wymaga ukończenia FAZY 1 (modele) i częściowo FAZY 3 (settings). 2 zadania równoległe.

### Zadanie 4.1: Menu Bar View + Onboarding

**Typ**: 🟢 PARALLEL
**Czas**: ⏱️ ~25 min
**Zależności**: 🔗 Zadania 0.1, 1.1
**Agent**: `react-specialist` (UI patterns) lub `software-architect`

**Cel**: UI menu bar dropdown i onboarding flow.

**Pliki do utworzenia**:
1. `MySTT/UI/MenuBarView.swift`
2. `MySTT/UI/OnboardingView.swift`

**Wymagania funkcjonalne**:

**MenuBarView**:
1. Status indicator: Ready / Recording / Processing / Done / Error
2. Ostatnia transkrypcja (skrócona do 100 znaków)
3. Wykryty język (EN/PL)
4. Przycisk "Settings..." otwierający okno ustawień
5. Przycisk "Quit"
6. Informacja o wybranym providerze STT i LLM
7. Toggle: Enable/Disable MySTT

**OnboardingView**:
1. Krok 1: Uprawnienia mikrofonu (request + status)
2. Krok 2: Uprawnienia Accessibility (instrukcja + status check)
3. Krok 3: Wybór hotkey (domyślny: Right Option)
4. Krok 4: Wybór LLM provider (local/remote)
5. Krok 5: "Ready!" z przyciskiem "Start Using MySTT"
6. Automatyczne pokazanie przy pierwszym uruchomieniu

**Kryteria sukcesu** ✅:
- [ ] Kompilacja bez błędów
- [ ] MenuBarView renderuje się w menu bar dropdown
- [ ] Status indicator zmienia się z AppState
- [ ] Settings... otwiera okno Settings
- [ ] Quit zamyka aplikację
- [ ] OnboardingView ma 5 kroków z nawigacją Next/Back

**Weryfikacja** 🔍:
```bash
xcodebuild -scheme MySTT -configuration Debug build 2>&1 | tail -5
grep -r "MenuBarView\|OnboardingView" MySTT/MySTT/UI/
```

---

### Zadanie 4.2: Settings View (5 tabów)

**Typ**: 🟢 PARALLEL
**Czas**: ⏱️ ~30 min
**Zależności**: 🔗 Zadania 0.1, 1.1
**Agent**: `react-specialist` lub `software-architect`

**Cel**: Kompletny panel ustawień z 5 tabami.

**Pliki do utworzenia**:
1. `MySTT/UI/SettingsView.swift` - TabView wrapper
2. `MySTT/UI/GeneralSettingsTab.swift` - ogólne (launch at login, sounds, notifications)
3. `MySTT/UI/STTSettingsTab.swift` - STT provider, model selection
4. `MySTT/UI/LLMSettingsTab.swift` - LLM provider, model, API keys, "Test Connection"
5. `MySTT/UI/DictionarySettingsTab.swift` - edytor terminów, rules
6. `MySTT/UI/HotkeySettingsTab.swift` - wybór hotkey z KeyboardShortcuts recorder

**Wymagania funkcjonalne**:

**SettingsView**: TabView z 5 tabami, rozmiar 500x400

**GeneralSettingsTab**: Launch at login toggle, play sounds toggle, show notifications toggle, auto-paste toggle

**STTSettingsTab**: STTProvider picker, Whisper model picker (auto/small/large-v3-turbo), Deepgram API key (jeśli cloud)

**LLMSettingsTab**:
1. LLMProvider picker (dropdown z 5 opcjami)
2. Dynamiczne pola zależne od wybranego providera:
   - localMLX → model path, Python path
   - localOllama → model name, Ollama URL
   - grok → API key (secure field)
   - groq → API key (secure field)
   - openai → API key (secure field)
3. "Test Connection" button z wynikiem (success/fail + latency)
4. API keys przechowywane w Keychain (nie w UserDefaults)

**DictionarySettingsTab**: Lista terminów z add/remove, edycja rules, import/export JSON

**HotkeySettingsTab**: KeyboardShortcuts recorder, aktualny hotkey display

**Kryteria sukcesu** ✅:
- [ ] Kompilacja bez błędów
- [ ] 5 tabów renderuje się w Settings window
- [ ] LLM tab dynamicznie zmienia pola na podstawie wybranego providera
- [ ] API keys używają SecureField (nie TextField)
- [ ] Dictionary tab pozwala dodać/usunąć term
- [ ] Hotkey tab używa KeyboardShortcuts recorder

**Weryfikacja** 🔍:
```bash
xcodebuild -scheme MySTT -configuration Debug build 2>&1 | tail -5
# Sprawdź 5 tabów
grep -c "tabItem" MySTT/MySTT/UI/SettingsView.swift
# Oczekiwany: 5

# Sprawdź SecureField dla API keys
grep -r "SecureField" MySTT/MySTT/UI/LLMSettingsTab.swift
```

---

## FAZA 5: Pipeline end-to-end (SEKWENCYJNA)

> Wymaga ukończenia wszystkich poprzednich faz. To jest integracja wszystkiego.

### Zadanie 5.1: AppState + główny pipeline

**Typ**: 🔵 SEQUENTIAL
**Czas**: ⏱️ ~35 min
**Zależności**: 🔗 WSZYSTKIE poprzednie zadania (0.1, 1.1-1.4, 2.1-2.3, 3.1-3.3, 4.1-4.2)
**Agent**: `software-architect`

**Cel**: Połączenie wszystkich komponentów w działający pipeline.

**Pliki do utworzenia/modyfikacji**:
1. `MySTT/App/AppState.swift` - centralny state manager (pełna implementacja)
2. `MySTT/App/AppDelegate.swift` - lifecycle hooks
3. `MySTT/App/MySTTApp.swift` - aktualizacja z pełnym wiring

**Wymagania funkcjonalne**:

**AppState**:
1. Inicjalizacja wszystkich komponentów (audio, STT, LLM, postprocessor, paster, hotkey)
2. Published properties: isRecording, isProcessing, lastTranscription, detectedLanguage, statusMessage
3. `startRecording()` - uruchomienie pipeline nagrywania
4. `stopRecordingAndProcess()` - zatrzymanie + pełny pipeline:
   - Stop audio → STT → PostProcess → Auto-paste
5. Binding hotkey callbacks do start/stop recording
6. Error handling na każdym etapie z user-facing messages
7. Graceful degradation: jeśli LLM fail → wklej wynik Stage 1
8. Settings observation: zmiana providera → przeładowanie komponentu
9. Lazy model loading: WhisperKit ładowany przy pierwszym użyciu

**AppDelegate**:
1. `applicationDidFinishLaunching`: sprawdź uprawnienia, pokaż onboarding jeśli first launch
2. `applicationWillTerminate`: cleanup (zamknij audio engine, usuń CGEvent tap)

**MySTTApp**:
1. Aktualizacja MenuBarExtra z dynamicznym icon (mic/mic.fill na podstawie isRecording)
2. Environment objects wstrzyknięte do wszystkich widoków
3. Settings scene z pełnym SettingsView

**Kryteria sukcesu** ✅:
- [ ] Kompilacja bez błędów
- [ ] Aplikacja uruchamia się i pokazuje ikonę w menu bar
- [ ] Hotkey uruchamia nagrywanie (zmiana statusu)
- [ ] Pipeline: audio → STT → postprocess → paste wykonuje się bez crash
- [ ] Zmiana LLM providera w settings → nowy provider jest używany
- [ ] Graceful degradation działa (wyłącz LLM → paste raw STT)
- [ ] Onboarding pokazuje się przy pierwszym uruchomieniu

**Weryfikacja** 🔍:
```bash
# Kompilacja pełna
xcodebuild -scheme MySTT -configuration Debug build 2>&1 | tail -5

# Sprawdź że AppState łączy wszystkie komponenty
grep -r "AudioCaptureEngine\|WhisperKitEngine\|PostProcessor\|AutoPaster\|HotkeyManager" MySTT/MySTT/App/AppState.swift
# Oczekiwany: wszystkie 5 znalezione

# Sprawdź pipeline flow
grep -r "startRecording\|stopRecordingAndProcess\|transcribe\|process\|paste" MySTT/MySTT/App/AppState.swift
```

**Ryzyka** ⚠️:
- Integracja wielu async komponentów może powodować race conditions
- **Mitigacja** 🛡️: Użyj @MainActor dla AppState, Task groups dla sekwencyjnego pipeline, cancellation support

---

## FAZA 6: Skrypty Python + modele (SEKWENCYJNA)

### Zadanie 6.1: Skrypty Python i setup modeli

**Typ**: 🔵 SEQUENTIAL
**Czas**: ⏱️ ~20 min
**Zależności**: 🔗 Zadania 2.2, 3.1
**Agent**: `general-purpose`

**Cel**: Skrypty Python dla MLX inference i punctuation correction + script do pobierania modeli.

**Pliki do utworzenia**:
1. `Scripts/mlx_infer.py` - MLX inference helper
2. `Scripts/punctuation_correct.py` - byt5-text-correction wrapper
3. `Scripts/setup_models.sh` - pobieranie i setup modeli
4. `Scripts/requirements.txt` - Python dependencies
5. `Scripts/test_mlx.py` - test script dla MLX
6. `Scripts/test_punctuation.py` - test script dla punctuation

**Wymagania funkcjonalne**:

**mlx_infer.py**:
```
Usage: python3 mlx_infer.py --model <model_path> --prompt <text> --max-tokens 512 --temp 0.1
Output: corrected text to stdout
```
1. Ładowanie modelu mlx-lm
2. Generowanie odpowiedzi z parametrami
3. Tylko tekst na stdout (bez logów, debugów)
4. Error handling: model nie znaleziony, brak mlx-lm

**punctuation_correct.py**:
```
Usage: python3 punctuation_correct.py "<pl> tekst do poprawienia"
Output: poprawiony tekst to stdout
```
1. Użycie deepmultilingualpunctuation (prostsze niż byt5)
2. Fallback: jeśli deepmultilingualpunctuation niedostępne, użyj prostego regex
3. Prefix <pl>/<en> obsługiwany

**setup_models.sh**:
1. Sprawdź Python3 i pip3
2. Zainstaluj requirements.txt
3. Pobierz model MLX (mlx-community/Qwen2.5-3B-Instruct-4bit)
4. Pobierz model punctuation
5. Wyświetl podsumowanie (rozmiary, ścieżki)
6. Opcjonalnie: zainstaluj Ollama i pull qwen2.5:3b

**requirements.txt**:
```
mlx-lm>=0.19.0
deepmultilingualpunctuation>=1.0
transformers>=4.40.0
```

**Kryteria sukcesu** ✅:
- [ ] mlx_infer.py działa z zainstalowanym mlx-lm: `python3 Scripts/mlx_infer.py --model mlx-community/Qwen2.5-3B-Instruct-4bit --prompt "Fix: hello world" --max-tokens 50 --temp 0.1`
- [ ] punctuation_correct.py działa: `python3 Scripts/punctuation_correct.py "<en> hello world how are you"`
- [ ] setup_models.sh jest wykonywalny i nie ma błędów składni
- [ ] requirements.txt zawiera poprawne pakiety
- [ ] test_mlx.py przechodzi
- [ ] test_punctuation.py przechodzi

**Weryfikacja** 🔍:
```bash
# Sprawdź składnię Python
python3 -m py_compile Scripts/mlx_infer.py && echo "OK" || echo "FAIL"
python3 -m py_compile Scripts/punctuation_correct.py && echo "OK" || echo "FAIL"

# Sprawdź bash script
bash -n Scripts/setup_models.sh && echo "OK" || echo "FAIL"

# Test punctuation (jeśli dependencies zainstalowane)
python3 Scripts/punctuation_correct.py "<en> hello world how are you today" 2>/dev/null || echo "Dependencies needed"
```

---

## FAZA 7: Testy + QA (SEKWENCYJNA z elementami równoległymi)

### Zadanie 7.1: Unit Tests

**Typ**: 🟢 PARALLEL (3 podzadania mogą być równoległe)
**Czas**: ⏱️ ~30 min
**Zależności**: 🔗 Fazy 1-5
**Agent**: `test-automator`

**Cel**: Testy jednostkowe dla kluczowych komponentów.

**Pliki do utworzenia**:
1. `Tests/ModelsTests/LanguageTests.swift`
2. `Tests/ModelsTests/AppSettingsTests.swift`
3. `Tests/PostProcessingTests/DictionaryEngineTests.swift`
4. `Tests/PostProcessingTests/PostProcessorTests.swift`
5. `Tests/LLMProviderTests/LLMPromptBuilderTests.swift`
6. `Tests/LLMProviderTests/OpenAICompatibleClientTests.swift`

**Testy do napisania**:

**LanguageTests**:
- `test_initFromWhisperCode_english` → .english
- `test_initFromWhisperCode_polish` → .polish
- `test_initFromWhisperCode_unknown` → .unknown
- `test_initFromWhisperCode_enUS` → .english

**AppSettingsTests**:
- `test_codable_roundtrip` → encode → decode → equal
- `test_defaultValues` → sprawdź domyślne wartości
- `test_llmProvider_isLocal` → localMLX.isLocal == true, grok.isLocal == false

**DictionaryEngineTests**:
- `test_preProcess_caseInsensitive` → "kubernetes" → "Kubernetes"
- `test_preProcess_multipleTerms` → zamiana kilku terminów
- `test_postProcess_doubleSpaces` → "hello  world" → "hello world"
- `test_loadDefaultDictionary` → ładowanie bundled JSON
- `test_getDictionaryTermsForPrompt` → formatowany string

**PostProcessorTests**:
- `test_processWithLLMDisabled` → skip Stage 2
- `test_processWithLLMFail` → graceful degradation
- `test_fullPipeline` → Stage 1 + Stage 2 mock

**LLMPromptBuilderTests**:
- `test_buildSystemPrompt_english` → zawiera "English"
- `test_buildSystemPrompt_polish` → zawiera "Polish diacritical"
- `test_buildSystemPrompt_withDictionary` → zawiera termy

**Kryteria sukcesu** ✅:
- [ ] Wszystkie testy kompilują się
- [ ] Minimum 15 test cases
- [ ] Wszystkie testy przechodzą (zielone)
- [ ] Brak flaky tests

**Weryfikacja** 🔍:
```bash
xcodebuild test -scheme MySTT -destination 'platform=macOS' 2>&1 | grep -E "Test Suite|Tests|passed|failed"
# Oczekiwany: All tests passed
```

---

### Zadanie 7.2: Integration Test - End-to-End

**Typ**: 🔵 SEQUENTIAL
**Czas**: ⏱️ ~20 min
**Zależności**: 🔗 Zadanie 7.1 + Faza 5
**Agent**: `test-automator`

**Cel**: Test integracyjny pełnego pipeline (bez prawdziwego mikrofonu).

**Pliki do utworzenia**:
1. `Tests/IntegrationTests/PipelineIntegrationTests.swift`
2. `Tests/IntegrationTests/MockAudioProvider.swift`
3. `Tests/Fixtures/test_audio_en.wav` (lub generowany programowo)
4. `Tests/Fixtures/test_audio_pl.wav` (lub generowany programowo)

**Testy**:
- `test_fullPipeline_english` → mock audio → STT mock → postprocess → wynik po angielsku
- `test_fullPipeline_polish` → mock audio → STT mock → postprocess → wynik po polsku
- `test_pipeline_llmFallback` → LLM fail → graceful degradation
- `test_pipeline_noPostprocessing` → all post-processing disabled → raw STT output
- `test_settingsChange_switchProvider` → zmiana providera → nowy provider użyty

**Kryteria sukcesu** ✅:
- [ ] Wszystkie integration tests przechodzą
- [ ] Pipeline obsługuje oba języki
- [ ] Graceful degradation działa
- [ ] Provider switching działa

---

## FAZA 8: Build + Dystrybucja (SEKWENCYJNA)

### Zadanie 8.1: Build Configuration + DMG

**Typ**: 🔵 SEQUENTIAL
**Czas**: ⏱️ ~15 min
**Zależności**: 🔗 Fazy 1-7
**Agent**: `build-engineer`

**Cel**: Konfiguracja release build i dystrybucja.

**Pliki do utworzenia/modyfikacji**:
1. `Scripts/build_release.sh` - automatyczny build release
2. `Scripts/create_dmg.sh` - tworzenie DMG
3. Aktualizacja Xcode project: Release configuration, optimization flags

**Wymagania**:
1. Release build z optymalizacją -O
2. Strip debug symbols
3. Code signing (ad-hoc lub Developer ID)
4. DMG z drag-to-Applications UX
5. Readme w DMG z instrukcjami setup

**Kryteria sukcesu** ✅:
- [ ] `Scripts/build_release.sh` tworzy MySTT.app w build/
- [ ] App uruchamia się po dwukrotnym kliknięciu
- [ ] Rozmiar app < 60 MB (bez modeli)
- [ ] DMG tworzy się poprawnie

**Weryfikacja** 🔍:
```bash
bash Scripts/build_release.sh 2>&1 | tail -5
# Sprawdź rozmiar
du -sh build/Release/MySTT.app
# Oczekiwany: < 60 MB

# Sprawdź podpis
codesign --verify build/Release/MySTT.app && echo "Signed OK" || echo "Not signed"
```

---

## Analiza ryzyk globalnych

| # | Ryzyko | Prawdopodobieństwo | Wpływ | Mitigacja |
|---|---|---|---|---|
| R1 | WhisperKit API zmienia się między wersjami | Średnie | Wysoki | Pin konkretną wersję w SPM; sprawdź changelog przed update |
| R2 | Python subprocess wolny przy pierwszym wywołaniu (ładowanie modelu) | Wysokie | Średni | Warm-up przy starcie app; cache załadowanego modelu w background |
| R3 | CGEvent tap nie działa bez Accessibility | Pewne | Krytyczny | Onboarding z jasną instrukcją; check permission na starcie |
| R4 | Brak mikrofonu / uprawnienia odrzucone | Średnie | Krytyczny | Graceful error message; re-request permission button |
| R5 | Ollama nie uruchomione gdy local LLM wybrany | Wysokie | Średni | Auto-detect; notification z instrukcją "ollama serve" |
| R6 | Duże modele nie mieszczą się w RAM (8GB Mac) | Średnie | Wysoki | Auto-detect RAM; wybierz mniejszy model; warning w UI |
| R7 | Symulacja Cmd+V nie działa w niektórych app | Niskie | Średni | Fallback do AXUIElement; manual copy z notification |
| R8 | Rate limiting na remote APIs | Niskie | Niski | Exponential backoff; cache ostatnich wyników |
| R9 | Python nie zainstalowany na systemie użytkownika | Średnie | Wysoki | Bundled Python env; lub pomiń Stage 1 punctuation |
| R10 | WhisperKit model download fail (brak internetu) | Średnie | Wysoki | Retry z progress UI; offline fallback do mniejszego modelu |

---

## Mapa zależności zadań

```
Zadanie 0.1 (Xcode init)
    │
    ├──→ Zadanie 1.1 (Models)    ─┐
    ├──→ Zadanie 1.2 (Audio)      │
    ├──→ Zadanie 1.3 (Hotkey)     ├──→ FAZA 1 gotowa
    └──→ Zadanie 1.4 (Paste)     ─┘
              │
    ┌─────────┼─────────┐
    │         │         │
    ▼         ▼         ▼
  Zad 2.1   Zad 2.2   Zad 2.3    ──→ FAZA 2 gotowa
 (Whisper) (LLM x5) (Deepgram)
    │         │         │
    ├─────────┼─────────┘
    │         │
    ▼         ▼         ▼
  Zad 3.1   Zad 3.2   Zad 3.3    ──→ FAZA 3 gotowa
(Pipeline) (Dict)   (Keychain)
    │         │         │
    ├─────────┘         │
    │                   │
    ▼         ▼         │
  Zad 4.1   Zad 4.2 ◄──┘         ──→ FAZA 4 gotowa
(MenuBar) (Settings)
    │         │
    └────┬────┘
         │
         ▼
      Zad 5.1                     ──→ FAZA 5 (integration)
    (AppState)
         │
         ▼
      Zad 6.1                     ──→ FAZA 6 (Python scripts)
    (Scripts)
         │
    ┌────┼────┐
    ▼         ▼
  Zad 7.1   Zad 7.2              ──→ FAZA 7 (testy)
  (Unit)  (Integration)
         │
         ▼
      Zad 8.1                     ──→ FAZA 8 (build)
    (Release)
```

---

## Sesje Claude Code - optymalna kolejność uruchamiania

### Runda 1 (1 sesja)
```
Sesja A: Zadanie 0.1 (Xcode init)
```

### Runda 2 (4 sesje równoległe)
```
Sesja B: Zadanie 1.1 (Models + Protokoły)
Sesja C: Zadanie 1.2 (Audio Capture)
Sesja D: Zadanie 1.3 (Hotkey Manager)
Sesja E: Zadanie 1.4 (Auto-Paste)
```

### Runda 3 (3 sesje równoległe)
```
Sesja F: Zadanie 2.1 (WhisperKit STT)
Sesja G: Zadanie 2.2 (LLM Providers x5)
Sesja H: Zadanie 2.3 (Deepgram STT)
```

### Runda 4 (3 sesje równoległe)
```
Sesja I: Zadanie 3.1 (Post-Processing Pipeline)
Sesja J: Zadanie 3.2 (Dictionary Engine)
Sesja K: Zadanie 3.3 (Keychain + Utilities)
```

### Runda 5 (2 sesje równoległe)
```
Sesja L: Zadanie 4.1 (Menu Bar + Onboarding UI)
Sesja M: Zadanie 4.2 (Settings 5 tabów)
```

### Runda 6 (1 sesja)
```
Sesja N: Zadanie 5.1 (AppState + Pipeline Integration)
```

### Runda 7 (1 sesja)
```
Sesja O: Zadanie 6.1 (Python Scripts + Models)
```

### Runda 8 (2 sesje - Unit Tests równoległe, potem Integration)
```
Sesja P: Zadanie 7.1 (Unit Tests)
Sesja Q: Zadanie 7.2 (Integration Tests) ← po Sesji P
```

### Runda 9 (1 sesja)
```
Sesja R: Zadanie 8.1 (Build + DMG)
```

**Łączna liczba sesji**: 18 (ale dzięki równoległości: 9 rund)
**Maksymalna równoległość**: 4 sesje jednocześnie (Runda 2)

---

## Protokół weryfikacji każdego zadania

Każde zadanie musi przejść następującą pętlę weryfikacji:

```
┌─────────────────────────┐
│   Wykonaj zadanie       │
└──────────┬──────────────┘
           │
           ▼
┌─────────────────────────┐
│   Uruchom weryfikację   │
│   (kryteria sukcesu)    │
└──────────┬──────────────┘
           │
     ┌─────┴─────┐
     │            │
  PASS ✅     FAIL ❌
     │            │
     ▼            ▼
┌──────────┐  ┌──────────────────┐
│  Gotowe  │  │  Zidentyfikuj    │
│          │  │  błędy           │
└──────────┘  └──────┬───────────┘
                     │
                     ▼
              ┌──────────────────┐
              │  Napraw błędy    │
              └──────┬───────────┘
                     │
                     ▼
              ┌──────────────────┐
              │  Ponowna         │
              │  weryfikacja     │──── FAIL → powrót do "Napraw błędy"
              └──────┬───────────┘
                     │
                  PASS ✅
                     │
                     ▼
              ┌──────────────────┐
              │  Gotowe          │
              └──────────────────┘
```

**Zasady pętli**:
1. Maksymalnie 5 iteracji napraw-sprawdź na zadanie
2. Po 5 iteracjach → eskalacja do użytkownika z opisem problemu
3. Każda iteracja loguje: co było źle, co naprawiono, wynik ponownej weryfikacji
4. Weryfikacja musi obejmować WSZYSTKIE kryteria sukcesu (nie tylko to co wcześniej failowało)

---

## Instrukcja dla sesji Claude Code

Każda sesja Claude Code powinna rozpocząć się od:

```
1. Przeczytaj implementation-plan.md i znajdź swoje zadanie
2. Przeczytaj architecture.md dla kontekstu architektonicznego
3. Sprawdź zależności - czy poprzednie zadania są ukończone
4. Wykonaj zadanie zgodnie z wymaganiami
5. Uruchom weryfikację (wszystkie kryteria sukcesu)
6. Jeśli FAIL → napraw → ponowna weryfikacja → powtarzaj
7. Gdy wszystko PASS → zakończ sesję z raportem:
   - Status: DONE ✅
   - Pliki utworzone/zmodyfikowane
   - Czas wykonania
   - Uwagi/problemy napotkane
```
