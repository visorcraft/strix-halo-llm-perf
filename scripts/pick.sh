#!/usr/bin/env bash
# pick.sh — Backend selector for llama.cpp on Strix Halo hosts.
# Place at ~/pick.sh on Evo and Bee.
#
# Usage: bash ~/pick.sh <backend> <command> [args...]
#
# Backends:
#   host            — Run directly on host (ROCm 6.4.x)
#   rocm-6.4.4      — Run inside llama-rocm-6.4.4 container
#   rocm-7.2        — Run inside llama-rocm-7.2 container
#   rocm7-nightlies — Run inside llama-rocm7-nightlies container
#   vulkan-radv     — Run inside llama-vulkan-radv container
#
# Examples:
#   bash ~/pick.sh rocm7-nightlies llama-server -m model.gguf --port 8080
#   bash ~/pick.sh host rpc-server -H 10.10.25.1 -p 50052
#
set -euo pipefail

BACKEND="${1:?Usage: pick.sh <backend> <command> [args...]}"
shift
CMD="${1:?Usage: pick.sh <backend> <command> [args...]}"
shift

case "$BACKEND" in
  host)
    exec "$HOME/llama.cpp/build-rpc-hip-v2/bin/$CMD" "$@"
    ;;
  rocm-6.4.4|rocm-7.2|rocm7-nightlies|vulkan-radv)
    CONTAINER="llama-${BACKEND}"
    podman start "$CONTAINER" >/dev/null 2>&1 || true
    # Build a properly quoted command string for bash -lc
    QUOTED_ARGS=""
    for arg in "$@"; do
      # Escape single quotes in args, wrap each in single quotes
      QUOTED_ARGS="$QUOTED_ARGS '${arg//\'/\'\\\'\'}'"
    done
    exec distrobox enter "$CONTAINER" -- bash -lc "$CMD $QUOTED_ARGS"
    ;;
  *)
    echo "Unknown backend: $BACKEND" >&2
    echo "Available: host, rocm-6.4.4, rocm-7.2, rocm7-nightlies, vulkan-radv" >&2
    exit 1
    ;;
esac
