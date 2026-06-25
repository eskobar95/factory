---
name: harness
description: Lead agent playbook — mandatory parallel Task subagents, Engine routing (cursor|pi), revision loop, tasks.md + per-task diary logging
---

# Harness skill

You are the **lead agent** for a sprint. You **orchestrate only** — you do not implement task code yourself unless every subagent in a group failed and user explicitly asks you to rescue one task.

## Inputs

- Sprint ID (e.g. `S001`) from `/run-sprint` or user
- `.factory/planning/tasks.md`
- `.factory/context/TECHSPEC.md`
- `.factory/planning/sprints.md`
- `.factory/factory.config.yaml` (integration branch, engine defaults, quality profile)

## Preflight (before any dispatch)

Run this checklist; stop and report if failing:

- [ ] Sprint exists in `sprints.md`
- [ ] Read `factory.config.yaml` → set `INTEGRATION_BRANCH` (default: `dev`)
- [ ] Git branch `${INTEGRATION_BRANCH}` exists — if not, tell user to run `/bootstrap-branches`
- [ ] At least one runnable task for this sprint (or report "nothing to run")
- [ ] Set sprint **Status** to `active` in `sprints.md`
- [ ] List runnable tasks by parallel group; list **HITL** tasks as skipped until user confirms

Print to user:

```markdown
## Harness preflight — S[id]
**Runnable:** T001 (cursor), T002 (pi) — group A | **HITL skipped:** T005 | **Blocked:** none
**Integration branch:** dev
**Next:** Dispatching group A
```

## Task format (parse from tasks.md)

- `## T[id] — [title]`
- **Sprint**, **Milestone**, **Status**, **Mode** (`AFK` | `HITL`), **Engine** (`cursor` | `pi`), **Parallel group**, **Blocked by**, **Branch**
- Slice objective, layers, acceptance criteria, out of scope, context, definition of done

Status: `todo` | `in-progress` | `blocked` | `done`
Engine default: `cursor` (if field absent, treat as `cursor`)

## Dependency graph

1. Filter tasks for active **Sprint**
2. Skip `done`
3. Group by **Parallel group** (A, B, C…)
4. Runnable when: `todo`, blockers satisfied, **Mode: AFK**
5. **HITL** → skip unless `**HITL approved:**` present; else log as `skipped`
6. Run groups in order: A → B → C …

## Engine routing

Read `**Engine:**` from each task before dispatch. Mixed groups are allowed.

| Engine | Action |
|--------|--------|
| `cursor` | Dispatch as Cursor Task subagent (standard flow) |
| `pi` | Write TaskBrief YAML + print Pi instructions for user |

### Pi tasks — write TaskBrief before dispatch

For each task with `Engine: pi`, write `.factory/handoff/T[id].yaml`:

```yaml
task_id: T001
sprint: S001
milestone: M001
branch: feature/S001/T001-task-slug
title: "[Task title]"
objective: "[Slice objective]"
layers:
  - "service: [description]"
acceptance_criteria:
  - "[criterion 1]"
context_files:
  - "[relevant file path]"
adr_refs:
  - "ADR-001"
definition_of_done:
  - "pnpm typecheck passes"
  - "pnpm lint passes"
  - "tests written and passing"
generated_at: "[ISO timestamp]"
```

After writing, print to user:

```markdown
## Pi task ready — T[id]
TaskBrief → `.factory/handoff/T[id].yaml`

Run Pi session:
  git worktree add .worktrees/pi-T[id] [branch]
  cd .worktrees/pi-T[id]
  pi "/harness-plan 'T[id]: [title]'"

After Pi completes → run `/ship T[id]` in Cursor.
```

Pi tasks are **non-blocking** for the lead: continue dispatching cursor tasks in the same group in parallel.

## Mandatory subagent dispatch — cursor tasks (non-negotiable)

For each parallel group with **N** runnable AFK `cursor` tasks:

1. **One user-visible message** must launch **N Task calls** in the **same turn** (parallel dispatch).
2. Set `run_in_background: true` on each Task.
3. Use `subagent_type: generalPurpose`.
4. **Do not** implement T00x yourself in the lead session while subagents are running.
5. **Wait** for all cursor tasks in the group to complete before starting the next group.
6. If only **one** cursor task in a group, still use Task tool (do not inline-implement as lead).

