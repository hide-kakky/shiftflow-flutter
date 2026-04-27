# ShiftFlow Flutter 実装計画 v1.1

## 0. 運用参照順（必須）
1. `AGENTS.md`
2. `docs/ルール参照順.md`
3. `docs/開発フロー.md`

## 1. ゴール
1. v1.1 要件を Flutter + Supabase で実装可能な形へ落とす。
2. モバイル / PC で役割の異なる情報設計を成立させる。
3. 要件 -> API -> DB -> 実装 -> テストの追跡可能性を文書で維持する。

## 2. 現在地
- 基盤実装と旧導線ベースの主要画面は存在する。
- v1.1 の中核は以下まで反映済み:
  - `組織 -> ユニット -> フォルダ` の DB 増築
  - `currentOrganization` / `currentUnit` の bootstrap 返却
  - 参加申請 / 招待リンク / 承認待ちの API 基盤
  - 個人メッセージ分離の API / DB 基盤
  - モバイル段階表示 / PC分割表示の画面骨格
- ただし、以下はまだ仕上げ段階に未到達:
  - Auth / Participation の実機検証
  - 新しいモバイル/PC ナビと検索/DM直遷移の実機確認
  - `member` の権限境界が実機でも崩れないことの確認
  - Integration / E2E の追加
  - 運用文書への最終反映

## 3. 次の実装対象
1. Auth / Participation 導線の実機検証
2. 新しいナビ / 検索 / プロフィール / 個人チャットの実機検証
3. `member` の currentUnit / フォルダ / メッセージ権限境界の実機確認
4. Integration テスト追加
5. E2E / 運用文書の反映
6. Home / Participation の微調整
7. リリース準備の確認

## 4. 認証テスト運用の再設計方針（TASUKI 参考）
1. ログイン画面は「通常ユーザー向けUI」を維持し、`Test Login` のような文言を常設しない。
2. QA用の補助導線は本番ビルドで無効化する（例: `kDebugMode` + `--dart-define` フラグで有効化）。
3. テストユーザーは Supabase 側で管理し、アプリ側に固定パスワードやテスト専用表示を埋め込まない。
4. 検証は「実運用と同じ操作」で行う（メール入力・パスワード送信・通常遷移）。
5. `TASUKI` 同様、ローカル環境で複数ロールのテストアカウントを再生成できるスクリプトを用意する。

## 5. 認証テスト運用タスク（完了済み）
1. `lib/core/config` の `AppFlavor` / `enableQaTools` で、ビルド時に QA 機能の有効/無効を制御可能にした。
2. Auth画面は通常UIを維持しつつ、開発時のみ到達可能な QA 補助導線（長押し）を実装した。
3. QA 導線は「アカウント候補入力補助」のみに限定し、一般向け文言に統一した。
4. `scripts/create_test_users.ts` と `docs/セットアップガイド.md` を整備した。
5. `docs/テスト計画.md` に「本番UI同等テスト」を追加した。

## 6. 検証手順
```bash
flutter pub get
flutter gen-l10n
flutter analyze
flutter test
/bin/zsh -lc "SUPABASE_URL=http://127.0.0.1:55421 SUPABASE_ANON_KEY=... TEST_USER_PASSWORD='TestPass123!' deno run --allow-env --allow-net scripts/verify_v11_routes.ts"
/bin/zsh -lc "SUPABASE_URL=http://127.0.0.1:55421 SUPABASE_ANON_KEY=... SUPABASE_SERVICE_ROLE_KEY=... SHIFTFLOW_ORGANIZATION_ID=11111111-1111-1111-1111-111111111111 TEST_USER_PASSWORD='TestPass123!' deno run --allow-env --allow-net scripts/verify_v11_access.ts"
supabase db reset --local --yes
supabase db lint --local --fail-on error
```

## 7. リスク
- Supabase Local が Docker依存のため、ローカル環境差異に注意。
