---
name: ship
description: Full quality gate before PR — verify, deslop, thermo, react-doctor, check-compiler, sentrux, make-pr-easy, open PR
---

# Ship skill

Run the sequential quality gate on the current branch and open or update a PR.

## Inputs

- Task ID (optional — infer from branch name if absent)
- `.factory/factory.config.yaml` (quality profile, sentrux.enabled, git.integration_branch)
- Current git branch diff vs integration branch

## Step 1 — verify

Load and run `skills/harness/verify/SKILL.md`.

If verify fails: **stop**. Report failures to user. Do not continue.

## Step 2 — deslop

Read the full diff vs integration branch. Remove AI-generated slop:

- Unnecessary comments that restate what the code does
- `any` casts used only to bypass type errors
- Defensive `try/catch` blocks on trusted code paths
- Deeply nested logic that should use early returns
- Patterns inconsistent with surrounding codebase style

Commit deslop fixes on the current branch with message: `style: deslop [Txxx]`

## Step 3 — thermo-nuclear

Load and run `skills/harness/thermo-nuclear-code-quality-review/SKILL.md`.

Flag (do not auto-fix):
- Files > 1000 lines introduced in this diff
- New circular dependencies
- God objects (single class/module doing 3+ unrelated things)
- Hardcoded values that belong in config/constants

If critical findings: report to user and ask whether to fix now or create follow-up task.

## Step 4 — react-doctor (conditional)

Only run if diff contains files matching: `*.tsx`, `*.jsx`, `app/`, `components/`, `pages/`.

Check:
- No hardcoded colors or spacing (must use design tokens / Tailwind classes)
- No inline styles (unless dynamic)
- Components > 200 lines → flag for split
- Props drilling > 3 levels → flag

Report findings. Do not auto-fix UI findings.

## Step 5 — check-compiler

Load and run `skills/check-compiler-errors/SKILL.md` (cursor-team-kit).

TypeScript must compile with zero errors in strict mode. If errors exist: fix them, commit: `fix: typescript [Txxx]`.

## Step 6 — sentrux (strict profile only)

Only if `factory.config.yaml sentrux.enabled: true`.

```bash
sentrux check_rules
```

If violations exist AND `sentrux.block_on_violation: true`: **stop**, report violations, do not open PR.

If `block_on_violation: false`: report violations as warnings.

## Step 7 — make-pr-easy-to-review

Load and run `skills/make-pr-easy-to-review/SKILL.md` (cursor-team-kit).

- Add TL;DR to PR description matching the actual diff
- Separate core files from generated/mechanical files in PR body
- Call out risky changes, migration order, rollout plan

## Step 8 — open or update PR

- Target: `git.integration_branch` from `factory.config.yaml` (default: `dev`)
- Title: `[Txxx] [task title]`
- Body: structured (TL;DR, files changed, testing, gate results)
- Include gate summary table in PR description:

```markdown
## Quality gate

| Check | Result |
|-------|--------|
| verify (typecheck + lint + test) | ✅ pass |
| deslop | ✅ clean |
| thermo-nuclear | ✅ pass |
| react-doctor | ⚠️ 1 warning (see below) |
| check-compiler | ✅ pass |
| sentrux | skipped (disabled) |
```

## Output to user

```markdown
## /ship T[id] complete

**PR:** [url]
**Gate:** verify ✅ | deslop ✅ | thermo ✅ | react-doctor ⚠️ | compiler ✅
**Warnings:** [list or none]
**Next:** await PR review | /review-pr [url]
```

## Rules

- Never open PR if verify fails
- Never skip deslop on AI-generated diffs
- Thermo findings are advisory unless file > 1k lines (then block)
- Do not auto-fix react-doctor findings without user confirmation
