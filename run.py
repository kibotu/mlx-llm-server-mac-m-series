#!/usr/bin/env python3
"""Run script for mlx local model server.

Starts the MLX server with the Qwen 3.6.35B A3B 4bit model.
Idempotent - kills any existing server before starting.
"""

import os
import signal
import subprocess
import sys
from pathlib import Path


MODEL_DIR = (
    Path.home() / ".cache" / "mlx-community" / "mlx-community/Qwen3.6-35B-A3B-4bit"
)


def log(msg: str, level: str = "info") -> None:
    """Log messages with colored output."""
    colors = {
        "info": "\033[36m",
        "success": "\033[32m",
        "warning": "\033[33m",
        "error": "\033[31m",
        "run": "\033[34m",
    }
    reset = "\033[0m"
    color = colors.get(level, "")
    print(f"{color}[{level.upper()}]{reset} {msg}")


def kill_existing_server() -> bool:
    """Kill any existing mlx-server processes."""
    try:
        result = subprocess.run(
            ["lsof", "-ti", ":5000"],
            capture_output=True,
            text=True,
        )
        pids = result.stdout.strip().split()

        if pids:
            log("Found server running on port 5000, terminating...", "warning")
            for pid in pids:
                try:
                    os.kill(int(pid), signal.SIGTERM)
                except ProcessLookupError:
                    pass
        return True
    except Exception as e:
        log(f"Could not check for existing server: {e}", "warning")
        return True


def verify_model_exists() -> bool:
    """Check if the model is available."""
    required_files = [
        "model-00001-of-00002.safetensors",
        "model-00002-of-00002.safetensors",
        "config.json",
        "tokenizer.json",
    ]

    if not MODEL_DIR.exists():
        log(f"Model directory not found: {MODEL_DIR}", "error")
        log("Run 'mlx-server setup' to download the model", "error")
        return False

    for f in required_files:
        if not (MODEL_DIR / f).exists():
            log(f"Missing model file: {f}", "error")
            return False

    return True


def run_server() -> int:
    """Start the MLX server."""
    log("Starting MLX server...", "run")
    log(f"Model: {MODEL_DIR}", "run")

    env = os.environ.copy()
    env["MLX_DEVICE"] = "metal"

    cmd = [
        sys.executable,
        "-m",
        "mlx_lm.server",
        "--model-path",
        str(MODEL_DIR),
        "--port",
        "5000",
        "--max-tokens",
        "4096",
        "--max-sequence-length",
        "8192",
    ]

    try:
        process = subprocess.Popen(
            cmd,
            env=env,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
        )

        lines = []
        for line in process.stdout:
            lines.append(line)
            print(line, end="")

            if "FastAPI" in line or "uvicorn" in line:
                break

        process.stdout.close()

        if process.returncode is not None and process.returncode != 0:
            log("Server exited unexpectedly", "error")
            return 1

        log("Server started successfully", "success")
        log("Access at http://localhost:5000", "success")
        log("API: POST /api/generate with {prompt, max_tokens}", "success")

    except FileNotFoundError:
        log("mlx_lm.server not found", "error")
        log("Run 'mlx-server setup' to install dependencies", "error")
        return 1
    except KeyboardInterrupt:
        log("Shutting down server...", "info")
        process.terminate()
        process.wait()
        return 0
    except Exception as e:
        log(f"Failed to start server: {e}", "error")
        return 1


def main() -> int:
    """Main entry point."""
    print("🚀 MLX Model Server")
    print("=" * 40)

    # Kill existing server
    kill_existing_server()

    # Verify model
    if not verify_model_exists():
        return 1

    # Run server
    return run_server()


if __name__ == "__main__":
    sys.exit(main())
