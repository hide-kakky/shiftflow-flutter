# NEXT SESSION CHECKLIST

## 0. このセッションのゴール
- Firebase / FCM の設定を完了し、実機で push 通知を確認する。
- 終了時に通知検証ログを残す。

## 1. 開始時（そのまま実行）
- [ ] `cd /Users/hide_kakky/Dev/shiftflow_flutter`
- [ ] `git switch feature/fcm-config-setup`
- [ ] `./scripts/ios_local_status.sh`
- [ ] `git stash list`
- [ ] 必要なら `git stash apply stash@{0}` で `local-firebase-config` を戻す

## 2. まず読む（3分）
- [ ] `AGENTS.md`
- [ ] `docs/SHIFTFLOW_rule_reference.md`
- [ ] `docs/NEXT_SESSION_BRIEF.md`
- [ ] `plan.md`
- [ ] `task.md`

## 3. 開発前確認
- [ ] `flutter pub get`
- [ ] `flutter gen-l10n`
- [ ] `env/dev.json` の `FIREBASE_*` が埋まっているか確認
- [ ] Firebase Console の iOS / Android app 設定値を確認
- [ ] Supabase secrets の設定値を準備

## 4. 実装（優先順）
- [ ] Firebase Console で iOS / Android app を登録
- [ ] APNs Auth Key を Firebase Cloud Messaging に登録
- [ ] `supabase secrets set` で `FCM_PROJECT_ID / FCM_CLIENT_EMAIL / FCM_PRIVATE_KEY` を設定
- [ ] `supabase functions deploy api`
- [ ] `supabase functions deploy dispatch_notifications`
- [ ] `supabase functions deploy notify_due_tasks`
- [ ] `supabase functions deploy retry_failed_notifications`

## 5. 実装後検証
- [ ] `flutter run -d ios --dart-define-from-file=env/dev.json`
- [ ] 通知許可を与える
- [ ] `notification_subscriptions` に FCM トークンが入ることを確認
- [ ] メッセージ作成後に `notification_dispatch_logs` が `sent` になることを確認
- [ ] 実機で push 通知を受信する

## 6. 反映前
- [ ] `docs/SHIFTFLOW_e2e_scenarios.md` に通知検証結果を記録
- [ ] 必要なら `plan.md` / `task.md` / `implementation_plan.md` を更新
- [ ] 使用後の stash を整理する

## 7. GitHub
- [ ] `gh auth status` 確認
- [ ] `git push -u origin feature/fcm-config-setup`
- [ ] PR作成または設定メモを残す
