#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TOKEN_FILE="$ROOT_DIR/env/supabase_cli.env"

load_token_from_file() {
  if [ ! -f "$TOKEN_FILE" ]; then
    return 1
  fi

  # shellcheck disable=SC1090
  set -a
  source "$TOKEN_FILE"
  set +a

  if [ -n "${SUPABASE_ACCESS_TOKEN:-}" ]; then
    return 0
  fi
  return 1
}

if [ -z "${SUPABASE_ACCESS_TOKEN:-}" ]; then
  load_token_from_file || true
fi

if [ -z "${SUPABASE_ACCESS_TOKEN:-}" ]; then
  echo "[ERROR] SUPABASE_ACCESS_TOKEN が見つかりません。"
  echo ""
  echo "次のどちらかで設定してください。"
  echo "1) 一時的に実行:"
  echo "   SUPABASE_ACCESS_TOKEN=<YOUR_PAT> $0 projects list"
  echo ""
  echo "2) ローカルファイルを作成:"
  echo "   cp $ROOT_DIR/env/supabase_cli.env.example $TOKEN_FILE"
  echo "   # その後 SUPABASE_ACCESS_TOKEN を実値に更新"
  exit 1
fi

if [[ "${SUPABASE_ACCESS_TOKEN}" == sb_publishable_* ]]; then
  echo "[ERROR] SUPABASE_ACCESS_TOKEN に Publishable key が設定されています。"
  echo "必要なのは Personal Access Token (通常 'sbp_' で始まる値) です。"
  exit 1
fi

if [ "$#" -eq 0 ]; then
  echo "[INFO] 使用例:"
  echo "  $0 projects list"
  echo "  $0 link --project-ref <PROJECT_REF> --password <DB_PASSWORD>"
  exit 0
fi

SUPABASE_ACCESS_TOKEN="$SUPABASE_ACCESS_TOKEN" supabase "$@"
