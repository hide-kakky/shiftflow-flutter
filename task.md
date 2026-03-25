# ShiftFlow Flutter 実装タスク

## Git運用（必須）
- [ ] `main` で直接作業しない
- [ ] `feat/*` または `fix/*` ブランチで実装
- [ ] CIグリーン確認後にPR作成
- [x] GitHub Public リポジトリ `hide-kakky/shiftflow-flutter` 作成済み

## Phase 1: 基盤
- [x] Flutterプロジェクト初期化（iOS/Android/Web）
- [x] Riverpod/go_router/supabase_flutter/intl 導入
- [x] Supabase スキーマ + RLS + Storage
- [x] Edge Functions（api/dispatch_notifications/notify_due_tasks）
- [x] 文書一式（TASUKI形式）
- [x] CIひな形（Flutter + Supabase migration check）

## Phase 2: 機能同等化
- [ ] Auth導線の実機検証
- [x] Authテスト運用の再設計（本番UIを維持しつつ QA 可能にする）
- [x] `Test Login` などテスト専用文言をログイン画面に常設しない設計へ統一
- [x] QA専用導線をビルドフラグで制御（Debug/QAのみ有効、本番は無効）
- [x] テストユーザー作成/更新スクリプトを `scripts/` に追加
- [x] `docs/SHIFTFLOW_setup_guide.md` に test users 構築手順を追加
- [x] `docs/SHIFTFLOW_testing_plan.md` に「本番UI同等テスト」観点を追加
- [x] Tasks 詳細UI（担当者・期限・優先度）
- [x] Tasks 添付ファイル対応（アップロード/紐付け/表示）
- [x] Messages 詳細UI（既読状態・コメント一覧・ピン）
- [x] Messages 作成導線（フォルダ選択・テンプレート適用・添付）
- [x] Folders/Templates 管理画面の拡充
- [x] Admin 画面（Users/Organizations/Audit）の操作導線
- [x] Settings の表示名編集
- [ ] Settings のプロフィール画像対応
- [x] Tasks 一覧の `My / Created / All` 切替

## Phase 3: 品質
- [x] 基本UI導線のWidgetテスト追加（Auth/Home/Messages/Settings/Admin）
- [ ] DB/RLS 自動テスト拡充
- [ ] API 正常系/異常系テスト拡充
- [ ] Integrationテスト（主要CUJ）
- [ ] 通知失敗リトライ処理の実装
- [x] DB migration 運用を stateless 化（`scripts/db_push.sh` + `--db-url`）

## 次セッションで最初にやること
- [ ] [docs/NEXT_SESSION_CHECKLIST.md](./docs/NEXT_SESSION_CHECKLIST.md) を上から実行
