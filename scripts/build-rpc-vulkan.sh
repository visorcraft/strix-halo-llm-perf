#!/usr/bin/env bash
set -euo pipefail

# Generic public build script for llama.cpp Vulkan+RPC.
# No host/user-specific paths required.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

LLAMA_SRC_DIR="${LLAMA_SRC_DIR:-$ROOT_DIR/third_party/llama.cpp}"
LLAMA_BUILD_DIR="${LLAMA_BUILD_DIR:-$ROOT_DIR/build-rpc-vk}"
LLAMA_INSTALL_PREFIX="${LLAMA_INSTALL_PREFIX:-$ROOT_DIR/dist/rpc-vk}"
LLAMA_REPO_URL="${LLAMA_REPO_URL:-https://github.com/visorcraft/llama.cpp.git}"
LLAMA_REF="${LLAMA_REF:-master}"
CMAKE_BUILD_TYPE="${CMAKE_BUILD_TYPE:-Release}"
BUILD_JOBS="${BUILD_JOBS:-$(nproc)}"

log() { echo "[build-rpc-vulkan] $*"; }

ensure_llama_src() {
  if [[ -d "$LLAMA_SRC_DIR/.git" ]]; then
    log "Updating existing llama.cpp at: $LLAMA_SRC_DIR"
    git -C "$LLAMA_SRC_DIR" remote set-url origin "$LLAMA_REPO_URL"
    git -C "$LLAMA_SRC_DIR" fetch --all --prune
    git -C "$LLAMA_SRC_DIR" checkout "$LLAMA_REF"
    git -C "$LLAMA_SRC_DIR" reset --hard "origin/$LLAMA_REF" || true
  else
    log "Cloning llama.cpp into: $LLAMA_SRC_DIR"
    mkdir -p "$(dirname "$LLAMA_SRC_DIR")"
    git clone --depth 1 --branch "$LLAMA_REF" "$LLAMA_REPO_URL" "$LLAMA_SRC_DIR"
  fi
}

configure_build() {
  log "Configuring CMake build"
  cmake -S "$LLAMA_SRC_DIR" -B "$LLAMA_BUILD_DIR" \
    -DCMAKE_BUILD_TYPE="$CMAKE_BUILD_TYPE" \
    -DGGML_VULKAN=ON \
    -DGGML_RPC=ON
}

compile_build() {
  log "Compiling (jobs=$BUILD_JOBS)"
  cmake --build "$LLAMA_BUILD_DIR" -j "$BUILD_JOBS"
}

install_build() {
  log "Installing to $LLAMA_INSTALL_PREFIX"
  cmake --install "$LLAMA_BUILD_DIR" --prefix "$LLAMA_INSTALL_PREFIX"
}

print_summary() {
  log "Build complete"
  log "Source:  $LLAMA_SRC_DIR"
  log "Build:   $LLAMA_BUILD_DIR"
  log "Install: $LLAMA_INSTALL_PREFIX"

  echo
  echo "Binaries:"
  for b in llama-bench llama-cli llama-server rpc-server; do
    if [[ -x "$LLAMA_INSTALL_PREFIX/bin/$b" ]]; then
      echo "  - $LLAMA_INSTALL_PREFIX/bin/$b"
    elif [[ -x "$LLAMA_BUILD_DIR/bin/$b" ]]; then
      echo "  - $LLAMA_BUILD_DIR/bin/$b"
    else
      echo "  - $b (not found)"
    fi
  done
}

ensure_llama_src
configure_build
compile_build
install_build
print_summary