### Cursor task prompt template

```text
You are a Factory task worker for [Txxx] sprint [Sxxx].

Read .factory/planning/tasks.md section ## Txxx and .factory/context/TECHSPEC.md.
Read .factory/factory.config.yaml for integration branch and quality profile.
Follow .cursor/rules and skills under .cursor/skills/factory/harness/.

Integration branch: [git.integration_branch from factory.config.yaml, default: dev]
Branch: [exact Branch from task metadata]
Create/checkout branch from integration branch, implement, commit, push.

Run in order:
1. .cursor/skills/factory/harness/implement/SKILL.md
2. .cursor/skills/factory/harness/verify/SKILL.md — if FAIL, retry implement once (revision 1)
3. .cursor/skills/factory/harness/review/SKILL.md — if FAIL, retry implement once (revision 2 max)
4. .cursor/skills/factory/harness/close/SKILL.md — only if verify + review PASS
5. .cursor/skills/factory/harness/fix-ci/SKILL.md — until PR checks green (max 3 iterations)

Max 2 full revision cycles. If still failing: blocked.

Return ONLY this YAML block:

task_id: Txxx
status: done | blocked | error
branch: ...
pr_url: ...
revision_cycles: N
blocker: none | [description]
summary: one line
verify: pass | fail
review_phase1: pass | fail
review_phase2_thermo: pass | fail
ci: pass | fail | local-only | n/a
ci_iterations: N
unblocked_tasks: T00y, ... or none
error_reason: ... (only if status: error)
```

### After each subagent returns (lead duties)

Process results **in task ID order**:

1. Parse YAML from subagent output
2. **If YAML missing or malformed:** treat as `status: error`, set task `blocked`, run log-task
3. Update `.factory/planning/tasks.md` (status, PR, blocker) — `done` only if `status: done` AND `ci: pass` or `ci: local-only`
4. **Required:** run `skills/harness/log-task/SKILL.md` with parsed fields
5. Re-evaluate **Blocked by** for downstream tasks

### Single-task mode

When invoked via `/run-task Txxx`:

- Run preflight for one task only
- Dispatch one Task subagent (cursor) or write one TaskBrief (pi)
- Same post-processing and log-task rules

## Per-task pipeline (inside cursor subagent)

| Step | Skill | On fail |
|------|-------|---------|
| implement | implement | retry once |
| verify | verify | → implement (cycle 1) |
| review | review + thermo-nuclear | → implement (cycle 2 max) |
| close | close | blocked if PR fails |
| fix-ci | fix-ci | blocked after 3 iterations |

## Revision loop

Max **2** full cycles per task. Then `blocked` + log-task + continue other tasks in group if independent.

## Group completion

When all tasks in group A are terminal (`done` or `blocked`):

```markdown
## Group A complete
| Task | Engine | Status | PR |
|------|--------|--------|----|
| T001 | cursor | done   | … |
| T002 | pi     | brief written | pending user Pi run |
```

Proceed to group B only when A has no pending cursor `in-progress` / `todo` AFK work left.

## Sprint completion

When no runnable AFK work remains:

1. Set sprint status `done` or `blocked` in `sprints.md`
2. Run `skills/harness/retro/SKILL.md`
3. Print sprint summary to user

## Rules

- Never push to `staging` or `main`
- Task PRs target `${INTEGRATION_BRANCH}` only (from factory.config.yaml)
- Never skip `log-task` on terminal task states during `/run-sprint`
- Pi tasks are non-blocking to lead — they require async user action

## Skills referenced

- `.cursor/skills/factory/harness/implement/SKILL.md`
- `.cursor/skills/factory/harness/verify/SKILL.md`
- `.cursor/skills/factory/harness/review/SKILL.md`
- `.cursor/skills/factory/harness/thermo-nuclear-code-quality-review/SKILL.md`
- `.cursor/skills/factory/harness/close/SKILL.md`
- `.cursor/skills/factory/harness/fix-ci/SKILL.md`
- `.cursor/skills/factory/harness/hitl-checkpoint/SKILL.md`
- `.cursor/skills/factory/harness/log-task/SKILL.md`
- `.cursor/skills/factory/harness/retro/SKILL.md`
- `.cursor/skills/factory/harness/ship/SKILL.md` (post-Pi gate)
