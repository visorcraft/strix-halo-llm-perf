#!/usr/bin/env bash
set -euo pipefail

RETRIES="${RETRIES:-2}"
TIMEOUT_SEC="${TIMEOUT_SEC:-1800}"

# Usage:
#   run-one-backend.sh <backend> <model>
# Example:
#   run-one-backend.sh vulkan-native qwen
#   run-one-backend.sh rocm72 qwen
# Optional env:
#   RETRIES=3 TIMEOUT_SEC=2400 OUT_DIR=~/bench-runs run-one-backend.sh rocm72 minimax
#   QWEN_MODEL_PATH=~/models/Qwen3-Coder-Next-Q4_K_M.gguf
#   MINIMAX_MODEL_PATH=~/models/minimax-m2.5/Q3_K_M/MiniMaxAI.MiniMax-M2.5.Q3_K_M-00001-of-00007.gguf

BACKEND="${1:-}"
MODEL_KEY="${2:-}"

if [[ -z "$BACKEND" || -z "$MODEL_KEY" ]]; then
  echo "Usage: $0 <backend> <model>"
  echo "Backends: vulkan-native vulkan-container rocm644 rocm72 rocm7nightly rocm64local"
  echo "Models: qwen minimax"
  exit 1
fi

QWEN_MODEL_PATH_DEFAULT="$HOME/models/Qwen3-Coder-Next-Q4_K_M.gguf"
MINIMAX_MODEL_PATH_DEFAULT="$HOME/models/minimax-m2.5/Q3_K_M/MiniMaxAI.MiniMax-M2.5.Q3_K_M-00001-of-00007.gguf"

case "$MODEL_KEY" in
  qwen)
    MODEL_PATH="${QWEN_MODEL_PATH:-$QWEN_MODEL_PATH_DEFAULT}"
    ;;
  minimax)
    MODEL_PATH="${MINIMAX_MODEL_PATH:-$MINIMAX_MODEL_PATH_DEFAULT}"
    ;;
  *)
    echo "Unknown model: $MODEL_KEY"
    exit 1
    ;;
esac

TS="$(date +%F_%H-%M-%S)"
OUT_DIR="${OUT_DIR:-$HOME/bench-runs}"
mkdir -p "$OUT_DIR"
LOG="$OUT_DIR/${TS}_${BACKEND}_${MODEL_KEY}.log"

# Canonical benchmark profiles
VULKAN_FLAGS="--n-gpu-layers 99 -p 512 -n 128"
ROCM_TUNED_FLAGS="--n-gpu-layers 99 -fa 1 -mmp 0 -ub 2048 -ctk q4_0 -ctv q4_0 -p 512 -n 128"

run_cmd() {
  local cmd="$1"
  local attempt=1

  while [[ $attempt -le $RETRIES ]]; do
    local tmp
    tmp="$(mktemp)"

    {
      echo "=== run metadata ==="
      echo "timestamp: $(date -Is)"
      echo "backend: $BACKEND"
      echo "model: $MODEL_KEY"
      echo "model_path: $MODEL_PATH"
      echo "attempt: $attempt/$RETRIES"
      echo "timeout_sec: $TIMEOUT_SEC"
      echo "command: $cmd"
      echo

      echo "=== warmup (discard) ==="
      timeout "$TIMEOUT_SEC" bash -lc "$cmd" || true
      echo

      echo "=== measured run ==="
      timeout "$TIMEOUT_SEC" bash -lc "$cmd"
    } 2>&1 | tee "$tmp"

    cat "$tmp" > "$LOG"

    if grep -q "pp512" "$tmp" && grep -q "tg128" "$tmp"; then
      rm -f "$tmp"
      echo
      echo "Saved: $LOG"
      return 0
    fi

    echo "[WARN] Missing pp512/tg128 in output on attempt $attempt" | tee -a "$LOG"
    rm -f "$tmp"
    ((attempt++))
    sleep 2
  done

  echo "[ERROR] Failed after $RETRIES attempts: $BACKEND $MODEL_KEY" >&2
  return 1
}

case "$BACKEND" in
  vulkan-native)
    # Force Mesa RADV ICD for reproducible native Vulkan performance on Strix Halo.
    # Without this, host may pick AMDVLK/LLPC path and underperform significantly.
    CMD="VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/radeon_icd.x86_64.json VK_LOADER_LAYERS_DISABLE=all /tmp/llama-vulkan/build/bin/llama-bench -m '$MODEL_PATH' $VULKAN_FLAGS"
    run_cmd "$CMD"
    ;;

  vulkan-container)
    podman start llama-vulkan-radv >/dev/null 2>&1 || true
    CMD="podman exec llama-vulkan-radv bash -lc \"llama-bench -m '$MODEL_PATH' $VULKAN_FLAGS\""
    run_cmd "$CMD"
    ;;

  rocm644)
    podman start llama-rocm-6.4.4 >/dev/null 2>&1 || true
    CMD="podman exec llama-rocm-6.4.4 bash -lc \"llama-bench -m '$MODEL_PATH' $ROCM_TUNED_FLAGS\""
    run_cmd "$CMD"
    ;;

  rocm72)
    podman start llama-rocm-7.2 >/dev/null 2>&1 || true
    CMD="podman exec llama-rocm-7.2 bash -lc \"llama-bench -m '$MODEL_PATH' $ROCM_TUNED_FLAGS\""
    run_cmd "$CMD"
    ;;

  rocm7nightly)
    podman start llama-rocm7-nightlies >/dev/null 2>&1 || true
    # Best-known config on Strix Halo for rocm7-nightlies (improves pp/tg on recent runs).
    CMD="podman exec llama-rocm7-nightlies bash -lc \"llama-bench -m '$MODEL_PATH' $ROCM_TUNED_FLAGS\""
    run_cmd "$CMD"
    ;;

  rocm64local)
    CMD="ROCBLAS_USE_HIPBLASLT=1 /tmp/llama-hip/build/bin/llama-bench -m '$MODEL_PATH' --n-gpu-layers 99 -p 512 -n 128"
    run_cmd "$CMD"
    ;;

  *)
    echo "Unknown backend: $BACKEND"
    exit 1
    ;;
esac
