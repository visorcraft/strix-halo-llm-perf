# Fastest Host-Native Build Guide: visorcraft/llama.cpp (HIP RPC)

This guide is the **fast host-native path** for building and running `visorcraft/llama.cpp` on Linux.

Use this when you want the same style of runtime as:
- `build-rpc-hip-v2/bin/llama-server`
- large-context serving
- high throughput with HIP + RPC support enabled

All paths below are generic (no personal usernames).

---

## 1) Prerequisites

Install:
- `git`
- `cmake`
- C/C++ toolchain (`gcc`, `g++`, `make` or `ninja`)
- ROCm/HIP toolchain and runtime

---

## 2) Pull latest visorcraft fork

```bash
cd ~/llama.cpp

git remote set-url origin https://github.com/visorcraft/llama.cpp.git
git fetch --all --prune --tags
git checkout master
git reset --hard origin/master
git submodule sync --recursive
git submodule update --init --recursive --jobs 8

git rev-parse --short HEAD
```

---

## 3) Fast host-native build (HIP + RPC + server)

```bash
cd ~/llama.cpp

cmake -S . -B build-rpc-hip-v2 \
  -DGGML_HIP=ON \
  -DGGML_RPC=ON \
  -DLLAMA_BUILD_SERVER=ON \
  -DCMAKE_BUILD_TYPE=Release

cmake --build build-rpc-hip-v2 --config Release -j "$(nproc)"
```

---

## 4) Run llama-server (template command)

```bash
~/llama.cpp/build-rpc-hip-v2/bin/llama-server \
  -m ~/models/Qwen3-Coder-Next-UD-Q6_K_XL/Qwen3-Coder-Next-UD-Q6_K_XL-00001-of-00003.gguf \
  --port 8082 \
  --host 0.0.0.0 \
  --chat-template-file ~/.idlehands/templates/qwen3.jinja \
  --jinja \
  -ngl 99 \
  -fa on \
  -np 4 \
  -c 800000 \
  -cb \
  -ctk q4_0 \
  -ctv q4_0 \
  --ctx-checkpoints 0 \
  --cache-reuse 64 \
  --no-warmup \
  --slots \
  -dio
```

---

## 5) Run in background + log file

```bash
nohup ~/llama.cpp/build-rpc-hip-v2/bin/llama-server \
  -m ~/models/Qwen3-Coder-Next-UD-Q6_K_XL/Qwen3-Coder-Next-UD-Q6_K_XL-00001-of-00003.gguf \
  --port 8082 --host 0.0.0.0 \
  --chat-template-file ~/.idlehands/templates/qwen3.jinja --jinja \
  -ngl 99 -fa on -np 4 -c 800000 -cb \
  -ctk q4_0 -ctv q4_0 \
  --ctx-checkpoints 0 --cache-reuse 64 --no-warmup --slots -dio \
  > ~/llama.cpp/build-rpc-hip-v2/llama-server.log 2>&1 < /dev/null &
```

Check:

```bash
pgrep -af "build-rpc-hip-v2/bin/llama-server"
ss -ltnp | grep ":8082"
tail -n 50 ~/llama.cpp/build-rpc-hip-v2/llama-server.log
```

---

## 6) Verify build revision used by binary

```bash
~/llama.cpp/build-rpc-hip-v2/bin/llama-bench \
  -m ~/models/Qwen3-Coder-Next-UD-Q6_K_XL/Qwen3-Coder-Next-UD-Q6_K_XL-00001-of-00003.gguf \
  -ngl 99 -p 1 -n 1 -r 1
```

Look for the final line:

```text
build: <commit> (<build-number>)
```

That line is the exact source revision for the binary you ran.

---

## 7) Why build IDs can differ (example: `f0603802` vs `53f151590`)

Different binary paths can point to different source trees/builds.

- Example older path: `/tmp/llama-vulkan/...` (older build id)
- Current host-native path: `~/llama.cpp/build-rpc-hip-v2/...` (current build id)

If results look inconsistent, first confirm the binary path and the `build:` line.

---

## 8) Exact setup to reproduce ~467 pp / ~36.8 tg (Vulkan RADV, Mesa)

Those numbers are **Vulkan RADV** numbers, not HIP numbers.

Two equivalent ways to reproduce:

### A) kyuz0 RADV container + visorcraft binary (recommended reproducibility)

Build (inside container, using your synced `~/llama.cpp`):

```bash
podman exec llama-vulkan-radv bash -lc '
  cd ~/llama.cpp
  cmake -S . -B build-visor-vulkan-radv \
    -DGGML_VULKAN=ON \
    -DLLAMA_BUILD_SERVER=ON \
    -DCMAKE_BUILD_TYPE=Release
  cmake --build build-visor-vulkan-radv --config Release -j "$(nproc)"
'
```

Benchmark:

```bash
podman exec llama-vulkan-radv bash -lc '
  ~/llama.cpp/build-visor-vulkan-radv/bin/llama-bench \
    -m ~/models/Qwen3-Coder-Next-UD-Q6_K_XL/Qwen3-Coder-Next-UD-Q6_K_XL-00001-of-00003.gguf \
    --n-gpu-layers 99 -p 512 -n 128 -r 3
'
```

Expected class of result:
- `pp512` around **467 t/s**
- `tg128` around **36.7–36.8 t/s**

### B) host-native RADV build

```bash
cd ~/llama.cpp
cmake -S . -B build-visor-vulkan-host \
  -DGGML_VULKAN=ON \
  -DLLAMA_BUILD_SERVER=ON \
  -DCMAKE_BUILD_TYPE=Release
cmake --build build-visor-vulkan-host --config Release -j "$(nproc)"

VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/radeon_icd.x86_64.json \
VK_LOADER_LAYERS_DISABLE=all \
~/llama.cpp/build-visor-vulkan-host/bin/llama-bench \
  -m ~/models/Qwen3-Coder-Next-UD-Q6_K_XL/Qwen3-Coder-Next-UD-Q6_K_XL-00001-of-00003.gguf \
  --n-gpu-layers 99 -p 512 -n 128 -r 3
```

---

## 9) Mapping guide sections to benchmark families

- Sections 3–5 (**HIP RPC build/server**) => long-context serving workflow (`build-rpc-hip-v2`)
- Section 8 (**Vulkan RADV**) => the ~467 pp / ~36.8 tg benchmark workflow
