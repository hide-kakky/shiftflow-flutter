# NEXT SESSION BRIEF

## 現在の状態（2026-04-21 時点）
- リポジトリ: `https://github.com/hide-kakky/shiftflow-flutter`
- 現在ブランチ: `chore/continue-development`
- 状態:
  - 基本機能の未接続 UI を一通り実装済み
  - `flutter analyze` / `flutter test` は通過済み
  - 実機起動は iPhone へのインストールまでは到達
  - ただしアプリ起動直後に `SUPABASE_URL` / `SUPABASE_ANON_KEY` 未指定で停止
- 補足:
  - `env/dev.json` は未作成
  - 実機向けに iOS ローカル差分が出ている
  - iOS ローカル差分は feature 実装コミットへ混ぜない運用を維持する

## 直近で完了したこと
- Tasks
  - タスク詳細シートを追加
  - タスク編集 / 削除 UI を追加
  - 添付をタップして開く導線を追加
- Messages
  - 複数選択と一括既読を追加
  - 詳細シートから削除できるようにした
  - 添付をタップして開く導線を追加
- Admin
  - テンプレート編集 / 削除 UI を追加
- API / Repository
  - `updateTask` を拡張
  - `updateTemplate` / `deleteTemplate` を追加
  - Edge Function 側に template の `PATCH` / `DELETE` ルートを追加
- テスト
  - 既存 widget test を拡張
  - `test/features/shell/app_router_test.dart` を追加
  - 認証リダイレクトと auth state change の再評価を固定

## まだ終わっていないこと
1. `env/dev.json` を作成して実機で Supabase 接続確認
2. 実機で次の基本操作を通す
   - ログイン
   - タスク詳細 / 編集 / 削除
   - メッセージ一括既読 / 詳細削除 / 添付起動
   - Admin テンプレート編集 / 削除
3. 実機テスト結果を docs に反映
4. 現在ブランチを push / PR / merge

## 今の論点
- 実機起動そのものは通るが、`--dart-define-from-file=env/dev.json` がないとアプリが停止する
- 実機確認用に iOS のローカル差分がある
  - `ios/Podfile`
  - `ios/Podfile.lock`
  - `ios/Runner.xcodeproj/project.pbxproj`
  - `ios/Runner/Runner.entitlements`
- 特に Bundle ID と entitlement 調整はローカル検証都合なので、コミット前に切り分けが必要

## 再開時の最短コマンド
```bash
cd /Users/hide_kakky/Dev/shiftflow_flutter
./scripts/ios_local_status.sh
cp env/dev.json.example env/dev.json
# env/dev.json の SUPABASE_URL / SUPABASE_ANON_KEY を設定
flutter run -d 00008110-000645C62E86201E --dart-define-from-file=env/dev.json
```

## 次回のおすすめ着手順
1. `AGENTS.md` と `docs/SHIFTFLOW_rule_reference.md` を読む
2. `env/dev.json` を作成して Supabase 接続設定を入れる
3. 実機で基本機能を順番に確認する
4. 実機確認後に `./scripts/ios_local_store.sh` で iOS ローカル差分を退避する
5. その後に GitHub 公開フローへ進む

## 次回の完了条件候補
- 実機で主要 CUJ が一通り確認できる
- iOS ローカル差分を feature 差分から分離できている
- 現在ブランチが push / PR / merge 済み

## ルール参照順（必須）
1. `AGENTS.md`
2. `docs/SHIFTFLOW_rule_reference.md`
3. `docs/SHIFTFLOW_development_flow.md`
