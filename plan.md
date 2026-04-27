# ShiftFlow Flutter デリバリープラン（v1.1移行版）

## 0. 運用ルール
0. 参照優先順は `AGENTS.md` -> `docs/ルール参照順.md` -> `docs/開発フロー.md` とする。
1. 実装前に `docs/要件定義_v1.1_草案.md`、`docs/API定義.md`、`docs/データベーススキーマ.md`、`docs/実装ガイド_v1.0.md` を確認する。
2. 実装完了時に `plan.md` / `task.md` / `implementation_plan.md` を更新する。
3. ステータス記法: `✅ 完了` / `▶ 進行中` / `□ 未着手`
4. 末尾の `ACTION` を常に最新化する。
5. Git運用は `main` 直コミット禁止。

## 1. 現在地
- フェーズ: v1.1 正本同期 -> DB / API 再設計
- 状態
  - ✅ Flutter + Supabase 基盤構築
  - ✅ 要件〜運用文書の整備
  - ✅ CI と DBテスト土台
  - ✅ GitHub Public リポジトリ作成・`main` 初回 push 完了
  - ✅ v1.1 文書正本の同期
  - ✅ 認証テスト運用の再設計（本番UIを崩さない QA 導線 + ドキュメント反映）
  - ✅ 基本UI導線のWidgetテスト追加（Auth/Home/Messages/Settings/Admin）
  - ✅ Settings の表示名編集
  - ✅ Tasks 一覧の `My / Created / All` 切替
  - ✅ Settings のプロフィール画像（表示/更新）
  - ✅ Messages 作成導線（フォルダ選択 / テンプレート適用 / 添付）
  - ✅ Messages 一覧（フォルダフィルタ / 未読のみ表示）
  - ✅ 通知失敗リトライ基盤（`retry_count` / `next_retry_at` / `retry_failed_notifications`）
  - ✅ 画面遷移時にメニューバーを固定する ShellRoute 化
  - ✅ DB / API / 文脈管理の再設計
  - ✅ Home / Messages / Admin の v1.1 実装着手
  - ✅ Participation 受け側 UI（組織コード申請 / 招待受諾）追加
  - ✅ v1.1 API / DB-RLS 検証スクリプト追加
  - ✅ ローカル migration 適用
  - ✅ `getBootstrapData` のローカル実レスポンス確認
  - ✅ RLS 再帰と direct message select 漏れを migration で修正
  - ✅ モバイル下部ナビ4件化と個人メニュー集約
  - ✅ `/search` / `/users/:userId` / `/messages/direct/:userId` の導線追加
  - ✅ 主要画面の重なり遷移を避ける page 遷移へ変更
  - ✅ member の権限外ユニット露出を API / bootstrap / currentUnit 変更の各層で遮断
  - ✅ フォルダ / メッセージ / タスク / 添付 / 検索を accessible unit ベースで再防御

## 2. マイルストーン
| # | マイルストーン | 状態 | Exit条件 |
| --- | --- | --- | --- |
| 1 | v1.1 Spec Sync | ▶ | 要件・API・DB・設計・テスト・運用文書が同期済み |
| 2 | Data / API Refactor | ✅ | DB / RLS / API が新要件を表現可能 |
| 3 | UI Refactor | ✅ | Home / Messages / Admin / Participation の新導線が反映済み |
| 4 | Release Readiness | □ | E2E完了・運用手順確定 |

## 3. ACTION
- ACTION-1: `flutter analyze` と `flutter test` を常時グリーン維持。
- ACTION-2: `scripts/verify_v11_routes.ts` と `scripts/verify_v11_access.ts` をローカル確認手順へ組み込む。
- ACTION-3: Auth / Participation 導線と新ナビ導線の実機検証を行う。
- ACTION-4: `member@shiftflow.local` で本部 / 西日本エリアが見えず currentUnit 変更も拒否されることを実機確認する。
- ACTION-5: Integration テストを追加し、ログイン -> 参加 -> 利用開始 -> 検索/DM を固定する。
- ACTION-6: E2E と運用文書へ今回のナビ / 検索 / プロフィール / DM 導線を反映する。
