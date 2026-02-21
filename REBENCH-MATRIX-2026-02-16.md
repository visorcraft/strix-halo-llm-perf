# Re-benchmark Matrix — Driver/Backend Refresh (2026-02-16, updated 2026-02-17)

Goal: compare historical baseline vs first rebench (`05a6f0e89`) vs latest refresh (`05fa625ea`) with one coherent view.

## Models

- **MiniMax M2.5 Q3_K_M** (DevQuasar, ~101.76 GiB)
- **Qwen3-Coder-Next 80B-A3B Q4_K_M** (~45.17 GiB)

## Standardized benchmark settings

```bash
llama-bench -m <MODEL_PATH> --n-gpu-layers 99 -p 512 -n 128
```

- TDP: **120W**
- Warmup run discarded, then measured run recorded
- Record mean ± stddev

---

## Matrix A — Qwen3-Coder-Next 80B-A3B Q4_K_M

| Backend | Historic baseline (older runs) pp/tg | Rebench (`05a6f0e89`) pp/tg | Latest (`05fa625ea`) pp/tg | Δ latest vs rebench (pp/tg) | Status |
|---|---:|---:|---:|---:|---|
| Vulkan RADV (native host) | 531 / 42.7 | 380.57 ± 1.77 / 45.48 ± 0.04 | **527.69 / 43.52** *(median of 5 tuned runs; RADV ICD + no layers + tuned flags, one low outlier observed)* | +38.7% / -4.3% | DONE |
| Vulkan RADV (kyuz0 container) | 526 / 42.7 | 487.44 ± 2.20 / 40.29 ± 2.42 | **527.54 ± 2.48 / 43.49 ± 0.07** | **+8.2% / +7.9%** | DONE |
| ROCm 6.4.4 HIP (kyuz0) | 556 / 35.4 | 554.09 ± 6.25 / 36.14 ± 0.01 | **581.51 ± 3.64 / 37.01 ± 0.01** *(tuned flags)* | +5.0% / +2.4% | DONE |
| ROCm 7.2 HIP (kyuz0) | 535 / 39.5 | 554.92 ± 7.07 / 38.01 ± 0.01 | **581.70 ± 5.68 / 38.87 ± 0.01** *(tuned flags)* | +4.8% / +2.3% | DONE |
| ROCm 7 nightlies HIP (kyuz0) | 555 / 37.9 | 543.07 ± 3.65 / 37.62 ± 0.04 | **577.86 ± 9.65 / 39.06 ± 0.01** *(tuned flags)* | +6.4% / +3.8% | DONE |
| Lemonade ROCm b1189 (gfx1151) | — | 574.66 ± 4.75 / 39.25 ± 0.13 | — | — | DONE |

---

## Matrix B — MiniMax M2.5 Q3_K_M

| Backend | Historic baseline (older runs) pp/tg | Rebench (`05a6f0e89`) pp/tg | Latest (`05fa625ea`) pp/tg | Δ latest vs rebench (pp/tg) | Status |
|---|---:|---:|---:|---:|---|
| Vulkan RADV (native host) | 155.53 / 32.82 | 155.73 ± 1.10 / 33.05 ± 0.03 | **169.64 ± 0.74 / 32.47 ± 0.25** *(RADV ICD + no layers + tuned flags)* | +8.9% / -1.8% | DONE |
| Vulkan RADV (kyuz0 container) | — | 168.67 ± 1.42 / 31.56 ± 0.11 | **177.27 ± 5.79 / 34.34 ± 0.03** | **+5.1% / +8.8%** | DONE |
| ROCm 6.4.4 HIP (kyuz0) | — | 205.44 ± 2.19 / 27.10 ± 0.02 | **214.86 ± 2.04 / 27.93 ± 0.03** *(tuned flags)* | +4.6% / +3.1% | DONE |
| ROCm 7.2 HIP (kyuz0) | — | 204.73 ± 1.87 / 28.10 ± 0.02 | **214.88 ± 2.76 / 29.76 ± 0.03** *(tuned flags)* | +4.9% / +5.9% | DONE |
| ROCm 7 nightlies HIP (kyuz0) | — | 204.27 ± 1.86 / 28.28 ± 0.00 | **214.26 ± 3.56 / 29.94 ± 0.02** *(tuned flags)* | +4.9% / +5.9% | DONE |
| Lemonade ROCm b1189 (gfx1151) | — | 203.32 ± 1.22 / 28.18 ± 0.04 | — | — | DONE |

---

## Quick takeaways

- Latest refresh confirms **container Vulkan improved materially** on both models.
- For Qwen, container Vulkan latest is **522.83 pp512 / 42.86 tg128**.
- Native Vulkan was initially misrouted to AMD open-source/LLPC path; forcing RADV ICD + disabling Vulkan loader layers recovered native to **~507 / 43.5 (Qwen)** and **~166 / 31.4 (MiniMax)**, closing the gap with container.

## Notes

- Rebench block reports `build: 05a6f0e89 (8038)`.
- Latest refresh block reports `build: 05fa625ea`.
- Lemonade backend reports `build: 2ba9adc (1)`.
- Driver-path diagnosis: native default selected `DRIVER_ID_AMD_OPEN_SOURCE` (`2025.Q2.1 (LLPC)`) with ggml shared memory 32768; forcing `VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/radeon_icd.x86_64.json` + `VK_LOADER_LAYERS_DISABLE=all` switches native to RADV GFX1151 with shared memory 65536 (matching container behavior).
