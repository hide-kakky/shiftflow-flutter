# NEXT SESSION BRIEF

## 現在の状態（2026-04-07 時点）
- リポジトリ: `https://github.com/hide-kakky/shiftflow-flutter`
- 現在ブランチ: `main`
- 状態: 作業ツリーはクリーン
- 補足:
  - ホーム画面の Notion 系 UI 再設計は `main` へ push 済み
  - ローカル / リモートともに作業ブランチは整理済み
  - 実機 UI 確認のため Push capability を外したローカル差分は stash に退避済み

## 直近で完了したこと
- Home 画面を再設計
  - 概要指標の再配置
  - クイック導線の追加
  - 「いま見るべきこと」の要約表示
  - `DESIGN Notion.md` から必要な要素だけ抽出して反映
- `plan.md` / `task.md` / `implementation_plan.md` / `docs/SHIFTFLOW_pwa_gap_analysis_2026-03-26.md` を更新
- `flutter analyze` / `flutter test` を通過
- `main` へローカルマージし、`origin/main` へ push 済み
- 使い終わったローカル / リモートブランチを整理

## まだ終わっていないこと
1. Firebase / FCM の実設定
2. Supabase secrets 設定と Functions 再デプロイ
3. 実機で push 通知の本番相当検証
4. `docs/SHIFTFLOW_e2e_scenarios.md` への検証結果記録

## 今の論点
- `Personal Team` では Push Notifications capability が使えない
- 実機 UI 確認のため、一時的に Push 関連を外して起動した
- 実機で push 通知まで確認するには、次のどちらかが必要
  - Apple Developer Program の有料アカウントで正式に署名する
  - 通知検証は後回しにして、まず Web / 非 Push 実機で UI 開発を進める

## 再開時の最短コマンド
```bash
cd /Users/hide_kakky/Dev/shiftflow_flutter
./scripts/ios_local_status.sh
git stash list
flutter pub get
flutter gen-l10n
```

## stash メモ
- `stash@{0}`: `ios-local-build-files: 2026-04-07 11:03:05`
  - 実機確認時の iOS ローカル差分
- `stash@{1}`: `local-firebase-config: ui-check-temp`
  - `GoogleService-Info.plist` と一時 Firebase 設定
- `stash@{2}`: `local-firebase-config: 2026-04-03`
  - 旧 Firebase ローカル設定
- `stash@{3}`: `ios-local-build-files: 2026-03-31 22:36:02`
  - 旧 iOS ローカル差分

## 次回のおすすめ着手順
1. `AGENTS.md` と `docs/SHIFTFLOW_rule_reference.md` を読む
2. `git stash list` を確認し、今回使う stash を決める
3. UI 続行なら:
   - stash は戻さず `main` のまま作業ブランチを切る
4. FCM 続行なら:
   - 必要な stash を `apply`
   - Apple / Firebase / Supabase の設定を再開

## 次回の完了条件候補
- UI 継続の場合:
  - Home 以外の画面とのデザイン整合を進める
- FCM 継続の場合:
  - 実機で push 通知を 1 回以上受信
  - `docs/SHIFTFLOW_e2e_scenarios.md` に結果を残す

## ルール参照順（必須）
1. `AGENTS.md`
2. `docs/SHIFTFLOW_rule_reference.md`
3. `docs/SHIFTFLOW_development_flow.md`
