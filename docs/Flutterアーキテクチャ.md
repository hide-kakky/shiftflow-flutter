# SHIFTFLOW Flutter Architecture v1.1

## 1. 全体像
- クライアント: Flutter（iOS/Android/Web）
- BFF/API: Supabase Edge Function `api`
- 認証: Supabase Auth（Password。Magic Link は履歴扱い）
- DB: Supabase Postgres（RLS有効）
- Storage: Supabase Storage（`profiles`, `attachments`）

## 2. アプリシェル
- 認証状態と参加状態を分離して扱う。
- 主な状態:
  - 未認証
  - 認証済み未参加
  - 参加申請中
  - active
  - suspended
  - revoked
- `active` のみ主要業務シェルへ遷移する。
- `未参加 / 申請中 / suspended / revoked` は状態別案内画面へ遷移する。

## 3. グローバル文脈
- `currentOrganization`
- `currentUnit`
- `organizationState`
- `availableOrganizations`
- `availableUnits`
- `navigationCapabilities`
- `badgeCounts`

これらは bootstrap 取得後にグローバル Provider へ保持する。

## 4. レイヤー構成
1. Presentation
- 画面:
  - Auth / Participation
  - Home
  - Tasks
  - Messages
  - Settings
  - Admin
- モバイルと PC でレイアウトを分岐する

2. Application
- Riverpod Provider/Controller で状態管理
- `currentOrganization` / `currentUnit` の切替をアプリ横断で扱う
- DM と共有メッセージは状態を分離する

3. Data
- `ApiClient` が `supabase.functions.invoke('api')` を実行
- Repository は route 名を隠蔽し DTO を返す

4. Backend
- route ディスパッチ
- DBアクセス
- 文脈検証
- RLS / 権限検証

## 5. 画面責務
### Home
- モバイル:
  - すぐ確認すべき実データを少数表示
- PC:
  - 俯瞰/比較/補助情報を同時表示

### Messages
- `currentUnit` を前提に表示する
- タブ:
  - 全て
  - 個人
  - 主要フォルダ
  - 上位ユニット
  - 下位ユニット

### Admin
- モバイル:
  - 段階表示
- PC:
  - 分割表示

## 6. ルーティング
- `/auth`
- `/participation`
- `/home`
- `/tasks`
- `/messages`
- `/settings`
- `/admin`

未ログイン時は `/auth`。
認証済みだが未参加/申請中などは `/participation`。
主要画面は `ShellRoute` 配下で保持し、モバイルでは下部ナビ + 中央 FAB を維持する。

## 7. レイアウト分岐ポイント
- Home
- Messages
- Admin
- 一覧 + 詳細の分割表示が必要な画面

モバイルでは段階表示、PCでは一覧/詳細/補助情報の分割表示を基本とする。

## 8. 例外処理
- API は `{ ok, code, reason, result }`
- UI は `ApiException` に集約する
- 状態別表示:
  - 0件
  - 通信失敗
  - 権限不足
  - 承認待ち
  - suspended / revoked

## 9. i18n
- ARB: `lib/l10n/app_ja.arb`, `lib/l10n/app_en.arb`
- 生成: `flutter gen-l10n`
- 言語設定はローカル保存 + `saveUserSettings` でサーバ同期

## 10. 関連文書
- [要件定義_v1.1_草案.md](./要件定義_v1.1_草案.md)
- [API定義.md](./API定義.md)
- [データベーススキーマ.md](./データベーススキーマ.md)
