# ShiftFlow Flutter デリバリープラン（自律更新版）

## 0. 運用ルール
0. 参照優先順は `AGENTS.md` -> `docs/ルール参照順.md` -> `docs/開発フロー.md` とする。
1. 実装前に `docs/要件定義_v1.0.md` と `docs/実装ガイド_v1.0.md` を確認する。
2. 実装完了時に `plan.md` / `task.md` / `implementation_plan.md` を更新する。
3. ステータス記法: `✅ 完了` / `▶ 進行中` / `□ 未着手`
4. 末尾の `ACTION` を常に最新化する。
5. Git運用は `main` 直コミット禁止。

## 1. 現在地
- フェーズ: Phase 1 -> Phase 2 移行準備
- 状態
  - ✅ Flutter + Supabase 基盤構築
  - ✅ 要件〜運用文書の整備
  - ✅ CI と DBテスト土台
  - ✅ GitHub Public リポジトリ作成・`main` 初回 push 完了
  - ▶ Flutter画面の機能同等化（Tasks/Messages/Admin/Folders-Templates の主要操作導線まで完了）
  - ✅ 認証テスト運用の再設計（本番UIを崩さない QA 導線 + ドキュメント反映）
  - ✅ 基本UI導線のWidgetテスト追加（Auth/Home/Messages/Settings/Admin）
  - ✅ Settings の表示名編集
  - ✅ Tasks 一覧の `My / Created / All` 切替
  - ✅ Settings のプロフィール画像（表示/更新）
  - ✅ Messages 作成導線（フォルダ選択 / テンプレート適用 / 添付）
  - ✅ Messages 一覧（フォルダフィルタ / 未読のみ表示）
  - ✅ 通知失敗リトライ基盤（`retry_count` / `next_retry_at` / `retry_failed_notifications`）
  - ✅ 画面遷移時にメニューバーを固定する ShellRoute 化
  - ✅ Home 画面の情報設計とビジュアルを再構成（Notion系の余白 / 指標 / 導線を反映）
  - ▶ PWA差分の棚卸し（Phase 3: E2E / Integration）

## 2. マイルストーン
| # | マイルストーン | 状態 | Exit条件 |
| --- | --- | --- | --- |
| 1 | Foundation | ✅ | 基盤・文書・CIが揃う |
| 2 | Core Parity | ▶ | 主要CUJがiOS/Android/Webで動作 |
| 3 | Notification Hardening | □ | 通知3トリガーと重複防止が安定 |
| 4 | Release Readiness | □ | E2E完了・運用手順確定 |

## 3. ACTION
- ACTION-1: `flutter analyze` と `flutter test` を常時グリーン維持。
- ACTION-2: Auth導線の実機検証と、管理系UIの実操作テストを拡張。
- ACTION-2a: Widgetテストを土台に、次は Integrationテストで主要CUJを埋める。
- ACTION-3: `docs/E2Eシナリオ.md` に沿って実機E2Eを実施し、結果を記録。
- ACTION-4: DB/RLS と API の自動テストを拡充する。
- ACTION-5: DB migration を `scripts/db_push.sh`（`--db-url` stateless 実行）へ統一し、`link` 切替依存をなくす。
