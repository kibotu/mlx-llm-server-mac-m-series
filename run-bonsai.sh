#!/usr/bin/env bash
# Bonsai server runner - uses Bonsai-demo uv environment, starts server, recovers from crashes

set -euo pipefail

# Config
BONSAI_DIR="$(cd "$(dirname "$0")/Bonsai-demo" && pwd)"
MAX_RETRIES=5
RETRY_DELAY=5

# Derived from Bonsai-demo scripts
SCRIPT_DIR="$BONSAI_DIR/scripts"
DEMO_DIR="$BONSAI_DIR"
COMMON_SH="$SCRIPT_DIR/common.sh"

# Defaults that can be overridden
BONSAI_MODEL="${BONSAI_MODEL:-8B}"
BONSAI_FAMILY="${BONSAI_FAMILY:-bonsai}"
PORT="${PORT:-8898}"

LOG_FILE="$HOME/.cache/bonsai-server.log"
SERVER_PID=""

log() { echo "[$(date +%H:%M:%S)] $*" | tee -a "$LOG_FILE"; }
die() { log "ERROR: $*"; exit 1; }

# Source Bonsai venv
source_bonsai_venv() {
    if [[ -f "$BONSAI_DIR/.venv/bin/activate" ]]; then
        source "$BONSAI_DIR/.venv/bin/activate"
        log "Activated Bonsai venv: $BONSAI_DIR/.venv/bin/python"
    else
        die "Bonsai venv not found. Run ./Bonsai-demo/setup.sh first."
    fi
}

# System info logging
log_system_info() {
    local total_mem used_mem wired_mem
    total_mem=$(sysctl -n hw.memsize | awk '{print int($1/1024/1024/1024)"GB"}')
    used_mem=$(vm_stat | awk '/Pages active/ {print int($3*4096/1024/1024/1024)"GB"}')
    wired_mem=$(vm_stat | awk '/Pages wired/ {print int($4*4096/1024/1024/1024)"GB"}')

    log "System: $(sw_vers -productName) $(sw_vers -productVersion)"
    log "Hardware: $(sysctl -n machdep.cpu.brand_string)"
    log "Memory: $total_mem total, $used_mem active, $wired_mem wired"
    log "Bonsai config: FAMILY=${BONSAI_FAMILY} MODEL=${BONSAI_MODEL}"
}

# Cleanup on exit
cleanup() {
    log "Shutting down"
    [[ -n "$SERVER_PID" ]] && kill -TERM "$SERVER_PID" 2>/dev/null || true
    free_port
    log "Server stopped"
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

# Source common.sh and validate model
validate_model() {
    if [[ ! -f "$COMMON_SH" ]]; then
        die "common.sh not found at $COMMON_SH"
    fi
    cd "$BONSAI_DIR"
    source "$COMMON_SH"
    
    assert_valid_model
    assert_mlx_downloaded
}

# Setup Bonsai venv
setup_env() {
    ensure_venv "$DEMO_DIR"
    export HF_HOME="$DEMO_DIR/.hf_cache"
    mkdir -p "$HF_HOME/hub"
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
    log "Starting server (attempt $1/$MAX_RETRIES)"
    log "Port: $PORT | Model: Bonsai-${BONSAI_FAMILY}-${BONSAI_MODEL}"
    log "Endpoint: http://localhost:$PORT/v1/chat/completions"

    # Activate venv and run start_mlx_server.sh
    "$DEMO_DIR/.venv/bin/python" -m mlx_lm.server \
        --model "$DEMO_DIR/models/Bonsai-${BONSAI_MODEL}-mlx" \
        --host 0.0.0.0 \
        --port "$PORT" \
        --temp 0.5 \
        --top-p 0.85 \
        &

    SERVER_PID=$!
    log "Server started (PID: $SERVER_PID)"

    # Monitor loop
    while kill -0 "$SERVER_PID" 2>/dev/null; do
        sleep 30
    done
}

main() {
    log "========================================"
    log "Bonsai MLX Server Starting"
    log "========================================"
    log_system_info

    # Kill any existing instance first
    free_port

    source_bonsai_venv
    validate_model
    setup_env

    # Restart loop
    for i in $(seq 1 $MAX_RETRIES); do
        run_server "$i" || log "Server crashed, retrying in ${RETRY_DELAY}s"
        SERVER_PID=""
        sleep "$RETRY_DELAY"
    done

    die "Failed after $MAX_RETRIES attempts"
}

trap cleanup EXIT INT TERM
main "$@"
