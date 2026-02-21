# Qwen3.5-397B np=1 Max Context (2026-02-20)

## Summary

Tested maximum context window for single-slot (`-np 1`) configuration on distributed Bee+Evo RPC setup.

All tests passed with no memory faults or crashes.

## Test Configuration

- Model: `Qwen3.5-397B-A17B-UD-Q4_K_XL`
- Topology: Bee (client) + Evo (RPC helper)
- Build: `visorcraft/llama.cpp` (includes PRs #19433, #19625, #19768, #19773)
- Runtime: `-np 1`, `-dio`, `-fa on`, `--rpc <evo>:50052`
- Prompt shape: `opt` repeated (stable pattern)

## Results

| Case | ctx_size | target_tokens | Status | prompt_tokens | Latency (1st) | Latency (2nd) |
|------|----------|---------------|--------|---------------|---------------|---------------|
| np1_ctx150k | 150000 | 75000 | ✅ PASS | 75010 | 417.9s | 5.35s |
| np1_ctx200k | 200000 | 100000 | ✅ PASS | 100010 | 636.2s | 6.18s |
| np1_ctx250k | 250000 | 125000 | ✅ PASS | 125004 | 894.2s | 7.10s |
| np1_ctx300k | 300000 | 150000 | ✅ PASS | 150010 | 1193.4s | 8.03s |

## Key Findings

1. **Maximum tested context: 300k with ~150k prompt tokens** — works reliably
2. **No memory faults** across all tests
3. **First-request latency** scales with prompt size (~418s at 75k → ~1193s at 150k)
4. **Second request (KV cached)** is fast (5–8s)
5. **Server stability**: remained alive across all attempts

## Comparison with np=2

| Config | Max ctx_size | Max prompt tokens | Status |
|--------|--------------|-------------------|--------|
| np=2 | 200000 | ~100000 | PASS |
| **np=1** | **300000** | **~150000** | **PASS** |

Single-slot configuration provides significantly higher per-request context budget.

## Practical Guidance

For single-user workloads requiring maximum context:
- Use `-np 1 -c 300000` for up to ~150k prompt tokens
- Expect ~20 minute initial processing for 150k prompts
- Subsequent turns in same conversation are fast (KV cache)

## Related

- np=2 high-context results: `2026-02-20_qwen397b-np2-high-context.md`
- Prompt-shape sensitivity findings: `2026-02-20_qwen397b-prompt-shape-sensitivity.md`
