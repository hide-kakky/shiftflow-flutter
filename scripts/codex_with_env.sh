#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TOKEN_FILE="$ROOT_DIR/env/supabase_cli.env"
CODEX_DEFAULT_BIN="/Users/hide_kakky/.vscode/extensions/openai.chatgpt-26.318.11754-darwin-arm64/bin/macos-aarch64/codex"

resolve_codex_bin() {
  if command -v codex >/dev/null 2>&1; then
    command -v codex
    return 0
  fi
  if [ -x "${CODEX_BIN:-}" ]; then
    echo "$CODEX_BIN"
    return 0
  fi
  if [ -x "$CODEX_DEFAULT_BIN" ]; then
    echo "$CODEX_DEFAULT_BIN"
    return 0
  fi
  return 1
}

if [ -f "$TOKEN_FILE" ]; then
  # shellcheck disable=SC1090
  set -a
  source "$TOKEN_FILE"
  set +a
fi

if ! CODEX_BIN_RESOLVED="$(resolve_codex_bin)"; then
  echo "[ERROR] codex コマンドが見つかりません。"
  echo "次のどちらかを設定してください。"
  echo "1) PATH に codex を追加"
  echo "2) 実行時に CODEX_BIN を指定"
  echo "   CODEX_BIN=/path/to/codex ./scripts/codex_with_env.sh --version"
  exit 1
fi

exec "$CODEX_BIN_RESOLVED" "$@"
