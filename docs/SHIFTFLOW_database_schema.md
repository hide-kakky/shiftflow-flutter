# SHIFTFLOW Database Schema

- 実装ファイル:
  - `supabase/migrations/20260321093000_init_shiftflow_schema.sql`
  - `supabase/migrations/20260326123000_notification_retry_columns.sql`

## 1. 列挙型
- `app.user_role`: `admin`, `manager`, `member`, `guest`
- `app.member_status`: `pending`, `active`, `suspended`, `revoked`
- `app.task_status`: `open`, `in_progress`, `on_hold`, `completed`, `canceled`
- `app.priority_level`: `low`, `medium`, `high`
- `app.dispatch_event`: `new_message`, `new_task_assigned`, `task_due_tomorrow`

## 2. 主要テーブル
| テーブル | 用途 | 主キー | 組織分離キー |
| --- | --- | --- | --- |
| `organizations` | 組織情報 | `id` | - |
| `users` | ユーザー情報 | `id` | - |
| `memberships` | 組織所属・ロール | `id` | `organization_id` |
| `folders` | メッセージ整理用フォルダ | `id` | `organization_id` |
| `folder_members` | 非公開フォルダの閲覧メンバー | `(folder_id,user_id)` | folder経由 |
| `templates` | 定型文 | `id` | `organization_id` |
| `tasks` | タスク本体 | `id` | `organization_id` |
| `task_assignees` | タスク担当者 | `(task_id,user_id)` | task経由 |
| `messages` | メッセージ本体 | `id` | `organization_id` |
| `message_reads` | 既読情報 | `id` | message経由 |
| `message_comments` | コメント | `id` | `organization_id` |
| `attachments` | 添付メタデータ | `id` | `organization_id` |
| `task_attachments` | タスク添付紐付け | `(task_id,attachment_id)` | task経由 |
| `message_attachments` | メッセージ添付紐付け | `(message_id,attachment_id)` | message経由 |
| `audit_logs` | 監査ログ | `id` | `organization_id` |
| `login_audits` | ログイン監査 | `id` | `organization_id` |
| `auth_proxy_logs` | 認証周辺ログ | `id` | 間接 |
| `notification_subscriptions` | 通知購読設定 | `id` | user経由 |
| `notification_dispatch_logs` | 通知配信履歴 | `id` | `organization_id` |

## 3. RLS方針
- 原則
  - 自組織のみ参照可能。
  - 更新権限は `admin/manager/member/guest` に応じて制限。
- 実装関数
  - `app.current_user_id()`
  - `app.has_membership(org_id)`
  - `app.has_role(org_id, allowed_roles[])`
- 代表ポリシー
  - 管理系更新: `admin/manager`
  - ユーザー自己更新: 自分のみ
  - 監査ログ参照: `admin/manager`

## 4. Storage
- バケット
  - `profiles`（プロフィール画像）
  - `attachments`（添付ファイル）
- ポリシー
  - 認証済みユーザーのみ read/write
  - 実運用で必要に応じて MIME/サイズ制限を強化

## 5. インデックス
- `idx_memberships_org_status`
- `idx_tasks_org_status`
- `idx_messages_org_created`
- `idx_notification_dispatch_unique`
- `idx_notification_dispatch_retry`

## 5.1 通知リトライ列（`notification_dispatch_logs`）
- `retry_count`:
  - 失敗後の再キュー回数。`0` 以上。
- `next_retry_at`:
  - 次回再試行可能時刻。`retry_failed_notifications` がこの時刻を見て再キューする。

## 6. 注意点
- `notification_dispatch_logs` は重複通知防止の中核。`event_type + source_id + target_user_id` の重複チェックを必ず維持する。
- アプリ側で `organization_id` を欠落させないこと。

## 7. 関連文書
- [SHIFTFLOW_api_definition.md](./SHIFTFLOW_api_definition.md)
- [SHIFTFLOW_testing_plan.md](./SHIFTFLOW_testing_plan.md)
