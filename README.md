# ShiftFlow Flutter

ShiftFlow PWA を Flutter + Supabase に移行するための統合リポジトリです。

GitHub: `https://github.com/hide-kakky/shiftflow-flutter`

## 構成
- Flutter アプリ: `lib/`（iOS/Android/Web 共通）
- Supabase: `supabase/`（migrations/functions/seed/tests）
- 進行管理: `plan.md`, `task.md`, `implementation_plan.md`
- 実装文書: `docs/`

## クイックスタート
```bash
cd /Users/hide_kakky/Dev/shiftflow_flutter
flutter pub get
flutter gen-l10n
supabase start
supabase db reset --local --yes
cp env/dev.json.example env/dev.json
# env/dev.json の SUPABASE_ANON_KEY を自分の値に更新
./scripts/run_web_dev.sh
```

## 主な設計ドキュメント
- [要件定義](./docs/SHIFTFLOW_requirements_v1.0.md)
- [実装ガイド](./docs/SHIFTFLOW_implementation_guide_v1.0.md)
- [Flutterアーキテクチャ](./docs/SHIFTFLOW_flutter_architecture.md)
- [API定義](./docs/SHIFTFLOW_api_definition.md)
- [DBスキーマ](./docs/SHIFTFLOW_database_schema.md)
- [テスト計画](./docs/SHIFTFLOW_testing_plan.md)

## Git運用ルール
- `main` 直コミット禁止
- 機能単位で feature ブランチを作成
- CI（Flutter + Supabase）グリーンを確認して PR マージ
