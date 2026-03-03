# 🚀 Strix Halo LLM Performance

Benchmarks and reproducible setup notes for local and distributed LLM inference on **Ryzen AI Max+ 395 (Strix Halo)** using `llama.cpp`.

> **Test systems:**
> - **Evo** = GMKtec EVO-X2 (Ryzen AI Max+ 395)
> - **Bee** = Beelink GTR9 Pro (Ryzen AI Max+ 395)
> - Both hosts have **128 GB unified LPDDR5X** and are linked by a direct **USB4/Thunderbolt cable (~9.4 Gbps measured)** for distributed RPC inference.

## TL;DR

- **Qwen3 30B-A3B MoE Q4_K_M:** **86.1 t/s** token generation (single host, Vulkan)
- **MiniMax M2.5 Q3_K_M (228.7B):** **32.8 t/s** token generation (single host, Vulkan)
- **Qwen3-Coder-Next 80B-A3B Q4_K_M:** **42.7 t/s** token generation
- **GPT-OSS 120B Q4_K_M:** **53.4 t/s** generation in llama-server tests
- **Nemotron-3 Nano 30B-A3B MXFP4:** **61.5 t/s** generation in llama-server tests

---

## 1) Hardware

| Component | Evo | Bee |
|---|---|---|
| System | GMKtec EVO-X2 | Beelink GTR9 Pro |
| SoC | Ryzen AI Max+ 395 | Ryzen AI Max+ 395 |
| CPU | 16C/32T Zen 5 | 16C/32T Zen 5 |
| iGPU | Radeon 8060S (gfx1151, 40 CU) | Radeon 8060S (gfx1151, 40 CU) |
| Memory | 128 GB unified LPDDR5X | 128 GB unified LPDDR5X |

**Distributed link:** direct USB4/Thunderbolt between Evo and Bee, ~9.4 Gbps effective in testing.

## 2) Software Stack

- **OS:** Fedora 43 (both hosts)
- **Kernel:** 6.18.x class
- **Primary backend:** ROCm 7.0 nightlies (via kyuz0 distrobox container)
- **Secondary backends:** Vulkan RADV (Mesa), ROCm 6.4.x (host), ROCm 7.2 (container)
- **Inference engine:** `llama.cpp`
- **Power profile:** 85W/120W tested; 120W usually wins for 7B+ models

## 3) Quick Start (Vulkan container)

```bash
podman pull docker.io/kyuz0/amd-strix-halo-toolboxes:vulkan-radv

distrobox create --name llama-vulkan-radv \
  --image docker.io/kyuz0/amd-strix-halo-toolboxes:vulkan-radv --yes

podman start llama-vulkan-radv

# benchmark example
podman exec llama-vulkan-radv bash -lc \
  "llama-bench -m ~/models/Qwen3-Coder-Next-Q4_K_M.gguf -ngl 99 -p 512 -n 128"
```

## 4) Single-Host Benchmarks (best results)

All rows below are working results only, using best observed configuration per model.

| Model | Size | Params | pp512 (t/s) | tg128 (t/s) |
|---|---:|---:|---:|---:|
| TinyLlama 1.1B Q4_K_M | 636 MiB | 1.10B | 6,513 | 249 |
| Llama 3.2 3B Q8_0 | 3.18 GiB | 3.21B | 2,248 | 60.9 |
| Llama 2 7B Q4_K_M | 3.80 GiB | 6.74B | 1,074 | 47.3 |
| Qwen2.5-Coder 7B Q6_K | 5.82 GiB | 7.62B | 1,089 | 36.7 |
| Qwen2.5 14B Q4_K_M | 8.37 GiB | 14.77B | 600 | 24.5 |
| Qwen3 30B-A3B MoE Q4_K_M | 17.28 GiB | 30.53B | 1,142 | **86.1** |
| Qwen2.5 32B Q4_K_M | 18.48 GiB | 32.76B | 242 | 11.3 |
| Llama 3.1 70B Q4_K_M | 39.59 GiB | 70.55B | 81.6 | 5.1 |
| Qwen3-Coder-Next 80B-A3B Q4_K_M | 45.17 GiB | 79.67B | 531 | 42.7 |
| GPT-OSS 120B Q4_K_M* | 58.5 GiB | 116.83B | 120 | 53.4 |
| MiniMax M2.1-REAP-139B Q4_K_M | 78.40 GiB | 139.15B | 203 | 29.3 |
| MiniMax M2.5 Q3_K_M | 101.76 GiB | 228.69B | 156 | **32.8** |
| Qwen3-235B-A22B Q3_K_M | 104.72 GiB | 235.09B | 101 | 17.2 |
| Nemotron-3 Nano 30B-A3B MXFP4* | 17.6 GiB | 30.0B | 112 | 61.5 |

