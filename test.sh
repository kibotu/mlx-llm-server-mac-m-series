#!/usr/bin/env bash
# Test script for MLX API server
set -euo pipefail

API_URL="${API_URL:-http://localhost:8898/v1/chat/completions}"

log() {
    echo "[$(date +%H:%M:%S)] $*"
}

test_health() {
    log "Testing health endpoint..."
    local resp
    resp=$(curl -s "http://localhost:8898/v1/models" 2>&1)
    
    if echo "$resp" | grep -q '"data"'; then
        log "✓ Health check passed"
        return 0
    else
        log "✗ Health check failed: $resp"
        return 1
    fi
}

test_chat() {
    log "Testing chat endpoint..."
    local resp
    resp=$(curl -s -X POST "$API_URL" \
        -H "Content-Type: application/json" \
        -d '{
            "model": "unsloth/Qwen3.6-35B-A3B-UD-MLX-4bit",
            "messages": [{"role": "user", "content": "Hello, how are you?"}],
            "max_tokens": 50,
            "temperature": 0.7
        }' 2>&1)
    
    if echo "$resp" | grep -q '"choices"'; then
        log "✓ Chat endpoint working"
        echo "$resp" | python3 -c "import sys,json; d=json.load(sys.stdin); print('Response:', d['choices'][0]['message']['content'][:100])" 2>/dev/null
        return 0
    else
        log "✗ Chat endpoint failed: $resp"
        return 1
    fi
}

main() {
    log "Starting API test..."
    
    if ! test_health; then
        log "ERROR: Health check failed - server may not be running"
        exit 1
    fi
    
    if test_chat; then
        log "All tests passed!"
        exit 0
    else
        log "ERROR: Chat test failed"
        exit 1
    fi
}

main "$@"
