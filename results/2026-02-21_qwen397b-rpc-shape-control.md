# Qwen3.5-397B RPC Shape-Control (2026-02-20/21)

## Setup
- Topology: Bee (client) + Evo (RPC)
- Build: `visorcraft/llama.cpp` fork
- Backend: HIP+RPC (`-dio`)
- Server profile: `-np 2 --ctx-size 200000`
- Method: full RPC + server restart between cases

Artifact: `/tmp/idlehands_optimizing/qwen397b_control_shapes_np2_v2_20260220_233624.json`

## Results

| Target | Shape | Calibrated Prompt Tokens | Result | Notes |
|---:|---|---:|---|---|
| 70k | opt | 69,970 | ✅ PASS (2/2) | attempt1 380.72s, attempt2 7.43s |
| 70k | mixed | 69,940 | ❌ FAIL | transport drop, server died |
| 90k | opt | 89,970 | ✅ PASS (2/2) | attempt1 545.54s, attempt2 8.23s |
| 90k | mixed | 89,929 | ❌ FAIL | transport drop + `Memory access fault by GPU node-1` |

## Takeaway
This path is **not shape-agnostic** at high context. `opt`-style prompts pass while mixed/natural-style prompts can fail on the same token budget.

Use caution before treating Qwen3.5-397B HIP+RPC as production-stable for arbitrary high-context prompts.
