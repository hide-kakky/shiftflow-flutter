#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TARGET="${1:-}"
shift || true

if [ -z "$TARGET" ]; then
  echo "[ERROR] 対象環境を指定してください: dev | prod"
  echo "使用例: $0 dev --dry-run"
  echo "       $0 prod"
  exit 1
fi

case "$TARGET" in
  dev)
    ENV_FILE="$ROOT_DIR/env/db_push.dev.env"
    ;;
  prod)
    ENV_FILE="$ROOT_DIR/env/db_push.prod.env"
    ;;
  *)
    echo "[ERROR] 不正な環境: $TARGET (dev/prod のみ対応)"
    exit 1
    ;;
esac

if [ ! -f "$ENV_FILE" ]; then
  echo "[ERROR] $ENV_FILE がありません。"
  if [ "$TARGET" = "dev" ]; then
    echo "作成例: cp $ROOT_DIR/env/db_push.dev.env.example $ENV_FILE"
  else
    echo "作成例: cp $ROOT_DIR/env/db_push.prod.env.example $ENV_FILE"
  fi
  exit 1
fi

# shellcheck disable=SC1090
set -a
source "$ENV_FILE"
set +a

if [ -z "${SUPABASE_ACCESS_TOKEN:-}" ] || [ -z "${SUPABASE_DB_URL:-}" ]; then
  echo "[ERROR] SUPABASE_ACCESS_TOKEN または SUPABASE_DB_URL が未設定です。"
  exit 1
fi

if [[ "$SUPABASE_ACCESS_TOKEN" == sb_publishable_* ]]; then
  echo "[ERROR] SUPABASE_ACCESS_TOKEN に Publishable key が設定されています。"
  echo "PAT (通常 sbp_...) を設定してください。"
  exit 1
fi

if [ "$TARGET" = "prod" ]; then
  echo "[WARN] PRODUCTION へ migration を適用します。"
  echo "対象 DB URL: ${SUPABASE_DB_URL}"
  printf "続行する場合は yes と入力: "
  read -r CONFIRM
  if [ "$CONFIRM" != "yes" ]; then
    echo "[INFO] 中断しました。"
    exit 1
  fi
fi

echo "[INFO] db push target: $TARGET"
SUPABASE_ACCESS_TOKEN="$SUPABASE_ACCESS_TOKEN" supabase db push --db-url "$SUPABASE_DB_URL" "$@"
