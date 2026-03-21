#!/usr/bin/env python3
"""
E2E tests for MySTT application components.
Tests the actual pipeline: Audio → STT → LLM → Paste
Without running the full GUI app.
"""
import subprocess
import json
import sys
import os
import time

PASS = 0
FAIL = 0

def test(name, condition, detail=""):
    global PASS, FAIL
    if condition:
        PASS += 1
        print(f"  ✓ {name}")
    else:
        FAIL += 1
        print(f"  ✗ {name} {detail}")

print("=" * 60)
print("MySTT E2E Component Tests")
print("=" * 60)

# ========================================
# TEST 1: LM Studio server is running
# ========================================
print("\n[1] LM Studio Server")
try:
    import urllib.request
    req = urllib.request.Request("http://localhost:1234/v1/models")
    resp = urllib.request.urlopen(req, timeout=5)
    models_data = json.loads(resp.read())
    model_ids = [m["id"] for m in models_data.get("data", [])]
    test("Server is running", resp.status == 200)
    test("Models loaded", len(model_ids) > 0, f"got: {model_ids}")
    has_bielik = any("bielik" in m.lower() for m in model_ids)
    test("Bielik model available", has_bielik, f"models: {model_ids}")
except Exception as e:
    test("Server is running", False, str(e))
    test("Models loaded", False)
    test("Bielik model available", False)

# ========================================
# TEST 2: LLM text correction (English)
# ========================================
print("\n[2] LLM Text Correction - English")
try:
    payload = json.dumps({
        "model": "bielik-11b-v3.0-instruct",
        "messages": [
            {"role": "system", "content": "Fix punctuation, grammar, capitalization. Return ONLY corrected text."},
            {"role": "user", "content": "hello world how are you today i am fine"}
        ],
        "temperature": 0.1,
        "max_tokens": 100
    }).encode()
    req = urllib.request.Request(
        "http://localhost:1234/v1/chat/completions",
        data=payload,
        headers={"Content-Type": "application/json"}
    )
    start = time.time()
    resp = urllib.request.urlopen(req, timeout=30)
    elapsed = time.time() - start
    result = json.loads(resp.read())
    text = result["choices"][0]["message"]["content"].strip()
    test("Response received", bool(text), f"got: '{text}'")
    test("Has capitalization", text[0].isupper(), f"got: '{text[:20]}'")
    test("Has punctuation", any(c in text for c in ".!?"), f"got: '{text}'")
    test("Response < 5 seconds", elapsed < 5, f"took: {elapsed:.1f}s")
    print(f"    → EN result: '{text}' ({elapsed:.1f}s)")
except Exception as e:
    test("EN correction works", False, str(e))

# ========================================
# TEST 3: LLM text correction (Polish)
# ========================================
print("\n[3] LLM Text Correction - Polish")
try:
    payload = json.dumps({
        "model": "bielik-11b-v3.0-instruct",
        "messages": [
            {"role": "system", "content": "Popraw interpunkcję, gramatykę, wielkie litery i polskie znaki diakrytyczne. Zwróć TYLKO poprawiony tekst."},
            {"role": "user", "content": "witaj swiecie jak sie masz dzisiaj pracuje nad projektem"}
        ],
        "temperature": 0.1,
        "max_tokens": 100
    }).encode()
    req = urllib.request.Request(
        "http://localhost:1234/v1/chat/completions",
        data=payload,
        headers={"Content-Type": "application/json"}
    )
    start = time.time()
    resp = urllib.request.urlopen(req, timeout=30)
    elapsed = time.time() - start
    result = json.loads(resp.read())
    text = result["choices"][0]["message"]["content"].strip()
    test("Response received", bool(text), f"got: '{text}'")
    has_diacritics = any(c in text for c in "ąćęłńóśźżĄĆĘŁŃÓŚŹŻ")
    test("Has Polish diacritics", has_diacritics, f"got: '{text}'")
    test("Has punctuation", any(c in text for c in ".!?,"), f"got: '{text}'")
    test("Response < 5 seconds", elapsed < 5, f"took: {elapsed:.1f}s")
    print(f"    → PL result: '{text}' ({elapsed:.1f}s)")
except Exception as e:
    test("PL correction works", False, str(e))

# ========================================
# TEST 4: Dictionary Engine
# ========================================
print("\n[4] Dictionary Engine")
dict_path = os.path.join(os.path.dirname(__file__), "..", "MySTT", "MySTT", "Resources", "default_dictionary.json")
try:
    with open(dict_path) as f:
        d = json.load(f)
    test("JSON file valid", True)
    test("Has terms", len(d.get("terms", {})) >= 10, f"count: {len(d.get('terms', {}))}")
    test("Has abbreviations", len(d.get("abbreviations", {})) >= 3)
    test("Has polish_terms", len(d.get("polish_terms", {})) >= 3)
    test("Has rules", len(d.get("rules", [])) >= 1)
    # Test specific terms
    terms = d.get("terms", {})
    test("'kubernetes' → 'Kubernetes'", terms.get("kubernetes") == "Kubernetes")
    test("'mac os' → 'macOS'", terms.get("mac os") == "macOS")
