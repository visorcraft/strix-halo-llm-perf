# MiniMax RPC Shape Screen (2026-02-21)

## Setup
- Topology: Bee (client) + Evo (RPC)
- Build: `visorcraft/llama.cpp` fork
- Backend: HIP+RPC (`-dio`)
- Mixed test profile by model:
  - MiniMax REAP Q8: `-np 2 --ctx-size 100000`
  - MiniMax M2.5 Q3_K_M: `-np 2 --ctx-size 200000`
- Prompt families: `opt` and natural-paragraph style

Artifact: `/tmp/idlehands_optimizing/minimax_shape_screen_np2_v2_20260221_064746.json`

## Results (8/8 PASS)

| Model | ctx/np | Target | Shape | Calibrated | Result |
|---|---|---:|---|---:|---|
| MiniMax REAP Q8 | 100k / 2 | 45k | opt | 44,959 | ✅ PASS (2/2) |
| MiniMax REAP Q8 | 100k / 2 | 45k | natural | 44,764 | ✅ PASS (2/2) |
| MiniMax REAP Q8 | 100k / 2 | 48k | opt | 47,958 | ✅ PASS (2/2) |
| MiniMax REAP Q8 | 100k / 2 | 48k | natural | 47,688 | ✅ PASS (2/2) |
| MiniMax M2.5 Q3_K_M | 200k / 2 | 70k | opt | 69,958 | ✅ PASS (2/2) |
| MiniMax M2.5 Q3_K_M | 200k / 2 | 70k | natural | 69,857 | ✅ PASS (2/2) |
| MiniMax M2.5 Q3_K_M | 200k / 2 | 90k | opt | 89,958 | ✅ PASS (2/2) |
| MiniMax M2.5 Q3_K_M | 200k / 2 | 90k | natural | 89,766 | ✅ PASS (2/2) |

## Takeaway
MiniMax models remained stable across both prompt families in this matrix. No memory-fault signature observed in this run.
