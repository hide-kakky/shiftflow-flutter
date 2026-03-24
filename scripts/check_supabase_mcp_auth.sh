#!/usr/bin/env bash
set -euo pipefail

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

if ! CODEX_BIN_RESOLVED="$(resolve_codex_bin)"; then
  echo "[ERROR] codex コマンドが見つかりません。"
  exit 1
fi

echo "[check] codex version"
"$CODEX_BIN_RESOLVED" --version || true

echo ""
echo "[check] mcp list"
LIST_OUTPUT="$("$CODEX_BIN_RESOLVED" mcp list 2>&1 || true)"
echo "$LIST_OUTPUT"

contains() {
  local text="$1"
  local pattern="$2"
  if command -v rg >/dev/null 2>&1; then
    echo "$text" | rg -q "$pattern"
    return $?
  fi
  echo "$text" | grep -E -q "$pattern"
}

echo ""
if contains "$LIST_OUTPUT" "supabase"; then
  if contains "$LIST_OUTPUT" "supabase.*Unsupported"; then
    echo "[result] supabase MCP は登録済みですが Auth=Unsupported です。"
    echo ""
    echo "次の対処を実施してください。"
    echo "1) codex / VSCode拡張を最新版へ更新"
    echo "2) codex mcp add supabase --url https://mcp.supabase.com"
    echo "3) codex mcp login supabase"
    echo ""
    echo "それでも改善しない場合は、当面は scripts/supabase_with_token.sh でCLI操作を継続します。"
    exit 2
  fi

  echo "[result] supabase MCP が検出されました。Auth状態を確認してください。"
  exit 0
fi

echo "[result] supabase MCP が未登録です。"
echo "実行: codex mcp add supabase --url https://mcp.supabase.com"
exit 3
