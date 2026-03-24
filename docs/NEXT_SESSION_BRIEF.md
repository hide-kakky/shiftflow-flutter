# NEXT SESSION BRIEF

## 現在の状態（2026-03-25 時点）
- リポジトリ: `https://github.com/hide-kakky/shiftflow-flutter`
- ブランチ: `main`
- 状態: `main` と `origin/main` は同期済み（クリーン）

## 完了済み
- Flutter + Supabase 基盤
- docs 一式（要件、設計、API、DB、テスト、運用、デプロイ）
- GitHub Actions CI（Flutter analyze/test + Supabase db reset/lint）
- Supabase 初期マイグレーション、RLS、Storage policy
- Tasks 詳細入力（優先度・期限・担当者） + 添付ファイル対応（アップロード/紐付け/表示）
- 環境変数運用改善（`env/*.json` + `scripts/run_web_dev.sh` / `scripts/run_web_qa.sh`）
- 認証テスト運用の再設計（本番UI維持 + QA補助導線 + test users 運用）
- Supabase 環境分離（`shiftflow-dev` / `shiftflow-prod`）
- DB migration の stateless 実行（`scripts/db_push.sh` + `--db-url`）

## 直近の優先タスク
1. Messages 詳細UI（既読状態・コメント一覧・ピン）
2. Admin 画面の操作導線（Users/Organizations/Audit）
3. Auth導線の実機検証（admin/manager/member）
4. E2Eシナリオの実施結果記録（`docs/SHIFTFLOW_e2e_scenarios.md`）
5. CI migration フローの `--db-url` 化（安全運用の統一）

## 再開時の最短コマンド
```bash
cd /Users/hide_kakky/Dev/shiftflow_flutter
git switch main && git pull --ff-only
git switch -c feat/phase2-messages-admin
flutter pub get
flutter gen-l10n
supabase start
supabase db reset --local --yes
./scripts/run_web_dev.sh
./scripts/db_push.sh dev --dry-run
```

## 完了条件（次回）
- Messages または Admin の Phase 2 タスクを1つ以上完了
- `flutter analyze` / `flutter test` / `supabase db lint --local --fail-on error` が成功
