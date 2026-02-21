# 📊 Full Benchmark Results

All tests run on GMKtec EVO-X2, Ryzen AI Max+ 395, 128 GB LPDDR5X-8000.

- **Backend**: Vulkan RADV (Mesa)
- **GPU**: `Radeon 8060S Graphics (RADV GFX1151)` — UMA, fp16, warp 64, KHR_coopmat matrix cores
- **llama.cpp**: Build `05a6f0e89` (b8038)
- **Kernel**: `6.18.9-200.fc43.x86_64`
- **Benchmark command**: `llama-bench -m <model> -ngl 99 -p 512 -n 128`
- **Date**: February 13, 2026

## 85W TDP Run

| Model | Size | Params | pp512 (t/s) | tg128 (t/s) |
|-------|------|--------|-------------|-------------|
| TinyLlama 1.1B Q4_K_M | 636 MiB | 1.10B | 6,513.17 ± 73.88 | 249.18 ± 1.26 |
| Llama 3.2 3B Q8_0 | 3.18 GiB | 3.21B | 2,247.60 ± 14.20 | 60.24 ± 0.78 |
| Llama 2 7B Q4_K_M | 3.80 GiB | 6.74B | 1,024.75 ± 19.80 | 45.52 ± 0.11 |
| Qwen2.5-Coder 7B Q6_K | 5.82 GiB | 7.62B | 998.35 ± 34.09 | 35.65 ± 0.03 |
| Qwen3 30B-A3B MoE Q4_K_M | 17.28 GiB | 30.53B | 975.70 ± 29.98 | 79.89 ± 4.37 |
| Llama 3.1 70B Q4_K_M | 39.59 GiB | 70.55B | 79.66 ± 0.07 | 5.06 ± 0.00 |

**Notes:**
- Qwen2.5 14B and 32B failed to load during the 85W run (download errors)
- Qwen3-235B-A22B also failed to load (multi-file GGUF download issue)

## 120W TDP Run

| Model | Size | Params | pp512 (t/s) | tg128 (t/s) |
|-------|------|--------|-------------|-------------|
| TinyLlama 1.1B Q4_K_M | 636 MiB | 1.10B | 6,358.17 ± 177.00 | 249.06 ± 0.31 |
| Llama 3.2 3B Q8_0 | 3.18 GiB | 3.21B | 2,161.97 ± 36.42 | 60.90 ± 0.06 |
| Llama 2 7B Q4_K_M | 3.80 GiB | 6.74B | 1,074.41 ± 33.12 | 47.25 ± 0.03 |
| Qwen2.5-Coder 7B Q6_K | 5.82 GiB | 7.62B | 1,088.98 ± 75.55 | 36.71 ± 0.02 |
| Qwen2.5 14B Q4_K_M | 8.37 GiB | 14.77B | 599.81 ± 22.10 | 24.47 ± 0.02 |
| Qwen3 30B-A3B MoE Q4_K_M | 17.28 GiB | 30.53B | 1,141.78 ± 6.18 | 86.07 ± 0.17 |
| Qwen2.5 32B Q4_K_M | 18.48 GiB | 32.76B | 242.44 ± 2.08 | 11.25 ± 0.00 |
| Llama 3.1 70B Q4_K_M | 39.59 GiB | 70.55B | 81.63 ± 0.07 | 5.10 ± 0.00 |

## Additional Models

### Qwen3-Coder-Next 80B-A3B (Q4_K_M) — Vulkan RADV, 120W

| Model | Size | Params | pp512 (t/s) | tg128 (t/s) |
|-------|------|--------|-------------|-------------|
| Qwen3-Coder-Next 80B-A3B Q4_K_M | 45.17 GiB | 79.67B | 531.48 ± 19.12 | 42.70 ± 0.04 |

Qwen3-Coder-Next is a newer MoE model (released Feb 2026) with 80B total / 3B active params, 512 experts, hybrid DeltaNet+attention architecture, and 256K native context. Designed specifically for coding agents and tool calling.

Compared to Qwen3 30B-A3B (same 3B active params): ~50% slower due to 2.6× larger model weights (46 GB vs 17 GB) requiring more memory bandwidth per token. Still usable at 42.7 t/s for interactive chat, with significantly better quality for agentic/coding tasks.

## Best of Both Runs

Taking the maximum value from either TDP setting:

| Model | pp512 (t/s) | tg128 (t/s) | Best TDP | Notes |
|-------|-------------|-------------|----------|-------|
| TinyLlama 1.1B Q4_K_M | 6,513 | 249 | 85W | Memory-bandwidth bound |
| Llama 3.2 3B Q8_0 | 2,248 | 60.9 | Mixed | pp=85W, tg=120W |
| Llama 2 7B Q4_K_M | 1,074 | 47.3 | 120W | Compute benefits from higher TDP |
| Qwen2.5-Coder 7B Q6_K | 1,089 | 36.7 | 120W | Q6 quant = more compute per token |
| Qwen2.5 14B Q4_K_M | 600 | 24.5 | 120W | 120W run only |
| Qwen3 30B-A3B MoE Q4_K_M | 1,142 | 86.1 | 120W | ⭐ Best interactive performance |
| Qwen2.5 32B Q4_K_M | 242 | 11.3 | 120W | 120W run only |
| Llama 3.1 70B Q4_K_M | 81.6 | 5.1 | 120W | Fits in 128 GB, usable for batch |