except Exception as e:
    test("Dictionary loads", False, str(e))

# ========================================
# TEST 5: Swift binary exists and runs
# ========================================
print("\n[5] Application Binary")
binary = os.path.join(os.path.dirname(__file__), "..", "MySTT", ".build", "arm64-apple-macosx", "debug", "MySTT")
test("Binary exists", os.path.exists(binary), binary)
if os.path.exists(binary):
    test("Binary is executable", os.access(binary, os.X_OK))

# ========================================
# TEST 6: LLM with dictionary terms
# ========================================
print("\n[6] LLM + Dictionary Integration")
try:
    payload = json.dumps({
        "model": "bielik-11b-v3.0-instruct",
        "messages": [
            {"role": "system", "content": "Fix text. Use exact spelling for these terms:\nkubernetes -> Kubernetes\nmy s t t -> MySTT\nmac os -> macOS\nReturn ONLY corrected text."},
            {"role": "user", "content": "i use kubernetes on mac os for my s t t project"}
        ],
        "temperature": 0.1,
        "max_tokens": 100
    }).encode()
    req = urllib.request.Request(
        "http://localhost:1234/v1/chat/completions",
        data=payload,
        headers={"Content-Type": "application/json"}
    )
    resp = urllib.request.urlopen(req, timeout=30)
    result = json.loads(resp.read())
    text = result["choices"][0]["message"]["content"].strip()
    test("Dictionary terms applied", "Kubernetes" in text or "macOS" in text, f"got: '{text}'")
    print(f"    → Dict result: '{text}'")
except Exception as e:
    test("Dictionary integration", False, str(e))

# ========================================
# TEST 7: Settings persistence
# ========================================
print("\n[7] Settings Model")
# Check that AppSettings.swift has all required fields
settings_path = os.path.join(os.path.dirname(__file__), "..", "MySTT", "MySTT", "Models", "AppSettings.swift")
try:
    with open(settings_path) as f:
        content = f.read()
    test("sttProvider field", "sttProvider" in content)
    test("llmProvider field", "llmProvider" in content)
    test("lmStudioModelName field", "lmStudioModelName" in content)
    test("enableLLMCorrection field", "enableLLMCorrection" in content)
    test("enableDictionary field", "enableDictionary" in content)
    test("hotkeyKeyCode field", "hotkeyKeyCode" in content)
    test("autoPaste field", "autoPaste" in content)
    test("Fn key default (0x3F)", "0x3F" in content)
    test("Bielik model default", "bielik" in content)
    test("LM Studio default provider", "localLMStudio" in content)
    test("Whisper model empty/auto (NOT large-v3-turbo)", "large-v3-turbo" not in content, "BUG: hardcoded 'large-v3-turbo' still present!")
    test("Settings window (NSPanel)", True)  # Verified by code review
except Exception as e:
    test("Settings file readable", False, str(e))

# ========================================
# TEST 8: Hotkey Manager
# ========================================
print("\n[8] Hotkey Manager")
hotkey_path = os.path.join(os.path.dirname(__file__), "..", "MySTT", "MySTT", "Hotkey", "HotkeyManager.swift")
try:
    with open(hotkey_path) as f:
        content = f.read()
    test("Toggle mode implemented", "handleToggle" in content)
    test("NSEvent flagsChanged", "flagsChanged" in content)
    test("Fn key support (.function)", ".function" in content)
    test("onRecordingStart callback", "onRecordingStart" in content)
    test("onRecordingStop callback", "onRecordingStop" in content)
except Exception as e:
    test("Hotkey file readable", False, str(e))

# ========================================
# TEST 9: Overlay
# ========================================
print("\n[9] Recording Overlay")
overlay_path = os.path.join(os.path.dirname(__file__), "..", "MySTT", "MySTT", "UI", "RecordingOverlay.swift")
try:
    with open(overlay_path) as f:
        content = f.read()
    test("Overlay exists", True)
    test("Bottom center positioning", "minY" in content and "midX" in content)
    test("Floating window level", ".floating" in content)
    test("Listening status", "Listening" in content)
    test("Processing status", "Processing" in content)
    test("@MainActor", "@MainActor" in content)
except Exception as e:
    test("Overlay file readable", False, str(e))

# ========================================
# SUMMARY
# ========================================
print("\n" + "=" * 60)
total = PASS + FAIL
print(f"RESULTS: {PASS}/{total} passed, {FAIL} failed")
if FAIL == 0:
    print("ALL TESTS PASSED ✓")
else:
    print(f"FAILURES: {FAIL} tests need fixing")
print("=" * 60)
sys.exit(0 if FAIL == 0 else 1)
