#!/usr/bin/env python3
"""Test script for Cerebras LLM API."""

import os
from openai import OpenAI

API_KEY = os.getenv("CEREBRAS_API_KEY", "your-api-key-here")
BASE_URL = "https://api.cerebras.ai/v1"


def test_cerebras():
    client = OpenAI(api_key=API_KEY, base_url=BASE_URL)

    response = client.chat.completions.create(
        model="llama3.1-8b",
        messages=[
            {"role": "system", "content": "You are a helpful assistant."},
            {"role": "user", "content": "Say hello in one sentence."},
        ],
        max_tokens=50,
    )

    print(f"Model: {response.model}")
    print(f"Response: {response.choices[0].message.content}")
    print(f"Usage: {response.usage}")


if __name__ == "__main__":
    test_cerebras()
