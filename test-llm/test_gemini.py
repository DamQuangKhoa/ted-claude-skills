#!/usr/bin/env python3
"""Test script for Google Gemini API."""

import os
from openai import OpenAI

API_KEY = os.getenv("GEMINI_API_KEY", "your-api-key-here")


def test_gemini():
    client = OpenAI(
        api_key=API_KEY, base_url="https://generativelanguage.googleapis.com/v1beta"
    )

    response = client.chat.completions.create(
        model="gemini-2.5-flash",
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
    test_gemini()
