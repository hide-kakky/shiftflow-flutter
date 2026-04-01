# AGENTS.md

このリポジトリで作業する全エージェント向けの必須ルール。

## 基本方針
- 日本語で説明する。
- `main` へ直接コミットしない。必ず `feat/*` / `fix/*` / `docs/*` ブランチで作業する。
- コミットメッセージは日本語で統一する。

## iOSローカル差分（`!?`）運用ルール【必須】
実機起動後に発生する iOS ローカル差分は、機能実装と混ぜてコミットしない。

対象ファイル:
- `ios/Runner.xcodeproj/project.pbxproj`
- `ios/Runner.xcworkspace/contents.xcworkspacedata`
- `ios/Runner/Info.plist`
- `ios/Podfile.lock`

### 新ブランチ作成前（必須）
1. `./scripts/ios_local_status.sh` を実行
2. `!?` がある場合は `./scripts/ios_local_store.sh` を実行
3. その後に `git switch -c <branch>`

### 実機検証時
- 実機検証の直前だけ `./scripts/ios_local_apply.sh` を実行する。
- 実機検証完了後は `./scripts/ios_local_store.sh` で再退避する。

### 禁止事項
- `ios` ローカル差分を feature/docs の実装コミットに混ぜること。
- `pop` 前提運用（stashを消す運用）。復元は `apply` を使う。

### 逸脱時の復旧
- `!?` のまま分岐してしまった場合は、すぐ `./scripts/ios_local_store.sh` を実行する。
- すでにコミットへ混入した場合は、iOSローカル差分をコミットから外してから PR を作成する。
