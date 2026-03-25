# SHIFTFLOW API Definition

- 実装: `supabase/functions/api/index.ts`
- 呼び出し方式: `POST /functions/v1/api` に `{ route, method?, args?, ... }`

## 1. 共通仕様
### Request
```json
{
  "route": "addNewTask",
  "args": [{ "title": "在庫確認" }]
}
```

### Response
```json
{
  "ok": true,
  "result": {}
}
```

### Error
```json
{
  "ok": false,
  "code": "forbidden",
  "reason": "forbidden"
}
```

## 2. ルート一覧
### Bootstrap
| route | 説明 | 権限 |
| --- | --- | --- |
| `getBootstrapData` | ダッシュボード初期情報取得 | admin/manager/member |
| `getHomeContent` | ホーム表示情報取得 | admin/manager/member |

### Tasks
| route | 説明 | 権限 |
| --- | --- | --- |
| `listMyTasks` | 自分向けタスク一覧 | admin/manager/member |
| `listCreatedTasks` | 自分が作成したタスク一覧 | admin/manager/member |
| `listAllTasks` | 組織内タスク一覧 | admin/manager |
| `getTaskById` | タスク詳細 | admin/manager/member |
| `addNewTask` | タスク作成 | admin/manager/member |
| `updateTask` | タスク更新 | admin/manager/member |
| `completeTask` | タスク完了 | admin/manager/member |
| `deleteTaskById` | タスク削除 | admin/manager/member |

### Messages
| route | 説明 | 権限 |
| --- | --- | --- |
| `getMessages` | メッセージ一覧（`folderId` 指定可） | admin/manager/member |
| `getMessageById` | メッセージ詳細+コメント | admin/manager/member |
| `addNewMessage` | メッセージ作成（現状 Flutter UI はタイトル/本文中心） | admin/manager/member |
| `deleteMessageById` | メッセージ削除 | admin/manager/member |
| `addNewComment` | コメント追加 | admin/manager/member |
| `toggleMemoRead` | 既読トグル | admin/manager/member |
| `markMemoAsRead` | 既読化 | admin/manager/member |
| `markMemosReadBulk` | 一括既読化 | admin/manager/member |
| `messages/:id/pin` | ピン留め切替 | admin/manager |
| `messages/:id/read_status` | 既読/未読ユーザー一覧 | admin/manager |

### Folders / Templates
| route | 説明 | 権限 |
| --- | --- | --- |
| `listActiveFolders` | 有効フォルダ一覧 | admin/manager/member |
| `folders` (GET) | フォルダ一覧 | admin/manager/member |
| `folders` (POST) | フォルダ作成 | admin/manager |
| `folders/:id` (PATCH) | フォルダ更新 | admin/manager |
| `folders/:id` (DELETE) | フォルダアーカイブ | admin/manager |
| `templates` (GET) | テンプレート一覧 | admin/manager/member |
| `templates` (POST) | テンプレート作成 | admin/manager |

### Settings / Admin
| route | 説明 | 権限 |
| --- | --- | --- |
| `getUserSettings` | ユーザー設定取得（`name`, `imageUrl`, `theme`, `language`, `role`, `email`） | admin/manager/member/guest |
| `saveUserSettings` | ユーザー設定保存（現状は `name`, `theme`, `language`） | admin/manager/member |
| `listActiveUsers` | 有効ユーザー一覧 | admin/manager |
| `adminListUsers` | ユーザー管理一覧 | admin/manager |
| `adminUpdateUser` | ユーザー更新 | admin/manager |
| `adminListOrganizations` | 組織一覧 | admin/manager |
| `adminGetOrganization` | 組織詳細 | admin/manager |
| `adminUpdateOrganization` | 組織更新 | admin/manager |
| `getAuditLogs` | 監査ログ取得 | admin/manager |

### Attachments
| route | 説明 | 権限 |
| --- | --- | --- |
| `downloadAttachment` | 添付署名URL取得 | admin/manager/member |

## 3. バリデーション方針
- `title` や `name` など必須値はrouteごとに明示チェック。
- 不正値は `400` + `code` を返す。
- 権限不足は `403` + `forbidden` を返す。

## 4. 通知連携
- `addNewMessage` 後: `new_message`
- `addNewTask` 後: `new_task_assigned`
- `notify_due_tasks` で: `task_due_tomorrow`

## 5. 関連文書
- [SHIFTFLOW_requirements_v1.0.md](./SHIFTFLOW_requirements_v1.0.md)
- [SHIFTFLOW_database_schema.md](./SHIFTFLOW_database_schema.md)
- [SHIFTFLOW_pwa_gap_analysis_2026-03-26.md](./SHIFTFLOW_pwa_gap_analysis_2026-03-26.md)
