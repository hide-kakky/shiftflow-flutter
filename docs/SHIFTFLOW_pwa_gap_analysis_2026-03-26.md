# SHIFTFLOW PWA Gap Analysis (2026-03-26)

## 1. 目的
- `ShiftFlow_PWA` と `shiftflow_flutter` の差分を明文化し、優先タスクを明確化する。

## 2. 参照元
- `ShiftFlow_PWA/README.md`
- `ShiftFlow_PWA/frontend/public/index.html`
- `ShiftFlow_PWA/frontend/public/i18n.js`
- `ShiftFlow_PWA/functions/api/[[route]].js`
- `shiftflow_flutter/lib/**`
- `shiftflow_flutter/supabase/functions/api/index.ts`

## 3. 現在の評価
### 3.1 実装済み
- 認証: Magic Link / Password ログイン、QA補助導線、ロール別 API 制御
- Tasks: 作成、優先度、期限、担当者、添付アップロード、完了、`My / Created / All` 切替
- Messages: 一覧（フォルダフィルタ/未読のみ表示）、詳細、作成（フォルダ選択/テンプレート適用/添付）、コメント、ピン、既読切替、既読状況取得
- Admin: Users / Folders / Templates / Organizations / Audit の基本導線
- Settings: 表示名、テーマ、言語、プロフィール画像（表示/更新）

### 3.2 一部実装
- Home
  - Flutter は概要カード中心
  - PWA は Home 上の導線や情報量がより多い

### 3.3 未着手または不足
- Integration テストと手動 E2E 記録
- 通知失敗リトライ

## 4. 優先順位
1. Auth導線の実機検証とE2E記録
2. Integration テスト（主要CUJ）
3. 通知失敗リトライ

## 5. 判断メモ
- Phase 2 の機能同等化はほぼ完了。
- 次フェーズは「実機検証ログ」と「自動テストの厚み」を優先するのが最も効果的。
