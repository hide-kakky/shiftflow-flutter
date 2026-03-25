# SHIFTFLOW E2E Scenarios

## 1. 使い方
- 各シナリオを iOS / Android / Web で最低1回ずつ実施する。
- 結果は `pass/fail` とログURL（またはスクショ）を残す。

## 2. シナリオ
### E2E-01 Magic Link ログイン
1. Auth画面でメール入力
2. Magic Link受信
3. ログイン成功し `/home` 遷移
- 期待: セッション有効、ホームカード表示

### E2E-02 タスク作成〜完了
1. `Tasks` で新規作成
2. タイトル/説明/期限を設定
3. 更新後に `completeTask`
- 期待: 一覧反映、完了状態に遷移

### E2E-03 メッセージ投稿〜既読〜コメント
1. `Messages` で投稿
2. `markMemoAsRead` 実行
3. コメント追加
- 期待: 既読状態とコメントが即時反映

### E2E-04 フォルダ・テンプレート運用
1. 管理者でフォルダ作成
2. テンプレート追加
3. メッセージ作成時にフォルダ選択
- 期待: フォルダ/テンプレートが一覧に反映

### E2E-05 設定変更
1. 表示名を変更して保存
2. 言語を `ja/en` 切替
3. テーマを `light/dark/system` 切替
4. 再起動後に設定保持確認
- 期待: 表示名・表示言語・テーマが保持される

### E2E-06 管理者機能
1. `Admin > Users` でロール変更
2. `Admin > Organizations` で組織情報更新
3. `Admin > Audit` で履歴確認
- 期待: 変更内容が即時反映、監査ログ記録

### E2E-07 通知
1. 新規メッセージ作成
2. タスク担当割当
3. 期限前日通知（Cron）実行
- 期待: `notification_dispatch_logs` に重複なしで記録

## 3. 完了判定
- 全シナリオ `pass`
- 重大不具合なし

## 4. 実施ログ（2026-03-25, Local Supabase, Web）
- E2E-01 Magic Link ログイン: 未実施（次回）
- E2E-02 タスク作成〜完了: 未実施（次回）
- E2E-03 メッセージ投稿〜既読〜コメント: 未実施（次回）
- E2E-04 フォルダ・テンプレート運用: 実装済み（UI導線追加済み）、手動E2E未実施
- E2E-05 設定変更: 未実施（次回）
- E2E-06 管理者機能: 部分実施
  - `adminListUsers` を admin/manager/member で呼び分け
  - 結果: admin/manager は成功、member は `forbidden`
- E2E-07 通知: 未実施（次回）

## 5. PWA差分観点の追加確認
- Messages 作成時にフォルダ・テンプレート・添付が使えるか
- Tasks で `My / Created / All` の切替ができるか
- Settings でプロフィール画像の更新ができるか
