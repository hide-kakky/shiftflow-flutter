# SHIFTFLOW PWA Gap Analysis (2026-03-26)

## 1. 目的
- `ShiftFlow_PWA` を再精査し、`shiftflow_flutter` の現状との差分を明文化する。
- 「実装済み」「一部実装」「未着手」を分けて、次の開発判断をしやすくする。

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
- Messages: 一覧、詳細、コメント、ピン、既読切替、既読状況取得
- Admin: Users / Folders / Templates / Organizations / Audit の基本導線
- Settings: 表示名、テーマ、言語、プロフィール画像（表示/更新）

### 3.2 一部実装
- Home
  - Flutter は概要カードのみ
  - PWA は Home 上の導線や情報量がより多い
- Messages
  - API / DB はフォルダ、テンプレート、添付、既読制御を持つ
  - Flutter UI は詳細系は強化済みだが、作成時のフォルダ選択・テンプレート適用・添付追加が未反映

### 3.3 未着手または不足
- Messages 一覧のフォルダフィルタ / 未読のみ表示
- メッセージ作成時のフォルダ選択、テンプレート適用、添付追加
- Integration テストと手動 E2E 記録
- 通知失敗リトライ

## 4. 優先順位
1. Messages 作成導線の PWA 同等化
   - フォルダ選択
   - テンプレート適用
   - 添付追加
2. Integration テストと E2E 記録
3. 通知失敗リトライ

## 5. 判断メモ
- いまの Flutter は「管理系」と「詳細系」は前進している。
- 一方で PWA が強いのは「一覧から迷わず操作できる導線」と「作成フォームの完成度」。
- 次フェーズでは、画面を増やすより「既存画面の操作密度」を PWA に寄せるのが効果的。
