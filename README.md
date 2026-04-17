# MLX Server

> 🍎 Native Apple Silicon ML Inference Server for Qwen 3.6.35B

Lightning-fast local LLM inference powered by Apple's MLX framework. Run the Qwen 3.6.35B 4bit quantized model directly on your Mac.

---

## ✨ Features

- **🚀 Blazing Fast Inference** - Native MLX kernels optimized for Apple Silicon M1/M2/M3/M4
- **💾 Memory Efficient** - 4-bit quantization reduces 35B model to ~18GB
- **🔒 Privacy First** - All inference happens locally on your machine
- **⚡ One-Command Start** - Single script handles setup, downloads, and server
- **♻️ Idempotent & Robust** - Safe to run anytime, auto-restarts on crash
- **🛡️ Self-Healing** - Terminates old instances, restarts server on failure
- **⚡ M2 Max Optimized** - Leveraging hardware acceleration

---

## 🖥️ Requirements

- macOS 14.0+ (Sonoma) or 15.0+ (Sequoia)
- Apple Silicon (M1/M2/M3/M4 chip)
- 24GB RAM minimum (35B model at 4-bit)
- Python 3.10+
- `uv` package manager

---

## 🚀 Quick Start

```bash
cd mlx-server

# One command - everything it does automatically:
./run.sh
```

That's it. The script will:

1. ✅ Create virtual environment & install dependencies
2. ✅ Download model with progress bar
3. ✅ Kill any existing server instances
4. ✅ Start the server on port 5000
5. ✅ Auto-restart if it crashes

---

## 🔗 API Usage

### Server URL

```
http://localhost:5000
```

### Generate Endpoint

```
http://localhost:5000/api/generate
```

### Example Request

```bash
curl -X POST http://localhost:5000/api/generate \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "What is the capital of France?",
    "max_tokens": 256,
    "temperature": 0.7
  }'
```

### Example with Streaming

```bash
curl -X POST http://localhost:5000/api/generate \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Write a haiku about AI",
    "max_tokens": 50,
    "stream": true
  }'
```

---

## 🛑 Stopping the Server

### Graceful Shutdown

Press `Ctrl+C` in the terminal where `./run.sh` is running.

### Force Kill

```bash
lsof -ti:5000 | xargs -r kill -9
```

### Kill All MLX Server Processes

```bash
pkill -f "mlx_lm.server"
```

---

## ⚡ Performance (M2 Max)

Estimated performance on M2 Max (16-core GPU, 40GB unified memory):

| Metric | Value |
|--------|-------|
| **Model Size (4-bit)** | ~18GB |
| **Inference Speed** | 20-35 tokens/sec |
| **Context Window** | 8K tokens |
| **Memory Usage** | 24-28GB VRAM |
| **Startup Time** | ~15-30 seconds |
| **Concurrent Requests** | 2-4 (depends on memory) |

---

## 🎯 How It Works

```
┌─────────────────────────────────────┐
│         ./run.sh                    │
│  • Downloads models if missing     │
│  • Installs dependencies           │
│  • Terminates old instances        │
│  • Restarts on crash (retry x5)    │
└─────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────┐
│        Qwen 3.6.35B A3B            │
│  • 4-bit AWQ quantization          │
│  • 35B parameters                  │
│  • 3B activated (MoE)              │
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

## 🙏 Credits

- [MLX](https://github.com/ml-explore/mlx) - Apple's machine learning framework
- [Qwen](https://huggingface.co/Qwen) - Alibaba's large language model
- [mlx-community](https://huggingface.co/mlx-community) - Community quantized models
- [uv](https://github.com/astral-sh/uv) - Fast Python package installer

---

## 🤝 Contributing

Contributions welcome! Please open issues and pull requests.

---

## 📞 Support

Having trouble? Open an issue on GitHub.

---

**Made with ❤️ and 🍎 on Apple Silicon**
