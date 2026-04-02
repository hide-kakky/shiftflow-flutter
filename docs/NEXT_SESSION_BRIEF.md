# NEXT SESSION BRIEF

## 現在の状態（2026-04-03 時点）
- リポジトリ: `https://github.com/hide-kakky/shiftflow-flutter`
- 現在ブランチ: `feature/fcm-config-setup`
- 状態: 作業ツリーはクリーン
- 補足: ローカル `main` には FCM 実装がマージ済みだが、`origin/main` にはまだ未 push

## 完了済み
- Flutter + Supabase 基盤
- docs 一式（要件、設計、API、DB、テスト、運用、デプロイ）
- GitHub Actions CI（Flutter analyze/test + Supabase db reset/lint）
- Supabase 初期マイグレーション、RLS、Storage policy
- Tasks 詳細入力（優先度・期限・担当者） + 添付ファイル対応（アップロード/紐付け/表示）
- Tasks 一覧の `My / Created / All` 切替
- Messages 作成導線（フォルダ選択 / テンプレート適用 / 添付）
- Messages 一覧（フォルダフィルタ / 未読のみ表示）
- 通知失敗リトライ基盤（`retry_count` / `next_retry_at` / `retry_failed_notifications`）
- Settings の表示名編集
- Settings のプロフィール画像（表示/更新）
- 認証テスト運用の再設計（本番UI維持 + QA補助導線 + test users 運用）
- Supabase 環境分離（`shiftflow-dev` / `shiftflow-prod`）
- DB migration の stateless 実行（`scripts/db_push.sh` + `--db-url`）
- Widget テスト追加（Auth/Home/Messages/Settings/Admin）
- 画面遷移時にメニューバーが巻き込まれないよう `ShellRoute` 化
- FCM プッシュ通知基盤の実装
  - Flutter 側で FCM トークン取得と `notification_subscriptions` への登録
  - Supabase Edge Functions から FCM HTTP v1 で配送
  - `notification_dispatch_logs` の `queued -> sent/failed` 更新
  - `retry_failed_notifications` から再送を実行
  - iOS Push capability 用の entitlements / background mode 追加
- 通知用 migration を dev へ適用済み
  - `20260326123000_notification_retry_columns.sql`
  - `20260402110000_add_fcm_notification_support.sql`
- `ios/Runner.xcworkspace/xcshareddata/swiftpm/` を `.gitignore` へ追加

## PWA 再精査で見えた差分
1. Integration テストと手動 E2E 記録

## 直近の優先タスク
1. Firebase / FCM の実設定
2. Supabase secrets 設定と Functions 再デプロイ
3. 実機で通知トークン登録と push 配信確認
4. E2Eシナリオの実施結果記録（`docs/SHIFTFLOW_e2e_scenarios.md`）

## 再開時の最短コマンド
```bash
cd /Users/hide_kakky/Dev/shiftflow_flutter
git switch feature/fcm-config-setup
./scripts/ios_local_status.sh
flutter pub get
flutter gen-l10n
# 必要なら Firebase ローカル設定を復元
git stash list
# local-firebase-config を戻す場合
git stash apply stash@{0}
```

## 次回の具体タスク
1. Firebase Console で iOS / Android app を登録
2. APNs Auth Key を Firebase Cloud Messaging に登録
3. `env/dev.json` に `FIREBASE_*` を設定
4. Supabase に以下 secrets を設定
   - `FCM_PROJECT_ID`
   - `FCM_CLIENT_EMAIL`
   - `FCM_PRIVATE_KEY`
5. Functions を再デプロイ
   - `supabase functions deploy api`
   - `supabase functions deploy dispatch_notifications`
   - `supabase functions deploy notify_due_tasks`
   - `supabase functions deploy retry_failed_notifications`
6. 実機で通知許可、トークン登録、メッセージ通知受信を確認

## stash メモ
- `stash@{0}`: `local-firebase-config: 2026-04-03`
  - `GoogleService-Info.plist` などローカル Firebase 設定
- `stash@{1}`: `ios-local-build-files: 2026-03-31 22:36:02`
  - 旧 iOS ローカル差分。必要になるまでは触らない

## ルール参照順（必須）
1. `AGENTS.md`
2. `docs/SHIFTFLOW_rule_reference.md`
3. `docs/SHIFTFLOW_development_flow.md`

## 完了条件（次回）
- Firebase / FCM の実設定が揃っている
- 実機で push 通知を1回以上受信できる
- `docs/SHIFTFLOW_e2e_scenarios.md` に通知検証結果を残す
- 必要なブランチ / stash の整理方針が明確
