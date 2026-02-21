# Qwen3.5-397B np=2 High Context (2026-02-20)

## Summary

Tested high-context configurations for dual-slot (`-np 2`) setup on distributed Bee+Evo RPC.

## Test Configuration

- Model: `Qwen3.5-397B-A17B-UD-Q4_K_XL`
- Topology: Bee (client) + Evo (RPC helper)
- Build: `visorcraft/llama.cpp`
- Runtime: `-np 2`, `-dio`, `-fa on`, `--rpc <evo>:50052`
- Prompt shape: `opt` repeated (stable pattern)

## Results

| Case | ctx_size | target_tokens | Status | Notes |
|------|----------|---------------|--------|-------|
| np2_ctx256k | 256000 | 128000 | FAIL | exceed_ctx (128010 vs 128000 limit) — not a crash |
| **np2_ctx200k** | **200000** | **100000** | **✅ PASS** | 2/2 attempts, ~100010 prompt tokens |

## Key Findings

1. **Validated working config: `-np 2 -c 200000` with ~100k prompt tokens**
2. **256k ctx failed** due to strict token limit overflow (not a stability issue)
3. **No memory faults** in either test

## Practical Guidance

For dual-slot concurrent usage with high context:
- Use `-np 2 -c 200000` for up to ~100k prompt tokens per request
- Provides 2 concurrent slots for overlapping requests
