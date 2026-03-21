#!/usr/bin/env python3
"""Punctuation correction for MySTT. Outputs corrected text to stdout."""
import sys
import re


def simple_fallback(text):
    """Simple regex-based fallback when deepmultilingualpunctuation unavailable."""
    if not text:
        return text
    text = text[0].upper() + text[1:] if len(text) > 1 else text.upper()
    if text and text[-1] not in '.!?':
        text += '.'
    text = re.sub(r'\s{2,}', ' ', text)
    return text


def main():
    if len(sys.argv) < 2:
        print("Usage: punctuation_correct.py '<lang> text to correct'", file=sys.stderr)
        sys.exit(1)

    raw_input = " ".join(sys.argv[1:])

    lang = "en"
    text = raw_input
    if raw_input.startswith("<pl>"):
        lang = "pl"
        text = raw_input[4:].strip()
    elif raw_input.startswith("<en>"):
        lang = "en"
        text = raw_input[4:].strip()

    if not text.strip():
        print("", end="")
        return

    try:
        from deepmultilingualpunctuation import PunctuationModel
        model = PunctuationModel()
        result = model.restore_punctuation(text)
        print(result, end="")
    except ImportError:
        print(simple_fallback(text), end="")
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        print(simple_fallback(text), end="")


if __name__ == "__main__":
    main()
