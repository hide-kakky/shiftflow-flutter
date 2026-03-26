# Supabase DB Tests

このディレクトリは、ローカルSupabaseで実行するSQLテストを配置します。

## 実行例
```bash
supabase start
supabase db reset --local --yes
psql postgresql://postgres:postgres@127.0.0.1:55422/postgres -f supabase/tests/rls_access_matrix.sql
psql postgresql://postgres:postgres@127.0.0.1:55422/postgres -f supabase/tests/notification_dispatch_dedup.sql
psql postgresql://postgres:postgres@127.0.0.1:55422/postgres -f supabase/tests/notification_retry_smoke.sql
```

## テスト方針
- RLSによる越境拒否
- 通知重複防止ロジック
- 通知失敗リトライ対象の抽出確認
- 将来的に pgTAP 導入で自動化拡張
