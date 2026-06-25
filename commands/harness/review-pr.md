# /review-pr [pr-url]

Fetch PR review comments, triage them, and apply fixes.

## Usage

```text
/review-pr https://github.com/org/repo/pull/42
/review-pr   (uses current branch's PR)
```

## What it does

1. Fetches review comments via `gh pr view` + `gh api`
2. Categorises: critical / warning / nitpick
3. Fixes critical and warning findings
4. Re-pushes branch
5. Resolves addressed comments

## Loads

`skills/get-pr-comments/SKILL.md` (cursor-team-kit)
