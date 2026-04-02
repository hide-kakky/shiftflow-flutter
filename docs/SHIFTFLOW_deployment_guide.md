# SHIFTFLOW Deployment Guide

## 1. リリース前チェック
```bash
flutter pub get
flutter gen-l10n
flutter analyze
flutter test
supabase db reset --local --yes
supabase db lint --local --fail-on error
```

## 2. GitHub Actions
- ワークフロー: `.github/workflows/ci.yml`
- 実行内容
  - Flutter: `analyze`, `test`
  - Supabase: migration reset + lint

## 3. Supabase反映（本番）
1. 本番プロジェクトへログイン
2. マイグレーション適用
3. Edge Functions デプロイ

例:
```bash
supabase login
supabase link --project-ref <project-ref>
supabase db push
supabase functions deploy api
supabase functions deploy dispatch_notifications
supabase functions deploy notify_due_tasks
supabase functions deploy retry_failed_notifications
```

### 3-1. FCM secrets
通知配送には、Supabase Edge Functions に次の secrets が必要。

```bash
supabase secrets set \
  FCM_PROJECT_ID=<firebase-project-id> \
  FCM_CLIENT_EMAIL=<service-account-email> \
  FCM_PRIVATE_KEY="$(cat ./secrets/firebase-private-key.pem)"
```

`FCM_PRIVATE_KEY` は改行を含む PEM をそのまま渡してよい。CI でも同じ3つを secrets として管理する。

## 4. Flutter配布
### Web
```bash
flutter build web \
  --dart-define=SUPABASE_URL=<prod-url> \
  --dart-define=SUPABASE_ANON_KEY=<prod-anon-key> \
  --dart-define=FIREBASE_API_KEY=<firebase-api-key> \
  --dart-define=FIREBASE_PROJECT_ID=<firebase-project-id> \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=<firebase-sender-id>
```

### iOS
```bash
flutter build ipa \
  --dart-define=SUPABASE_URL=<prod-url> \
  --dart-define=SUPABASE_ANON_KEY=<prod-anon-key> \
  --dart-define=FIREBASE_API_KEY=<firebase-api-key> \
  --dart-define=FIREBASE_PROJECT_ID=<firebase-project-id> \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=<firebase-sender-id> \
  --dart-define=FIREBASE_IOS_APP_ID=<firebase-ios-app-id> \
  --dart-define=FIREBASE_IOS_BUNDLE_ID=<bundle-id>
```

### Android
```bash
flutter build appbundle \
  --dart-define=SUPABASE_URL=<prod-url> \
  --dart-define=SUPABASE_ANON_KEY=<prod-anon-key> \
  --dart-define=FIREBASE_API_KEY=<firebase-api-key> \
  --dart-define=FIREBASE_PROJECT_ID=<firebase-project-id> \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=<firebase-sender-id> \
  --dart-define=FIREBASE_ANDROID_APP_ID=<firebase-android-app-id>
```

## 5. ロールバック
- DB: ロールバック用の追補マイグレーションを作成（破壊的rollbackは避ける）
- アプリ: 直前タグへ戻して再リリース

## 6. 関連
- [SHIFTFLOW_operations_guide.md](./SHIFTFLOW_operations_guide.md)
- [SHIFTFLOW_testing_plan.md](./SHIFTFLOW_testing_plan.md)
