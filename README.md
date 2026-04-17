# MLX Server

> 🍎 Local LLM inference server for Qwen 3.5-9B and Qwen 3.6-35B and Qwen 3.5-9B

Run Qwen models locally on your Mac with Apple's MLX framework. It's private, it's local, and it works. Don't expect to beat SOTA speeds, but it'll chat while you make coffee.

---

## ✨ Features

- **Local & Private** - All inference happens on your machine. Your data never leaves your Mac.
- **Reasonably Fast** - 20-35 tokens/sec on M2 Max. Good enough for casual use.
- **One-Command Start** - Single script handles setup, downloads, and server.
- **Self-Healing** - Terminates old instances, restarts server on failure.
- **OpenAI-Compatible API** - Works with existing tools and clients.
- **M2 Max Optimized** - Leveraging hardware acceleration
- **Configurable Context** - Default 64k context window for long documents
- **Multiple Models** - Choose between 9B and 35B parameter models

---

## 🖥️ Requirements

- macOS 14.0+ (Sonoma) or 15.0+ (Sequoia)
- Apple Silicon (M1/M2/M3/M4 chip)
- 8GB RAM minimum (for 9B model), 24GB RAM minimum (for 35B model)
- Python 3.10+
- `uv` package manager

---

## 🚀 Quick Start

### Default Model (Qwen3.5-9B-MLX-4bit)

```bash
cd mlx-server
./run.sh
```

This uses the **9B parameter model** with 4-bit quantization (~6GB). The script will:

1. ✅ Create virtual environment & install dependencies
2. ✅ Download model with progress bar
3. ✅ Kill any existing server instances (with retry)
4. ✅ Wait for port to release
5. ✅ Start the server on port 5001
6. ✅ Auto-restart if it crashes

**Note:** First run will take ~15-30 seconds. The model is ~6GB, so it's fast to download.

### Using Different Models

Set environment variables before running:

```bash
# Use the 9B model with Q4_K_M quantization
MODEL=mlx-community/Qwen3.5-9B-MLX-4bit ./run.sh

# Use the 35B model (A3B MoE)
MODEL=mlx-community/Qwen3.6-35B-A3B-4bit ./run.sh

# Set custom context window (default: 65536 / 64k)
CONTEXT_WINDOW=32768 ./run.sh

# Combine options
MODEL=mlx-community/Qwen3.6-35B-A3B-4bit CONTEXT_WINDOW=131072 ./run.sh
```

### Available Models

| Model | Parameters | Quantization | Size | Best For |
|-------|-----------|--------------|------|----------|
| `mlx-community/Qwen3.5-9B-MLX-4bit` | 9B | 4-bit (A3B) | ~6GB | Fast inference, limited RAM |
| `mlx-community/Qwen3.6-35B-A3B-4bit` | 35B (MoE) | 4-bit | ~18GB | Complex reasoning, more RAM |

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

### Example: Chat Completion (9B Model)

```bash
curl -X POST http://localhost:5001/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"mlx-community/Qwen3.5-9B-MLX-4bit","messages":[{"role":"user","content":"What is the capital of France?"}],"max_tokens":256,"temperature":0.7}'
```

### Example: Chat Completion (35B Model)

```bash
curl -X POST http://localhost:5001/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"mlx-community/Qwen3.6-35B-A3B-4bit","messages":[{"role":"user","content":"What is the capital of France?"}],"max_tokens":256,"temperature":0.7}'
```

### Example: Streaming Response

```bash
curl -X POST http://localhost:5001/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"mlx-community/Qwen3.5-9B-MLX-4bit","messages":[{"role":"user","content":"Write a haiku about AI"}],"max_tokens":50,"stream":true}'
```

### Using Python

```python
import requests

response = requests.post(
    "http://localhost:5001/v1/chat/completions",
    json={
        "model": "mlx-community/Qwen3.5-9B-MLX-4bit",
        "messages": [
            {"role": "user", "content": "Explain quantum computing in simple terms"}
        ],
        "max_tokens": 500,
        "temperature": 0.7
    }
)

print(response.json()["choices"][0]["message"]["content"])
```

### Context Window Configuration

The default context window is **64k tokens** (65536). To use a different size:

