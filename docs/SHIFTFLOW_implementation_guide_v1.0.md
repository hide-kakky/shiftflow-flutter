# SHIFTFLOW Implementation Guide v1.0

- 作成日: 2026-03-21
- 対象: Flutter + Supabase フル移行

## 1. 方針
- `ShiftFlow_PWA` の業務ルート・ロール設計・データモデルを維持する。
- UIはFlutterで最適化するが、機能同等を最優先する。
- バックエンドはSupabaseに一本化し、Cloudflare/GAS依存は持たない。

## 2. 開発プロセス（TASUKI準拠）
1. `plan.md` にフェーズと次アクションを更新。
2. `task.md` にタスク状態（未着手/進行中/完了）を更新。
3. 実装前後で `implementation_plan.md` を更新。
4. 仕様変更は `docs/` の該当文書を先に更新。

## 3. Git運用
- `main` 直コミット禁止。
- ブランチ命名: `feat/*`, `fix/*`, `chore/*`, `docs/*`。
- コミットメッセージは日本語で記述する。
- ルール参照順は `AGENTS.md` -> `docs/SHIFTFLOW_rule_reference.md` -> `docs/SHIFTFLOW_development_flow.md`。
- 1タスク1PRを原則とする。
- PRには以下を必ず記載する。
  - 背景
  - 変更内容
  - 検証結果
  - 影響範囲

## 4. 実装順序
### Phase 1: 基盤
- Flutter プロジェクトと基本依存の整備。
- Supabaseスキーマ・RLS・Storage・Edge Functions雛形。
- 主要文書、CI、最低限テスト基盤。

### Phase 2: 機能同等化
- Auth（Magic Link）
- Tasks / Messages / Folders / Templates
- Settings（theme/language/profile）
- Admin（users/orgs/audit）

### Phase 2.5: PWA差分の回収
- `docs/SHIFTFLOW_pwa_gap_analysis_2026-03-26.md` を起点に不足機能を埋める。
- 優先度は `Messages 作成導線 -> Tasks 複数一覧 -> Settings プロフィール画像` とする。
- 「理想要件」だけでなく「現在の実装状態」も同時に文書更新する。

### Phase 3: 品質強化
- 通知3トリガーの安定化。
- RLS/API/Widget/Integrationテスト拡充。
- 運用手順と障害対応手順の固化。

## 5. 実装規約
- Flutter
  - 状態管理: Riverpod
  - ルーティング: go_router
  - i18n: `intl` + ARB
- API
  - `ApiClient(route,args,extra)` でEdge Function `api` に統一アクセス
  - すべての業務操作は `route` 契約に従う
- DB
  - すべての業務テーブルで `organization_id` を保持
  - RLSは「自組織のみ + ロール制御」

## 6. DoD（Definition of Done）
- コード: `flutter analyze` / `flutter test` 成功
- DB: `supabase db reset --local` / `supabase db lint --local` 成功
- 文書: 要件・設計・テスト・運用文書のリンク整合性が取れている
- CI: GitHub Actionsで上記チェックが再現できる

## 7. 関連文書
- [SHIFTFLOW_requirements_v1.0.md](./SHIFTFLOW_requirements_v1.0.md)
- [SHIFTFLOW_flutter_architecture.md](./SHIFTFLOW_flutter_architecture.md)
- [SHIFTFLOW_testing_plan.md](./SHIFTFLOW_testing_plan.md)
- [SHIFTFLOW_pwa_gap_analysis_2026-03-26.md](./SHIFTFLOW_pwa_gap_analysis_2026-03-26.md)
- [SHIFTFLOW_rule_reference.md](./SHIFTFLOW_rule_reference.md)
- [NEXT_SESSION_CHECKLIST.md](./NEXT_SESSION_CHECKLIST.md)