\* llama-server measured rows (real API usage); includes serving overhead vs raw `llama-bench`.

### MiniMax M2.5 real-world summary

MiniMax M2.5 Q3_K_M sustains roughly **~30 t/s** in llama-server usage with long-context configurations, with strong practical output quality for coding/math/architecture prompts.

## 5) Backend Comparison (Vulkan vs ROCm, key models)

Winners-only view:

| Model | Best Prompt Processing (pp) | Best Generation (tg) |
|---|---|---|
| Qwen3-Coder-Next Q6_K_XL (single host) | ROCm 7.x nightlies (~502 pp) | **Vulkan AMDVLK (~38.7 tg)** |
| Qwen3-Coder-Next Q6_K_XL (RPC 2-host) | ROCm 7.0 nightlies (~490 pp) | ROCm 7.x container (~26.3 tg) |
| Qwen3-Coder-Next 80B-A3B Q4_K_M | ROCm 6.4.4 (~581 pp) | Vulkan RADV (~43.5 tg) |
| MiniMax M2.5 Q3_K_M | ROCm 6.4.4/7.x (~214 pp) | Vulkan RADV (~34.3 tg) |
| Qwen3 30B-A3B MoE Q4_K_M | Vulkan RADV | Vulkan RADV |

**Latest finding (Mar 3, 2026):** Full 7-backend comparison for Q6_K_XL reveals **Vulkan AMDVLK** is the new tg champion at **38.65 t/s** (+16% over ROCm 7.x), though it has the worst pp (358 t/s). Host native Vulkan RADV is also strong at **36.80 tg**. ROCm 7.x nightlies remains best for prompt processing (~502 pp).

Practical takeaway: **For interactive serving (tg-dominated), Vulkan AMDVLK or host RADV are best. For batch/prefill workloads, ROCm 7.x nightlies remains optimal.**

## 6) Distributed Inference (Evo + Bee RPC)

> **Critical:** for `llama-server`/`llama-cli` with `--rpc` on large models, use **`-dio`** (direct I/O) to avoid load hangs.

### Working two-host results

| Model | Backend | Split | pp512 (t/s) | tg128 (t/s) | Notes |
|---|---|---|---:|---:|---|
| MiniMax-M2.5-REAP-139B-A10B-Q8_0 | ROCm+RPC | 1.2/0.8 | 332.36 | **15.35** | Best tg from quick split sweep |
| Qwen3.5-397B-A17B-UD-Q4_K_XL | ROCm+RPC | auto | 147.55 | 11.76 | llama-bench path |
| Qwen3.5-397B-A17B-UD-Q4_K_XL | ROCm+RPC + `-dio` | 1/1 | 25.9* | **12.6*** | llama-server path |

\* server-observed pp/tg metrics (not direct `llama-bench`).

## 7) Key Findings

- **Bandwidth wall dominates** on Strix Halo unified memory.
- **Active parameters predict tg well** for MoE models on this platform:
  - 3B active → ~61–86 t/s
  - 5.1B active → ~53 t/s
  - ~10B active → ~29–33 t/s
  - 22B active → ~17 t/s
