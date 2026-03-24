# ShiftFlow Flutter デリバリープラン（自律更新版）

## 0. 運用ルール
1. 実装前に `docs/SHIFTFLOW_requirements_v1.0.md` と `docs/SHIFTFLOW_implementation_guide_v1.0.md` を確認する。
2. 実装完了時に `plan.md` / `task.md` / `implementation_plan.md` を更新する。
3. ステータス記法: `✅ 完了` / `▶ 進行中` / `□ 未着手`
4. 末尾の `ACTION` を常に最新化する。
5. Git運用は `main` 直コミット禁止。

## 1. 現在地
- フェーズ: Phase 1 -> Phase 2 移行準備
- 状態
  - ✅ Flutter + Supabase 基盤構築
  - ✅ 要件〜運用文書の整備
  - ✅ CI と DBテスト土台
  - ✅ GitHub Public リポジトリ作成・`main` 初回 push 完了
  - ▶ Flutter画面の機能同等化（Tasks 詳細入力 + 添付対応まで完了）
  - ▶ 認証テスト運用の再設計（本番UIを崩さないテスト導線の設計着手）

## 2. マイルストーン
| # | マイルストーン | 状態 | Exit条件 |
| --- | --- | --- | --- |
| 1 | Foundation | ✅ | 基盤・文書・CIが揃う |
| 2 | Core Parity | ▶ | 主要CUJがiOS/Android/Webで動作 |
| 3 | Notification Hardening | □ | 通知3トリガーと重複防止が安定 |
| 4 | Release Readiness | □ | E2E完了・運用手順確定 |

## 3. ACTION
- ACTION-1: `flutter analyze` と `flutter test` を常時グリーン維持。
- ACTION-2: Messages/Admin の詳細UI・入力バリデーションを拡張。
- ACTION-3: `docs/SHIFTFLOW_e2e_scenarios.md` に沿って実機E2Eを実施し、結果を記録。
- ACTION-4: Auth のテストログイン導線を「通常ログインUIのまま検証できる設計」に更新する（`TASUKI` の test users 運用を参考に、画面露出なしの QA 導線を定義）。
- ACTION-5: テスト環境分離を明文化する（`--dart-define` / flavor / ローカル Supabase テストユーザー生成手順）。
