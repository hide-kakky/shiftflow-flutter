# NEXT SESSION CHECKLIST

## 0. このセッションのゴール
- Phase 2（機能同等化）を1つ以上前進させる。
- 終了時に `flutter analyze` / `flutter test` をグリーンで終える。

## 1. 開始時（そのまま実行）
- [ ] `cd /Users/hide_kakky/Dev/shiftflow_flutter`
- [ ] `git switch main && git pull --ff-only`
- [ ] `git switch -c feat/phase2-<task-name>`

## 2. まず読む（3分）
- [ ] `docs/NEXT_SESSION_BRIEF.md`
- [ ] `plan.md`
- [ ] `task.md`

## 3. 開発前確認
- [ ] `flutter pub get`
- [ ] `flutter gen-l10n`
- [ ] `supabase start`
- [ ] `supabase db reset --local --yes`

## 4. 実装（優先順）
- [ ] Tasks 詳細UI（担当者・期限・添付）
- [ ] Messages 詳細UI（既読状態・コメント一覧・ピン）
- [ ] Admin 画面（Users/Organizations/Audit）

## 5. 実装後検証
- [ ] `flutter analyze`
- [ ] `flutter test`
- [ ] `supabase db lint --local --fail-on error`

## 6. 反映前
- [ ] `plan.md` / `task.md` / `implementation_plan.md` を更新
- [ ] `docs/` のリンク切れがないか確認

## 7. GitHub
- [ ] `gh auth status` 確認
- [ ] `git push -u origin <branch>`
- [ ] PR作成（目的、変更点、検証結果を記載）
