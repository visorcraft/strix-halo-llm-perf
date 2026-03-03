# Build Guide: visorcraft/llama.cpp (Host + kyuz0 Containers)

This guide shows how to build **your fork** (`https://github.com/visorcraft/llama.cpp.git`) so benchmarks and serving use your exact source revision.

It covers:
- Host-native builds (HIP / Vulkan)
- Builds inside kyuz0 distrobox containers (`llama-vulkan-radv`, `llama-vulkan-amdvlk`, `llama-rocm-*`)
- How to verify the build revision shown by `llama-bench`

---

## 1) Sync the source on host

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

## 2) Build on host (examples)

### HIP + RPC + server

```bash
cd ~/llama.cpp
cmake -S . -B build-rpc-hip-v2 \
  -DGGML_HIP=ON \
  -DGGML_RPC=ON \
  -DLLAMA_BUILD_SERVER=ON \
  -DCMAKE_BUILD_TYPE=Release

cmake --build build-rpc-hip-v2 --config Release -j "$(nproc)"
```

### Vulkan + server

```bash
cd ~/llama.cpp
cmake -S . -B build-visor-vulkan-host \
  -DGGML_VULKAN=ON \
  -DLLAMA_BUILD_SERVER=ON \
  -DCMAKE_BUILD_TYPE=Release

cmake --build build-visor-vulkan-host --config Release -j "$(nproc)"
```

---

## 3) Build inside kyuz0 containers

> Containers share your home directory, so `/home/thomas/llama.cpp` is visible inside each container.

### Ensure containers are running

```bash
podman start \
  llama-vulkan-radv \
  llama-vulkan-amdvlk \
  llama-rocm-6.4.4 \
  llama-rocm-7.2 \
  llama-rocm7-nightlies
```

### Vulkan RADV container

```bash
podman exec llama-vulkan-radv bash -lc '
  cd /home/thomas/llama.cpp
  cmake -S . -B build-visor-vulkan-radv \
    -DGGML_VULKAN=ON \
    -DLLAMA_BUILD_SERVER=ON \
    -DCMAKE_BUILD_TYPE=Release
  cmake --build build-visor-vulkan-radv --config Release -j "$(nproc)"
'
```

### Vulkan AMDVLK container

```bash
podman exec llama-vulkan-amdvlk bash -lc '
  cd /home/thomas/llama.cpp
  cmake -S . -B build-visor-vulkan-amdvlk \
    -DGGML_VULKAN=ON \
    -DLLAMA_BUILD_SERVER=ON \
    -DCMAKE_BUILD_TYPE=Release
  cmake --build build-visor-vulkan-amdvlk --config Release -j "$(nproc)"
'
```

### ROCm 6.4.4 container (works with full HIP toolchain)

```bash
podman exec llama-rocm-6.4.4 bash -lc '
  cd /home/thomas/llama.cpp
  cmake -S . -B build-visor-rocm-6.4.4 \
    -DGGML_HIP=ON \
    -DGGML_RPC=ON \
    -DLLAMA_BUILD_SERVER=ON \
    -DCMAKE_BUILD_TYPE=Release
  cmake --build build-visor-rocm-6.4.4 --config Release -j "$(nproc)"
'
```

---

## 4) Verify which revision a binary was built from

Run any built `llama-bench` and check the final `build:` line:

```bash
/home/thomas/llama.cpp/build-visor-vulkan-radv/bin/llama-bench \
  -m /home/thomas/models/Qwen3-Coder-Next-UD-Q6_K_XL/Qwen3-Coder-Next-UD-Q6_K_XL-00001-of-00003.gguf \
  --n-gpu-layers 99 -p 1 -n 1 -r 1
```

Example output tail:

```text
build: 53f151590 (105)
```

That means the binary itself was compiled from commit `53f151590`.

---

## 5) Why did a previous run show `f0603802` instead of `53f151590`?

Because the binary path was different.

- `f0603802` came from an older local tree at `/tmp/llama-vulkan/...`.
- `53f151590` comes from your synced fork at `~/llama.cpp/...`.

If you change the binary path, you may change the source revision used in tests.

---

## 6) Recommended benchmark command (container Vulkan)

```bash
podman exec llama-vulkan-radv bash -lc '
  /home/thomas/llama.cpp/build-visor-vulkan-radv/bin/llama-bench \
    -m /home/thomas/models/Qwen3-Coder-Next-UD-Q6_K_XL/Qwen3-Coder-Next-UD-Q6_K_XL-00001-of-00003.gguf \
    --n-gpu-layers 99 -p 512 -n 128 -r 3
'
```

Use the equivalent `build-visor-vulkan-amdvlk` path in the AMDVLK container.

---

## 7) Notes on ROCm 7.x containers

Some ROCm 7.x toolbox images may not include a complete HIP compile toolchain by default (or may have CMake/HIP detection incompatibilities).

If HIP builds fail there, this is usually a toolchain-image issue, not a `llama.cpp` source issue.

In that case:
- Use host HIP build or ROCm 6.4.4 container for source builds, and/or
- Use container prebuilt binaries for runtime-only testing.
