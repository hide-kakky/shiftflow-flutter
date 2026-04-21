# NEXT SESSION CHECKLIST

## 0. 最初に決めること
- [ ] 先に `実機確認` を終えるか、先に `GitHub へ公開` するか決める

## 1. 開始時（そのまま実行）
- [ ] `cd /Users/hide_kakky/Dev/shiftflow_flutter`
- [ ] `git branch --show-current`
- [ ] `./scripts/ios_local_status.sh`
- [ ] `git status --short`
- [ ] `flutter pub get`
- [ ] `flutter gen-l10n`

## 2. まず読む（3分）
- [ ] `AGENTS.md`
- [ ] `docs/SHIFTFLOW_rule_reference.md`
- [ ] `docs/NEXT_SESSION_BRIEF.md`
- [ ] `plan.md`
- [ ] `task.md`

## 3-A. 実機確認ルート
- [ ] `cp env/dev.json.example env/dev.json`
- [ ] `env/dev.json` に `SUPABASE_URL` を設定
- [ ] `env/dev.json` に `SUPABASE_ANON_KEY` を設定
- [ ] `flutter run -d 00008110-000645C62E86201E --dart-define-from-file=env/dev.json`
- [ ] ログインできることを確認
- [ ] `Tasks` で詳細 / 編集 / 削除を確認
- [ ] `Messages` で複数選択 / 一括既読 / 詳細削除 / 添付起動を確認
- [ ] `Admin > Templates` で編集 / 削除を確認
- [ ] 必要なら実機テスト結果を docs に追記

## 3-B. GitHub 公開ルート
- [ ] iOS ローカル差分を feature 差分へ混ぜない方針を確認
- [ ] 必要なら `./scripts/ios_local_store.sh` で iOS ローカル差分を退避
- [ ] `git diff --stat`
- [ ] `flutter analyze`
- [ ] `flutter test`
- [ ] コミット対象を確認
- [ ] 日本語コミットメッセージで commit
- [ ] ブランチを push
- [ ] PR 作成
- [ ] `main` へ merge

## 4. 今回の主な確認対象
- [ ] `TasksScreen` の詳細シート追加
- [ ] `TasksScreen` の編集 / 削除導線
- [ ] `MessagesScreen` の一括既読
- [ ] `MessagesScreen` の詳細削除
- [ ] 添付ダウンロード導線
- [ ] `AdminScreen` のテンプレート編集 / 削除
- [ ] `app_router` の認証リダイレクトテスト

## 5. 終了前
- [ ] 必要なら `docs/NEXT_SESSION_BRIEF.md` を更新
- [ ] 必要なら `docs/NEXT_SESSION_CHECKLIST.md` を更新
- [ ] 実機確認した場合は `./scripts/ios_local_store.sh` で iOS ローカル差分を再退避
- [ ] `git status --short` を確認

## 6. GitHub
- [ ] `gh auth status`
- [ ] 現在ブランチを push
- [ ] PR を作成
- [ ] merge 後にローカルを同期
