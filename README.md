# MLX Server

[![Medium](https://img.shields.io/badge/Medium-@kibotu-000000?style=flat-square&logo=medium&logoColor=white)](https://medium.com/@kibotu/two-paths-to-local-llm-servers-windows-nvidia-vs-mac-apple-silicon-1e28d606f600?sk=a5d9989d124d7f9b844927f0f545ed09)

> 🍎 Local LLM inference server for Qwen models on Apple Silicon

Run Qwen models locally on your Mac with Apple's MLX framework. It's private, it's local, and it works. Don't expect to beat SOTA speeds, but it'll chat while you make coffee.

---

## ✨ Features

- **Local & Private** - All inference happens on your machine. Your data never leaves your Mac.
- **Reasonably Fast** - ~60 tokens/sec on M2 Max (32GB RAM). Good enough for casual use.
- **One-Command Start** - Single script handles setup, downloads, and server.
- **Self-Healing** - Terminates old instances, restarts server on failure.
- **OpenAI-Compatible API** - Works with existing tools and clients.
- **M2 Max Optimized** - Leveraging hardware acceleration
- **Configurable Context** - Default 64k context window for long documents
- **Multiple Models** - Choose between 9B and 35B parameter models
- **OpenCode Integration** - Integrate with OpenCode for a powerful local development assistant

---

## 🖥️ Requirements

- macOS 14.0+ (Sonoma) or 15.0+ (Sequoia)
- Apple Silicon (M1/M2/M3/M4 chip)
- 8GB RAM minimum (for 9B model), 24GB RAM minimum (for 35B model)
- Python 3.10+
- `uv` package manager
- Optional: [OpenCode](https://opencode.ai) for AI-powered development assistance

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
5. ✅ Start the server on port 8898
6. ✅ Auto-restart if it crashes

**Note:** First run will take ~15-30 seconds. The model is ~6GB, so it's fast to download.

### Using Different Models

Set environment variables before running:

```bash
# Use the 9B model
MODEL=mlx-community/Qwen3.5-9B-MLX-4bit ./run.sh

# Use the 35B model (A3B MoE)
MODEL=mlx-community/Qwen3.6-35B-A3B-4bit ./run.sh

# Set custom context window (default: 65536 / 64k)
CONTEXT_WINDOW=32768 ./run.sh

# Combine options
MODEL=mlx-community/Qwen3.6-35B-A3B-4bit CONTEXT_WINDOW=131072 ./run.sh
```

### Available Models

| Model                                                                                           | Parameters | Quantization | Size | Best For |
|-------------------------------------------------------------------------------------------------|-----------|--------------|------|----------|
| [mlx-community/Qwen3.5-9B-MLX-4bit](https://huggingface.co/mlx-community/Qwen3.5-9B-MLX-4bit)   | 9B | 4-bit (A3B) | ~6GB | Fast inference, limited RAM |
| [mlx-community/gemma-4-e4b-it-4bit](https://huggingface.co/mlx-community/gemma-4-e4b-it-4bit)   | 4.5B | 4-bit | ~3GB | Tiny tasks, quick responses |
| [mlx-community/Qwen3.6-35B-A3B-4bit](https://huggingface.co/mlx-community/Qwen3.6-35B-A3B-4bit) | 35B (MoE) | 4-bit | ~18GB | Complex reasoning, more RAM |

---

## 🎯 For Travelers & Offline Work

Perfect for working during train rides, flights, or anywhere without internet access. Run your own local LLM, no subscriptions needed.

**Why use a local LLM?**

- No internet required - works offline
- No subscription costs - pay once for hardware
- No privacy concerns - your data stays local
- Works during flights, trains, and subway commutes

---

## 💻 For M5 Macs with 64GB RAM

If you have an M5 Mac with 64GB unified memory, you should try the **Qwen3.6-35B-A3B** model instead. The MoE (Mixture of Experts) architecture means only 3B parameters are active at any time, giving you SOTA performance while still running locally.

```bash
MODEL=mlx-community/Qwen3.6-35B-A3B-4bit ./run.sh
```

---

## 🔗 API Usage

### Server URL

```
http://localhost:8898
```

### API Endpoints (OpenAI-compatible)

```
http://localhost:8898/v1/chat/completions
http://localhost:8898/v1/completions
```

### Example: Chat Completion

```bash
curl -X POST http://localhost:8898/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"mlx-community/Qwen3.5-9B-MLX-4bit","messages":[{"role":"user","content":"What is the capital of France?"}],"max_tokens":256,"temperature":0.7}'
```

### Streaming Response

```bash
curl -X POST http://localhost:8898/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"mlx-community/Qwen3.5-9B-MLX-4bit","messages":[{"role":"user","content":"Write a haiku about AI"}],"max_tokens":50,"stream":true}'
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

## ⚙️ Integrating with OpenCode

[OpenCode](https://opencode.ai) brings local LLM intelligence into your editor. It combines the best of local inference with your existing development tools.

### Setting Up OpenCode with MLX Server

1. **Install OpenCode**

   ```bash
   # Using Homebrew
   brew install opencode

   # Or download from https://opencode.ai
   ```

2. **Configure OpenCode to use your MLX Server**

   Create or edit [~/.config/opencode/opencode.json](opencode/opencode.json):

```json
{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "local-mlx": {
      "name": "MLX (Local)",
      "npm": "@ai-sdk/openai-compatible",
      "options": {
        "baseURL": "http://127.0.0.1:8898/v1",
        "timeout": 180000,
        "chunkTimeout": 30000
      },
      "models": {
        "mlx-community/Qwen3.5-9B-MLX-4bit": {
          "name": "Qwen3.5-9B-MLX-4bit",
          "limit": {
            "context": 98304,
            "output": 6000
          }
        },
        "mlx-community/gemma-4-e4b-it-4bit": {
          "name": "Gemma4 E4B IT",
          "limit": {
            "context": 32768,
            "output": 2048
          }
        }
      }
    }
  },
  "model": "local-mlx/mlx-community/Qwen3.5-9B-MLX-4bit",
  "small_model": "local-mlx/mlx-community/gemma-4-e4b-it-4bit",
  "compaction": {
    "auto": true,
    "prune": true,
    "reserved": 5000
  }
}
```

3. **Start the server**

   ```bash
   ./run.sh
   ```

4. **Restart OpenCode**

   - Press `Cmd+Shift+R` to restart OpenCode
   - Or close and reopen the application

5. **Start chatting!**

   Now OpenCode will use your local MLX server for all AI-powered assistance.

### Adding a Provider to opencode.json

Add a custom provider that points to your local MLX server:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "local-mlx": {
      "name": "MLX (Local)",
      "npm": "@ai-sdk/openai-compatible",
      "options": {
        "baseURL": "http://127.0.0.1:8898/v1",
        "timeout": 180000,
        "chunkTimeout": 30000
      },
      "models": {
        "mlx-community/Qwen3.5-9B-MLX-4bit": {
          "name": "Qwen3.5-9B-MLX-4bit",
          "limit": {
            "context": 98304,
            "output": 6000
          }
        }
      }
    }
  },
  "model": "local-mlx/mlx-community/Qwen3.5-9B-MLX-4bit"
}
```

**Key points:**

- `name`: Display name for the provider
- `npm`: The npm package for the provider (for OpenAI-compatible APIs)
- `baseURL`: Your MLX server address (`http://127.0.0.1:8898/v1`)
- `timeout`: Request timeout in milliseconds (default: 180000)
- `chunkTimeout`: Timeout between streamed response chunks (default: 30000)
- `models`: Define available models with their context/output limits
- `model`: Reference your provider and model name
- `small_model`: Optional - use a smaller model for lightweight tasks

### Setting Default Model and Small Model

The `model` and `small_model` settings control which models OpenCode uses:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "local-mlx": {
      "name": "MLX (Local)",
      "npm": "@ai-sdk/openai-compatible",
      "options": {
        "baseURL": "http://127.0.0.1:8898/v1"
      },
      "models": {
        "mlx-community/Qwen3.5-9B-MLX-4bit": {
          "name": "Qwen3.5-9B-MLX-4bit"
        },
        "mlx-community/gemma-4-e4b-it-4bit": {
          "name": "Gemma4 E4B IT"
        }
      }
    }
  },
  "model": "local-mlx/mlx-community/Qwen3.5-9B-MLX-4bit",
  "small_model": "local-mlx/mlx-community/gemma-4-e4b-it-4bit"
}
```

- **`model`**: The main model for all operations
- **`small_model`**: A smaller/faster model for lightweight tasks like title generation
- Both reference the same provider (`local-mlx`) and model name

---

## ⚡ Performance (M2 Max, 32GB RAM)

Real-world performance on M2 Max (16-core GPU, 32GB unified memory):

### 9B Model (Default) - Qwen3.5-9B-MLX-4bit

| Metric | Value |
|--------|-------|
| **Model Size (4-bit)** | ~6GB |
| **Inference Speed** | **~60 tokens/sec** (Qwen3.5-9B Q4) |
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

## 🔧 Context Window & Auto Compact

### Understanding Context Window

The context window determines how much text the model can "see" at once. Default is **64k tokens**.

```bash
# Set custom context window
CONTEXT_WINDOW=32768 ./run.sh  # 32k
CONTEXT_WINDOW=131072 ./run.sh # 128k
CONTEXT_WINDOW=1048576 ./run.sh # 1M
```

### Auto Compact with Reserved Tokens

Auto compact keeps your conversation history manageable by removing old messages when the context window is full.

In your OpenCode config (`~/.config/opencode/opencode.json`):

```json
{
  "compaction": {
    "auto": true,
    "prune": true,
    "reserved": 16384
  }
}
```

- **`auto`**: Automatically compact when context is full (`true` by default)
- **`prune`**: Remove old tool outputs to save tokens (`true` by default)
- **`reserved`**: Token buffer for compaction (default: 10000). This keeps enough window to avoid overflow during compaction

**Why reserved tokens matter:** Without a reserved buffer, compaction might try to delete messages right at the edge, causing overflow issues. The reserved buffer ensures you have breathing room.

---

## 🛑 Stopping the Server

### Graceful Shutdown

Press `Ctrl+C` in the terminal where `./run.sh` is running.

### Force Kill

```bash
lsof -ti:8898 | xargs -r kill -9
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

## ⚙️ How It Works

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
| `PORT` | `8898` | Server port |
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
- [uv](https://github.com/astral-sh/uv) - Fast Python package installer
- [OpenCode](https://opencode.ai) - Local LLM IDE integration

---

## 📊 Benchmarking

To benchmark performance on different systems:

1. Clone the benchmark suite:
   ```bash
   git clone https://github.com/kibotu/llm_context_benchmarks
   ```

2. Run the benchmark with your model:
   ```bash
   cd llm_context_benchmarks
   uv run benchmark mlx mlx-community/Qwen3.5-9B-MLX-4bit
   ```

This will measure tokens/sec, memory usage, and latency across various context sizes.

---

## 🤝 Contributing

Contributions welcome! Please open issues and pull requests.

---

## 📞 Support

Having trouble? Open an issue on GitHub.

**Key configuration options:**

- **`provider`**: Define custom providers for your local server
- **`model`**: Main model for all operations
- **`small_model`**: Lightweight model for small tasks
- **`compaction.auto`**: Auto-compact when context is full
- **`compaction.reserved`**: Token buffer for safe compaction

---

**Made with ❤️ and 🍎 on Apple Silicon**
