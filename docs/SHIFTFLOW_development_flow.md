# SHIFTFLOW Development Flow

最終更新: 2026-03-25

## 1. 目的
- 開発速度と本番安全性を両立する。
- 「誰が実行しても同じ結果」になる運用に統一する。

## 2. 環境分離
- local: Docker上の Supabase Local（`supabase start`）
- dev: `shiftflow-dev`（project ref: `tabmibqeuasmeymispfb`）
- prod: `shiftflow-prod`（project ref: `teaixpfvlgtrqdtmovwg`）

## 3. ブランチ戦略
1. `main` に直接コミットしない。
2. `feat/*` または `fix/*` で実装。
3. コミットメッセージは日本語で統一する。
4. `flutter analyze` / `flutter test` / 必要な Supabase 検証を通してから PR。
5. PR マージ後に `main` を最新化して次のタスクへ進む。

## 4. 日常開発フロー（UI/機能実装）
1. `git switch main && git pull --ff-only`
2. `git switch -c feat/<task-name>`
3. `flutter pub get && flutter gen-l10n`
4. `supabase start && supabase db reset --local --yes`
5. `./scripts/run_web_dev.sh` で動作確認しながら実装
6. `flutter analyze && flutter test`
7. ドキュメント更新（`plan.md` / `task.md` / `implementation_plan.md`）
8. コミット、PR、マージ

## 5. Migration運用（重要）
### 5-1. 方針
- `supabase link` 切替依存を避け、`--db-url` で stateless 実行する。
- 実行は `scripts/db_push.sh` に統一する。

### 5-2. 初回設定
```bash
cp env/db_push.dev.env.example env/db_push.dev.env
cp env/db_push.prod.env.example env/db_push.prod.env
```

- `SUPABASE_ACCESS_TOKEN` には PAT（`sbp_...`）を設定
- `SUPABASE_DB_URL` には対象環境の接続文字列を設定

### 5-3. 実行
```bash
./scripts/db_push.sh dev --dry-run
./scripts/db_push.sh dev
./scripts/db_push.sh prod --dry-run
./scripts/db_push.sh prod
```

- `prod` 実行時は `yes` 確認が必須

## 6. Codex × Supabase 運用
- MCP 認証が `Unsupported` の場合は、MCP経由操作に固執せず CLI で継続する。
- CLI 実行は `scripts/supabase_with_token.sh` を使用する。
- 詳細は `docs/SHIFTFLOW_codex_supabase_mcp_troubleshooting.md` を参照。

## 7. セキュリティ
1. `env/*.json`, `env/*.env`, `supabase/.env` は Git 管理しない。
2. `service_role` / PAT はチャットやPRに貼らない。
3. 漏えいが疑われたら即ローテーション。
   - `docs/SHIFTFLOW_supabase_key_rotation_runbook.md`

## 8. リリース前チェック
- `flutter analyze` 成功
- `flutter test` 成功
- 必要な migration が dev/prod で適用済み
- E2Eシナリオ更新済み
- 監査ログや権限系に回帰がない
