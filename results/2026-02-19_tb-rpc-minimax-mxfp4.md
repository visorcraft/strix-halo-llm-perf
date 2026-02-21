# Benchmark Results — 2026-02-19 (MiniMax MXFP4)

## Model
- `MiniMax-M2.5-REAP-MXFP4_MOE-00001-of-00007.gguf` (multi-file GGUF set)

## Build
- `llama.cpp` commit: `3bb2fcc85` (build 8099)
- Flags: `-DGGML_VULKAN=ON -DGGML_RPC=ON`
- RPC transport: USB4/TB direct host-to-host link (private /30)

## Results

### Local (Evo only, Vulkan)
- `pp512`: **305.51 ± 6.86 t/s**
- `tg128`: **26.40 ± 0.01 t/s**

### Split (Evo Vulkan + Bee RPC, tensor-split 1/1)
- Backend: `Vulkan,RPC`
- Args: `--rpc <peer-rpc-endpoint> --tensor-split 1/1`
- `pp512`: **299.54 ± 6.19 t/s**
- `tg128`: **24.48 ± 0.02 t/s**

## Summary
- Distributed run works.
- For this model and split ratio, local-only is faster for both pp and tg.
