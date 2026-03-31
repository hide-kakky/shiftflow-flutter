#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

STASH_TAG="ios-local-build-files"

stash_ref="$(git stash list | awk -F: -v tag="$STASH_TAG" '$0 ~ tag {print $1; exit}')"

if [ -z "$stash_ref" ]; then
  echo "[INFO] 適用できる iOS 用stash（${STASH_TAG}）がありません。"
  exit 0
fi

echo "[INFO] 適用するstash: ${stash_ref}"
git stash apply "$stash_ref"
echo "[OK] stashを適用しました（stashは保持されます）。"
git status --short --branch
