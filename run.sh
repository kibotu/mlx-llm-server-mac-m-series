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

log() { echo "[$(date +%H:%M:%S)] $*" | tee -a "$LOG_FILE"; }
die() { log "ERROR: $*"; exit 1; }

# Cleanup on exit
cleanup() {
    log "Shutting down"
    [[ -n "$SERVER_PID" ]] && kill -TERM "$SERVER_PID" 2>/dev/null || true
    free_port
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
}

# Setup Python environment
setup_env() {
    command -v uv >/dev/null || die "uv not found - install from https://docs.astral.sh/uv"
    uv sync --quiet 2>/dev/null || uv pip install -q mlx-lm huggingface_hub
}

# Start the server
run_server() {
    log "Starting on port $PORT (temp=$TEMP, model=$MODEL)"
    uv run mlx_lm.server \
        --model "$MODEL" \
        --host 0.0.0.0 \
        --port "$PORT" \
        --temp "$TEMP" \
        --prompt-concurrency "$PROMPT_CONC" \
        --decode-concurrency "$DECODE_CONC" &

    SERVER_PID=$!
    wait "$SERVER_PID"
}

main() {
    log "MLX Server"

    # Kill any existing instance first
    free_port

    setup_env
    ensure_model

    # Restart loop
    for i in $(seq 1 $MAX_RETRIES); do
        log "Attempt $i/$MAX_RETRIES"
        run_server || log "Crashed, retrying in ${RETRY_DELAY}s"
        SERVER_PID=""
        sleep "$RETRY_DELAY"
    done

    die "Failed after $MAX_RETRIES attempts"
}

trap cleanup EXIT INT TERM
main "$@"