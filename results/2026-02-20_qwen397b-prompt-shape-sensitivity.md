# Qwen3.5-397B RPC Stability — Prompt-Shape Sensitivity (2026-02-20)

## Summary

While investigating repeated `Memory access fault by GPU node-1` crashes in distributed HIP+RPC runs, we found a reproducible **prompt-shape sensitivity**:

- Same server config
- Same approximate prompt token budget
- Different repeated-token text pattern
- Completely different stability outcome

This explains why prior tests appeared contradictory (`5/5 pass` in baseline matrix vs `0/N` in staircase/ceiling runs).

---

## Test Environment

- Model: `Qwen3.5-397B-A17B-UD-Q4_K_XL`
- Topology: Bee (client) + Evo (RPC helper)
- Build: `visorcraft/llama.cpp` (master with PRs #19433, #19625, #19768 merged)
- Binary path (both hosts): `~/llama.cpp/build-rpc-hip-v2/bin/llama-server`
- Runtime flags:
  - `--ctx-size 131072 -np 4`
  - `--rpc <evo>:50052 -ts 1/1`
  - `-dio --no-warmup --cache-ram 0`
  - `-ngl 99 -fa on`

---

## A/B Isolation at ~5k Tokens (`np4_ps32k`)

| Prompt shape | Target tokens | Actual prompt tokens | Outcome | Fault |
|---|---:|---:|---|---|
| `opt` repeated (`"opt ..."`) | 5000 | ~5010 | **10/10 pass** | none |
| `contexttoken` repeated (`"contexttoken ..."`) | 5000 | calibrated to same target | **fail on attempt 1** | `Memory access fault by GPU node-1` |

### Key takeaway

At this layer, failures are **not purely a token-count ceiling**; they can be triggered by prompt-token distribution/pattern.

---

## High-rung checks on passing shape (`opt`)

| Test | Target tokens | Actual prompt tokens | Attempts | Outcome |
|---|---:|---:|---:|---|
| Direct rung check | 20000 | ~20007 | 2 | **pass** |
| Direct rung check | 32000 | ~32010 | 2 | **pass** |

No GPU memory faults in these checks.

---

## Practical Guidance (Current)

1. Use **realistic prompt shapes** for stability gating (agent-like prompts), not pathological repeated-token patterns.
2. Keep `np4_ps32k` as current operational profile for multi-slot use.
3. Derive production guard rails from realistic ladders + burn-in, not from synthetic crash-inducing prompt patterns.

---

## Related local artifacts (not committed)

- `qwen397b_sweetspot_20260220_173241.{json,md,log}`
- `qwen397b_ceiling_20260220_171725.{json,md}`
