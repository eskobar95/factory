# /ship [task-id]

Run the full quality gate before opening or updating a PR.

## Usage

```text
/ship T001
/ship       (uses current branch, infers task from branch name)
```

## What it runs

Sequential quality chain — stops at first critical failure:

1. **verify** — typecheck + lint + tests
2. **deslop** — remove AI-slop from diff (unnecessary comments, `any` casts, defensive try/catch)
3. **thermo-nuclear** — spaghetti, 1k-line rule, code-judo, abstraction
4. **react-doctor** — if UI files changed (React/Next.js quality)
5. **check-compiler** — strict TypeScript compile check
6. **sentrux check_rules** — architecture boundary violations (if `sentrux.enabled: true`)
7. **make-pr-easy-to-review** — clean commits, improve PR description
8. **open/update PR**

Quality profile from `factory.config.yaml quality.profile`:
- `standard`: steps 1–5 + 7 + 8
- `strict`: all steps including sentrux
- `minimal`: step 1 only

## Loads

`skills/harness/ship/SKILL.md`

## Also used after Pi runs

After Pi completes a task, run `/ship T[id]` in Cursor to apply the same quality gate to Pi-produced code before the PR is opened.
