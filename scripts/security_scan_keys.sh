#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

echo "[scan] repository key patterns (sb_secret_ / sb_publishable_)"
HITS="$(rg -n "sb_secret_[A-Za-z0-9._-]+|sb_publishable_[A-Za-z0-9._-]+" -S . \
  --glob '!build' \
  --glob '!.dart_tool' \
  --glob '!**/node_modules/**' \
  --glob '!env/*.json' \
  --glob '!docs/SHIFTFLOW_supabase_key_rotation_runbook.md' || true)"

if [ -n "$HITS" ]; then
  echo "$HITS"
  echo "[scan] FAILED: repository contains key-like strings"
  exit 1
fi

echo "[scan] OK: no key-like strings found"
