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

## 3. 次の実装対象
1. Tasks画面の添付ファイル対応（Storageアップロード・task_attachments 紐付け）
2. Messages画面の既読一覧・コメント詳細・ピン操作
3. Admin画面のユーザー状態更新・組織設定更新
4. 認証テスト運用の再設計（本番投入可能なUI維持）

## 4. 認証テスト運用の再設計方針（TASUKI 参考）
1. ログイン画面は「通常ユーザー向けUI」を維持し、`Test Login` のような文言を常設しない。
2. QA用の補助導線は本番ビルドで無効化する（例: `kDebugMode` + `--dart-define` フラグで有効化）。
3. テストユーザーは Supabase 側で管理し、アプリ側に固定パスワードやテスト専用表示を埋め込まない。
4. 検証は「実運用と同じ操作」で行う（メール入力・Magic Link / Password 送信・通常遷移）。
5. `TASUKI` 同様、ローカル環境で複数ロールのテストアカウントを再生成できるスクリプトを用意する。

## 5. 認証テスト運用タスク（追加）
1. `lib/core/config` に `AppFlavor` / `enableQaTools` 設定を追加し、ビルド時に QA 機能の有効/無効を制御する。
2. Auth画面には露出せず、開発時のみ到達できる QA 導線（例: 長押しで開く hidden panel）を実装する。
3. QA 導線は「アカウント候補入力補助」までに留め、UI文言は一般向けに統一する。
4. `scripts/` に test users 作成/更新スクリプトを追加し、`docs/SHIFTFLOW_setup_guide.md` に手順を追記する。
5. `docs/SHIFTFLOW_testing_plan.md` に「本番UI同等テスト」の観点を追加する。

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
