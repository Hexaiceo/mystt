#!/usr/bin/env python3
"""MLX inference helper for MySTT. Outputs corrected text to stdout."""
import argparse
import sys

def main():
    parser = argparse.ArgumentParser(description="MLX LLM inference")
    parser.add_argument("--model", required=True, help="Model path (e.g., mlx-community/Qwen2.5-3B-Instruct-4bit)")
    parser.add_argument("--prompt", required=True, help="Text prompt")
    parser.add_argument("--max-tokens", type=int, default=512, help="Max output tokens")
    parser.add_argument("--temp", type=float, default=0.1, help="Temperature")
    args = parser.parse_args()

    try:
        from mlx_lm import load, generate
    except ImportError:
        print("Error: mlx-lm not installed. Run: pip3 install mlx-lm", file=sys.stderr)
        sys.exit(1)

    try:
        model, tokenizer = load(args.model)
        response = generate(
            model, tokenizer,
            prompt=args.prompt,
            max_tokens=args.max_tokens,
            temp=args.temp,
            verbose=False
        )
        # Output only the generated text
        print(response, end="")
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
