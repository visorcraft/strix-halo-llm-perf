# Backend Setup, Bench Commands, and Gotchas

This is the canonical backend operations doc.

If you only read one file before running backend benches, read this one.

## Global Rules

1. Run **one backend at a time, one model at a time**.
2. Use this benchmark shape for comparable results:

```bash
llama-bench -m <MODEL_PATH> --n-gpu-layers 99 -p 512 -n 128
```

3. Discard one warmup run, then record measured run.
4. Record: backend, exact command, build hash, pp512, tg128.
5. Use `scripts/run-one-backend.sh` unless you are debugging backend internals.

## Model Paths

- Qwen3-Coder-Next 80B-A3B Q4_K_M:
  `~/models/Qwen3-Coder-Next-Q4_K_M.gguf`
- MiniMax M2.5 Q3_K_M:
  `~/models/minimax-m2.5/Q3_K_M/MiniMaxAI.MiniMax-M2.5.Q3_K_M-00001-of-00007.gguf`

---

## Backend: Vulkan RADV (native host)

### Setup
- Binary: `/tmp/llama-vulkan/build/bin/llama-bench`
- **Force RADV ICD** and disable loader layers for correct performance:
  - `VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/radeon_icd.x86_64.json`
  - `VK_LOADER_LAYERS_DISABLE=all`

### Canonical command
```bash
VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/radeon_icd.x86_64.json \
VK_LOADER_LAYERS_DISABLE=all \
/tmp/llama-vulkan/build/bin/llama-bench \
  -m <MODEL_PATH> --n-gpu-layers 99 -p 512 -n 128
```

### Gotchas
- If ICD is not forced, host may pick AMD open-source/LLPC path with lower Vulkan-reported shared memory and much lower pp.
- If loader layers are left on, native can benchmark lower than container.

---

## Backend: Vulkan RADV (kyuz0 container)

### Setup
- Container: `llama-vulkan-radv`
- Image: `docker.io/kyuz0/amd-strix-halo-toolboxes:vulkan-radv`

### Canonical command
```bash
podman start llama-vulkan-radv
podman exec llama-vulkan-radv bash -lc \
  "llama-bench -m <MODEL_PATH> --n-gpu-layers 99 -p 512 -n 128"
```

### Gotchas
- Recreate container after image refresh to guarantee latest runtime state.
- Container has generally been the most stable Vulkan reference path.

---

## Backend: ROCm 6.4.4 HIP (kyuz0 container)

### Setup
- Container: `llama-rocm-6.4.4`
- Image: `docker.io/kyuz0/amd-strix-halo-toolboxes:rocm-6.4.4`

### Canonical command
```bash
podman start llama-rocm-6.4.4
podman exec llama-rocm-6.4.4 bash -lc \
  "llama-bench -m <MODEL_PATH> --n-gpu-layers 99 -p 512 -n 128"
```

### Gotchas
- First run after restart/build can be slower; always use warmup+measured pattern.

---

## Backend: ROCm 7.2 HIP (kyuz0 container)

> Note: keep ROCm 7 containers refreshed/recreated so benchmark rows use latest toolbox rebuilds (including upstream ROCm 7 regression workaround updates).

### Setup
- Container: `llama-rocm-7.2`
- Image: `docker.io/kyuz0/amd-strix-halo-toolboxes:rocm-7.2`

### Canonical command
```bash
podman start llama-rocm-7.2
podman exec llama-rocm-7.2 bash -lc \
  "llama-bench -m <MODEL_PATH> --n-gpu-layers 99 -p 512 -n 128"
```

### Gotchas
- Similar behavior to ROCm 6.4.4; very strong pp, lower tg than Vulkan.

---

## Backend: ROCm 7 nightlies HIP (kyuz0 container)

### Setup
- Container: `llama-rocm7-nightlies`
- Image: `docker.io/kyuz0/amd-strix-halo-toolboxes:rocm7-nightlies`

### Canonical command
```bash
podman start llama-rocm7-nightlies
podman exec llama-rocm7-nightlies bash -lc \
  "llama-bench -m <MODEL_PATH> --n-gpu-layers 99 -p 512 -n 128"
```

### Gotchas
- Performance is close to ROCm 7.2; track by model, don’t assume global winner.

---

## Backend: ROCm 6.4 local HIP + FA + hipBLASLt

### Setup
- Binary: `/tmp/llama-hip/build/bin/llama-bench`
- Runtime env: `ROCBLAS_USE_HIPBLASLT=1`

### Canonical command
```bash
ROCBLAS_USE_HIPBLASLT=1 /tmp/llama-hip/build/bin/llama-bench \
  -m <MODEL_PATH> --n-gpu-layers 99 -p 512 -n 128
```

### Gotchas
- Local HIP path is currently non-canonical for this matrix; prefer container backends for reproducible runs.
- For now, container ROCm rows are the reliable path.

---

## Backend: Lemonade ROCm b1189 (gfx1151)

### Setup
- External build/backend path used for comparison rows in matrix.

### Gotchas
- Keep clearly labeled as separate toolchain/build lineage from main llama.cpp rows.

---

## Fast Path Commands

Refresh/recreate backend containers on latest tags:

```bash
scripts/refresh-backend-containers.sh
# optional: include amdvlk + remove legacy rocm7rc container
scripts/refresh-backend-containers.sh --include-amdvlk --prune-legacy
```

Use the benchmark wrapper:

```bash
scripts/run-one-backend.sh vulkan-native qwen
scripts/run-one-backend.sh vulkan-container minimax
scripts/run-one-backend.sh rocm72 qwen
```

---

## Source of Truth for Performance

- Backend matrix and deltas: [`REBENCH-MATRIX-2026-02-16.md`](REBENCH-MATRIX-2026-02-16.md)
- Model-centric benchmark history: [`BENCHMARKS.md`](BENCHMARKS.md)
