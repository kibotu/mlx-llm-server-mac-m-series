# MLX Server

> 🍎 Native Apple Silicon ML Inference Server for Qwen 3.6.35B A3B

Lightning-fast local LLM inference powered by Apple's MLX framework. Run the Qwen 3.6.35B 4bit quantized model directly on your Mac with zero external dependencies.

---

## ✨ Features

- **🚀 Blazing Fast Inference** - Native MLX kernels optimized for Apple Silicon
- **💾 Memory Efficient** - 4-bit quantization reduces model size to ~22GB
- **🔒 Privacy First** - All inference happens locally on your machine
- **🎯 Easy Setup** - One-command installation with `uv`
- **♻️ Idempotent Scripts** - Safe to run multiple times
- **🛡️ Robust Server** - Auto-terminates existing instances
- **⚡ M2/M3/M4 Max Optimized** - Leveraging hardware acceleration

---

## 🖥️ Requirements

- macOS 14.0+ (Sonoma) or 15.0+ (Sequoia)
- Apple Silicon (M1/M2/M3/M4 chip)
- 24GB RAM minimum (35B model at 4-bit)
- Python 3.10+
- `uv` package manager

---

## 📦 Installation

### Quick Start

```bash
# Clone the repository
git clone https://github.com/kibotu/mlx-server.git
cd mlx-server

# Run setup (downloads model & dependencies)
python3 setup.py

# Start the server
python3 run.py
```

### Manual Installation

```bash
# Install uv if needed
pip install uv

# Install Python dependencies
uv pip install mlx-lm huggingface_hub

# Download the Qwen 3.6.35B A3B 4bit model
uv run python -c "
import huggingface_hub
hf = huggingface_hub.HfApi()
hf.hf_hub_download(repo_id='mlx-community/Qwen3.6-35B-A3B-4bit', filename='model-00001-of-00002.safetensors')
hf.hf_hub_download(repo_id='mlx-community/Qwen3.6-35B-A3B-4bit', filename='model-00002-of-00002.safetensors')
hf.hf_hub_download(repo_id='mlx-community/Qwen3.6-35B-A3B-4bit', filename='config.json')
hf.hf_hub_download(repo_id='mlx-community/Qwen3.6-35B-A3B-4bit', filename='tokenizer.json')
"
```

---

## 🏃 Running the Server

### Start Server

```bash
python3 run.py
```

The server will start at `http://localhost:5000` with the following configuration:

- **Model**: Qwen 3.6.35B A3B 4bit
- **Port**: 5000
- **Max Tokens**: 4096
- **Sequence Length**: 8192

### API Usage

```bash
curl -X POST http://localhost:5000/api/generate \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "What is the capital of France?",
    "max_tokens": 256,
    "temperature": 0.7
  }'
```

### Stop Server

```bash
# Graceful shutdown (Ctrl+C)
# Or kill process
lsof -ti:5000 | xargs -r kill -9
```

---

## ⚡ Performance (M2 Max)

Estimated performance on M2 Max (16-core GPU, 40GB unified memory):

| Metric | Value |
|--------|-------|
| **Model Size (4-bit)** | ~22GB |
| **Inference Speed** | 20-35 tokens/sec |
| **Context Window** | 8K tokens |
| **Memory Usage** | 24-28GB VRAM |
| **Startup Time** | ~15-30 seconds |

*Actual performance varies based on model variant and workload.*

---

## 🎯 Architecture

```
┌─────────────────────────────────────┐
│         MLX Server                  │
├─────────────────────────────────────┤
│  • FastAPI REST API                 │
│  • Uvicorn ASGI server              │
│  • Async request handling           │
│  • Streaming responses              │
└─────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────┐
│        Qwen 3.6.35B A3B            │
│  • 4-bit AWQ quantization          │
│  • 35B parameters                  │
│  • Activated: 3B params            │
└─────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────┐
│       Apple MLX Runtime            │
│  • Metal GPU kernels               │
│  • MPS acceleration                │
│  • Unified memory architecture      │
└─────────────────────────────────────┘
```

---

## 🔧 Configuration

Edit `run.py` to customize:

```python
# Port
"--port", "5000",

# Max tokens
"--max-tokens", "4096",

# Sequence length
"--max-sequence-length", "8192",
```

---

## 📁 Project Structure

```
mlx-server/
├── setup.py      # Download & install dependencies
├── run.py        # Start the server
└── README.md     # This file
```

---

## 🧪 Testing

```bash
# Test inference
python3 -c "
from mlx_lm import generate
response = generate(
    model_path='/Users/yourname/.cache/mlx-community/mlx-community/Qwen3.6-35B-A3B-4bit',
    prompt='Hello, how are you?',
    max_tokens=50
)
print(response)
"
```

---

## 📝 License

MIT License - feel free to use, modify, and distribute.

---

## 🙏 Credits

- [MLX](https://github.com/ml-explore/mlx) - Apple's machine learning framework
- [Qwen](https://huggingface.co/Qwen) - Alibaba's large language model
- [mlx-community](https://huggingface.co/mlx-community) - Community quantized models

---

## 🤝 Contributing

Contributions welcome! Please open issues and pull requests.

---

## 📞 Support

Having trouble? Open an issue on GitHub.

---

**Made with ❤️ and 🍎 on Apple Silicon**
