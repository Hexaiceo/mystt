#!/usr/bin/env python3
"""Test punctuation_correct.py"""
import subprocess
import sys
import os

SCRIPT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "punctuation_correct.py")


def test(input_text, expected_contains=None):
    result = subprocess.run(
        [sys.executable, SCRIPT, input_text],
        capture_output=True, text=True, timeout=30
    )
    output = result.stdout.strip()
    status = "PASS" if output else "FAIL (empty)"
    if expected_contains and expected_contains.lower() not in output.lower():
        status = f"FAIL (expected '{expected_contains}' in '{output}')"
    print(f"  Input: {input_text}")
    print(f"  Output: {output}")
    print(f"  Status: {status}")
    return "PASS" in status


tests_passed = 0
tests_total = 0

print("=== Punctuation Correction Tests ===")

tests_total += 1
if test("<en> hello world how are you today", "hello"):
    tests_passed += 1

tests_total += 1
if test("<pl> witaj swiecie jak sie masz", "witaj"):
    tests_passed += 1

tests_total += 1
if test("this is a test", "this"):
    tests_passed += 1

tests_total += 1
result = subprocess.run([sys.executable, SCRIPT, "<en> "], capture_output=True, text=True, timeout=10)
if result.returncode == 0:
    tests_passed += 1
    print("  Empty input: PASS")

print(f"\n=== Results: {tests_passed}/{tests_total} passed ===")
sys.exit(0 if tests_passed == tests_total else 1)
