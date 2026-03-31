#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

STASH_TAG="ios-local-build-files"

echo "== git status =="
git status --short --branch

echo
echo "== iOS stash list (${STASH_TAG}) =="
git stash list | awk -v tag="$STASH_TAG" '$0 ~ tag {print}'
