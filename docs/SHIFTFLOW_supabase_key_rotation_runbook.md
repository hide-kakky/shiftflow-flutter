# SHIFTFLOW Supabase Key Rotation Runbook

最終更新: 2026-03-24

## 1. 目的
- APIキー漏えい時に、被害拡大を止める。
- 開発/QA/本番の起動設定を安全に更新する。

## 2. まず最初にやること（5分以内）
1. 漏えいしたキーを **再利用しない**。
2. Supabase Dashboard でキーをローテーションする。
3. ローカル `env/*.json` と CI Secrets を新しいキーで更新する。
4. 旧キーを無効化（revoke）する。

## 3. ローテーション対象
- `Publishable key`（アプリで利用）
- `Secret key` / `service_role key`（サーバー・運用スクリプトで利用）
- 必要に応じて JWT Signing Keys

## 4. 実施手順（推奨順）
1. Supabase Dashboard にログイン
2. 対象プロジェクトを開く
3. Project Settings の API / JWT Keys で新しいキーを発行（Rotate）
4. 旧キーが有効なままなら Revoke して無効化
5. 下記を更新
   - ローカル: `env/dev.json`, `env/qa.json`, `env/android.json`
   - CI/CD: GitHub Actions Secrets
   - Supabase Functions 環境変数（`SUPABASE_SERVICE_ROLE_KEY` など）
6. `flutter run` / テスト / CI で疎通確認

## 5. ローカル更新コマンド例
```bash
cd /Users/hide_kakky/Dev/shiftflow_flutter

# 1) 既存ローカル設定をバックアップ（任意）
cp env/dev.json env/dev.json.bak.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true
cp env/qa.json env/qa.json.bak.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true
cp env/android.json env/android.json.bak.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true

# 2) テンプレートから作成（未作成時）
cp -n env/dev.json.example env/dev.json
cp -n env/qa.json.example env/qa.json
cp -n env/android.json.example env/android.json

# 3) 新しい Publishable key を手動で貼り付け
#    (dev.json / qa.json / android.json の SUPABASE_ANON_KEY)
```

## 6. 動作確認
```bash
./scripts/run_web_dev.sh
flutter analyze
flutter test
```

## 7. 漏えい確認（リポジトリ）
```bash
cd /Users/hide_kakky/Dev/shiftflow_flutter
rg -n "sb_secret_|service_role|SUPABASE_SERVICE_ROLE_KEY" -S . \
  --glob '!build' --glob '!.dart_tool' --glob '!**/node_modules/**'
```

## 8. 事故後の追加対応
- 監査ログ（Auth/API）を確認して不審アクセス有無を点検。
- 必要なら DB パスワードや外部連携トークンも連鎖ローテーション。
- チームへ「旧キー無効化済み / 新キー反映期限」を共有。

## 9. 参考
- Supabase公式: Rotating Anon, Service, and JWT Secrets
  - https://supabase.com/docs/guides/troubleshooting/rotating-anon-service-and-jwt-secrets-1Jq6yd
