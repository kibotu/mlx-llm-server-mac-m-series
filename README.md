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

## 🏃 Running the Server

### One Command

```bash
./run.sh
```

### Custom Configuration

```bash
MODEL=mlx-community/Qwen3.6-35B-A3B-4bit \
PORT=5000 \
TEMP=0.7 \
PROMPT_CONC=2 \
DECODE_CONC=2 \
./run.sh
```

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `MODEL` | `mlx-community/Qwen3.6-35B-A3B-4bit` | Model to load |
| `PORT` | `5000` | Server port |
| `TEMP` | `0.7` | Sampling temperature |
| `PROMPT_CONC` | `2` | Prompt concurrency |
| `DECODE_CONC` | `2` | Decode concurrency |

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

## 📁 Project Structure

```
mlx-server/
├── run.sh        # 🎯 Single entry point - does everything
├── uv.lock       # uv lockfile
├── pyproject.toml # Project configuration
└── README.md     # This file
```

---

## 📝 Logs

All server activity is logged to:

```
$HOME/.cache/mlx-server.log
```

Check for troubleshooting or debugging.

---

## 🧪 Testing Inference

```bash
# Test inference directly (before starting server)
uv run python3 -c '
from mlx_lm import generate
response = generate(
    model_path="mlx-community/Qwen3.6-35B-A3B-4bit",
    prompt="Hello, how are you?",
    max_tokens=50
)
print(response)
'
```

---

## 🔍 Troubleshooting

### Server won't start

```bash
# Check logs
tail -n 50 ~/.cache/mlx-server.log

# Check memory
sudo vmstat
```

### Port already in use

The script auto-terminates old instances. If it fails:

```bash
# Manual kill
lsof -ti:5000 | xargs -r kill -9

# Or use different port
PORT=5001 ./run.sh
```

### Out of memory

```bash
# Try smaller batch size
PROMPT_CONC=1 DECODE_CONC=1 ./run.sh
```

---

## 📝 License

MIT License - feel free to use, modify, and distribute.

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
