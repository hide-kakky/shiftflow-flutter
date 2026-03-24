#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="$ROOT_DIR/env/qa.cloud.json"
EXAMPLE_FILE="$ROOT_DIR/env/qa.cloud.json.example"

if [ ! -f "$ENV_FILE" ]; then
  echo "[ERROR] $ENV_FILE がありません。"
  echo "次を実行してください: cp $EXAMPLE_FILE $ENV_FILE"
  echo "その後、SUPABASE_URL / SUPABASE_ANON_KEY をクラウド値に更新してください。"
  exit 1
fi

cd "$ROOT_DIR"
flutter run -d chrome --dart-define-from-file="$ENV_FILE"
