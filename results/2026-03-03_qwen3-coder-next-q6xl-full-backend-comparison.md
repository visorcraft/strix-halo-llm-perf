# 2026-03-03 — Full Backend Comparison: Qwen3-Coder-Next Q6_K_XL

## Setup

- **Host:** Bee (Beelink GTR9 Pro, Ryzen AI Max+ 395, 128 GB)
- **Model:** Qwen3-Coder-Next UD Q6_K_XL (63.87 GiB, 79.67B params, MoE 80B-A3B)
- **llama.cpp:** visorcraft fork, `53f151590` (merged upstream through b8192)
- **Containers:** All kyuz0 distrobox containers freshly recreated from pulled images
- **Benchmark:** `llama-bench -p 512 -n 128 -r 3` (ROCm: `-fa 1 -mmp 0 -ub 2048 -ctk q4_0 -ctv q4_0`)

## Results

| Backend | Version | Build | pp512 (t/s) | tg128 (t/s) |
|---|---|---|---:|---:|
| Host (build-rpc-hip-v2) | ROCm 6.4.2 | 53f151590 (105) | 494.97 ± 13.79 | 31.65 ± 0.00 |
| Container (kyuz0) | ROCm 6.4.4 | 137435ff (8192) | 460.51 ± 59.30 | 31.58 ± 0.01 |
| Container (kyuz0) | ROCm 7.2 | 137435ff (8192) | 501.32 ± 0.97 | 32.69 ± 0.00 |
| Container (kyuz0) | ROCm 7.0 nightlies | 137435ff (8192) | 501.71 ± 5.53 | 32.78 ± 0.01 |
| Container (kyuz0) | Vulkan RADV (Mesa) | 137435ff (8192) | 448.32 ± 3.35 | 34.03 ± 0.13 |
| Container (kyuz0) | Vulkan AMDVLK | 137435ff (8192) | 358.27 ± 1.52 | 38.65 ± 0.04 |
| Host native | Vulkan RADV (Mesa) | f0603802 (8163) | 467.97 ± 0.44 | 36.80 ± 0.03 |

## Rankings

### Token Generation (tg128)

1. Vulkan AMDVLK — **38.65 t/s**
2. Host Vulkan RADV — 36.80 t/s
3. Container Vulkan RADV — 34.03 t/s
4. ROCm 7.0 nightlies — 32.78 t/s
5. ROCm 7.2 — 32.69 t/s
6. Host ROCm 6.4.2 — 31.65 t/s
7. ROCm 6.4.4 — 31.58 t/s

### Prompt Processing (pp512)

1. ROCm 7.0 nightlies — **501.71 t/s**
2. ROCm 7.2 — 501.32 t/s
3. Host ROCm 6.4.2 — 494.97 t/s
4. Host Vulkan RADV — 467.97 t/s
5. ROCm 6.4.4 — 460.51 t/s
6. Container Vulkan RADV — 448.32 t/s
7. Vulkan AMDVLK — 358.27 t/s

## Key Observations

- **AMDVLK is the surprise tg winner** — 38.65 t/s, +16% over ROCm 7.x, reversing previous "not recommended" status
- **All Vulkan backends beat all ROCm backends on tg** for this model/quant
- **ROCm 7.x still dominates pp** with ~501 t/s
- **AMDVLK has a severe pp penalty** (358 vs 502 t/s, -29%) — tradeoff for tg lead
- **Host native Vulkan RADV > Container Vulkan RADV** on both pp and tg

## Changes vs Feb 25

| Metric | Feb 25 | Mar 3 | Delta |
|---|---|---|---|
| Best tg | ROCm 7.x (33.26) | AMDVLK (38.65) | +16.2% |
| Best pp | Host ROCm 6.4.2 (496.38) | ROCm 7.x nightlies (501.71) | +1.1% |
| ROCm 7.x tg | 33.26 | 32.78 | -1.4% (noise) |
| ROCm 6.4.x tg | 31.90 | 31.58 | -1.0% (noise) |
