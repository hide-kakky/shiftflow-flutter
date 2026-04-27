# ShiftFlow Flutter 実装タスク

## Git運用（必須）
- [ ] `AGENTS.md` と `docs/ルール参照順.md` を確認
- [ ] `main` で直接作業しない
- [ ] `feat/*` / `fix/*` / `chore/*` / `docs/*` ブランチで実装
- [ ] コミットメッセージは日本語で記述
- [ ] CIグリーン確認後にPR作成
- [x] GitHub Public リポジトリ `hide-kakky/shiftflow-flutter` 作成済み

## Phase 1: 基盤
- [x] Flutterプロジェクト初期化（iOS/Android/Web）
- [x] Riverpod/go_router/supabase_flutter/intl 導入
- [x] Supabase スキーマ + RLS + Storage
- [x] Edge Functions（api/dispatch_notifications/notify_due_tasks）
- [x] 文書一式（TASUKI形式）
- [x] CIひな形（Flutter + Supabase migration check）

## Phase 2: v1.1 再設計
- [x] DB / RLS 再設計方針の文書化
- [x] API / Bootstrap 契約の再設計
- [x] Flutter の `currentOrganization` / `currentUnit` 文脈管理設計
- [x] Home / Messages / Admin の v1.1 情報設計差分整理
- [x] Auth / Participation 導線の再設計
- [x] ローカル Supabase へ v1.1 migration 適用
- [x] `getBootstrapData` の v1.1 実レスポンス確認
- [ ] Auth導線の実機検証
- [x] Authテスト運用の再設計（本番UIを維持しつつ QA 可能にする）
- [x] `Test Login` などテスト専用文言をログイン画面に常設しない設計へ統一
- [x] QA専用導線をビルドフラグで制御（Debug/QAのみ有効、本番は無効）
- [x] テストユーザー作成/更新スクリプトを `scripts/` に追加
- [x] `docs/セットアップガイド.md` に test users 構築手順を追加
- [x] `docs/テスト計画.md` に「本番UI同等テスト」観点を追加
- [x] Tasks 詳細UI（担当者・期限・優先度）
- [x] Tasks 添付ファイル対応（アップロード/紐付け/表示）
- [x] Messages 詳細UI（既読状態・コメント一覧・ピン）
- [x] Messages 作成導線（フォルダ選択・テンプレート適用・添付）
- [x] Messages 一覧（フォルダフィルタ / 未読のみ表示）
- [x] Folders/Templates 管理画面の拡充
- [x] Admin 画面（Users/Organizations/Audit）の操作導線
- [x] Settings の表示名編集
- [x] Settings のプロフィール画像対応
- [x] Tasks 一覧の `My / Created / All` 切替
- [x] Home 画面の UI 再設計を v1.1 要件で再評価
- [x] Messages 画面の `currentUnit / tab / scope` 基本導線反映
- [x] Admin 画面のモバイル段階表示 / PC分割表示の骨格反映
- [x] Messages の個人メッセージ UI を複数宛先・確認付きで仕上げる
- [x] Admin に `join_requests / units / invites` の実運用UIを追加
- [x] Home block を実データ前提で磨き込む
- [x] Participation 受け側UI（組織コード申請 / 招待受諾）を追加
- [x] モバイル下部ナビを `ホーム / タスク / 検索 / メッセージ` の4件へ再編
- [x] `設定` / `管理` を個人メニュー導線へ移動
- [x] 主要画面の重なり遷移を解消する route/page 遷移へ変更
- [x] 横断検索画面（`ALL / タスク / メッセージ / ユーザー`）を追加
- [x] ユーザープロフィール画面と個人チャット直遷移を追加
- [x] member が権限外ユニットを見たり `currentUnit` を変更できる問題を API 側で遮断
- [x] フォルダ / メッセージ / タスク / 添付 / 検索を accessible unit ベースで再防御

## Phase 3: 品質
- [x] 基本UI導線のWidgetテスト追加（Auth/Home/Messages/Settings/Admin）
- [x] DB/RLS 自動テスト拡充（組織越境 / ユニット越境 / DM越境）
- [x] API 正常系/異常系テスト拡充（bootstrap / join / invite / currentUnit）
- [x] bootstrap 状態分岐 / Participation / Home / Admin / Messages の Widget/Router テスト拡充
- [ ] Integrationテスト（主要CUJ）
- [x] 通知失敗リトライ処理の実装
- [x] DB migration 運用を stateless 化（`scripts/db_push.sh` + `--db-url`）
- [ ] 権限境界の回帰テストを `member cannot see HQ/west units` ケースまで追加

## 次セッションで最初にやること
- [ ] [docs/次回セッション確認項目.md](./docs/次回セッション確認項目.md) を上から実行
- [ ] Auth / Participation 導線の実機検証
- [ ] Integration テスト（ログイン -> 参加 -> 利用開始）を追加
- [ ] 新しいモバイル/PC ナビ・検索・DM直遷移の実機検証
- [ ] `member@shiftflow.local` で本部 / 西日本エリアが見えないことを実機確認
- [ ] Home / Participation の受け入れ観点を E2E シナリオに反映
