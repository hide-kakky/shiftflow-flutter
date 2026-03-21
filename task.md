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
- [ ] Tasks 詳細UI（担当者・期限・添付）
- [ ] Messages 詳細UI（既読状態・コメント一覧・ピン）
- [ ] Folders/Templates 管理画面の拡充
- [ ] Admin 画面（Users/Organizations/Audit）の操作導線

## Phase 3: 品質
- [ ] DB/RLS 自動テスト拡充
- [ ] API 正常系/異常系テスト拡充
- [ ] Integrationテスト（主要CUJ）
- [ ] 通知失敗リトライ処理の実装

## 次セッションで最初にやること
- [ ] [docs/NEXT_SESSION_CHECKLIST.md](./docs/NEXT_SESSION_CHECKLIST.md) を上から実行
