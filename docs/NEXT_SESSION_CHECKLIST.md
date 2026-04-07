# NEXT SESSION CHECKLIST

## 0. 最初に決めること
- [ ] 次回は `UI 継続` か `FCM 再開` のどちらを進めるか決める

## 1. 開始時（そのまま実行）
- [ ] `cd /Users/hide_kakky/Dev/shiftflow_flutter`
- [ ] `git switch main`
- [ ] `./scripts/ios_local_status.sh`
- [ ] `git stash list`
- [ ] `flutter pub get`
- [ ] `flutter gen-l10n`

## 2. まず読む（3分）
- [ ] `AGENTS.md`
- [ ] `docs/SHIFTFLOW_rule_reference.md`
- [ ] `docs/NEXT_SESSION_BRIEF.md`
- [ ] `plan.md`
- [ ] `task.md`

## 3-A. UI 継続ルート
- [ ] `git switch -c feat/<next-ui-task>`
- [ ] Home と他画面のデザイン整合を確認
- [ ] 必要な画面だけ実装修正
- [ ] `flutter analyze`
- [ ] `flutter test`

## 3-B. FCM 再開ルート
- [ ] 必要な stash を選ぶ
- [ ] `git stash apply stash@{0}` または対象 stash を適用
- [ ] `env/dev.json` の `FIREBASE_*` を確認
- [ ] Firebase Console の iOS / Android app 設定を確認
- [ ] Supabase secrets の設定値を準備

## 4-B. FCM 実装（優先順）
- [ ] Firebase Console で iOS / Android app を登録
- [ ] APNs Auth Key を Firebase Cloud Messaging に登録
- [ ] `supabase secrets set` で `FCM_PROJECT_ID / FCM_CLIENT_EMAIL / FCM_PRIVATE_KEY` を設定
- [ ] `supabase functions deploy api`
- [ ] `supabase functions deploy dispatch_notifications`
- [ ] `supabase functions deploy notify_due_tasks`
- [ ] `supabase functions deploy retry_failed_notifications`

## 5-B. FCM 実機検証
- [ ] `flutter run -d ios --dart-define-from-file=env/dev.json`
- [ ] 通知許可を与える
- [ ] `notification_subscriptions` に FCM トークンが入ることを確認
- [ ] メッセージ作成後に `notification_dispatch_logs` が `sent` になることを確認
- [ ] 実機で push 通知を受信する

## 6. 終了前
- [ ] 必要なら `plan.md` / `task.md` / `implementation_plan.md` を更新
- [ ] 実機確認した場合は `./scripts/ios_local_store.sh` で iOS ローカル差分を再退避
- [ ] 使い終わった stash を整理する

## 7. GitHub
- [ ] `gh auth status`
- [ ] 新しい作業ブランチを push
- [ ] 必要なら PR 作成
