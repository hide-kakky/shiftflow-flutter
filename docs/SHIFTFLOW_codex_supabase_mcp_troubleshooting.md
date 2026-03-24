# SHIFTFLOW Codex × Supabase MCP トラブルシュート

最終更新: 2026-03-25

## 1. よくある症状
- `supabase projects list` が `Access token not provided` で失敗
- `codex mcp login supabase` が `No authorization support detected`

## 2. 原因の分離
1. `supabase` CLI操作の失敗
- Codex実行環境に `SUPABASE_ACCESS_TOKEN` が渡っていない。

2. `codex mcp login supabase` の失敗
- `codex mcp list` の Auth が `Unsupported` の場合、MCP認証自体が未対応。

## 3. 実運用の回避策（推奨）
### 3-1. PAT を使って CLI 操作
```bash
cp env/supabase_cli.env.example env/supabase_cli.env
# env/supabase_cli.env の SUPABASE_ACCESS_TOKEN に PAT を設定

./scripts/supabase_with_token.sh projects list
./scripts/supabase_with_token.sh db push
```

### 3-1b. `db push` は stateless 実行に統一（推奨）
`supabase link` 切替方式ではなく、`--db-url` 指定で環境を固定する。

```bash
cp env/db_push.dev.env.example env/db_push.dev.env
cp env/db_push.prod.env.example env/db_push.prod.env

# env ファイルに SUPABASE_ACCESS_TOKEN(PAT) / SUPABASE_DB_URL を設定
./scripts/db_push.sh dev --dry-run
./scripts/db_push.sh prod --dry-run
```

本実行:

```bash
./scripts/db_push.sh dev
./scripts/db_push.sh prod
```

### 3-2. Codex 起動時に環境変数を読み込む
```bash
./scripts/codex_with_env.sh
```

## 4. MCP診断
```bash
./scripts/check_supabase_mcp_auth.sh
```

- `Auth=Unsupported` の場合:
  1. Codex CLI / VSCode拡張を更新
  2. `codex mcp add supabase --url https://mcp.supabase.com`
  3. `codex mcp login supabase`

## 5. セキュリティ注意
- `SUPABASE_ACCESS_TOKEN` / `service_role` は Git にコミットしない。
- 本番キーと開発キーを分離する。
- 漏えい時は [SHIFTFLOW_supabase_key_rotation_runbook.md](./SHIFTFLOW_supabase_key_rotation_runbook.md) に従いローテーションする。
