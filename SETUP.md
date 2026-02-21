# 🔧 Setup Guide — Fedora 43 + Vulkan LLM Inference on Strix Halo

Complete step-by-step guide for configuring a GMKtec EVO-X2 (or any Strix Halo machine) as a headless LLM inference box.

## Prerequisites

- GMKtec EVO-X2 or other Strix Halo device (Ryzen AI Max+ 395, 128 GB LPDDR5X)
- Fedora 43 Server installed (minimal, no desktop environment)
- SSH access to the machine

## 1. Basic System Setup

### Set hostname

```bash
sudo hostnamectl set-hostname <your-hostname>
```

### Set static IP (adjust for your network)

```bash
sudo nmcli con mod "Wired connection 1" \
  ipv4.method manual \
  ipv4.addresses <your-lan-ip>/<prefix> \
  ipv4.gateway <your-lan-gateway> \
  ipv4.dns "<dns1>,<dns2>"
sudo nmcli con up "Wired connection 1"
```

### Extend root LVM to use full disk

Fedora's default install only allocates ~15 GB for root. Extend it:

```bash
sudo lvextend -l +100%FREE /dev/<vg_name>/root
sudo resize2fs /dev/<vg_name>/root
```

Verify:

```bash
df -h /
# Should show full disk size (e.g., 1.8 TB)
```

### Use disk-backed /tmp instead of tmpfs

By default Fedora mounts `/tmp` as tmpfs (RAM-backed). For LLM work, you want disk-backed `/tmp` so large model files don't eat into your GPU-available memory:

```bash
sudo systemctl mask tmp.mount
sudo reboot
```

## 2. Kernel Parameters for GPU Unified Memory

This is the most critical step. Without these parameters, the GPU can only access a small fraction of the 128 GB RAM.

Edit GRUB defaults:

```bash
sudo vi /etc/default/grub
```

Add to `GRUB_CMDLINE_LINUX`:

```
iommu=pt amdgpu.gttsize=131072 ttm.pages_limit=33554432
```

| Parameter | Purpose |
|-----------|---------|
| `iommu=pt` | IOMMU passthrough mode — reduces overhead for iGPU unified memory access |
| `amdgpu.gttsize=131072` | Sets GPU Translation Table to 128 GB (131072 MiB) — allows GPU to address nearly all system RAM |
| `ttm.pages_limit=33554432` | Sets TTM pinned pages limit to 128 GB (33554432 × 4 KB = 128 GB) |

Apply and reboot:

```bash
sudo grub2-mkconfig -o /boot/grub2/grub.cfg
sudo reboot
```

### Create persistent modprobe config

```bash
cat <<'EOF' | sudo tee /etc/modprobe.d/amdgpu_llm_optimized.conf
# Strix Halo LLM-optimized GPU memory settings
options amdgpu gttsize=131072
options ttm pages_limit=33554432
EOF
```

### Verify GTT memory

After reboot:

```bash
cat /sys/class/drm/card*/device/mem_info_gtt_total
# Should show ~137438953472 (128 GB in bytes)
```

## 3. GPU Access and Performance Tuning

### Add user to GPU groups

```bash
sudo usermod -aG video,render $USER
```

(Log out and back in for group changes to take effect.)

### Install ROCm monitoring tools

```bash
sudo dnf install -y rocm-smi rocminfo
```

Verify GPU is detected:

```bash
rocm-smi
rocminfo | grep -A5 "Name:"
```

### Set up udev rules for GPU access

```bash
cat <<'EOF' | sudo tee /etc/udev/rules.d/99-amd-kfd.rules
SUBSYSTEM=="kfd", KERNEL=="kfd", MODE="0666"
EOF
sudo udevadm control --reload-rules
```

### Install and configure tuned

```bash
sudo dnf install -y tuned
sudo systemctl enable --now tuned
sudo tuned-adm profile accelerator-performance
```

Verify:

```bash
tuned-adm active
# Should show: Current active profile: accelerator-performance
```

## 4. Build llama.cpp with Vulkan

### Install build dependencies

```bash
sudo dnf install -y vulkan-headers vulkan-loader-devel mesa-vulkan-drivers \
  cmake gcc-c++ git
```

### Clone and build

```bash
git clone https://github.com/ggml-org/llama.cpp.git
cd llama.cpp
mkdir build && cd build
cmake .. -DGGML_VULKAN=ON -DCMAKE_BUILD_TYPE=Release
cmake --build . --config Release -j$(nproc)
```

### Verify Vulkan GPU detection

```bash
./bin/llama-bench --help 2>&1 | head -1
# Should build and run without errors

# Quick sanity check with a small model:
./bin/llama-bench -m /path/to/model.gguf -ngl 99 -p 512 -n 128
```

You should see in the output:
```
ggml_vulkan: 0 = Radeon 8060S Graphics (RADV GFX1151) (radv) | uma: 1 | fp16: 1 | warp size: 64 | matrix cores: KHR_coopmat
```

## 5. Download Models

Example using `huggingface-cli`:

```bash
pip install huggingface-hub

# Qwen3 30B-A3B MoE (sweet spot for this hardware)
huggingface-cli download Qwen/Qwen3-30B-A3B-GGUF qwen3-30b-a3b-q4_k_m.gguf --local-dir ~/models/

# Llama 3.1 70B (tests the limits of 128 GB)
huggingface-cli download bartowski/Meta-Llama-3.1-70B-Instruct-GGUF Meta-Llama-3.1-70B-Instruct-Q4_K_M.gguf --local-dir ~/models/
```

## 6. Run Benchmarks

```bash
cd llama.cpp/build

# Single model benchmark
./bin/llama-bench -m ~/models/qwen3-30b-a3b-q4_k_m.gguf -ngl 99 -p 512 -n 128

# Server mode for interactive use
./bin/llama-server -m ~/models/qwen3-30b-a3b-q4_k_m.gguf -ngl 99 -c 8192
```

## ROCm HIP Status

As of February 2026, ROCm HIP is **not functional** on gfx1151 with kernel 6.18:

- `libhsa-runtime64.so.1.18.0` segfaults at offset `0xa8b3e`
- The community has confirmed this is a known issue
- **Vulkan RADV is the recommended workaround** and actually outperforms HIP in several benchmarks (particularly token generation)

When ROCm HIP becomes stable, it may offer better prompt processing (pp) performance — community results show up to 50% higher pp512 with ROCm 6.4.4 on working setups.

## TDP Configuration

The EVO-X2 supports configurable TDP (85W default, up to 120W). Our benchmarks show:

- **85W**: Best for small models (≤3B) which are memory-bandwidth bound
- **120W**: 5–17% faster for models 7B+ where compute becomes the bottleneck

TDP can typically be configured in BIOS settings.

## Tips

- **`-fa 1` (flash attention)**: Recommended by the community for Strix Halo. Reduces memory usage at longer contexts.
- **`--no-mmap`**: Prevents memory-mapped file I/O which can cause slowdowns on unified memory architectures.
- **Monitor GPU usage**: `watch -n1 rocm-smi` to verify the GPU is being utilized.
- **linux-firmware**: Use version 20260110 or newer. Version 20251125 is known to break ROCm on Strix Halo.
