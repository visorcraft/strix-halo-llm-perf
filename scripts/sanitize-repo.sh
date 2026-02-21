#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

echo "[sanitize] scanning tracked files for obvious sensitive data..."

patterns=(
  '192\.168\.[0-9]{1,3}\.[0-9]{1,3}'
  '10\.77\.[0-9]{1,3}\.[0-9]{1,3}'
  '/root/\.ssh'
  '/home/thomas/\.ssh'
  'id_evo_x2'
  'id_bee'
  'ergo1280'
  '-----BEGIN (RSA|OPENSSH|EC|DSA) PRIVATE KEY-----'
  'ghp_[A-Za-z0-9]{36}'
  'AKIA[0-9A-Z]{16}'
)

# Grep only tracked files and skip .git internals automatically via git ls-files
files=$(git ls-files)
if [[ -z "$files" ]]; then
  echo "[sanitize] no tracked files found"
  exit 0
fi

found=0
for rx in "${patterns[@]}"; do
  if grep -nE "$rx" $files >/tmp/sanitize_hits.txt 2>/dev/null; then
    echo "[sanitize] ❌ matched pattern: $rx"
    cat /tmp/sanitize_hits.txt
    found=1
  fi
done

if [[ "$found" -ne 0 ]]; then
  echo "[sanitize] FAILED"
  exit 1
fi

echo "[sanitize] ✅ no sensitive patterns found"
