# ShiftFlow Flutter 実装計画

## 1. ゴール
1. ShiftFlow_PWA の業務機能を Flutter + Supabase で同等提供する。
2. iOS/Android/Web で同一ユースケースを成立させる。
3. 要件->設計->実装->テストの追跡可能性を文書で維持する。

## 2. 直近の実装完了
- Flutter骨格（Auth/Home/Tasks/Messages/Settings/Admin）
- APIクライアント層と route repository
- Supabase 初期マイグレーション + RLS + Storage policy
- Edge Function `api` と通知系Functions
- docs一式 + CI定義 + DBテスト雛形
- GitHub Public repository: `https://github.com/hide-kakky/shiftflow-flutter`
- Tasks 作成UIの拡張（優先度・期限・担当者選択）と API `addNewTask` の priority 保存対応
- Tasks 添付ファイル対応（Storageアップロード・`attachments`/`task_attachments` 紐付け・一覧表示）
- Messages 詳細UIの拡張（コメント一覧/追加・ピン切替・既読/未読ユーザー表示）
- Admin 画面の操作導線拡張（Users更新/Organizations更新/Audit再読込）
- Folders/Templates 管理導線の拡張（フォルダ作成・更新・アーカイブ、テンプレート作成）
- Supabase 環境分離（dev/prod）と stateless migration 運用（`scripts/db_push.sh`）を整備
- 基本UI導線のWidgetテスト追加（Auth/Home/Messages/Settings/Admin）
- Settings の表示名編集
- 画面遷移時にメニューバーを固定する ShellRoute 化
- `ShiftFlow_PWA` 再精査と差分整理（`docs/SHIFTFLOW_pwa_gap_analysis_2026-03-26.md`）

## 3. 次の実装対象
1. Messages 作成導線の PWA 差分回収（フォルダ/テンプレート/添付）
2. Tasks 一覧の `My / Created / All` 切替
3. Settings のプロフィール画像対応
4. Auth導線の実機検証（admin/manager/member のロール別確認）
5. `docs/SHIFTFLOW_e2e_scenarios.md` の実施結果記録
6. Widgetテストを補完する Integrationテストの追加（主要CUJ）

## 4. 認証テスト運用の再設計方針（TASUKI 参考）
1. ログイン画面は「通常ユーザー向けUI」を維持し、`Test Login` のような文言を常設しない。
2. QA用の補助導線は本番ビルドで無効化する（例: `kDebugMode` + `--dart-define` フラグで有効化）。
3. テストユーザーは Supabase 側で管理し、アプリ側に固定パスワードやテスト専用表示を埋め込まない。
4. 検証は「実運用と同じ操作」で行う（メール入力・Magic Link / Password 送信・通常遷移）。
5. `TASUKI` 同様、ローカル環境で複数ロールのテストアカウントを再生成できるスクリプトを用意する。

## 5. 認証テスト運用タスク（完了済み）
1. `lib/core/config` の `AppFlavor` / `enableQaTools` で、ビルド時に QA 機能の有効/無効を制御可能にした。
2. Auth画面は通常UIを維持しつつ、開発時のみ到達可能な QA 補助導線（長押し）を実装した。
3. QA 導線は「アカウント候補入力補助」のみに限定し、一般向け文言に統一した。
4. `scripts/create_test_users.ts` と `docs/SHIFTFLOW_setup_guide.md` を整備した。
5. `docs/SHIFTFLOW_testing_plan.md` に「本番UI同等テスト」を追加した。

## 6. 検証手順
```bash
flutter pub get
flutter gen-l10n
flutter analyze
flutter test
supabase db reset --local --yes
supabase db lint --local --fail-on error
```

## 7. リスク
- Supabase Local が Docker依存のため、ローカル環境差異に注意。
