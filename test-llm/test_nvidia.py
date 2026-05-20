#!/usr/bin/env python3
"""Test script for NVIDIA NIM API."""

import os
import requests

API_KEY = os.getenv("NVIDIA_API_KEY", "nv-your-key-here")

BASE_URL = "https://integrate.api.nvidia.com/v1/chat/completions"

MODELS = [
    "deepseek-ai/deepseek-r1",
    "nvidia/llama-3.1-nemotron-ultra-253b-v1",
    "nvidia/nemotron-3-super-120b-a12b",
    "meta/llama-3.1-405b-instruct",
    "qwen/qwen2.5-72b-instruct",
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
        print(f"  → {result[:100]}...")
    else:
        print(f"✗ {model}")
        print(f"  → {data.get('error', data)}")


if __name__ == "__main__":
    for model in MODELS:
        test_model(model)
