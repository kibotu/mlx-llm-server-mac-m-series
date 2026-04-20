#!/usr/bin/env bash
# MLX server runner - downloads models, starts server, recovers from crashes

set -euo pipefail

# Config
MODEL="${MODEL:-mlx-community/Qwen3.5-9B-MLX-4bit}"
PORT="${PORT:-8898}"
TEMP="${TEMP:-0.7}"
PROMPT_CONC="${PROMPT_CONC:-2}"
DECODE_CONC="${DECODE_CONC:-2}"
MAX_RETRIES=5
RETRY_DELAY=5

CACHE_DIR="$HOME/.cache/mlx-community"
MODEL_CACHE="$CACHE_DIR/$MODEL"
LOG_FILE="$HOME/.cache/mlx-server.log"

SERVER_PID=""
REQUEST_COUNT=0

log() { echo "[$(date +%H:%M:%S)] $*" | tee -a "$LOG_FILE"; }
die() { log "ERROR: $*"; exit 1; }

# System info logging
log_system_info() {
    local total_mem used_mem wired_mem
    total_mem=$(sysctl -n hw.memsize | awk '{print int($1/1024/1024/1024)"GB"}')
    used_mem=$(vm_stat | awk '/Pages active/ {print int($3*4096/1024/1024/1024)"GB"}')
    wired_mem=$(vm_stat | awk '/Pages wired/ {print int($4*4096/1024/1024/1024)"GB"}')

    log "System: $(sw_vers -productName) $(sw_vers -productVersion)"
    log "Hardware: $(sysctl -n machdep.cpu.brand_string)"
    log "Memory: $total_mem total, $used_mem active, $wired_mem wired"
    log "Model size: $(du -sh "$MODEL_CACHE" 2>/dev/null | awk '{print $1}' || echo 'not cached')"
}

# Memory monitoring
log_memory() {
    [[ -n "$SERVER_PID" ]] && kill -0 "$SERVER_PID" 2>/dev/null || return

    local rss vsz wired
    rss=$(ps -o rss= -p "$SERVER_PID" 2>/dev/null | awk '{print int($1/1024)"MB"}' || echo "N/A")
    vsz=$(ps -o vsz= -p "$SERVER_PID" 2>/dev/null | awk '{print int($1/1024)"MB"}' || echo "N/A")
    wired=$(vm_stat | awk '/Pages wired/ {print int($4*4096/1024/1024/1024)"GB"}')

    log "Memory - RSS: $rss, VSZ: $vsz, Wired: $wired"
}

# Request counter
monitor_requests() {
    kill -0 "$SERVER_PID" 2>/dev/null || return

    local new_count
    # Use awk to count and ensure single numeric output
    new_count=$(grep 'POST.*chat/completions.*200' "$LOG_FILE" 2>/dev/null | wc -l | tr -d ' ' || echo 0)

    # Ensure it's a valid number
    [[ "$new_count" =~ ^[0-9]+$ ]] || new_count=0

    if [[ $new_count -gt $REQUEST_COUNT ]]; then
        local diff=$((new_count - REQUEST_COUNT))
        REQUEST_COUNT=$new_count
        log "Requests: +$diff (total: $REQUEST_COUNT)"
        log_memory
    fi
}

# Cleanup on exit
cleanup() {
    log "Shutting down"
    [[ -n "$SERVER_PID" ]] && kill -TERM "$SERVER_PID" 2>/dev/null || true
    free_port
    log "Total requests served: $REQUEST_COUNT"
}

# Kill anything on our port
free_port() {
    local pids
    pids=$(lsof -ti:"$PORT" 2>/dev/null || true)
    [[ -z "$pids" ]] && return

    log "Freeing port $PORT (PIDs: $pids)"
    kill -9 $pids 2>/dev/null || true
    sleep 1
}

# Download model if missing
ensure_model() {
    [[ -d "$MODEL_CACHE" && -n "$(ls -A "$MODEL_CACHE" 2>/dev/null)" ]] && return

    log "Downloading $MODEL"
    mkdir -p "$CACHE_DIR"

    local files=(
        "config.json"
        "model-00001-of-00003.safetensors"
        "model-00002-of-00003.safetensors"
        "model-00003-of-00003.safetensors"
        "tokenizer.json"
        "tokenizer_config.json"
    )

    for f in "${files[@]}"; do
        log "  $f"
        uv run python3 -c "
from huggingface_hub import hf_hub_download
hf_hub_download('$MODEL', '$f', cache_dir='$MODEL_CACHE', local_dir_use_symlinks=False)
" || die "Download failed: $f"
    done

    log "Download complete: $(du -sh "$MODEL_CACHE" | awk '{print $1}')"
}

# Setup Python environment
setup_env() {
    command -v uv >/dev/null || die "uv not found - install from https://docs.astral.sh/uv"
    uv sync --quiet 2>/dev/null || uv pip install -q mlx-lm huggingface_hub
}

# Health check endpoint test
health_check() {
    local retries=10
    for i in $(seq 1 $retries); do
        if curl -s "http://localhost:$PORT/health" >/dev/null 2>&1 || \
           curl -s "http://localhost:$PORT/v1/models" >/dev/null 2>&1; then
            log "Server healthy (attempt $i/$retries)"
            return 0
        fi
        sleep 1
    done
    log "WARN: Health check failed after $retries attempts"
    return 1
}

# Start the server
run_server() {
    log "Starting server (attempt $i/$MAX_RETRIES)"
    log "Port: $PORT | Temp: $TEMP | Concurrency: P=$PROMPT_CONC D=$DECODE_CONC"
    log "Endpoint: http://localhost:$PORT/v1/chat/completions"

    uv run mlx_lm.server \
        --model "$MODEL" \
        --host 0.0.0.0 \
        --port "$PORT" \
        --temp "$TEMP" \
        --prompt-concurrency "$PROMPT_CONC" \
        --decode-concurrency "$DECODE_CONC" &

    SERVER_PID=$!
    sleep 3

    if kill -0 "$SERVER_PID" 2>/dev/null; then
        log "Server started (PID: $SERVER_PID)"
        log_memory
        health_check

        # Monitor loop
        while kill -0 "$SERVER_PID" 2>/dev/null; do
            monitor_requests
            sleep 30
        done
    fi
}

main() {
    log "========================================"
    log "MLX Server Starting"
    log "========================================"
    log_system_info

    # Kill any existing instance first
    free_port

    setup_env
    ensure_model

    # Restart loop
    for i in $(seq 1 $MAX_RETRIES); do
        run_server || log "Server crashed, retrying in ${RETRY_DELAY}s"
        SERVER_PID=""
        sleep "$RETRY_DELAY"
    done

    die "Failed after $MAX_RETRIES attempts"
}

trap cleanup EXIT INT TERM
main "$@"