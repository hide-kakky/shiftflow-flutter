# SHIFTFLOW Flutter Architecture

## 1. 全体像
- クライアント: Flutter（iOS/Android/Web）
- BFF/API: Supabase Edge Function `api`
- 認証: Supabase Auth（Magic Link）
- DB: Supabase Postgres（RLS有効）
- Storage: Supabase Storage（`profiles`, `attachments`）

## 2. レイヤー構成
1. Presentation
- 画面: `Auth`, `Home`, `Tasks`, `Messages`, `Settings`, `Admin`
- `go_router` で遷移、ログイン状態でガード

2. Application
- Riverpod Provider/Controller で画面状態を管理
- 画面ごとのユースケースを関数化

3. Data
- `ApiClient` が `supabase.functions.invoke('api')` を実行
- `RouteDataRepository` が route名を隠蔽しUIへDTOを返す

4. Backend
- `supabase/functions/api/index.ts` が routeディスパッチ
- DBアクセスは service role client で実行、アプリ権限は明示的に検証

## 3. ディレクトリ設計
```text
lib/
  core/
    api/
    config/
    providers/
  features/
    auth/
    home/
    tasks/
    messages/
    settings/
    admin/
    shared/
  l10n/
supabase/
  migrations/
  functions/
  tests/
```

## 4. 認証・認可フロー
1. ユーザーがメールアドレス入力
2. Supabase AuthがMagic Link送信
3. セッション作成後、アプリは `users` と `memberships` からアクセス文脈を解決
4. route実行前に `role/status/org` を検証

## 5. ルーティング
- `/auth`
- `/home`
- `/tasks`
- `/messages`
- `/settings`
- `/admin`

未ログイン時は `/auth` にリダイレクト。
ログイン後の主要画面は `ShellRoute` 配下で保持し、下部メニューが画面遷移アニメーションに巻き込まれない構成とする。

## 6. 例外処理方針
- APIは `{ ok, code, reason, result }` 形式を返す。
- Flutter側は `ApiException` に集約し、UIに簡潔なエラー表示を行う。
- 監査対象操作は `audit_logs` に記録する。

## 7. i18n
- ARB: `lib/l10n/app_ja.arb`, `lib/l10n/app_en.arb`
- 生成: `flutter gen-l10n`
- 言語設定はローカル保存 + `saveUserSettings` でサーバ同期

## 8. PWA差分の扱い
- 現状差分は [SHIFTFLOW_pwa_gap_analysis_2026-03-26.md](./SHIFTFLOW_pwa_gap_analysis_2026-03-26.md) で管理する。
- 特に `Messages` の作成導線、`Tasks` の複数一覧、`Settings` のプロフィール画像は未完了として追跡する。

## 9. 関連文書
- [SHIFTFLOW_api_definition.md](./SHIFTFLOW_api_definition.md)
- [SHIFTFLOW_database_schema.md](./SHIFTFLOW_database_schema.md)
- [SHIFTFLOW_setup_guide.md](./SHIFTFLOW_setup_guide.md)
