#!/usr/bin/env python3
"""Setup script for mlx local model server.

Downloads and installs all necessary dependencies and model artifacts.
Idempotent - safe to run multiple times.
"""

import os
import shutil
import subprocess
import sys
from pathlib import Path


def log(msg: str, level: str = "info") -> None:
    """Log messages with colored output."""
    colors = {
        "info": "\033[36m",
        "success": "\033[32m",
        "warning": "\033[33m",
        "error": "\033[31m",
    }
    reset = "\033[0m"
    color = colors.get(level, "")
    print(f"{color}[{level.upper()}]{reset} {msg}")


def run_cmd(cmd: list[str], desc: str) -> bool:
    """Run a shell command and report status."""
    print(f"  {desc}...")
    result = subprocess.run(cmd, check=True, capture_output=True, text=True)
    return True


def ensure_uv() -> bool:
    """Ensure uv is installed."""
    try:
        result = subprocess.run(
            ["uv", "--version"], capture_output=True, text=True, check=True
        )
        return True
    except (subprocess.CalledProcessError, FileNotFoundError):
        log("uv not found, installing...", "info")
        subprocess.run(["pip", "install", "uv"], check=True)
        return True


def ensure_python() -> bool:
    """Ensure Python 3.10+ is available."""
    try:
        result = subprocess.run(
            ["python3", "--version"], capture_output=True, text=True, check=True
        )
        version = result.stdout.split()[-1].lstrip("Python ")
        major, minor = map(int, version.split(".")[:2])
        return major > 3 or (major == 3 and minor >= 10)
    except (subprocess.CalledProcessError, ValueError):
        log("Python 3.10+ required", "error")
        return False


def install_dependencies() -> bool:
    """Install Python dependencies with uv."""
    log("Installing dependencies with uv...", "info")

    try:
        subprocess.run(
            ["uv", "pip", "install", "mlx-lm", "huggingface_hub"],
            check=True,
            capture_output=True,
            text=True,
        )
        log("Dependencies installed", "success")
        return True
    except subprocess.CalledProcessError as e:
        log(f"Failed to install dependencies: {e}", "error")
        return False


def download_model() -> bool:
    """Download the Qwen 3.6.35B A3B 4bit model."""
    repo_id = "mlx-community/Qwen3.6-35B-A3B-4bit"
    model_dir = Path.home() / ".cache" / "mlx-community" / repo_id
    model_dir.mkdir(parents=True, exist_ok=True)

    log(f"Downloading model from {repo_id}...", "info")

    try:
        subprocess.run(
            [
                "uv",
                "run",
                "-q",
                "python",
                "-c",
                f"""
import huggingface_hub
hf = huggingface_hub.HfApi()
hf.hf_hub_download(
    repo_id='{repo_id}',
    filename='model-00001-of-00002.safetensors',
    local_dir={model_dir},
    local_dir_use_symlinks=False,
)
hf.hf_hub_download(
    repo_id='{repo_id}',
    filename='model-00002-of-00002.safetensors',
    local_dir={model_dir},
    local_dir_use_symlinks=False,
)
hf.hf_hub_download(
    repo_id='{repo_id}',
    filename='config.json',
    local_dir={model_dir},
    local_dir_use_symlinks=False,
)
hf.hf_hub_download(
    repo_id='{repo_id}',
    filename='tokenizer_config.json',
    local_dir={model_dir},
    local_dir_use_symlinks=False,
)
hf.hf_hub_download(
    repo_id='{repo_id}',
    filename='tokenizer.json',
    local_dir={model_dir},
    local_dir_use_symlinks=False,
)
hf.hf_hub_download(
    repo_id='{repo_id}',
    filename='special_tokens_map.json',
    local_dir={model_dir},
    local_dir_use_symlinks=False,
)
""",
            ],
            check=True,
            capture_output=True,
            text=True,
        )
        log(f"Model cached to {model_dir}", "success")
        return True
    except subprocess.CalledProcessError as e:
        log(f"Failed to download model: {e}", "error")
        return False


def verify_installation() -> bool:
    """Verify the installation is correct."""
    model_dir = (
        Path.home() / ".cache" / "mlx-community" / "mlx-community/Qwen3.6-35B-A3B-4bit"
    )

    required_files = [
        "model-00001-of-00002.safetensors",
        "model-00002-of-00002.safetensors",
        "config.json",
        "tokenizer_config.json",
        "tokenizer.json",
        "special_tokens_map.json",
    ]

    missing = []
    for f in required_files:
        if not (model_dir / f).exists():
            missing.append(f)

    if missing:
        log(f"Missing files: {missing}", "error")
        return False

    try:
        import mlx_lm

        log("mlx_lm imported successfully", "success")
    except ImportError:
        log("mlx_lm not installed", "error")
        return False

    return True


def main() -> int:
    """Main entry point."""
    print("🔧 MLX Model Server Setup")
    print("=" * 40)

    # Check Python version
    if not ensure_python():
        return 1

    # Check/install uv
    if not ensure_uv():
        return 1

    # Install dependencies
    if not install_dependencies():
        return 1

    # Download model
    if not download_model():
        return 1

    # Verify installation
    if not verify_installation():
        return 1

    print("\n✅ Setup complete! Run 'mlx-server run' to start the server.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
