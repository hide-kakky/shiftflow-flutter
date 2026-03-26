# SHIFTFLOW Operations Guide

## 1. 日次運用
- 監視対象
  - Supabase Edge Functions ログ
  - `notification_dispatch_logs` 失敗件数
  - `audit_logs` の異常操作
- 定期作業
  - 失敗通知の再送確認
  - 不要なアカウント状態の棚卸し（`suspended/revoked`）

## 2. ユーザー運用
- 新規ユーザー
  - `users` 作成
  - `memberships` に `pending`
  - 承認後 `active` へ更新
- 停止
  - `memberships.status` を `suspended` または `revoked` に変更

## 3. 障害対応
### API障害
1. Edge Function ログを確認
2. `code/reason` を抽出
3. 該当 route の入力値・権限を確認

### DB障害
1. `supabase db lint --local` を実行
2. 直近マイグレーションを確認
3. 必要に応じて修正マイグレーションを追加

### 通知障害
1. `notification_dispatch_logs.status='failed'` を確認
2. `error_message` の分類
3. 再試行ジョブを実行
   - `retry_failed_notifications` を実行し、`status='queued'` へ戻す
   - 例:
```bash
curl -s "http://127.0.0.1:54321/functions/v1/retry_failed_notifications" \
  -H "apikey: ${SUPABASE_ANON_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"limit":100,"maxRetries":3}'
```

## 4. 監査
- 管理操作は `audit_logs` で追跡。
- 毎週、主要操作（ユーザー更新・組織更新）をレビュー。

## 5. セキュリティ
- Supabaseキーの漏洩防止（CI secret 管理）
- 最小権限でロール付与
- RLS変更時は必ずテストを追加
