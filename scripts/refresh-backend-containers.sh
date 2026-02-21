#!/usr/bin/env bash
set -euo pipefail

# Force-refresh backend containers so benchmarks run on the latest toolbox images.
#
# Default backends refreshed:
#   - llama-vulkan-radv      -> kyuz0/...:vulkan-radv
#   - llama-rocm-6.4.4       -> kyuz0/...:rocm-6.4.4
#   - llama-rocm-7.2         -> kyuz0/...:rocm-7.2
#   - llama-rocm7-nightlies  -> kyuz0/...:rocm7-nightlies
#
# Optional:
#   --include-amdvlk : also refresh llama-vulkan-amdvlk
#   --prune-legacy   : remove legacy container llama-rocm-7rc-rocwmma if present

INCLUDE_AMDVLK=0
PRUNE_LEGACY=0

for arg in "$@"; do
  case "$arg" in
    --include-amdvlk) INCLUDE_AMDVLK=1 ;;
    --prune-legacy) PRUNE_LEGACY=1 ;;
    -h|--help)
      cat <<'EOF'
Usage: scripts/refresh-backend-containers.sh [--include-amdvlk] [--prune-legacy]

Force-pulls latest images, removes existing distroboxes, and recreates them.
This guarantees containers are rebased to latest tag images.
EOF
      exit 0
      ;;
    *)
      echo "Unknown argument: $arg" >&2
      exit 1
      ;;
  esac
done

if ! command -v distrobox >/dev/null 2>&1; then
  echo "[ERROR] distrobox not found in PATH" >&2
  exit 1
fi

if ! command -v podman >/dev/null 2>&1; then
  echo "[ERROR] podman not found in PATH" >&2
  exit 1
fi

BACKENDS=(
  "llama-vulkan-radv|docker.io/kyuz0/amd-strix-halo-toolboxes:vulkan-radv"
  "llama-rocm-6.4.4|docker.io/kyuz0/amd-strix-halo-toolboxes:rocm-6.4.4"
  "llama-rocm-7.2|docker.io/kyuz0/amd-strix-halo-toolboxes:rocm-7.2"
  "llama-rocm7-nightlies|docker.io/kyuz0/amd-strix-halo-toolboxes:rocm7-nightlies"
)

if [[ "$INCLUDE_AMDVLK" -eq 1 ]]; then
  BACKENDS+=("llama-vulkan-amdvlk|docker.io/kyuz0/amd-strix-halo-toolboxes:vulkan-amdvlk")
fi

echo "== Pull latest backend images =="
for entry in "${BACKENDS[@]}"; do
  IFS='|' read -r _ image <<<"$entry"
  echo "[PULL] $image"
  podman pull "$image"
done

echo
echo "== Recreate distroboxes =="
for entry in "${BACKENDS[@]}"; do
  IFS='|' read -r name image <<<"$entry"
  echo "[REMOVE] $name (if exists)"
  distrobox rm -f "$name" >/dev/null 2>&1 || true

  echo "[CREATE] $name <- $image"
  distrobox create --name "$name" --image "$image" --yes >/dev/null

done

if [[ "$PRUNE_LEGACY" -eq 1 ]]; then
  echo
echo "== Prune legacy container =="
  distrobox rm -f llama-rocm-7rc-rocwmma >/dev/null 2>&1 || true
fi

echo
echo "== Final image IDs in use =="
for entry in "${BACKENDS[@]}"; do
  IFS='|' read -r name image <<<"$entry"
  image_id="$(podman inspect "$name" --format '{{.Image}}' 2>/dev/null || true)"
  echo "$name"
  echo "  image: $image"
  echo "  image_id: $image_id"
done

echo
echo "[OK] Backend containers refreshed and recreated on latest images."
