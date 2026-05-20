#!/usr/bin/env python3
"""Test script for Groq LLM API."""

import os
import requests

API_KEY = os.getenv("GROQ_API_KEY", "your-api-key-here")

BASE_URL = "https://api.groq.com/openai/v1/chat/completions"

MODELS = [
    "llama-3.3-70b-versatile",
    "llama-4-scout-17b-16e-instruct",
    "qwen3-32b",
    "deepseek-r1-distill-70b",
    "kimi-k2-instruct",
]


def test_model(model):
    headers = {"Authorization": f"Bearer {API_KEY}", "Content-Type": "application/json"}

    payload = {
        "model": model,
        "messages": [{"role": "user", "content": "Say hello in one sentence."}],
        "max_tokens": 50,
    }

    response = requests.post(BASE_URL, headers=headers, json=payload)
    data = response.json()

    if "choices" in data:
        result = data["choices"][0]["message"]["content"]
        print(f"✓ {model}")
        print(f"  → {result}")
    else:
        print(f"✗ {model}")
        print(f"  → {data.get('error', data)}")


if __name__ == "__main__":
    for model in MODELS:
        test_model(model)
