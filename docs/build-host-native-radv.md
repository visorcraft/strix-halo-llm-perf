# Build Process: Host-Native Vulkan RADV

## 1) Sync source

```bash
cd ~/llama.cpp

git remote set-url origin https://github.com/visorcraft/llama.cpp.git
git fetch --all --prune --tags
git checkout master
git reset --hard origin/master
git submodule sync --recursive
git submodule update --init --recursive --jobs 8
```

## 2) Configure build

```bash
cd ~/llama.cpp

cmake -S . -B build-visor-vulkan-host \
  -DGGML_VULKAN=ON \
  -DLLAMA_BUILD_SERVER=ON \
  -DCMAKE_BUILD_TYPE=Release
```

## 3) Compile

```bash
cmake --build build-visor-vulkan-host --config Release -j "$(nproc)"
```
