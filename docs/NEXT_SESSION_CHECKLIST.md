# NEXT SESSION CHECKLIST

## 1. 開始時
- [ ] `cd /Users/hide_kakky/Dev/shiftflow_flutter`
- [ ] `git switch main && git pull --ff-only`
- [ ] `git switch -c feat/<next-task>`

## 2. 開発前確認
- [ ] `flutter pub get`
- [ ] `flutter gen-l10n`
- [ ] `supabase start`
- [ ] `supabase db reset --local --yes`

## 3. 実装後検証
- [ ] `flutter analyze`
- [ ] `flutter test`
- [ ] `supabase db lint --local --fail-on error`

## 4. PR前
- [ ] `plan.md` / `task.md` / `implementation_plan.md` 更新
- [ ] `docs/` の差分確認
- [ ] 変更のスクショまたはログ添付

## 5. GitHub
- [ ] `gh auth status` 確認
- [ ] `git push -u origin <branch>`
- [ ] PR作成
