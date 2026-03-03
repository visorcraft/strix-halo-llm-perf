# Build Guide: `build-rpc-hip-v2` vs Host-Native Vulkan RADV

This is a **separate, side-by-side** guide for the two workflows:

1. `build-rpc-hip-v2` (HIP + RPC + server, long-context serving path)
2. Host-native Vulkan RADV (Mesa) benchmark path (the ~467 pp / ~36.8 tg class)

All paths are generic (`~`), no personal usernames.

---

## A) `build-rpc-hip-v2` (HIP + RPC + server)

### A1. Sync visorcraft fork

```bash
cd ~/llama.cpp

git remote set-url origin https://github.com/visorcraft/llama.cpp.git
git fetch --all --prune --tags
git checkout master
git reset --hard origin/master
git submodule sync --recursive
git submodule update --init --recursive --jobs 8
```

### A2. Configure + build

```bash
cd ~/llama.cpp
cmake -S . -B build-rpc-hip-v2 \
  -DGGML_HIP=ON \
  -DGGML_RPC=ON \
  -DLLAMA_BUILD_SERVER=ON \
  -DCMAKE_BUILD_TYPE=Release

cmake --build build-rpc-hip-v2 --config Release -j "$(nproc)"
```

### A3. Run server (same flag family as your production command)

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

### A4. Background mode + health checks

```bash
nohup ~/llama.cpp/build-rpc-hip-v2/bin/llama-server \
  -m ~/models/Qwen3-Coder-Next-UD-Q6_K_XL/Qwen3-Coder-Next-UD-Q6_K_XL-00001-of-00003.gguf \
  --port 8082 --host 0.0.0.0 \
  --chat-template-file ~/.idlehands/templates/qwen3.jinja --jinja \
  -ngl 99 -fa on -np 4 -c 800000 -cb \
  -ctk q4_0 -ctv q4_0 \
  --ctx-checkpoints 0 --cache-reuse 64 --no-warmup --slots -dio \
  > ~/llama.cpp/build-rpc-hip-v2/llama-server.log 2>&1 < /dev/null &

pgrep -af "build-rpc-hip-v2/bin/llama-server"
ss -ltnp | grep ":8082"
tail -n 50 ~/llama.cpp/build-rpc-hip-v2/llama-server.log
```

---

## B) Host-native Vulkan RADV (Mesa)

### B1. Configure + build

```bash
cd ~/llama.cpp
cmake -S . -B build-visor-vulkan-host \
  -DGGML_VULKAN=ON \
  -DLLAMA_BUILD_SERVER=ON \
  -DCMAKE_BUILD_TYPE=Release

cmake --build build-visor-vulkan-host --config Release -j "$(nproc)"
```

### B2. Run benchmark with forced RADV ICD

```bash
VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/radeon_icd.x86_64.json \
VK_LOADER_LAYERS_DISABLE=all \
~/llama.cpp/build-visor-vulkan-host/bin/llama-bench \
  -m ~/models/Qwen3-Coder-Next-UD-Q6_K_XL/Qwen3-Coder-Next-UD-Q6_K_XL-00001-of-00003.gguf \
  --n-gpu-layers 99 -p 512 -n 128 -r 3
```

Expected class of result (Bee-like setup):
- `pp512` around **467 t/s**
- `tg128` around **36.8 t/s**

---

## C) Confirm which revision each binary uses

For either build, run a tiny bench and read the trailing `build:` line:

```bash
~/llama.cpp/build-rpc-hip-v2/bin/llama-bench \
  -m ~/models/Qwen3-Coder-Next-UD-Q6_K_XL/Qwen3-Coder-Next-UD-Q6_K_XL-00001-of-00003.gguf \
  -ngl 99 -p 1 -n 1 -r 1

~/llama.cpp/build-visor-vulkan-host/bin/llama-bench \
  -m ~/models/Qwen3-Coder-Next-UD-Q6_K_XL/Qwen3-Coder-Next-UD-Q6_K_XL-00001-of-00003.gguf \
  -ngl 99 -p 1 -n 1 -r 1
```

Example tail:

```text
build: 53f151590 (105)
```

If you see a different hash (for example `f0603802`), you are running a different binary path/tree.
