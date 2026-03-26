# ShiftFlow Flutter

ShiftFlow PWA を Flutter + Supabase に移行するための統合リポジトリです。

GitHub: `https://github.com/hide-kakky/shiftflow-flutter`

## 構成
- Flutter アプリ: `lib/`（iOS/Android/Web 共通）
- Supabase: `supabase/`（migrations/functions/seed/tests）
- 進行管理: `plan.md`, `task.md`, `implementation_plan.md`
- 実装文書: `docs/`

## クイックスタート
```bash
cd /Users/hide_kakky/Dev/shiftflow_flutter
flutter pub get
flutter gen-l10n
supabase start
supabase db reset --local --yes
cp env/dev.json.example env/dev.json
# env/dev.json の SUPABASE_ANON_KEY を自分の値に更新
./scripts/run_web_dev.sh

# QA(ローカルSupabase向け)
./scripts/run_web_qa_local.sh
```

## QA環境の使い分け（重要）
- ローカルSupabaseを使う: `env/qa.local.json` + `./scripts/run_web_qa_local.sh`
- クラウドSupabaseを使う: `env/qa.cloud.json` + `./scripts/run_web_qa_cloud.sh`
- 互換スクリプト: `./scripts/run_web_qa.sh`（内部的には `qa.local.json` を使う）

## DB Migration 運用（推奨）
`db push` は `--db-url` + 環境別ラッパで実行し、`supabase link` の切替に依存しない運用を採用する。

```bash
# 1) テンプレートを作成
cp env/db_push.dev.env.example env/db_push.dev.env
cp env/db_push.prod.env.example env/db_push.prod.env

# 2) 各ファイルに PAT と DB URL を設定

# 3) 実行
./scripts/db_push.sh dev --dry-run
./scripts/db_push.sh dev
./scripts/db_push.sh prod --dry-run
./scripts/db_push.sh prod
```

## 主な設計ドキュメント
- [要件定義](./docs/SHIFTFLOW_requirements_v1.0.md)
- [実装ガイド](./docs/SHIFTFLOW_implementation_guide_v1.0.md)
- [Flutterアーキテクチャ](./docs/SHIFTFLOW_flutter_architecture.md)
- [API定義](./docs/SHIFTFLOW_api_definition.md)
- [DBスキーマ](./docs/SHIFTFLOW_database_schema.md)
- [テスト計画](./docs/SHIFTFLOW_testing_plan.md)
- [PWA差分分析](./docs/SHIFTFLOW_pwa_gap_analysis_2026-03-26.md)
- [開発フロー](./docs/SHIFTFLOW_development_flow.md)
- [Supabase キーローテーション手順](./docs/SHIFTFLOW_supabase_key_rotation_runbook.md)
- [Codex × Supabase MCP トラブルシュート](./docs/SHIFTFLOW_codex_supabase_mcp_troubleshooting.md)

## Git運用ルール
- `main` 直コミット禁止
- 機能単位で feature ブランチを作成
- コミットメッセージは日本語で記述
- CI（Flutter + Supabase）グリーンを確認して PR マージ
