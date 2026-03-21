# NEXT SESSION BRIEF

## 現在の状態（2026-03-21 時点）
- リポジトリ: `https://github.com/hide-kakky/shiftflow-flutter`
- ブランチ: `main`
- 状態: `main` と `origin/main` は同期済み（クリーン）

## 完了済み
- Flutter + Supabase 基盤
- docs 一式（要件、設計、API、DB、テスト、運用、デプロイ）
- GitHub Actions CI（Flutter analyze/test + Supabase db reset/lint）
- Supabase 初期マイグレーション、RLS、Storage policy

## 直近の優先タスク
1. Tasks 詳細UI（担当者・期限・添付）
2. Messages 詳細UI（既読状態・コメント一覧・ピン）
3. Admin 画面の操作導線（Users/Organizations/Audit）

## 再開時の最短コマンド
```bash
cd /Users/hide_kakky/Dev/shiftflow_flutter
git switch main && git pull --ff-only
git switch -c feat/phase2-tasks-details
flutter pub get
flutter gen-l10n
supabase start
supabase db reset --local --yes
```

## 完了条件（次回）
- Phase 2 タスクを1つ以上完了
- `flutter analyze` / `flutter test` / `supabase db lint --local --fail-on error` が成功
