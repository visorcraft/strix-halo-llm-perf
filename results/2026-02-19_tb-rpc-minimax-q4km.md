# Benchmark Results — 2026-02-19

## Scope
These are the runs performed in this session (not all backends).

### Model
- `MiniMax-M2.5-REAP-Q4_K_M` (multi-file GGUF set)
- Bench command used shard file:
  - `MiniMax-M2.5-REAP-Q4_K_M-00001-of-00007.gguf` (multi-file GGUF set)

### Build
- `llama.cpp` commit: `3bb2fcc85` (build 8099)
- Build flags: `-DGGML_VULKAN=ON -DGGML_RPC=ON`
- Transport for RPC: USB4/TB direct link (`thunderbolt0`, private static /30)

## Results

### 1) Local baseline (Evo only, Vulkan)
- `pp512`: **250.48 ± 7.89 t/s**
- `tg128`: **28.72 ± 0.86 t/s**

### 2) Distributed offload (Evo Vulkan + Bee RPC)
- Backend reported by bench: **`Vulkan,RPC`**
- Args: `--rpc <peer-rpc-endpoint> --tensor-split 1/1`
- `pp512`: **272.00 ± 4.80 t/s**
- `tg128`: **26.70 ± 0.02 t/s**

## Interpretation
- Prompt processing (`pp512`) improved with RPC offload.
- Token generation (`tg128`) decreased vs local-only.
- Functional distributed path confirmed; optimization still needed for best generation throughput.

## Notes
- This session did **not** run all backend variants in `scripts/run-one-backend.sh`.
- Only the two configurations above were measured.
