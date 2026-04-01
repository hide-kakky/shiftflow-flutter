# SHIFTFLOW Setup Guide

## 1. 前提
- macOS / Linux
- Flutter SDK（stable）
- Supabase CLI
- Docker Desktop（Supabase Local 用）
- Xcode（iOSビルド時）
- Android Studio + SDK（Androidビルド時）

## 2. 初期セットアップ
```bash
cd /Users/hide_kakky/Dev/shiftflow_flutter
flutter pub get
flutter gen-l10n
```

## 3. Supabase Local 起動
```bash
supabase start
supabase db reset --local --yes
supabase db lint --local --fail-on error
```

## 4. Flutter 実行
`SUPABASE_URL` と `SUPABASE_ANON_KEY` は `--dart-define` / `--dart-define-from-file` で渡す。
毎回の手入力を避けるため、`env/*.json` を使う手順を推奨する。

### 4-1. 一度だけ設定ファイルを作る
```bash
cp env/dev.json.example env/dev.json
cp env/qa.json env/qa.local.json
cp env/qa.cloud.json.example env/qa.cloud.json
cp env/android.json.example env/android.json
```

`env/dev.json` / `env/qa.local.json` / `env/qa.cloud.json` の `SUPABASE_ANON_KEY` を、自分の環境の値に置き換える。

> `env/*.json` は `.gitignore` 済みで、リポジトリには含まれない。

### 4-2. スクリプトで起動（推奨）

### Web（通常）
```bash
./scripts/run_web_dev.sh
```

### Web（QA補助導線 + ローカルSupabase）
```bash
./scripts/run_web_qa_local.sh
```

### Web（QA補助導線 + クラウドSupabase）
```bash
./scripts/run_web_qa_cloud.sh
```

### Web
```bash
flutter run -d chrome --dart-define-from-file=env/dev.json
```

### Web（QA補助導線を有効化 / ローカル）
```bash
flutter run -d chrome --dart-define-from-file=env/qa.local.json
```

### Web（QA補助導線を有効化 / クラウド）
```bash
flutter run -d chrome --dart-define-from-file=env/qa.cloud.json
```

### iOS
```bash
flutter run -d ios \
  --dart-define-from-file=env/dev.json
```

### Android
```bash
flutter run -d android --dart-define-from-file=env/android.json
```

### 4-3. iOS 実機差分の退避/復元（`!?` 対策）
iOS 実機起動後は、`ios/` 配下にローカル差分が出ることがある。  
`main` をクリーンに保つため、次のスクリプトを使う。

```bash
# 退避（!? を消す）
./scripts/ios_local_store.sh

# 状態確認
./scripts/ios_local_status.sh

# 実機検証前に戻す（popではなくapply）
./scripts/ios_local_apply.sh
```

- `ios_local_store.sh`: iOS差分4ファイルのみを `stash push -u` で退避
- `ios_local_apply.sh`: `ios-local-build-files` の最新stashを `apply`（stashは保持）
- `ios_local_status.sh`: `git status` と iOS用stash一覧を表示

> 新ブランチ作成前の必須手順:
> `./scripts/ios_local_status.sh` を実行し、`!?` が出ていたら `./scripts/ios_local_store.sh` を実行してから `git switch -c <branch>` する。

## 5. Magic Link テスト
1. `Auth` 画面でメールアドレスを入力。
2. Supabase Local Inbucket（通常 `http://127.0.0.1:55424`）でメールを確認。
3. Magic Link を開き、アプリへ戻る。

## 6. テストユーザー作成（パスワードログイン検証用）
```bash
set -a
source supabase/.env
set +a
deno run --allow-env --allow-net scripts/create_test_users.ts
```

`supabase/.env` が無い場合は、`supabase start` の表示値をそのまま指定する。

```bash
SUPABASE_URL=http://127.0.0.1:55421 \
SUPABASE_SERVICE_ROLE_KEY=<YOUR_SECRET_KEY> \
TEST_USER_PASSWORD=TestPass123! \
deno run --allow-env --allow-net scripts/create_test_users.ts
```

- 既定ユーザー: `admin@shiftflow.local` / `manager@shiftflow.local` / `member@shiftflow.local`
- 既定パスワード: `TestPass123!`（`TEST_USER_PASSWORD` で変更可）
- QA補助導線はログイン説明文の長押しで開く（Debug + `ENABLE_QA_TOOLS=true` のときのみ）

## 7. よくあるエラー
- `SUPABASE_URL and SUPABASE_ANON_KEY are required`
  - `--dart-define` / `--dart-define-from-file` の未指定。
- `docker is not running`
  - Docker Desktop を起動してから `supabase start`。
- `route_not_implemented`
  - `route` 名の誤字、または未実装。
- `Failed to fetch ... /functions/v1/api`
  - 接続先の Supabase URL が想定と不一致、または対象環境へ `api` 関数が未デプロイ。
- `deno: command not found`
  - Deno をインストールしてから再実行。
- iPhone の通知設定に ShiftFlow が出ない
  - 通知許可ダイアログが未実行。アプリ初回起動時に表示されるので「許可」する。
  - 既に拒否済みの場合は `設定 > 通知 > ShiftFlow` で手動で許可する。

## 8. 関連
- [SHIFTFLOW_rule_reference.md](./SHIFTFLOW_rule_reference.md)
- [SHIFTFLOW_testing_plan.md](./SHIFTFLOW_testing_plan.md)
- [SHIFTFLOW_deployment_guide.md](./SHIFTFLOW_deployment_guide.md)
- [SHIFTFLOW_codex_supabase_mcp_troubleshooting.md](./SHIFTFLOW_codex_supabase_mcp_troubleshooting.md)
- [SHIFTFLOW_development_flow.md](./SHIFTFLOW_development_flow.md)
- `scripts/db_push.sh`（`--db-url` ベースの stateless migration 実行）
