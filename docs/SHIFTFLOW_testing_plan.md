# SHIFTFLOW Testing Plan

## 1. テスト方針
- 目的: 機能同等性と権限制御を保証する。
- 範囲: DB/RLS, Edge Functions, Flutter Unit/Widget/Integration, 通知, クロスプラットフォーム。

## 2. テストレベル
### 2.1 DB/RLS
- ロール別アクセス検証（admin/manager/member/guest）
- 組織越境アクセス拒否
- `pending/suspended/revoked` の拒否

### 2.2 API/Edge Functions
- 正常系: 主要ルートで 200 + 想定データ
- 異常系: 権限不足, 不正パラメータ, 存在しないID
- 監査ログ記録の確認

### 2.3 Flutter
- Unit: Provider/Repository/DTO
- Widget: 画面遷移、フォーム入力、エラー表示
- Integration: ログイン〜主要業務導線

### 2.4 通知
- 新規メッセージ
- 担当タスク作成
- 期限前日通知
- 重複防止・失敗時ログ確認

### 2.5 クロスプラットフォーム
- iOS/Android/Web で同一CUJをスモーク実行

### 2.6 認証テスト運用（本番UI同等）
- ログイン画面には `Test Login` などテスト専用文言を常設しない。
- QA補助導線は Debug かつ `ENABLE_QA_TOOLS=true` の場合のみ有効にする。
- 検証は通常導線（メール入力 / Magic Link / パスワードログイン）で実施する。
- ロール切替はアプリUIを増やさず、`scripts/create_test_users.ts` で用意したアカウントを使って実施する。

## 3. 実行コマンド
```bash
flutter analyze
flutter test
supabase db reset --local --yes
supabase db lint --local --fail-on error
```

### 3.0 UI テスト起動（推奨）
```bash
./scripts/run_web_dev.sh
```

QA補助導線を有効化して確認する場合:

```bash
./scripts/run_web_qa.sh
```

### 3.1 認証テスト準備コマンド
```bash
set -a
source supabase/.env
set +a
deno run --allow-env --allow-net scripts/create_test_users.ts
```

### 3.2 DB Migration 適用（stateless）
```bash
./scripts/db_push.sh dev --dry-run
./scripts/db_push.sh dev
./scripts/db_push.sh prod --dry-run
./scripts/db_push.sh prod
```

`supabase/.env` が無い場合:

```bash
SUPABASE_URL=http://127.0.0.1:55421 \
SUPABASE_SERVICE_ROLE_KEY=<YOUR_SECRET_KEY> \
TEST_USER_PASSWORD=TestPass123! \
deno run --allow-env --allow-net scripts/create_test_users.ts
```

## 4. 完了基準
- CI がグリーン
- E2Eシナリオ全件完了
- 重要不具合（P1/P2）が未残存

## 5. テストケースリンク
- [SHIFTFLOW_e2e_scenarios.md](./SHIFTFLOW_e2e_scenarios.md)
- `supabase/tests/rls_access_matrix.sql`
- `supabase/tests/notification_dispatch_dedup.sql`
