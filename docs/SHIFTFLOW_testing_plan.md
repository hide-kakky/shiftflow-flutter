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

## 3. 実行コマンド
```bash
flutter analyze
flutter test
supabase db reset --local --yes
supabase db lint --local --fail-on error
```

## 4. 完了基準
- CI がグリーン
- E2Eシナリオ全件完了
- 重要不具合（P1/P2）が未残存

## 5. テストケースリンク
- [SHIFTFLOW_e2e_scenarios.md](./SHIFTFLOW_e2e_scenarios.md)
- `supabase/tests/rls_access_matrix.sql`
- `supabase/tests/notification_dispatch_dedup.sql`
