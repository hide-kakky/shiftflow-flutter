#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

STASH_TAG="ios-local-build-files"
TARGETS=(
  "ios/Runner.xcodeproj/project.pbxproj"
  "ios/Runner.xcworkspace/contents.xcworkspacedata"
  "ios/Runner/Info.plist"
  "ios/Podfile.lock"
)

# 対象4ファイルに差分がない場合は何もしない。
if git status --short -- "${TARGETS[@]}" | grep -q .; then
  STASH_MESSAGE="${STASH_TAG}: $(date '+%Y-%m-%d %H:%M:%S')"
  git stash push -u -m "$STASH_MESSAGE" -- "${TARGETS[@]}"
  echo "[OK] iOSローカル差分を退避しました: ${STASH_MESSAGE}"
  git status --short --branch
else
  echo "[INFO] 退避対象のiOS差分はありません。"
fi
