# RPC Build Guide (Vulkan + llama.cpp)

This guide shows how to build a public, reproducible `llama.cpp` setup with:

- Vulkan backend
- RPC backend (for cross-host split/offload)

No host-specific details are required.

---

## 1) Prerequisites

You need a Linux host with:

- `git`
- `cmake`
- C/C++ toolchain (`gcc`, `g++`, `make`/`ninja`)
- Vulkan loader/dev packages
- `glslc` (shader compiler)

Example package groups vary by distro.

---

## 2) Build using the provided script

From repository root:

```bash
chmod +x scripts/build-rpc-vulkan.sh
scripts/build-rpc-vulkan.sh
```

Defaults:

- Source dir: `./third_party/llama.cpp`
- Build dir: `./build-rpc-vk`
- Install prefix: `./dist/rpc-vk`
- Build type: `Release`
- Parallel jobs: `nproc`

You can override with environment variables:

```bash
LLAMA_SRC_DIR=/path/to/llama.cpp \
LLAMA_BUILD_DIR=/path/to/build \
LLAMA_INSTALL_PREFIX=/path/to/install \
LLAMA_REF=master \
CMAKE_BUILD_TYPE=Release \
BUILD_JOBS=16 \
scripts/build-rpc-vulkan.sh
```

---

## 3) Confirm binaries

Expected binaries after build:

- `llama-bench`
- `llama-cli`
- `llama-server`
- `rpc-server`

Check:

```bash
./dist/rpc-vk/bin/llama-bench --help
./dist/rpc-vk/bin/rpc-server --help
```

---

## 4) Runtime environment (Vulkan)

On some systems, forcing a known Vulkan ICD improves consistency:

```bash
export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/radeon_icd.x86_64.json
export VK_LOADER_LAYERS_DISABLE=all
```

If your platform differs, adjust/remove these variables.

---

## 5) RPC smoke test (generic)

### Host B (RPC server)

```bash
./dist/rpc-vk/bin/rpc-server -H <peer-bind-ip> -p 50052 --device Vulkan0
```

### Host A (client bench)

```bash
./dist/rpc-vk/bin/llama-bench \
  -m <model.gguf> \
  --n-gpu-layers 99 \
  -p 512 -n 128 \
  --rpc <peer-bind-ip>:50052 \
  --tensor-split 1/1
```

If RPC is active, backend output should include `Vulkan,RPC`.

---

## 6) Troubleshooting

- **`rpc-server` missing**: ensure `-DGGML_RPC=ON` was used.
- **Vulkan not found**: install Vulkan dev loader + `glslc` and rebuild.
- **Cannot connect to RPC peer**: check bind IP, route, and firewall.
- **HIP/ROCm errors**: this guide is Vulkan+RPC only; HIP stack is separate.

---

## 7) Security note

`rpc-server` is experimental and not hardened for open/public networks.
Keep it on trusted private networks only.
