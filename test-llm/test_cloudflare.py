#!/usr/bin/env python3
"""Test script for Cloudflare Workers AI."""

import os
import requests

ACCOUNT_ID = os.getenv("CLOUDFLARE_ACCOUNT_ID", "your-account-id")
API_KEY = os.getenv("CLOUDFLARE_API_KEY", "your-api-key")

BASE_URL = f"https://api.cloudflare.com/client/v4/accounts/{ACCOUNT_ID}/ai/run"

MODELS = [
    "@cf/meta/llama-4-scout-17b-16e-instruct",
    "@cf/meta/llama-3.3-70b-instruct-fp8-fast",
    "@cf/deepseek-ai/deepseek-r1-distill-qwen-32b",
    "@cf/qwen/qwq-32b",
    "@cf/google/gemma-4-26b-a4b-it",
    "@cf/mistralai/mistral-small-3.1-24b-instruct",
]


def test_model(model):
    url = f"{BASE_URL}/{model}"

    headers = {"Authorization": f"Bearer {API_KEY}", "Content-Type": "application/json"}

    payload = {
        "messages": [{"role": "user", "content": "Say hello in one sentence."}],
        "max_tokens": 50,
    }

    response = requests.post(url, headers=headers, json=payload)
    data = response.json()

    if data.get("success") and "response" in data.get("result", {}):
        print(f"✓ {model}")
        print(f"  → {data['result']['response']}")
    else:
        print(f"✗ {model}")
        print(f"  → {data.get('errors', data.get('result', {}))}")


if __name__ == "__main__":
    for model in MODELS:
        test_model(model)
