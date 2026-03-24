#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="$ROOT_DIR/env/dev.json"

if [ ! -f "$ENV_FILE" ]; then
  echo "[ERROR] $ENV_FILE がありません。"
  echo "次を実行してください: cp $ROOT_DIR/env/dev.json.example $ENV_FILE"
  exit 1
fi

cd "$ROOT_DIR"
flutter run -d chrome --dart-define-from-file="$ENV_FILE"