## 85W vs 120W Analysis

| Model | pp512 Δ | tg128 Δ |
|-------|---------|---------|
| TinyLlama 1.1B | -2.4% (85W wins) | ~0% (tie) |
| Llama 3.2 3B | -3.8% (85W wins) | +1.1% |
| Llama 2 7B | +4.8% | +3.8% |
| Qwen2.5-Coder 7B | +9.1% | +3.0% |
| Qwen3 30B-A3B MoE | +17.0% | +7.7% |
| Llama 3.1 70B | +2.5% | +0.8% |

**Pattern**: Small models that fit easily in cache are bandwidth-bound and don't benefit from higher TDP. Larger models (7B+) see consistent 3–17% improvement from the extra compute headroom.

## Community Comparison

### vs kyuz0 Framework Desktop (same CPU/RAM, best backend per test)

Source: [kyuz0 Interactive Viewer](https://kyuz0.github.io/amd-strix-halo-toolboxes/) — Fedora 42, kernel 6.18, llama.cpp b7034.

| Model | Metric | Us (RADV) | kyuz0 Best | Backend | Δ |
|-------|--------|-----------|-----------|---------|---|
| Llama 2 7B (Q4_K_M vs Q4_0) | pp512 | 1,074 | 1,598 | ROCm 6.4.4 | -33% |
| Llama 2 7B (Q4_K_M vs Q4_0) | tg128 | 47.3 | 55.9 | RADV | -15% |
| Qwen3 30B-A3B MoE Q4_K_M | pp512 | 1,142 | 1,264 | ROCm 6.4.4 | -10% |
| Qwen3 30B-A3B MoE Q4_K_M | tg128 | 86.1 | 86.0 | AMDVLK | **+0.1%** ✅ |

**Notes:**
- The Llama 2 comparison uses different quants (our Q4_K_M vs their Q4_0) which affects results
- kyuz0's best pp numbers come from ROCm 6.4.4 HIP — unavailable to us (HSA segfault)
- Our Qwen3 30B-A3B tg128 result **matches the community best**

### RADV vs AMDVLK Driver Comparison

We installed AMDVLK v2025.Q2.1 and ran head-to-head benchmarks (120W TDP):

| Model | Metric | RADV | AMDVLK | Winner |
|-------|--------|------|--------|--------|
| Llama 2 7B Q4_K_M | pp512 | **1,061** | 306 | RADV (+247%) |
| Llama 2 7B Q4_K_M | tg128 | 47.2 | **47.4** | Tie |
| Qwen3 30B-A3B MoE Q4_K_M | pp512 | **1,028** | 742 | RADV (+39%) |
| Qwen3 30B-A3B MoE Q4_K_M | tg128 | 80.2 | **85.3** | AMDVLK (+6.4%) |

**Root cause — halved shared memory:**

```
RADV:    shared memory: 65536  ← correct (64 KB LDS per workgroup)
AMDVLK:  shared memory: 32768  ← wrong (half the actual hardware capability)
```

AMDVLK v2025.Q2.1 misreports the GPU's Local Data Store size on gfx1151. RDNA 3.5 has 64 KB LDS per workgroup (as RADV correctly exposes), but AMDVLK only sees 32 KB. This halved LDS cripples compute shader performance — particularly prompt processing which is heavily compute-bound.

Even with `-ub 512` (lhl's recommended batch size for AMDVLK), performance was *worse*: pp512=263 t/s, tg128=43.6 ± 8.59 (high variance indicates instability).

**Conclusion:** AMDVLK has incomplete/buggy gfx1151 support as of v2025.Q2.1. The 2 GB single-buffer allocation limit is an additional constraint that can prevent larger models from loading. **RADV is the only viable Vulkan driver on Strix Halo today.**

kyuz0's positive AMDVLK results were likely obtained with a different version or on a configuration where these issues don't manifest

### vs Nvidia DGX Spark (from lhl's testing)

Source: [lhl/strix-halo-testing](https://github.com/lhl/strix-halo-testing) — gpt-oss-120B model comparison.

At short context (2K), Strix Halo token generation is within 6–14% of DGX Spark (RTX 5070 class). Spark pulls ahead significantly at longer contexts (32K+) and on prompt processing. See lhl's repo for the detailed breakdown.

## Vulkan RADV vs ROCm 7.2 HIP

Tested using [kyuz0's rocm-7.2 toolbox container](https://github.com/kyuz0/amd-strix-halo-toolboxes) via distrobox. Same llama.cpp build (b8038), 120W TDP.

| Model | Metric | Vulkan RADV | ROCm 7.2 HIP | Winner |
|-------|--------|-------------|---------------|--------|
| Llama 2 7B Q4_K_M | pp512 | 1,074 | **1,182** | HIP (+10%) |
| Llama 2 7B Q4_K_M | tg128 | **47.3** | 41.8 | RADV (+13%) |
| Qwen3 30B-A3B MoE Q4_K_M | pp512 | **1,142** | 1,098 | RADV (+4%) |
| Qwen3 30B-A3B MoE Q4_K_M | tg128 | **86.1** | 66.2 | RADV (+30%) |
| Llama 3.1 70B Q4_K_M | pp512 | 81.6 | **123.9** | HIP (+52%) |
| Llama 3.1 70B Q4_K_M | tg128 | **5.1** | 4.9 | RADV (+4%) |
| Qwen3-Coder-Next 80B-A3B Q4_K_M | pp512 | **531** | 535 | Tie (~1%) |
| Qwen3-Coder-Next 80B-A3B Q4_K_M | tg128 | **42.7** | 39.5 | RADV (+8%) |
| Qwen3-Coder-Next 80B-A3B Q4_K_M | pp8192 | — | 354 | HIP only (8K context) |

**Analysis:**
- ROCm 7.2 HIP wins prompt processing on dense models (7B: +10%, 70B: +52%)
- Vulkan RADV wins token generation across the board (13–30% faster)
- For MoE models (Qwen3 30B-A3B), RADV wins both pp and tg
- ROCm 7.2 has a known compiler regression ([llvm/llvm-project#147700](https://github.com/llvm/llvm-project/pull/147700)) affecting loop unrolling — kyuz0's container includes a workaround but may not fully resolve it
- ROCm 6.4.4 may perform better (kyuz0's best pp numbers come from 6.4.4, not 7.2)

**Recommendation by workload:**
- **Interactive chat / token generation** → Vulkan RADV
- **Batch processing / embeddings / large prompt ingestion** → ROCm HIP (especially for 70B+ models)

## Qwen3-235B-A22B (Q3_K_M) — The 128GB Play

235B total parameters, 22B active (128 experts, 8 active per token). This is the largest model we can fit in 128 GB — the Q3_K_M quant uses 105 GB, leaving ~18 GB for KV cache and OS.

### Vulkan RADV vs ROCm 7.2 HIP (120W)

| Model | Size | Backend | pp512 (t/s) | tg128 (t/s) |
|-------|------|---------|-------------|-------------|
| Qwen3-235B-A22B Q3_K_M | 104.72 GiB | **Vulkan RADV** | 101.34 ± 1.10 | **17.21 ± 0.01** |
| Qwen3-235B-A22B Q3_K_M | 104.72 GiB | **ROCm 7.2 HIP** | **169.92 ± 0.76** | 14.32 ± 0.01 |

**Analysis:**
- Same pattern as other models: HIP wins pp (+67%), RADV wins tg (+20%)
- At 17.2 t/s (RADV) / 14.3 t/s (HIP), interactive chat is possible but sluggish — a 300-token response takes ~17–21 seconds
- The 22B active params make this roughly 6× slower at token generation than the 3B-active MoE models (Qwen3 30B-A3B, Coder-Next)
- Memory is extremely tight: 121–122 GB used out of 123 GB, leaving minimal room for KV cache — long conversations may OOM
- **Best use case**: Async/batch tasks where quality matters more than speed. For interactive chat, Qwen3 30B-A3B (86 t/s) remains the better choice

## MiniMax MoE Models — The Large Model Shootout

Testing frontier-class MoE models that push 128 GB to the limit. All tests: Vulkan RADV, 120W TDP.

### MiniMax M2.1-REAP-139B-A10B (Q4_K_M) — 78.4 GiB

139B total parameters (pruned from 230B via REAP), 10B active (192 experts, 8 active per token). 196K context. 74% SWE-bench Verified.

| Model | Size | Params | pp512 (t/s) | tg128 (t/s) |
|-------|------|--------|-------------|-------------|
| MiniMax M2.1-REAP-139B-A10B Q4_K_M | 78.40 GiB | 139.15B | 202.75 ± 1.24 | **29.29 ± 0.00** |

**Analysis:**
- At 29.3 t/s, this is **70% faster** than Qwen3-235B (17.2 t/s) — the active param ratio predicts this perfectly (10B vs 22B active)
- pp512 at 203 t/s is 2× faster than Qwen3-235B (101 t/s) — fewer expert weights to stream through
- Comfortably fits in 128 GB with ~44 GB headroom for KV cache — can handle long contexts without OOM
- **Best "big brain" model for interactive use**: 29 t/s is genuinely usable for chat, a 300-token response takes ~10 seconds
- Quality vs Qwen3-235B is a tradeoff: M2.1-REAP scores 74% SWE-bench vs Qwen3-235B's higher raw intelligence, but the speed difference makes M2.1-REAP far more practical

### MiniMax M2.5 (Q3_K_M) — 101.76 GiB — 🏆 New Champion

229B total parameters, ~10B active (256 experts, 8 active per token). 80.2% SWE-bench Verified (matches Claude Opus 4.6). Q3_K_M quant from [DevQuasar](https://huggingface.co/DevQuasar/MiniMaxAI.MiniMax-M2.5-GGUF).

| Model | Size | Params | pp512 (t/s) | tg128 (t/s) |
|-------|------|--------|-------------|-------------|
| MiniMax M2.5 Q3_K_M | 101.76 GiB | 228.69B | 155.53 ± 0.99 | **32.82 ± 0.07** |

**Analysis:**
- At 32.8 t/s, **12% faster than M2.1-REAP** (29.3 t/s) despite similar active params (~10B) — the Q3_K_M quant is smaller per-expert, reducing memory bandwidth per token
- Fits comfortably with ~21 GB headroom for KV cache and OS
- pp512 at 156 t/s is slower than M2.1-REAP (203 t/s) — more total expert weights to handle during prompt processing
- 80.2% SWE-bench Verified vs M2.1-REAP's 74% — strictly better quality
- **Best frontier model you can run locally on 128 GB**: a 300-token response takes ~9 seconds

### MiniMax M2.5 (IQ4_XS) — 114.8 GiB — ❌ OOM

The ubergarm IQ4_XS quant (mainline llama.cpp-compatible) is too large at 115 GB — OOM killed.

### MiniMax M2.5 (ik_llama.cpp IQ3_KS) — 87.2 GiB — ❌ No Vulkan Shaders

The ubergarm smol-IQ3_KS quant fits in RAM (87 GB) but ik_llama.cpp lacks Vulkan compute shaders for the IQ3_KS type. Result: **0.88 t/s** — unusable. Falls back to CPU dequant. Use Q3_K_M from DevQuasar instead.

### Large MoE Comparison

| Model | Active Params | Size | tg128 (t/s) | SWE-bench | Fits 128GB? |
|-------|--------------|------|-------------|-----------|-------------|
| Qwen3 30B-A3B MoE | 3B | 17.3 GiB | **86.1** | N/A | ✅ Plenty |
| Qwen3-Coder-Next 80B-A3B | 3B | 45.2 GiB | **42.7** | N/A | ✅ Comfortable |
| **MiniMax M2.5 Q3_K_M** | **~10B** | **101.8 GiB** | **32.8** 🏆 | **80.2%** | **✅ Comfortable** |
| MiniMax M2.1-REAP-139B | 10B | 78.4 GiB | 29.3 | 74% | ✅ Comfortable |
| Qwen3-235B-A22B | 22B | 104.7 GiB | 17.2 | N/A | ⚠️ Tight |
| MiniMax M2.5 IQ4_XS | ~10B | 114.8 GiB | OOM | 80.2% | ❌ No |
| MiniMax M2.5 IQ3_KS (ik_llama) | ~10B | 87.2 GiB | 0.88 💀 | 80.2% | ⚠️ No Vulkan shaders |

**Key insight:** Active parameters determine token generation speed almost perfectly on memory-bandwidth-bound hardware. At ~256 GB/s LPDDR5X bandwidth:
- 3B active → ~86 t/s (Qwen3 30B-A3B)
- 10B active → ~29 t/s (MiniMax M2.1-REAP)
- 22B active → ~17 t/s (Qwen3-235B)

## Real-World llama-server Testing — MiniMax M2.5 Q3_K_M

Tested via `llama-server` with OpenAI-compatible API, Vulkan RADV, 120W TDP. Server config: `-ngl 99 -c 196608 -ctk q4_0 -ctv q4_0 -fa on --jinja`.

Full 196K native context window with Q4_0 KV cache quantization. Memory usage: ~117 GiB of 123 GiB (~6 GiB headroom).

### Test Results

| Test | Prompt Tokens | Generated Tokens | Prompt Speed | Generation Speed | Wall Time | Finish |
|------|--------------|-----------------|-------------|-----------------|-----------|--------|
| Coding (palindrome function) | 57 | 783 | 38.6 t/s | 28.8 t/s | 29s | stop |
| Math (optimization problem) | 83 | 1,571 | 50.8 t/s | 29.7 t/s | 53s | stop |
| Architecture (distributed rate limiter) | 83 | 5,836 | 50.8 t/s | 29.7 t/s | 3m18s | stop |

### Analysis

- **Generation speed is consistent at ~29.7 t/s** regardless of response length (783 → 5,836 tokens)
- **No degradation from 196K context allocation** — same speed as the 4K context benchmark (32.8 t/s bench vs 29.7 t/s real-world; the ~10% gap is typical server overhead: chat template processing, sampling, API serialization)
- **Reasoning overhead**: The model uses `<think>` tokens before answering. The coding test used ~350 reasoning + ~430 answer tokens. The architecture test used ~2,000 reasoning + ~3,800 answer tokens. All tokens generate at the same speed — reasoning just adds wall time.
- **Quality**: Genuinely strong output. The architecture question produced a 22K-char response with ASCII diagrams, Go pseudocode, component tables, CAP theorem analysis, and failure mode discussion. Comparable to senior engineer output.
- **Memory**: 117 GiB used with 196K context allocated. For shorter context (-c 4096), only ~104 GiB used with much more headroom. In practice, even multi-turn conversations rarely exceed 32K tokens.

### Practical Recommendations

- **Daily driver config**: `-c 32768 -ctk q4_0 -ctv q4_0` — plenty of context, ~15 GiB headroom
- **Maximum context**: `-c 196608 -ctk q4_0 -ctv q4_0` — works but tight (~6 GiB free), risk of OOM on very long conversations
- **Speed expectation**: ~30 t/s sustained. A typical coding answer takes 15-30s. A detailed architecture response takes 2-3 minutes.

## New Models — February 14, 2026

Tested via `llama-server` with OpenAI-compatible chat completions API, Vulkan RADV, 120W TDP. Server config: `-ngl 99 -fa on -ctk q4_0 -ctv q4_0 --jinja`.

> **Note:** These results are from real llama-server API calls (not `llama-bench`). The `timings` object in the API response provides per-request prompt and generation speed. Results are representative of actual interactive performance including server overhead.

### GPT-OSS 120B (Q4_K_M) — OpenAI Open-Weight MoE

OpenAI's first open-weight model. 117B total parameters, **5.1B active** (MoE), 131K context, Apache 2.0 license. Uses "Harmony" response format with built-in reasoning (`reasoning_content` field).

- **Source**: [unsloth/gpt-oss-120b-GGUF](https://huggingface.co/unsloth/gpt-oss-120b-GGUF)
- **Quant**: Q4_K_M (58.5 GiB, 2 splits)
- **RAM usage**: ~60 GiB with 65K context allocated
- **Server config**: `-c 65536 -ctk q4_0 -ctv q4_0 -fa on --jinja`

| Test | Prompt Tokens | Generated Tokens | Prompt Speed | Generation Speed |
|------|--------------|-----------------|-------------|-----------------|
| Math reasoning (15×37) | 85 | 255 | 120.2 t/s | **53.4 t/s** |

**Analysis:**
- At **53.4 t/s**, GPT-OSS sits exactly where the active-params formula predicts for 5.1B active: between Qwen3-Coder-Next (3B active → 42.7 t/s bench) and Nemotron-3 Nano (3B active → 61.5 t/s)
- The slightly higher speed vs Coder-Next despite more active params (5.1B vs 3B) is because the test used shorter generation (tg255 vs tg128 bench), and llama-server overhead is lower on shorter prompts
- Built-in reasoning mode works — model outputs `reasoning_content` alongside the final answer
- 58.5 GiB model weight leaves ~62 GiB headroom on 128 GB — very comfortable, plenty of room for long contexts
- Correct math reasoning on first try (555 ✓)
- **Best use case**: General-purpose open-weight model with reasoning. Good balance of speed, quality, and memory efficiency. Apache 2.0 license is ideal for commercial/self-hosted use.

### Nemotron-3 Nano 30B-A3B (MXFP4_MOE) — NVIDIA Lightweight MoE

NVIDIA's lightweight MoE model. 30B total parameters, **3B active**, **1M native context window**, MXFP4 quant (4-bit mixed precision). Built-in thinking mode.

- **Source**: [noctrex/Nemotron-3-Nano-30B-A3B-MXFP4_MOE-GGUF](https://huggingface.co/noctrex/Nemotron-3-Nano-30B-A3B-MXFP4_MOE-GGUF)
- **Quant**: MXFP4_MOE (17.6 GiB)
- **RAM usage**: ~18 GiB — massive headroom on 128 GB
- **Server config**: `-c 32768 -ctk q4_0 -ctv q4_0 -fa on --jinja`

| Test | Prompt Tokens | Generated Tokens | Prompt Speed | Generation Speed |
|------|--------------|-----------------|-------------|-----------------|
| Math reasoning (15×37) | ~50 | ~308 | 112.0 t/s | **61.5 t/s** |

**Analysis:**
- At **61.5 t/s**, Nemotron-3 Nano is the **fastest non-trivial model tested** — only TinyLlama 1.1B (249 t/s) and Llama 3.2 3B (60.9 t/s) are in the same range, and neither has comparable intelligence
- 3B active params → perfectly aligned with bandwidth predictions (Qwen3 30B-A3B also has 3B active at 86.1 t/s bench; the gap is llama-server overhead vs raw llama-bench)
- **Only 18 GiB RAM** — leaves 105 GiB free. Could theoretically allocate massive KV cache for the 1M context window
- Tool calling works out of the box — tested with exec and file operations via OpenAI function calling format
- Thinking mode (`<think>` tokens) enabled by default
- Correct math reasoning on first try (555 ✓)
- **Best use case**: Fast local agent/assistant. Ideal for OpenClaw or similar AI agent frameworks where speed matters more than frontier intelligence. The 1M context window is unprecedented at this model size.

### Updated Large MoE Comparison

| Model | Active Params | Size | tg (t/s) | Source | Context | Fits 128GB? |
|-------|--------------|------|----------|--------|---------|-------------|
| Qwen3 30B-A3B MoE | 3B | 17.3 GiB | **86.1** ⭐ | llama-bench | 32K | ✅ Plenty |
| **Nemotron-3 Nano 30B-A3B** | **3B** | **17.6 GiB** | **61.5** | llama-server | **1M** | **✅ Plenty** |
| **GPT-OSS 120B** | **5.1B** | **58.5 GiB** | **53.4** | llama-server | **131K** | **✅ Comfortable** |
| Qwen3-Coder-Next 80B-A3B | 3B | 45.2 GiB | 42.7 | llama-bench | 262K | ✅ Comfortable |
| MiniMax M2.5 Q3_K_M | ~10B | 101.8 GiB | 32.8 🏆 | llama-bench | 196K | ✅ Comfortable |
| MiniMax M2.1-REAP-139B | 10B | 78.4 GiB | 29.3 | llama-bench | 196K | ✅ Comfortable |
| Qwen3-235B-A22B | 22B | 104.7 GiB | 17.2 | llama-bench | 32K | ⚠️ Tight |
| MiniMax M2.5 IQ4_XS | ~10B | 114.8 GiB | OOM | — | — | ❌ No |
| MiniMax M2.5 IQ3_KS (ik_llama) | ~10B | 87.2 GiB | 0.88 💀 | llama-bench | — | ⚠️ No Vulkan shaders |

**Key insight:** Active parameters determine token generation speed almost perfectly on memory-bandwidth-bound hardware. At ~256 GB/s LPDDR5X bandwidth:
- 3B active → ~61–86 t/s (Nemotron-3 Nano, Qwen3 30B-A3B)
- 5.1B active → ~53 t/s (GPT-OSS 120B)
- 10B active → ~29–33 t/s (MiniMax M2.1-REAP, M2.5)
- 22B active → ~17 t/s (Qwen3-235B)

## GPT-OSS 120B Derestricted — Driver Backend Comparison

Tested the derestricted i1-Q3_K_M quant (66.2 GiB) across three backends with freshly built llama.cpp (commit `079feab9e`, 2026-02-14). All 120W TDP.

| Backend | Build | Load Time | pp (t/s) | tg (t/s) | Notes |
|---------|-------|-----------|----------|----------|-------|
| **Vulkan RADV** | `/tmp/llama-vulkan-new/` | ~45s | **330–359** | **46–50** ✅ | mmap shares unified LPDDR5X directly (zero-copy) |
| **CPU** (32 threads) | `/tmp/llama-cpu/` | ~60s | **117.9** | 20.6 | Zen 5 AVX-512 wins pp; loses tg 2.4× |
| **ROCm 6.4 HIP** | `/tmp/llama-hip/` | >30min ❌ | DNF | DNF | Stuck at tensor upload (54/67 GB after 25 min). Killed. |

**Key insight:** HIP's explicit GPU memory copy model is catastrophically broken on Strix Halo's unified memory. It tries to copy 67 GB from "system" RAM to "GPU" RAM — but they're the same physical LPDDR5X. Vulkan RADV uses mmap to share the memory directly (zero-copy), which is why it loads in 45 seconds vs HIP never finishing.

CPU is a viable alternative for prompt-heavy workloads where Zen 5's AVX-512 matrix ops outperform Vulkan's prompt processing (118 vs 80–360 t/s depending on prompt structure). But for generation, Vulkan is 2.4× faster.

## Qwen3-Coder-Next — 262K Native Context

GGUF metadata confirms `qwen3next.context_length: 262144` — the model was trained at 262K natively. Architecture details from metadata:

| Parameter | Value |
|-----------|-------|
| Native context | 262,144 |
| Layers | 48 |
| KV heads | 2 (heavy GQA) |
| Key/Value dim | 256 each |
| Experts | 512 total, 10 active |
| RoPE freq base | 5,000,000 |
| Attention pattern | Full attention every 4th layer (rest sliding window) |

Running at full 262K (`-c 262144 -fa on`), FP16 KV cache (no quantization — unnecessary with 128 GB):

- **KV cache**: ~24.6 GiB at full 262K
- **Total RSS**: ~53 GiB (model 46 + KV ~7 pre-allocated)
- **No speed regression** vs 128K on short/medium prompts

### API Benchmark Results (262K context)

| Test | Time | Prompt | Completion | Speed | Result |
|------|------|--------|------------|-------|--------|
| Simple Q&A | 0.5s | 34 | 2 | — | ✅ Correct |
| Code gen (TypeScript) | 13.1s | 111 | 575 | 44 t/s | ✅ Clean output |
| Single tool call | 2.2s | 573 | 23 | — | ✅ `read_file` |
| Multi-turn (read→synth) | 5.0s | 690→808 | 22→85 | — | ✅ Correct |
| Edit file (NaN fix) | 4.7s | 575 | 128 | — | ✅ Perfect exact match |
| Large prompt (3.2K tok) | 11.3s | 3,265 | 116 | ~82 t/s | ✅ Good analysis |

## Qwen3-Coder-Next REAP-48B — Expert-Pruned Variant ❌

[lovedheart/Qwen3-Coder-Next-REAP-48B-A3B-GGUF](https://huggingface.co/lovedheart/Qwen3-Coder-Next-REAP-48B-A3B-GGUF) — 40% expert pruning via REAP (Router-weighted Expert Activation Pruning). 512→308 experts, same 3B active params, same 262K context.

- **Quant**: Q4_K_XL (31.1 GiB vs original 45.2 GiB)
- **Server**: Vulkan RADV, `-c 262144 -fa on --jinja`

### Head-to-Head: REAP-48B vs Original 80B

| Test | Original 80B | REAP 48B | Ratio |
|------|-------------|----------|-------|
| Simple Q&A | 0.5s | 5.1s | 10× slower ❌ |
| Code gen (575-623 tok) | 13.1s (44 t/s) | 34.9s (17.8 t/s) | 2.5× slower ❌ |
| Tool call | 2.2s | 6.7s | 3× slower ❌ |
| Multi-turn | 5.0s | 11.3s | 2.3× slower ❌ |
| Edit file | 4.7s | 15.8s | 3.4× slower ❌ |
| Large prompt (3.3K) | 11.3s | 36.2s | 3.2× slower ❌ |
| Tool quality | ✅ All correct | ✅ All correct | Tie |
| Disk | 45.2 GiB | 31.1 GiB | ✅ REAP saves 14 GiB |
| RAM (with 262K KV) | 53 GiB | 54 GiB | Tie |

**Verdict: Not recommended.** Despite identical 3B active parameters, REAP-48B is 2–3× slower across all tests. The Q4_K_XL quant type may be less optimized than Q4_K_M in llama.cpp's Vulkan shaders, and the reduced expert pool may cause suboptimal routing. Tool calling quality is preserved, but the speed regression makes it worse than even dense 24B models (Mistral Small 3.2 at 15.1 t/s). The only advantage — 14 GiB less disk space — is irrelevant with 1.5 TB free.

## Optimization Parameter Ablation — February 15, 2026

Systematic testing of commonly recommended llama-server optimization flags. All tests on Qwen3-Coder-Next 80B-A3B Q4_K_M, Vulkan RADV, `-c 262144 -fa on`, 120W TDP.

### Speculative Decoding (ngram-mod)

Tested ngram-based speculative decoding — predicts upcoming tokens from n-gram patterns in already-generated text, verifies in batch. No draft model required.

**Flags tested:** `--spec-type ngram-mod --spec-ngram-size-n 12 --draft-min 16 --draft-max 32`

| Test | Tokens | Spec Decoding | Generation (t/s) | Prompt Eval (t/s) |
|------|--------|--------------|-------------------|-------------------|
| TypeScript BST (baseline) | 512 | ❌ Off | **46.0** | 66.8 (cold) |
| TypeScript BST | 512 | ✅ ngram-mod | **46.05** | 181.9 (cache) |
| Express CRUD routes | 2,048 | ✅ ngram-mod | **45.08** | 227.4 |
| Jest unit tests | 2,048 | ✅ ngram-mod | **45.10** | 182.5 |

**Verdict: No improvement.** Generation speed is identical (within noise). The 2,048-token tests with highly repetitive patterns (CRUD boilerplate, test case boilerplate) showed no benefit — actually 1-2% slower due to speculation overhead.

**Why:** Qwen3-Coder-Next uses 512 experts with 10 active per token, producing high-entropy output that n-gram pattern matching cannot predict. The speculative overhead (evaluating candidate tokens + verification) costs more than it saves. Ngram speculation may work better on dense models with more predictable output distributions.

### Unified KV Cache + No-Mmap

**Flags tested:** `--kv-unified --no-mmap`

| Config | Generation (t/s) | Prompt Eval (t/s) |
|--------|-------------------|-------------------|
| Default (no flags) | **46.0** | 181.9 |
| `--kv-unified --no-mmap` | **46.01** | 180.8 |

**Verdict: No improvement.** Both flags are no-ops on Strix Halo:
- `--kv-unified` is designed for split CPU/GPU memory configurations. On Strix Halo, LPDDR5X is already unified — there's nothing to unify.
- `--no-mmap` prevents lazy page faults by loading the full model at startup. Vulkan RADV already maps model weights into GPU-visible memory on startup, making this redundant.

### Batch Size Tuning

**Flags tested:** `-b` (logical batch) and `-ub` (physical ubatch) at various sizes.

| Config | Prompt Eval (t/s) | Generation (t/s) |
|--------|-------------------|-------------------|
| Default (`-b 2048 -ub 512`) | **224.3** | **46.1** |
| `-b 512 -ub 512` | **225.2** | **45.9** |
| `-b 2048 -ub 1024` | **224.8** | **46.0** |
| `-b 4096 -ub 2048` | **223.0** | **46.0** |

Test prompt: 87 tokens (HTTP server framework design), 512 tokens generated.

**Verdict: No improvement.** All four configurations produce identical results within noise margin (±0.2 t/s). The GPU compute units are not the bottleneck — memory bandwidth is. Changing how work is batched doesn't help when the GPU is idle waiting for memory reads.

### Summary: The Bandwidth Wall

Every software optimization tested hits the same fundamental limit: **~160 GB/s effective LPDDR5X bandwidth**. The GPU's 40 RDNA 3.5 compute units are largely idle during token generation — they finish computing each token's forward pass before the next chunk of model weights arrives from memory.

| Optimization | Expected Benefit | Actual Result | Why |
|-------------|-----------------|---------------|-----|
| Ngram speculative decoding | Free speed boost | ❌ 0% (±1%) | MoE high entropy defeats n-gram prediction |
| `--kv-unified` | Better unified mem | ❌ 0% | Already unified (Strix Halo) |
| `--no-mmap` | Faster loading | ❌ 0% | Vulkan already maps fully |
| Batch size (512→4096) | Better throughput | ❌ 0% | Bandwidth-limited, not compute-limited |

**What would actually help:**
1. **KV cache quantization** (`-ctk q4_0 -ctv q4_0`) — reduces attention bandwidth at long contexts. But risks quality degradation (reenz0h reports garbage output with KV quants below Q8 on GPT-OSS 120B). Not worth it when RAM is plentiful.
2. **Smaller model quant** (IQ4_XS) — less bandwidth per weight read, but quality drops and Vulkan shader support is limited.
3. **Different hardware** — HBM (datacenter GPUs, DGX Spark), faster RAM, or dedicated VRAM with higher bandwidth.

For Strix Halo at 46 t/s generation: **the setup is already optimal. The lemon is dry.**

## ROCm 6.4 HIP + Flash Attention + hipBLASLt — February 15, 2026

Fresh llama.cpp build (`9e118b9`) with ROCm 6.4 HIP, compiled with `-DGGML_CUDA_FA=ON` (flash attention for HIP). Tested with `hipblaslt` package installed and `ROCBLAS_USE_HIPBLASLT=1` environment variable. All tests: 120W TDP, Qwen3-Coder-Next 80B-A3B Q4_K_M.

### Build Configuration

```bash
cmake -B build \
    -DGGML_HIP=ON \
    -DGGML_HIP_NO_VMM=ON \
    -DGGML_CUDA_FA=ON \
    -DAMDGPU_TARGETS=gfx1151 \
    -DCMAKE_BUILD_TYPE=Release
```

### Results

| Configuration | pp512 (t/s) | tg128 (t/s) | Notes |
|--------------|-------------|-------------|-------|
| HIP + FA + hipBLASLt | 573.46 ± 22.40 | 37.57 ± 0.01 | `ROCBLAS_USE_HIPBLASLT=1` |
| HIP + FA (no hipBLASLt) | 575.21 ± 15.15 | 37.39 ± 0.01 | hipBLASLt not yet installed |
| HIP + hipBLASLt, no FA | 571.60 ± 20.46 | 37.29 ± 0.01 | `-fa 0` |
| HIP cold run (first after build) | 371.45 ± 7.91 | 24.52 ± 1.01 | Cold cache / first load penalty |

### Comparison vs Previous Backends (Qwen3-Coder-Next 80B-A3B Q4_K_M)

| Backend | pp512 (t/s) | tg128 (t/s) | Notes |
|---------|:-----------:|:-----------:|-------|
| **Vulkan RADV** | 531 | **42.7** ✅ | Still best for token generation |
| ROCm 6.4 HIP + FA + hipBLASLt (new) | **575** ✅ | 37.6 | Best prompt processing |
| ROCm 7.2 HIP (kyuz0 b8063, Feb 15) | 535 | **39.5** | Latest container, best HIP tg |
| ROCm 7.2 HIP (kyuz0 b8038, earlier) | 559 | 37.9 | Previous container |
| ROCm 6.4.4 HIP (kyuz0 container) | 556 | 35.4 | Previous baseline |

### Key Findings & Gotchas

1. **hipBLASLt makes no difference on MoE models.** The `ROCBLAS_USE_HIPBLASLT=1` env var is a runtime flag that tells rocBLAS to use hipBLASLt internally — no special compile flag needed. But on Qwen3-Coder-Next (MoE, 3B active), the GEMM operations are too small to benefit. hipBLASLt likely helps more on dense models with larger matrix multiplications.

2. **Flash Attention makes no difference at small context sizes.** FA vs no-FA at pp512/tg128 is within margin of error (575 vs 572 pp, 37.6 vs 37.3 tg). FA's benefit is at **large context windows** (8K+) where it reduces memory usage and maintains speed. This aligns with [hardware-corner.net's analysis](https://www.hardware-corner.net/strix-halo-llm-optimization/).

3. **Cold run penalty is severe.** First benchmark after build showed 371 pp / 24.5 tg — a 35% penalty. Subsequent runs consistently hit 575/37.6. Always discard the first run or do a warm-up pass.

5. **Vulkan RADV still wins for interactive use.** Despite HIP's 8% pp advantage, Vulkan RADV's 13% tg advantage makes it the better choice for chat/agent workloads where token generation speed determines user experience.

## Data availability

Benchmark summaries in this repository are kept as curated markdown tables and notes.
Raw machine logs are intentionally excluded from version control.
## Qwen3.5-397B RPC Stability Isolation (2026-02-20)

A targeted A/B run on Bee+Evo (`--ctx-size 131072 -np 4`, HIP+RPC, `-dio`) showed that failures were not solely token-count driven.

- `opt` repeated prompt shape at ~5k tokens: **10/10 pass**
- `contexttoken` repeated prompt shape at ~5k tokens: **fails on first attempt** with `Memory access fault by GPU node-1`
- Follow-up direct checks on `opt` shape passed at:
  - ~20k prompt tokens (2/2)
  - ~32k prompt tokens (2/2)

This explains earlier contradictory runs (baseline matrix pass vs staircase/ceiling fail): synthetic prompt shape can trigger a crash path even at moderate token counts.

Detailed write-up: `results/2026-02-20_qwen397b-prompt-shape-sensitivity.md`
