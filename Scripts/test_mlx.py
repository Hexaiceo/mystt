#!/usr/bin/env python3
"""Test mlx_infer.py (syntax check only - model download is slow)"""
import subprocess
import sys
import os

SCRIPT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "mlx_infer.py")

print("=== MLX Inference Tests ===")

print("Test 1: Python syntax check...")
result = subprocess.run([sys.executable, "-m", "py_compile", SCRIPT], capture_output=True, text=True)
if result.returncode == 0:
    print("  PASS: Syntax OK")
else:
    print(f"  FAIL: {result.stderr}")
    sys.exit(1)

print("Test 2: --help flag...")
result = subprocess.run([sys.executable, SCRIPT, "--help"], capture_output=True, text=True)
if result.returncode == 0 and "--model" in result.stdout:
    print("  PASS: Help shows --model flag")
else:
    print("  FAIL: Help not working")
    sys.exit(1)

print("Test 3: Missing required args...")
result = subprocess.run([sys.executable, SCRIPT], capture_output=True, text=True)
if result.returncode != 0:
    print("  PASS: Correctly fails without args")
else:
    print("  FAIL: Should fail without args")
    sys.exit(1)

print("\n=== All tests passed ===")
