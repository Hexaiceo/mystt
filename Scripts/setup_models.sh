#!/bin/bash
set -e

echo "=== MySTT Model Setup ==="

if ! command -v python3 &> /dev/null; then
    echo "ERROR: python3 not found. Install Python 3.10+."
    exit 1
fi
echo "Python: $(python3 --version)"

if ! command -v pip3 &> /dev/null; then
    echo "ERROR: pip3 not found."
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
echo "Installing Python requirements..."
pip3 install -r "$SCRIPT_DIR/requirements.txt"

echo ""
echo "Downloading MLX model (Qwen2.5-3B-Instruct-4bit)..."
python3 -c "from mlx_lm import load; load('mlx-community/Qwen2.5-3B-Instruct-4bit'); print('MLX model ready.')"

echo ""
echo "Downloading punctuation model..."
python3 -c "from deepmultilingualpunctuation import PunctuationModel; PunctuationModel(); print('Punctuation model ready.')"

echo ""
echo "--- Optional: Ollama ---"
if command -v ollama &> /dev/null; then
    echo "Ollama found. Pulling qwen2.5:3b..."
    ollama pull qwen2.5:3b
else
    echo "Ollama not installed. To install: brew install ollama"
fi

echo ""
echo "=== Setup Complete ==="
