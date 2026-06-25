# Factory 2.0 Skills Index

Quick reference for all skills. Skills live at `.cursor/skills/factory/`.

---

## Planning track — before sprint

| Skill | Command | When |
|-------|---------|------|
| `planning/align` | `/align` | Align on idea, update `CONTEXT.md` + ADRs. Run before writing PRD. |
| `planning/to-prd` | `/to-prd` | Update or create `PRD.md` / `context/features/[feat].md` + TECHSPEC. Never recreates. |
| `planning/to-backlog` | `/to-backlog` | Break PRD into milestones, sprints, vertical-slice tasks with AFK/HITL/Engine. |
| `planning/adr-lookup` | (on ADR/lint failure) | Read ADR scope, enforcement, how to fix. |

**Fast path:** `/to-plan` runs all three in one session.

---

## Harness track — execution

| Skill | Role | When |
|-------|------|------|
| `harness/harness` | Lead agent | Preflight, Engine routing (cursor\|pi), parallel dispatch. |
| `harness/implement` | Subagent | Checkout branch, implement, commit. |
| `harness/verify` | Subagent | Typecheck / lint / tests. Structured pass/fail. |
| `harness/review` | Subagent | Phase 1: task fit + security. Phase 2: thermo-nuclear. |
| `harness/thermo-nuclear-code-quality-review` | Invoked by review + ship | Spaghetti, 1k-line, code-judo. |
| `harness/ship` | `/ship` | Full quality gate: verify → deslop → thermo → react-doctor → compiler → sentrux → PR. |
| `harness/close` | Subagent | Open PR, update `tasks.md`, unblock next group. |
| `harness/fix-ci` | Subagent | Poll `gh pr checks`, fix until green (max 3 iterations). |
| `harness/hitl-checkpoint` | Human gate | Approve HITL tasks before dispatch. |
| `harness/log-task` | Lead only | Per-task entry to `diary.md`. |
| `harness/retro` | Lead only | Sprint retro summary in `diary.md`. |
| `harness/milestone-ci` | Background Agent | Security audit + React Doctor + bundle + test suite for `/milestone-review`. |

**Pipeline per cursor task:** `implement → verify → review → close → fix-ci` (max 2 revision cycles)
**Pipeline per pi task:** write TaskBrief → user runs Pi session → `/ship` in Cursor

---

## Harness commands

| Command | When |
|---------|------|
| `/bootstrap-branches` | First-time: create integration + staging branches |
| `/run-sprint S001` | Run all AFK tasks in sprint (parallel groups, Engine routing) |
| `/run-task T003` | Run one task |
| `/hitl-checkpoint T005` | Approve HITL task before implement |
| `/ship T001` | Quality gate + open PR (also used after Pi runs) |
| `/review-pr [url]` | Fetch PR comments, triage, fix, re-push |
| `/milestone-review M001` | CI gates + integration → staging PR |

---

## Productivity

| Skill | Command | When |
|-------|---------|------|
| `productivity/handoff` | `/handoff [focus]` | Compact session summary for next chat. |
| `productivity/capture-rule` | `/capture-rule` | Persist learned project pattern as `.factory/rules/project-*.mdc`. |
| `productivity/migrate-to-2.0` | `/migrate-to-2.0` | Audit + migrate Factory 1.0 project to 2.0 (non-destructive). |

---

## Hooks (always-on)

| Script | Event | What |
|--------|-------|------|
| `hooks/run-typecheck.sh` | `afterFileEdit` `.ts/.tsx` | Typecheck. Blocks on fail. |
| `hooks/run-security-audit.sh` | `afterFileEdit` package files | `pnpm audit`. |
| `hooks/run-stop-checks.sh` | `stop` (end of turn) | Lint + secret scan. |
| `hooks/guard-branches.sh` | `beforeShellExecution` | Block force push to protected branches. |
| `hooks/guard-secrets.sh` | `beforeShellExecution` | Block `git add/commit` of `.env`, keys, credentials. |

---

## Rules (always-on)

| Rule | Key constraint |
|------|---------------|
| `base.mdc` | Strict TS, no `any`, conventional commits, branch format |
| `nextjs.mdc` | Server Components default, no secrets in client |
| `drizzle.mdc` | Transactions, migration naming, no raw SQL without comment |
| `git.mdc` | No direct commits to protected branches, PR description required |
| `testing.mdc` | Vitest `--run`, what to test, co-location |
| `security.mdc` | Secrets, webhooks, SSRF, authz |
| `architecture.mdc` | ADR lookup on architecture failures |

**Project-specific rules** (2.0): `.factory/rules/project-*.mdc` → `.cursor/rules/project-*.mdc`

---

## Quality stack

| Tool | Where | What |
|------|-------|------|
| **Graphify** | Project (CLI) | Knowledge graph — graph before grep during planning |
| **Sentrux** | Project (MCP + CLI) | Architecture score, boundary rules, session baseline |
| **thermo-nuclear** | `/ship` gate | Spaghetti, 1k-line, abstraction |
| **deslop** | `/ship` gate | Remove AI-slop from diff |
| **react-doctor** | `/ship` gate (UI) | Design tokens, component size, props drilling |
| **check-compiler** | `/ship` gate | Strict TypeScript compile |
| **Bugbot** | On PR | General bug review |
| **Security Reviewer** | On PR | Auth, injection, trust boundaries |
| **Approval Agent** | On PR | Policy-based auto-approve |

Bootstrap Graphify + Sentrux + Pi: `scripts/bootstrap-pi.sh`

---

## Quick lookup

| I want to… | Use |
|-----------|-----|
| Align before building | `/align` |
| Write/update product spec | `/to-prd` |
| Break work into tasks | `/to-backlog` |
| Run a sprint | `/run-sprint S001` |
| Run one task | `/run-task T003` |
| Route a task to Pi | Set `**Engine:** pi` in tasks.md, then `/run-sprint` |
| Quality gate + open PR | `/ship T001` |
| Fix PR review comments | `/review-pr [url]` |
| Capture a project pattern | `/capture-rule` |
| Migrate from 1.0 | `/migrate-to-2.0` |
| Update factory kit | `/factory-update` |
| Bootstrap Pi + Graphify | `scripts/bootstrap-pi.sh` |