```bash
# 32k context window
CONTEXT_WINDOW=32768 ./run.sh

# 128k context window  
CONTEXT_WINDOW=131072 ./run.sh

# 1M context window
CONTEXT_WINDOW=1048576 ./run.sh
```

**Note:** Larger context windows require more VRAM. Adjust based on your available memory.

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

### Kill Specific Model

```bash
# Kill 9B model
pkill -f "Qwen3.5-9B"

# Kill 35B model  
pkill -f "Qwen3.6-35B"
```

---

## ⚡ Performance (M2 Max)

Real-world performance on M2 Max (16-core GPU, 40GB unified memory):

### 9B Model (Default)

| Metric | Value |
|--------|-------|
| **Model Size (4-bit)** | ~6GB |
| **Inference Speed** | 40-60 tokens/sec |
| **Context Window** | 64k tokens (default) |
| **Memory Usage** | 8-12GB VRAM |
| **Startup Time** | ~10-20 seconds |
| **Concurrent Requests** | 4-8 (depends on memory) |

### 35B Model

| Metric | Value |
|--------|-------|
| **Model Size (4-bit)** | ~18GB |
| **Inference Speed** | 20-35 tokens/sec |
| **Context Window** | 64k tokens (default) |
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
│  • Configures 64k context window   │
└─────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────┐
│        Qwen 3.5-9B / 35B A3B        │
│  • 4-bit AWQ quantization (MLX)    │
│  • 9B or 35B parameters (MoE)      │
│  • Configurable context window     │
└─────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────┐
│       Apple MLX Runtime            │
│  • Metal GPU kernels               │
│  • MPS acceleration                │
│  • Unified memory architecture      │
│  • Optimized for Apple Silicon     │
└─────────────────────────────────────┘
```

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `MODEL` | `mlx-community/Qwen3.5-9B-MLX-4bit` | Model to load |
| `PORT` | `5001` | Server port |
| `TEMP` | `0.7` | Sampling temperature |
| `PROMPT_CONC` | `2` | Prompt concurrency |
| `DECODE_CONC` | `2` | Decode concurrency |
| `CONTEXT_WINDOW` | `65536` | Max context size (64k default) |

### Model Selection Examples

```bash
# Use default 9B model
./run.sh

# Use 35B model
MODEL=mlx-community/Qwen3.6-35B-A3B-4bit ./run.sh

# Use 9B model with larger context
MODEL=mlx-community/Qwen3.5-9B-MLX-4bit CONTEXT_WINDOW=131072 ./run.sh

# Custom temperature and context
MODEL=mlx-community/Qwen3.5-9B-MLX-4bit TEMP=0.5 CONTEXT_WINDOW=32768 ./run.sh
```

---

## 🙏 Credits

- [MLX](https://github.com/ml-explore/mlx) - Apple's machine learning framework
- [Qwen](https://huggingface.co/Qwen) - Alibaba's large language models
- [mlx-community](https://huggingface.co/mlx-community) - Community MLX-optimized models
- [unsloth](https://github.com/unslothai/unsloth) - GGUF quantization for Qwen
- [uv](https://github.com/astral-sh/uv) - Fast Python package installer

---

## 📦 Models

### Qwen3.5-9B-MLX-4bit (Default)

- **Repo:** `mlx-community/Qwen3.5-9B-MLX-4bit`
- **Parameters:** 9 billion
- **Quantization:** 4-bit AWQ (MLX format)
- **Size:** ~6GB
- **Best for:** Fast inference, limited resources

### Qwen3.6-35B-A3B-4bit

- **Repo:** `mlx-community/Qwen3.6-35B-A3B-4bit`
- **Parameters:** 35 billion (MoE - 3B active)
- **Quantization:** 4-bit AWQ
- **Size:** ~18GB
- **Best for:** Complex reasoning, more capable

### Qwen3.5-9B-GGUF (Unsloth)

- **Repo:** `unsloth/Qwen3.5-9B-GGUF`
- **Quantizations:** Q4_K_M, Q5_K_M, and more
- **Format:** GGUF (compatible with llama.cpp)
- **Best for:** Maximum compatibility, cross-platform

---

## 🤝 Contributing

Contributions welcome! Please open issues and pull requests.

---

## 📞 Support

Having trouble? Open an issue on GitHub.

---

**Made with ❤️ and 🍎 on Apple Silicon**
