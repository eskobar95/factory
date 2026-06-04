# Factory Skills Index

Quick reference for all skills. Use this when you need to find the right skill to load.

---

## Planning track — before sprint

| Skill | Command | When |
|-------|---------|------|
| `planning/align` | `/align` | Align on idea, update `CONTEXT.md` + ADRs. Run before writing PRD. |
| `planning/to-prd` | `/to-prd` | Write `PRD.md` + `TECHSPEC.md` from aligned understanding. |
| `planning/to-backlog` | `/to-backlog` | Break PRD into milestones, sprints, vertical-slice tasks with AFK/HITL. |

**Fast path:** `/to-plan` runs all three in one session (good for small scope).

---

## Harness track — execution

| Skill | Role | When |
|-------|------|------|
| `harness/harness` | Lead agent | Preflight, builds dep graph, dispatches parallel Task subagents per group. |
| `harness/implement` | Subagent | Checkout branch, implement task within scope, commit. |
| `harness/verify` | Subagent | Run `pnpm typecheck` / `lint` / `test --run`. Structured pass/fail. |
| `harness/review` | Subagent | **Phase 1:** task fit, security. **Phase 2:** thermo-nuclear maintainability. |
| `harness/thermo-nuclear-code-quality-review` | Invoked by review | Code-judo, 1k-line rule, spaghetti check. |
| `harness/close` | Subagent | Self-review diff, open PR to `dev`, update `tasks.md`, unblock next group. |
| `harness/fix-ci` | Subagent | Poll `gh pr checks`, fix until green (max 3 iterations). |
| `harness/hitl-checkpoint` | Human gate | `/hitl-checkpoint` — approve HITL tasks before dispatch. |
| `harness/log-task` | Lead only | Append per-task entry to `diary.md` on done/blocked/skipped. |
| `harness/retro` | Lead only | Sprint retro summary in `diary.md`. Suggests factory improvements. |
| `harness/milestone-ci` | Background Agent | Security audit + React Doctor + bundle + test suite. For `/milestone-review`. |

**Pipeline per task:** `implement → verify → review → close → fix-ci` (max 2 revision cycles)

## Harness commands

| Command | When |
|---------|------|
| `/bootstrap-branches` | First-time setup: create `dev` + `staging` |
| `/run-sprint S001` | Run all AFK tasks in sprint (parallel groups) |
| `/run-task T003` | Run one task (retry, HITL after approval) |
| `/hitl-checkpoint T005` | Approve HITL task before implement |
| `/milestone-review M001` | CI gates + `dev → staging` PR |

---

## Productivity

| Skill | Command | When |
|-------|---------|------|
| `productivity/handoff` | `/handoff [focus]` | Compact session → temp file. Reference `.ai/` paths, do not duplicate. |

---

## Hooks (always-on, no invocation needed)

| Script | Event | What |
|--------|-------|------|
| `hooks/run-typecheck.sh` | `afterFileEdit` `.ts/.tsx` | Typecheck. Blocks on fail. |
| `hooks/run-security-audit.sh` | `afterFileEdit` package files | `pnpm audit`. Logs to `diary.md`. |
| `hooks/run-stop-checks.sh` | `stop` (end of turn) | Lint + secret scan. Auto-corrects via `followup_message`. |
| `hooks/guard-branches.sh` | `beforeShellExecution` | Block force push + direct commits to `dev/staging/main`. |
| `hooks/guard-secrets.sh` | `beforeShellExecution` | Block `git add/commit` of `.env`, keys, credentials. |

---

## Rules (always-on)

| Rule | Scope | Key constraint |
|------|-------|---------------|
| `base.mdc` | All files | Strict TS, no `any`, conventional commits, branch format |
| `nextjs.mdc` | `*.ts`, `*.tsx` | Server Components default, no secrets in client |
| `drizzle.mdc` | DB/schema files | Transactions, migration naming, no raw SQL without comment |
| `git.mdc` | Always | No direct commits to protected branches, PR description required |
| `testing.mdc` | Test files | Vitest `--run`, what to test, co-location |
| `security.mdc` | Always | Secrets, webhooks, SSRF, authz |

---

## Vendor / additional skills

See [`skills/catalog/README.md`](catalog/README.md) for third-party skills (Matt Pocock, project overrides).

Project-specific skills live in `.ai/skills/` → symlinked to `.cursor/skills/project/`.

---

## Quick lookup by task

| I want to… | Use |
|-----------|-----|
| Understand my idea before building | `/align` |
| Write product + tech spec | `/to-prd` |
| Break work into tasks | `/to-backlog` |
| Run a sprint | `/run-sprint S001` |
| Run one task | `/run-task T003` |
| Approve HITL task | `/hitl-checkpoint T005` |
| Create dev/staging branches | `/bootstrap-branches` |
| Review a milestone and open staging PR | `/milestone-review M001` |
| Save context before session ends | `/handoff` |
| Update factory in this project | `/factory-update` |
