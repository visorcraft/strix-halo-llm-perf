# RPC HIP Serving Guide (Strix Halo, distributed llama-server)

How to serve large models (>100 GiB) across two Strix Halo hosts using `llama-server` with HIP + RPC.

> **⚠️ Critical:** You **must** use the `-dio` (direct I/O) flag when running `llama-server` or `llama-cli` over RPC on Strix Halo. Without it, the server hangs indefinitely during tensor loading. See [llama.cpp #19745](https://github.com/ggml-org/llama.cpp/issues/19745).

---

## Why `-dio` is required

On Strix Halo's unified memory architecture (CPU and GPU share 128 GB LPDDR5X), the default `mmap` loading path causes a HIP/HSA allocation collision when transferring large tensor buffers to the remote RPC peer's GPU. The server gets stuck at the `load_tensors` phase — dots appear in the log but health never reaches 200.

`-dio` (direct I/O) bypasses mmap entirely, reading model files directly from disk into GPU buffers. This avoids the collision and loads reliably.

**Key facts:**
- `llama-bench` works without `-dio` (it uses a simpler, non-server loading codepath)
- `llama-server` and `llama-cli` both hang without `-dio`
- Tested across ROCm 6.4.2, 7.2, and 7.0 nightlies — same behavior on all
- Small models (<50 GiB) may work without `-dio`, but always use it for safety with RPC

---

## 1) Prerequisites

Two Strix Halo hosts (Ryzen AI Max+ 395 or similar), each with:

- 128 GB unified LPDDR5X
- Fedora 43+ (or similar with ROCm support)
- ROCm HIP toolchain installed (`rocm-hip-devel`, etc.)
- Direct network link between hosts (USB4/Thunderbolt recommended for ~9.4 Gbps)
- `llama.cpp` built with HIP + RPC support

---

## 2) Build llama.cpp with HIP + RPC

On **both** hosts:

```bash
cd ~/llama.cpp
git checkout master && git pull

cmake -B build-rpc-hip \
  -DGGML_HIP=ON \
  -DGGML_RPC=ON \
  -DAMDGPU_TARGETS=gfx1151 \
  -DCMAKE_HIP_ARCHITECTURES=gfx1151 \
  -DCMAKE_BUILD_TYPE=Release

cmake --build build-rpc-hip --config Release -j$(nproc)
```

### Optional: rocWMMA flash attention

If your ROCm version includes `rocwmma` headers with gfx1151 support (ROCm 7.2+ nightly toolbox), add:

```
-DGGML_HIP_ROCWMMA_FATTN=ON
```

Note: Fedora's `rocwmma-devel` 6.4.0 does **not** support gfx1151 (`static assertion failed: Unsupported architecture`). Use the ROCm 7.2 COPR toolbox or newer headers.

---

## 3) Start the RPC server (remote host)

On the host that will provide GPU compute as a remote peer:

```bash
~/llama.cpp/build-rpc-hip/bin/rpc-server -H <bind-ip> -p 50052
```

Where `<bind-ip>` is the IP on the direct link interface (e.g., the Thunderbolt/USB4 address).

Verify it's listening:
```bash
ss -lnt | grep 50052
```

### As a systemd user service (recommended)

```ini
# ~/.config/systemd/user/llama-rpc-hip.service
[Unit]
Description=llama.cpp HIP RPC server
After=network-online.target

[Service]
Type=simple
ExecStart=%h/llama.cpp/build-rpc-hip/bin/rpc-server -H <bind-ip> -p 50052
Restart=always
RestartSec=5

[Install]
WantedBy=default.target
```

```bash
systemctl --user daemon-reload
systemctl --user enable --now llama-rpc-hip.service
```

---

## 4) Start llama-server (client host)

On the host where the model files reside:

```bash
ROCBLAS_USE_HIPBLASLT=1 ~/llama.cpp/build-rpc-hip/bin/llama-server \
  -m /path/to/model.gguf \
  --host 0.0.0.0 --port 8081 \
  -ngl 99 -fa on \
  --rpc <rpc-server-ip>:50052 \
  -ts 1/1 \
  --ctx-size 4096 \
  --no-warmup \
  -dio
```

### Flag breakdown

| Flag | Purpose |
|---|---|
| `-dio` | **REQUIRED.** Direct I/O — bypasses mmap, fixes RPC tensor upload hang |
| `--rpc <ip>:50052` | Connect to the remote RPC server |
| `-ts 1/1` | Split tensors evenly across local GPU and remote RPC peer |
| `-ngl 99` | Offload all layers to GPU |
| `-fa on` | Flash attention |
| `--no-warmup` | Skip warmup (saves time on large models; warmup can be done after load) |
| `--ctx-size 4096` | Context size (adjust as needed; larger = more memory) |
| `ROCBLAS_USE_HIPBLASLT=1` | Environment variable; may improve GEMM performance on dense models |

### Verify health

```bash
# Poll until 200 (large models take 3-5 minutes to load)
curl -s http://localhost:8081/health
```

---

## 5) Tested configurations

| Model | Size | Split | Load time | tg (t/s) | Status |
|---|---|---|---|---|---|
| MiniMax-M2.5-REAP-139B-A10B-Q8_0 | 138 GiB | 1/1 | ~190-196s | ~15.8 | ✅ with `-dio` |
| Qwen3.5-397B-A17B-UD-Q4_K_XL | 205 GiB | 1/1 | ~285-290s | ~12.6 | ✅ with `-dio` |

### `-dio` ROCm version matrix

All tested with MiniMax-M2.5-REAP-139B-A10B-Q8_0 (138 GiB) over RPC, llama-server with `-dio`:

| ROCm Version | Source | Without `-dio` | With `-dio` | Load time | tg (t/s) | pp (t/s) |
|---|---|---|---|---|---|---|
| 6.4.2 (HIP 6.4.43484-9999) | Host-built llama.cpp | ❌ hangs forever | ✅ healthy | ~196s | **15.85** | **75.17** |
| 7.2 | kyuz0/amd-strix-halo-toolboxes container | ❌ hangs forever | ✅ healthy | ~190s | **15.88** | 49.05 |
| 7.0 nightlies | kyuz0/amd-strix-halo-toolboxes container | ❌ hangs forever | ✅ healthy | ~191s | **15.83** | **71.71** |

**MiniMax Q8: Generation speed identical across all ROCm versions (~15.8-15.9 t/s).** Prompt processing is notably lower on ROCm 7.2 containers (~49 t/s vs ~72-75 t/s for 6.4.2 and nightlies).

### Qwen3.5-397B-A17B-UD-Q4_K_XL (205 GiB) — `-dio` ROCm version matrix

| ROCm Version | Source | Load time | tg (t/s) | pp (t/s) |
|---|---|---|---|---|
| 6.4.2 (HIP 6.4.43484-9999) | Host-built llama.cpp | ~290s | **12.56** | **25.92** |
| 7.2 | kyuz0/amd-strix-halo-toolboxes container | ~285s | **12.55** | **28.00** |
| 7.0 nightlies | kyuz0/amd-strix-halo-toolboxes container | ~285s | **12.69** | 24.69 |

**Generation speed identical across all ROCm versions (~12.5-12.7 t/s).** Prompt processing similar (~25-28 t/s).

### Vulkan RPC does NOT work for large distributed models

| Client Backend | RPC Server Backend | Result |
|---|---|---|
| HIP (any version) | HIP | ✅ works with `-dio` |
| Vulkan RADV | HIP | ❌ fails — single 147 GB RPC allocation |

Vulkan's RPC path requests the entire remote tensor buffer as a single allocation (~147 GB for MiniMax Q8), which exceeds what the remote RPC server can allocate at once. HIP splits the tensors across local (~68 GB) and remote (~72 GB) properly.

**Use HIP↔HIP for all large distributed model serving on Strix Halo.**
| Qwen3-Coder-Next-Q4_K_M | 46 GiB | 1/1 | ~30s | ~37 | ✅ (works with or without `-dio`) |

---

## 6) Troubleshooting

### Server stuck at 503, log shows `load_tensors ... RPC0 ...` with dots

**You forgot `-dio`.** Kill the server, add `-dio`, restart.

### `terminate called without an active exception` (crash in `libamdhip64`)

Same root cause — HIP/HSA allocation failure during mmap→RPC tensor upload. Add `-dio`.

### RPC server not reachable

- Check `ss -lnt | grep 50052` on the server host
- Check firewall: `sudo firewall-cmd --list-ports`
- Verify direct link connectivity: `ping <rpc-server-ip>`

### rocWMMA build failure (`Unsupported architecture`)

Your `rocwmma-devel` headers don't support gfx1151. Either:
- Build without `-DGGML_HIP_ROCWMMA_FATTN=ON` (works fine, just no WMMA flash attention)
- Use ROCm 7.2+ nightly headers from the COPR repo or kyuz0 toolbox

---

## 7) Security note

`rpc-server` is experimental and not hardened for public networks. Keep it on trusted private links only (direct USB4/Thunderbolt or isolated VLAN).
