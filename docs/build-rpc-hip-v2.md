# Build Process: `build-rpc-hip-v2`

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

cmake -S . -B build-rpc-hip-v2 \
  -DGGML_HIP=ON \
  -DGGML_RPC=ON \
  -DLLAMA_BUILD_SERVER=ON \
  -DCMAKE_BUILD_TYPE=Release
```

## 3) Compile

```bash
cmake --build build-rpc-hip-v2 --config Release -j "$(nproc)"
```
