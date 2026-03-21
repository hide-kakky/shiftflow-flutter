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
`SUPABASE_URL` と `SUPABASE_ANON_KEY` は `--dart-define` で渡す。

### Web
```bash
flutter run -d chrome \
  --dart-define=SUPABASE_URL=http://127.0.0.1:55421 \
  --dart-define=SUPABASE_ANON_KEY=<YOUR_ANON_KEY>
```

### iOS
```bash
flutter run -d ios \
  --dart-define=SUPABASE_URL=http://127.0.0.1:55421 \
  --dart-define=SUPABASE_ANON_KEY=<YOUR_ANON_KEY>
```

### Android
```bash
flutter run -d android \
  --dart-define=SUPABASE_URL=http://10.0.2.2:55421 \
  --dart-define=SUPABASE_ANON_KEY=<YOUR_ANON_KEY>
```

## 5. Magic Link テスト
1. `Auth` 画面でメールアドレスを入力。
2. Supabase Local Inbucket（通常 `http://127.0.0.1:55424`）でメールを確認。
3. Magic Link を開き、アプリへ戻る。

## 6. よくあるエラー
- `SUPABASE_URL and SUPABASE_ANON_KEY are required`
  - `--dart-define` の未指定。
- `docker is not running`
  - Docker Desktop を起動してから `supabase start`。
- `route_not_implemented`
  - `route` 名の誤字、または未実装。

## 7. 関連
- [SHIFTFLOW_testing_plan.md](./SHIFTFLOW_testing_plan.md)
- [SHIFTFLOW_deployment_guide.md](./SHIFTFLOW_deployment_guide.md)
