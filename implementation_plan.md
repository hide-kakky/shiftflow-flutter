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

## 4. 検証手順
```bash
flutter pub get
flutter gen-l10n
flutter analyze
flutter test
supabase db reset --local --yes
supabase db lint --local --fail-on error
```

## 5. リスク
- Supabase Local が Docker依存のため、ローカル環境差異に注意。
