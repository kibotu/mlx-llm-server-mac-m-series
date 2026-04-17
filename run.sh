#!/usr/bin/env bash
# run.sh - Unified script for MLX server
# Downloads models if missing, starts server, restarts on crash
# Idempotent, robust, and production-ready

set -euo pipefail

# Configuration
readonly MODEL="${MODEL:-mlx-community/Qwen3.6-35B-A3B-4bit}"
readonly PORT="${PORT:-5001}"
readonly TEMP="${TEMP:-0.7}"
readonly PROMPT_CONC="${PROMPT_CONC:-2}"
readonly DECODE_CONC="${DECODE_CONC:-2}"
readonly MAX_RETRIES=5
readonly RETRY_DELAY=5

# Paths
readonly CACHE_DIR="$HOME/.cache/mlx-community"
readonly MODEL_CACHE="$CACHE_DIR/$MODEL"
readonly LOG_FILE="$HOME/.cache/mlx-server.log"

# Logging function
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

log_info() { log "INFO" "$*"; }
log_warn() { log "WARN" "$*"; }
log_error() { log "ERROR" "$*"; }

# Cleanup function
cleanup() {
    log_info "Server stopped gracefully"
}
trap cleanup EXIT

# Check if port is in use
port_in_use() {
    lsof -ti:"$PORT" > /dev/null 2>&1
}

# Kill process on port
kill_port() {
    local pids
    local max_attempts=30
    local attempt=1
    
    pids=$(lsof -ti:"$PORT" 2>/dev/null || true)
    if [ -n "$pids" ]; then
        log_warn "Terminating existing server on port $PORT (PIDs: $pids)..."
        
        while [ $attempt -le $max_attempts ]; do
            # Kill all processes on this port
            for pid in $pids; do
                kill -9 "$pid" 2>/dev/null || true
            done
            
            # Wait for port to be released
            sleep 1
            
            # Re-check for processes
            pids=$(lsof -ti:"$PORT" 2>/dev/null || true)
            if [ -z "$pids" ]; then
                log_info "Port $PORT is now free"
                return 0
            fi
            
            attempt=$((attempt + 1))
            if [ $attempt -le $max_attempts ]; then
                log_warn "Waiting for port $PORT to release (attempt $attempt/$max_attempts, remaining PIDs: $pids)..."
            fi
        done
        
        # Final aggressive cleanup - kill any remaining by process name
        log_warn "Final cleanup - searching for mlx_lm processes..."
        local mlx_pids
        mlx_pids=$(pgrep -f "mlx_lm.server" 2>/dev/null || true)
        for pid in $mlx_pids; do
            log_warn "Killing MLX process $pid"
            kill -9 "$pid" 2>/dev/null || true
            sleep 0.5
        done
        
        log_warn "Port $PORT still in use after cleanup attempts"
    fi
}

# Download model with progress
download_model() {
    log_info "Model cache: $MODEL_CACHE"
    log_info "Downloading model: $MODEL"
    
    # Create cache directory
    mkdir -p "$CACHE_DIR"
    
    # Check if model already exists
    if [ -d "$MODEL_CACHE" ] && [ "$(ls -A "$MODEL_CACHE" 2>/dev/null)" ]; then
        log_info "Model already cached, skipping download"
        return 0
    fi
    
    log_info "Fetching model files from HuggingFace..."
    
    # Download all required files
    local required_files=(
        "model-00001-of-00004.safetensors"
        "model-00002-of-00004.safetensors"
        "model-00003-of-00004.safetensors"
        "model-00004-of-00004.safetensors"
        "config.json"
        "tokenizer_config.json"
        "tokenizer.json"
    )
    
    for file in "${required_files[@]}"; do
        log_info "Downloading: $file"
        uv run python3 -c "
import huggingface_hub
hf = huggingface_hub.HfApi()
hf.hf_hub_download(
    repo_id='$MODEL',
    filename='$file',
    cache_dir='$MODEL_CACHE',
    local_dir_use_symlinks=False
)
" || {
            log_error "Failed to download $file"
            exit 1
        }
    done
    
    log_info "Model cached to: $MODEL_CACHE"
}

# Check Python environment
check_environment() {
    if [ ! -d ".venv" ]; then
        log_warn "Virtual environment not found, creating..."
        python3 -m venv .venv
        source .venv/bin/activate
        uv pip install -q uv
    fi
    
    source .venv/bin/activate
    
    if ! command -v uv > /dev/null 2>&1; then
        log_error "uv not found"
        exit 1
    fi
    
    if ! python -c "import mlx_lm" 2>/dev/null; then
        log_info "Installing dependencies..."
        uv add -q mlx-lm huggingface_hub
    fi
}

# Start server
start_server() {
    log_info "Starting MLX server..."
    log_info "Model: $MODEL"
    log_info "Port: $PORT"
    log_info "Temp: $TEMP"
    log_info "Prompt concurrency: $PROMPT_CONC"
    log_info "Decode concurrency: $DECODE_CONC"
    log_info "API: http://localhost:$PORT"
    log_info "API generate: http://localhost:$PORT/api/generate"
    
    uv run --with mlx-lm mlx_lm.server \
        --model "$MODEL" \
        --host 0.0.0.0 \
        --port "$PORT" \
        --temp "$TEMP" \
        --prompt-concurrency "$PROMPT_CONC" \
        --decode-concurrency "$DECODE_CONC"
}

# Main function
main() {
    log_info "=========================================="
    log_info "MLX Server Starting..."
    log_info "=========================================="
    
    # Check and setup environment
    check_environment
    
    # Download model if needed
    download_model
    
    # Kill any existing server
    kill_port
    
    # Ensure port is free (safety check)
    if lsof -ti:"$PORT" > /dev/null 2>&1; then
        log_warn "Port $PORT still occupied, waiting 3s..."
        sleep 3
    fi
    
    # Start server with crash restart logic
    for ((i = 1; i <= MAX_RETRIES; i++)); do
        log_info "Server start attempt $i/$MAX_RETRIES..."
        
        # Start server in background
        start_server &
        SERVER_PID=$!
        
        # Wait for server to be ready
        sleep 2
        
        # Check if server is still running
        if kill -0 $SERVER_PID 2>/dev/null; then
            log_info "Server running on port $PORT (PID: $SERVER_PID)"
            log_info "API available at http://localhost:$PORT"
            log_info "Generate endpoint: http://localhost:$PORT/api/generate"
            log_info "Keep this script running to keep server alive"
            # Keep script alive to maintain server process
            wait $SERVER_PID
        fi
        
        log_warn "Server crashed, will retry in $RETRY_DELAY seconds..."
        sleep "$RETRY_DELAY"
        
        # Kill old process before retry
        kill -9 $SERVER_PID 2>/dev/null || true
    done
    
    log_error "Server failed to start after $MAX_RETRIES attempts"
    exit 1
}

main "$@"
