# SHIFTFLOW Requirements v1.0

- 作成日: 2026-03-21
- 対象プロジェクト: `shiftflow_flutter`
- 参照元: `ShiftFlow_PWA`（`README.md`, `functions/api/config.js`, `functions/api/[[route]].js`, `migrations/*.sql`）

## 1. 目的
ShiftFlow_PWA で提供していた業務機能を、Flutter（iOS/Android/Web）+ Supabase に移植し、同等機能を運用可能な状態で提供する。

## 2. スコープ
- 対象
  - Flutter アプリ（iOS/Android/Web）
  - Supabase（Auth, Postgres, Storage, Edge Functions）
  - ドキュメント・CI・運用手順
- 非対象
  - Cloudflare D1/KV/R2/GAS 依存の継続
  - 既存データの移行
  - Google OAuth 独自実装

## 3. ユーザーロール
| ロール | 説明 | 主な権限 |
| --- | --- | --- |
| `admin` | 組織管理者 | 全機能（組織管理・ユーザー管理・監査ログ） |
| `manager` | 現場責任者 | 業務機能全般 + 管理系の一部 |
| `member` | 一般メンバー | タスク・メッセージ・設定 |
| `guest` | 仮状態 | 認証後の最小アクセスのみ |

## 4. 機能要件（FR）
### 4.1 認証
- FR-AUTH-001: Supabase Magic Link でログインできる。
- FR-AUTH-002: ログイン後、所属組織とロールに基づくアクセス制御を行う。
- FR-AUTH-003: `pending/suspended/revoked` は業務APIを拒否する。

### 4.2 タスク
- FR-TASK-001: タスク CRUD（`addNewTask`, `updateTask`, `completeTask`, `deleteTaskById`）。
- FR-TASK-002: 一覧取得（`listMyTasks`, `listCreatedTasks`, `listAllTasks`, `getTaskById`）。
- FR-TASK-003: 担当者割当（`task_assignees`）と通知連携。

### 4.3 メッセージ
- FR-MSG-001: メッセージ CRUD（`getMessages`, `getMessageById`, `addNewMessage`, `deleteMessageById`）。
- FR-MSG-002: コメント投稿（`addNewComment`）。
- FR-MSG-003: 既読制御（`toggleMemoRead`, `markMemoAsRead`, `markMemosReadBulk`）。
- FR-MSG-004: ピン留め（`messages/:id/pin`）と既読状況確認（`messages/:id/read_status`）。

### 4.4 フォルダ・テンプレート
- FR-FOLDER-001: フォルダ取得/作成/更新/アーカイブ（`listActiveFolders`, `folders` CRUD）。
- FR-FOLDER-002: テンプレート取得/作成（`templates` GET/POST）。

### 4.5 設定
- FR-SET-001: ユーザー設定取得・保存（`getUserSettings`, `saveUserSettings`）。
- FR-SET-002: アプリテーマ切替（system/light/dark）。
- FR-SET-003: 言語切替（`ja/en`）。

### 4.6 管理機能
- FR-ADM-001: ユーザー管理（`listActiveUsers`, `adminListUsers`, `adminUpdateUser`）。
- FR-ADM-002: 組織管理（`adminListOrganizations`, `adminGetOrganization`, `adminUpdateOrganization`）。
- FR-ADM-003: 監査ログ閲覧（`getAuditLogs`）。

### 4.7 添付・Storage
- FR-ATT-001: 添付メタデータ管理（`attachments`, `task_attachments`, `message_attachments`）。
- FR-ATT-002: 添付取得（`downloadAttachment`）で署名URLを返す。
- FR-ATT-003: `profiles`, `attachments` バケットを使用。

### 4.8 通知
- FR-NOTI-001: 新規メッセージ通知。
- FR-NOTI-002: 担当タスク作成通知。
- FR-NOTI-003: 期限前日通知（Cron/定期実行）。
- FR-NOTI-004: 重複送信を `notification_dispatch_logs` で防止。

## 5. 非機能要件（NFR）
- NFR-SEC-001: 全テーブルに RLS を適用し、組織越境アクセスを禁止。
- NFR-SEC-002: API は JWT 前提、Edge Function でロールを検証。
- NFR-I18N-001: 日本語・英語のUI文言をARBで管理。
- NFR-OPS-001: CIで `flutter analyze`, `flutter test`, `supabase db reset/lint` を実行。
- NFR-TRACE-001: 要件→設計→実装→テストを文書リンクで追跡可能にする。

## 6. 受け入れ基準
- AC-001: iOS/Android/Web で同じ主要CUJ（ログイン、タスク、メッセージ、設定、管理）を完了できる。
- AC-002: `docs/SHIFTFLOW_e2e_scenarios.md` のシナリオが全て実施済み。
- AC-003: 主要ルートがEdge Function `api` で呼び出せる。
- AC-004: RLSテストで越境アクセス拒否を確認済み。

## 7. トレーサビリティ
- 要件: 本書
- 実装方針: [SHIFTFLOW_implementation_guide_v1.0.md](./SHIFTFLOW_implementation_guide_v1.0.md)
- 設計: [SHIFTFLOW_flutter_architecture.md](./SHIFTFLOW_flutter_architecture.md)
- API: [SHIFTFLOW_api_definition.md](./SHIFTFLOW_api_definition.md)
- DB: [SHIFTFLOW_database_schema.md](./SHIFTFLOW_database_schema.md)
- テスト: [SHIFTFLOW_testing_plan.md](./SHIFTFLOW_testing_plan.md), [SHIFTFLOW_e2e_scenarios.md](./SHIFTFLOW_e2e_scenarios.md)
- 運用/デプロイ: [SHIFTFLOW_operations_guide.md](./SHIFTFLOW_operations_guide.md), [SHIFTFLOW_deployment_guide.md](./SHIFTFLOW_deployment_guide.md)
