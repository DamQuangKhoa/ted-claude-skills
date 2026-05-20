#!/usr/bin/env python3
"""Test script for OpenRouter API."""

import os
import requests

API_KEY = os.getenv(
    "OPENROUTER_API_KEY",
    "your-api-key-here",
)

BASE_URL = "https://openrouter.ai/api/v1/chat/completions"

MODELS = [
    "deepseek/deepseek-r1",
    "deepseek/deepseek-chat-v3-0324",
    "qwen/qwen3.6-plus",
    "meta-llama/llama-4-scout:free",
    "meta-llama/llama-3.3-70b-instruct:free",
    "google/gemma-4-31b-it:free",
    "nvidia/nemotron-3-super-120b-a12b:free",
    "openai/gpt-oss-120b:free",
    "minimax/minimax-m2.5:free",
]


def test_model(model):
    headers = {
        "Authorization": f"Bearer {API_KEY}",
        "Content-Type": "application/json",
        "HTTP-Referer": "https://test.local",
        "X-Title": "Test",
    }

    payload = {
        "model": model,
        "messages": [{"role": "user", "content": "Say hello in one sentence."}],
        "max_tokens": 50,
    }

    response = requests.post(BASE_URL, headers=headers, json=payload)
    data = response.json()

    if "choices" in data and data["choices"]:
        result = data["choices"][0].get("message", {}).get("content")
        if result:
            print(f"✓ {model}")
            print(f"  → {result[:100]}")
        else:
            print(f"✗ {model} (empty response)")
    else:
        print(f"✗ {model}")
        print(f"  → {data.get('error', data)}")


if __name__ == "__main__":
    for model in MODELS:
        test_model(model)
