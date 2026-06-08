#!/usr/bin/env python3
"""Tiny test script to check if the remote server works."""
import requests
import sys

def test_server():
    url = "http://localhost:8898/v1/models"
    try:
        resp = requests.get(url, timeout=10)
        print(f"✓ Health check: {resp.status_code}")
        print(f"  Models: {resp.json().get('data', [])[:2]}")
        return True
    except requests.exceptions.ConnectionError:
        print("✗ Connection failed")
        return False

def test_chat():
    url = "http://localhost:8898/v1/chat/completions"
    payload = {
        "model": "unsloth/Qwen3.6-35B-A3B-UD-MLX-4bit",
        "messages": [{"role": "user", "content": "Hello!"}],
        "max_tokens": 50,
        "temperature": 0.7
    }
    try:
        resp = requests.post(url, json=payload, timeout=30)
        print(f"✓ Chat response: {resp.status_code}")
        if resp.status_code == 200:
            data = resp.json()
            print(f"  Response: {data['choices'][0]['message']['content'][:100]}...")
            return True
        else:
            print(f"  Error: {resp.text[:200]}")
            return False
    except Exception as e:
        print(f"✗ Chat failed: {e}")
        return False

if __name__ == "__main__":
    print("Testing remote server...")
    if test_server():
        print("\nRunning chat test...")
        test_chat()
        sys.exit(0)
    sys.exit(1)
