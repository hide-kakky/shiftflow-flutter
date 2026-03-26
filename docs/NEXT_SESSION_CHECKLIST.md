# NEXT SESSION CHECKLIST

## 0. このセッションのゴール
- Phase 2 の残タスク（Auth実機検証）と Phase 3（E2E/Integration）を前進させる。
- 終了時に `flutter analyze` / `flutter test` をグリーンで終える。

## 1. 開始時（そのまま実行）
- [ ] `cd /Users/hide_kakky/Dev/shiftflow_flutter`
- [ ] `git switch main && git pull --ff-only`
- [ ] `git switch -c feat/phase3-<task-name>`

## 2. まず読む（3分）
- [ ] `docs/NEXT_SESSION_BRIEF.md`
- [ ] `plan.md`
- [ ] `task.md`

## 3. 開発前確認
- [ ] `flutter pub get`
- [ ] `flutter gen-l10n`
- [ ] `supabase start`
- [ ] `supabase db reset --local --yes`
- [ ] `./scripts/run_web_dev.sh`
- [ ] `./scripts/db_push.sh dev --dry-run`

## 4. 実装（優先順）
- [ ] Auth導線の実機検証（admin/manager/member）
- [ ] `docs/SHIFTFLOW_e2e_scenarios.md` の実施ログ更新
- [ ] Integrationテスト（主要CUJ）

## 5. 実装後検証
- [ ] `flutter analyze`
- [ ] `flutter test`
- [ ] `supabase db lint --local --fail-on error`
- [ ] 必要なら `./scripts/db_push.sh dev` で migration を dev へ反映

## 6. 反映前
- [ ] `plan.md` / `task.md` / `implementation_plan.md` を更新
- [ ] `docs/` のリンク切れがないか確認

## 7. GitHub
- [ ] `gh auth status` 確認
- [ ] `git push -u origin <branch>`
- [ ] PR作成（目的、変更点、検証結果を記載）