- **Optimization ablation:** speculative decoding, unified KV flags, no-mmap, and batch-size tuning produced negligible gains in this setup.
- **120W vs 85W:** 120W generally helps 7B+ models; very small models are often bandwidth-limited and see little benefit.
- **Qwen3.5-397B stability can be prompt-shape sensitive:** on `np4_ps32k`, a synthetic repeated-token pattern crashed immediately while an `opt`-shaped prompt passed at 5k, 20k, and ~32k prompt tokens. See [`results/2026-02-20_qwen397b-prompt-shape-sensitivity.md`](results/2026-02-20_qwen397b-prompt-shape-sensitivity.md).
- **Qwen3.5-397B max context found:**
  - `np=1`: ctx 300k with ~150k prompt tokens ✅
  - `np=2`: ctx 200k with ~100k prompt tokens ✅
  - See [`results/2026-02-20_qwen397b-np1-max-context.md`](results/2026-02-20_qwen397b-np1-max-context.md) and [`results/2026-02-20_qwen397b-np2-high-context.md`](results/2026-02-20_qwen397b-np2-high-context.md).
- **Qwen3.5-397B RPC caveat:** at `np2 ctx200k`, `opt` prompts passed (70k/90k) while mixed prompts failed (including GPU memory fault). See [`results/2026-02-21_qwen397b-rpc-shape-control.md`](results/2026-02-21_qwen397b-rpc-shape-control.md).
- **MiniMax RPC stability update:**
  - Shape screen passed **8/8** (Q8 at 45k/48k, Q3_K_M at 70k/90k; opt + natural)
  - High-edge test passed at `np2 ctx256k` with ~`128k` prompt tokens (opt + natural)
  - See [`results/2026-02-21_minimax-rpc-shape-screen.md`](results/2026-02-21_minimax-rpc-shape-screen.md) and [`results/2026-02-21_minimax-q3km-np2-256k-128k.md`](results/2026-02-21_minimax-q3km-np2-256k-128k.md).

## 8) Known Issues

- **RPC serving requires `-dio`** for large-model loads with `--rpc` on this platform (`llama-server` / `llama-cli`).
- **AMDVLK update (Mar 2026):** AMDVLK now leads on tg for Q6_K_XL (38.65 t/s) but has significantly worse pp (358 t/s). Consider for tg-dominated interactive workloads; RADV remains the safer all-round Vulkan path.
- **HIP cold-run penalty exists:** first HIP run after fresh build can be significantly slower; warm up before recording data.

## 9) Community Resources

- [kyuz0/amd-strix-halo-toolboxes](https://github.com/kyuz0/amd-strix-halo-toolboxes)
- [kyuz0 interactive benchmark viewer](https://kyuz0.github.io/amd-strix-halo-toolboxes/)
- [lhl/strix-halo-testing](https://github.com/lhl/strix-halo-testing)
- [Strix Halo Wiki](https://strixhalo.wiki)

### Brief comparison vs kyuz0

Results are broadly aligned with community trends: backend wins vary by metric/model, with ROCm commonly stronger on prompt throughput and Vulkan RADV often stronger on generation responsiveness.

## 10) Documentation

- [BENCHMARKS.md](BENCHMARKS.md) — full benchmark archive and analysis
- [BACKENDS.md](BACKENDS.md) — backend-specific setup and caveats
- [SETUP.md](SETUP.md) — reproducible machine setup
- [docs/rpc-build.md](docs/rpc-build.md) — distributed Vulkan RPC build flow
- [docs/rpc-hip-serving.md](docs/rpc-hip-serving.md) — RPC HIP serving guide (`-dio` requirement)

## 11) Repo Hygiene / Sanitization

This repository is intentionally sanitized for public sharing:
- no passwords/passphrases/keys/tokens
- no private IPs or local SSH key paths
- no raw host logs committed

Quick check:
```bash
./scripts/sanitize-repo.sh
```

## 12) License

[MIT](LICENSE)
