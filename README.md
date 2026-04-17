# MLX Server

> 🍎 Local LLM inference server for Qwen 3.6.35B

Run Qwen 3.6.35B locally on your Mac with Apple's MLX framework. It's private, it's local, and it works. Don't expect to beat SOTA speeds, but it'll chat while you make coffee.

---

## ✨ Features

- **Local & Private** - All inference happens on your machine. Your data never leaves your Mac.
- **Reasonably Fast** - 20-35 tokens/sec on M2 Max. Good enough for casual use.
- **One-Command Start** - Single script handles setup, downloads, and server.
- **Self-Healing** - Terminates old instances, restarts server on failure.
- **OpenAI-Compatible API** - Works with existing tools and clients.
- **M2 Max Optimized** - Leveraging hardware acceleration

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
./run.sh
```

That's it. The script will:

1. ✅ Create virtual environment & install dependencies
2. ✅ Download model with progress bar
3. ✅ Kill any existing server instances (with retry)
4. ✅ Wait for port to release
5. ✅ Start the server on port 5001
6. ✅ Auto-restart if it crashes

**Note:** First run will take ~15-30 seconds. The model is ~18GB, so expect to wait a bit.

---

## 🔗 API Usage

### Server URL

```
http://localhost:5001
```

### API Endpoints (OpenAI-compatible)

```
http://localhost:5001/v1/chat/completions
http://localhost:5001/v1/completions
```

### Example: Chat Completion

```bash
curl -X POST http://localhost:5001/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"mlx-community/Qwen3.6-35B-A3B-4bit","messages":[{"role":"user","content":"What is the capital of France?"}],"max_tokens":256,"temperature":0.7}'
```

### Example: Streaming Chat

```bash
curl -X POST http://localhost:5001/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"mlx-community/Qwen3.6-35B-A3B-4bit","messages":[{"role":"user","content":"Write a haiku about AI"}],"max_tokens":50,"stream":true}'
```

---

## 🛑 Stopping the Server

### Graceful Shutdown

Press `Ctrl+C` in the terminal where `./run.sh` is running.

### Force Kill

```bash
lsof -ti:5001 | xargs -r kill -9
```

### Kill All MLX Server Processes

```bash
pkill -f "mlx_lm.server"
```

---

## ⚡ Performance (M2 Max)

Real-world performance on M2 Max (16-core GPU, 40GB unified memory):

| Metric | Value |
|--------|-------|
| **Model Size (4-bit)** | ~18GB |
| **Inference Speed** | 20-35 tokens/sec |
| **Context Window** | 8K tokens |
| **Memory Usage** | 24-28GB VRAM |
| **Startup Time** | ~15-30 seconds |
| **Concurrent Requests** | 2-4 (depends on memory) |

**Reality check:** This isn't *lightning* fast. It's... adequately fast. Like, "writing emails while waiting for coffee" fast. Don't expect it to beat SOTA models on speed benchmarks. It's good for local, it's private, and sometimes that's more than enough.

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
