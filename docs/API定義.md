# SHIFTFLOW API Definition v1.1

- 実装: `supabase/functions/api/index.ts`
- 呼び出し方式: `POST /functions/v1/api` に `{ route, method?, args?, ... }`

## 1. 共通仕様
### Request
```json
{
  "route": "getBootstrapData",
  "args": [{ "organizationId": "uuid", "currentUnitId": "uuid" }]
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

## 2. route 設計方針
- route 方式は暫定維持する。
- すべての業務 route は `organizationId` または解決可能な組織文脈を前提とする。
- メッセージ系 route は `currentUnitId` と `messageScope` を扱える形へ拡張する。
- 参加導線系 route は未参加/承認待ち状態でも利用できる。

## 3. route 一覧
### Bootstrap
| route | 説明 | 権限 |
| --- | --- | --- |
| `getBootstrapData` | 現在ユーザー状態、利用可能組織、現在の組織、現在のユニット、ロール、参加状態、利用可能ナビ、未読/未完了件数を返す | 認証済み |
| `getHomeContent` | ホーム表示情報取得。モバイル/PCで block 単位の返却を切り替える | active user |
| `changeCurrentUnit` | 現在地ユニット変更 | active user |

### Participation
| route | 説明 | 権限 |
| --- | --- | --- |
| `searchOrganizationsByCode` | 組織コード検索 | 認証済み |
| `requestOrganizationJoin` | 組織参加申請 | 未参加 |
| `listJoinRequests` | 参加申請一覧 | owner/admin |
| `approveJoinRequest` | 参加申請承認 | owner/admin |
| `rejectJoinRequest` | 参加申請拒否 | owner/admin |
| `createOrganizationInvite` | 招待リンク発行 | owner/admin |
| `acceptOrganizationInvite` | 招待リンク受諾 | 認証済み |

### Units
| route | 説明 | 権限 |
| --- | --- | --- |
| `listUnits` | 組織内ユニット一覧・階層取得 | active user |
| `createUnit` | ユニット作成 | owner/admin/unit manager |
| `updateUnit` | ユニット更新 | owner/admin/unit manager |
| `assignUnitMember` | ユニット所属/ロール設定 | owner/admin/unit manager |

### Tasks
| route | 説明 | 権限 |
| --- | --- | --- |
| `listMyTasks` | 自分向けタスク一覧 | active user |
| `listCreatedTasks` | 自分が作成したタスク一覧 | active user |
| `listAllTasks` | 閲覧可能な全タスク一覧 | active user |
| `getTaskById` | タスク詳細 | active user |
| `addNewTask` | タスク作成。`unitId` を必須で扱う | active user |
| `updateTask` | タスク更新 | active user |
| `completeTask` | タスク完了 | active user |
| `deleteTaskById` | タスク削除 | active user |

### Messages
| route | 説明 | 権限 |
| --- | --- | --- |
| `getMessages` | メッセージ一覧。`currentUnitId`, `tab`, `folderId`, `scope`, `unreadOnly`, `keyword` を扱う | active user |
| `getMessageById` | メッセージ詳細 + コメント | active user |
| `addNewMessage` | メッセージ作成。`scope`, `unitId`, `folderId`, `recipientUserIds` を扱う | active user |
| `deleteMessageById` | メッセージ削除 | active user |
| `addNewComment` | コメント追加 | active user |
| `toggleMemoRead` | 既読トグル | active user |
| `markMemoAsRead` | 既読化 | active user |
| `markMemosReadBulk` | 一括既読化 | active user |
| `messages/:id/pin` | ピン留め切替 | active user |
| `messages/:id/read_status` | 既読/未読一覧 | 管理権限者または投稿権限者 |

### Folders / Templates
| route | 説明 | 権限 |
| --- | --- | --- |
| `listActiveFolders` | 現在の組織/ユニット文脈で利用可能なフォルダ一覧 | active user |
| `folders` (GET) | フォルダ一覧 | active user |
| `folders` (POST) | フォルダ作成。`unitId` を必須で扱う | owner/admin/unit manager |
| `folders/:id` (PATCH) | フォルダ更新 | owner/admin/unit manager |
| `folders/:id` (DELETE) | フォルダアーカイブ | owner/admin/unit manager |
| `templates` (GET) | テンプレート一覧 | active user |
| `templates` (POST) | テンプレート作成 | owner/admin/unit manager |
| `templates/:id` (PATCH) | テンプレート更新 | owner/admin/unit manager |
| `templates/:id` (DELETE) | テンプレート削除 | owner/admin/unit manager |

### Settings / Admin
| route | 説明 | 権限 |
| --- | --- | --- |
| `getUserSettings` | ユーザー設定取得（`name`, `imageUrl`, `language`, `email`, `organizationState`） | 認証済み |
| `saveUserSettings` | ユーザー設定保存（`name`, `imageUrl`, `language`） | 認証済み |
| `listActiveUsers` | 組織内有効ユーザー一覧 | owner/admin |
| `adminListUsers` | ユーザー管理一覧。`organizationId` 必須 | owner/admin |
| `adminUpdateUser` | ユーザー状態/権限更新。`organizationId` 必須 | owner/admin |
| `adminListOrganizations` | 利用可能組織一覧 | owner/admin |
| `adminGetOrganization` | 組織詳細 | owner/admin |
| `adminUpdateOrganization` | 組織更新 | owner/admin |
| `getAuditLogs` | 監査ログ取得。`organizationId` 必須、必要に応じて `unitId` も扱う | owner/admin |

### Attachments
| route | 説明 | 権限 |
| --- | --- | --- |
| `downloadAttachment` | 添付署名URL取得。共有メッセージ/個人メッセージ/タスク文脈を検証して返す | active user |

## 4. バリデーション方針
- 必須項目は route ごとに明示チェックする。
- `organizationId`, `unitId`, `folderId`, `messageId`, `taskId` などの文脈IDはサーバー側でも検証する。
- 不正値は `400` + `code` を返す。
- 権限不足は `403` + `forbidden` を返す。
- 参加前や承認待ちは `403` または専用 code で返し、UIで状態別案内へ分岐する。

## 5. 通知連携
- `addNewMessage` 後: `new_message`
- 個人メッセージ作成後: `new_direct_message`
- `addNewTask` 後: `new_task_assigned`
- 参加申請承認後: `join_request_approved`
- 招待受諾後: `invite_accepted`
- `notify_due_tasks` で: `task_due_tomorrow`

## 6. 関連文書
- [要件定義_v1.1_草案.md](./要件定義_v1.1_草案.md)
- [データベーススキーマ.md](./データベーススキーマ.md)
- [Flutterアーキテクチャ.md](./Flutterアーキテクチャ.md)
