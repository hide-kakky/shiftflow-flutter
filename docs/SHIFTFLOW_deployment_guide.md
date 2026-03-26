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

## 4. Flutter配布
### Web
```bash
flutter build web \
  --dart-define=SUPABASE_URL=<prod-url> \
  --dart-define=SUPABASE_ANON_KEY=<prod-anon-key>
```

### iOS
```bash
flutter build ipa \
  --dart-define=SUPABASE_URL=<prod-url> \
  --dart-define=SUPABASE_ANON_KEY=<prod-anon-key>
```

### Android
```bash
flutter build appbundle \
  --dart-define=SUPABASE_URL=<prod-url> \
  --dart-define=SUPABASE_ANON_KEY=<prod-anon-key>
```

## 5. ロールバック
- DB: ロールバック用の追補マイグレーションを作成（破壊的rollbackは避ける）
- アプリ: 直前タグへ戻して再リリース

## 6. 関連
- [SHIFTFLOW_operations_guide.md](./SHIFTFLOW_operations_guide.md)
- [SHIFTFLOW_testing_plan.md](./SHIFTFLOW_testing_plan.md)
