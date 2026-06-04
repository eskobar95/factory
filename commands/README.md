# Commands

Cursor slash commands installed via `.cursor/commands` → symlink to `.factory/kit/commands`.

Each command is a markdown file. Cursor loads it when you type `/command-name`.

## Planning

| Command | File | Description |
|---------|------|-------------|
| `/align` | [planning/align.md](planning/align.md) | Align on idea; update CONTEXT + ADRs |
| `/to-prd` | [planning/to-prd.md](planning/to-prd.md) | Write PRD + TECHSPEC |
| `/to-backlog` | [planning/to-backlog.md](planning/to-backlog.md) | Milestones, sprints, vertical-slice tasks |
| `/to-plan` | [planning/to-plan.md](planning/to-plan.md) | All three planning steps (fast path) |

**Outputs:** `.factory/context/`, `.factory/planning/`

## Harness

| Command | File | Description |
|---------|------|-------------|
| `/bootstrap-branches` | [harness/bootstrap-branches.md](harness/bootstrap-branches.md) | Create `dev` + `staging` branches |
| `/run-sprint` | [harness/run-sprint.md](harness/run-sprint.md) | Execute sprint tasks in parallel groups |
| `/run-task` | [harness/run-task.md](harness/run-task.md) | Run a single task |
| `/hitl-checkpoint` | [harness/hitl-checkpoint.md](harness/hitl-checkpoint.md) | Approve HITL task before implement |
| `/milestone-review` | [harness/milestone-review.md](harness/milestone-review.md) | CI gates + `dev → staging` PR |

**Reads:** `.factory/planning/tasks.md` · **Writes:** PRs, `tasks.md`, `.factory/logs/diary.md`

## Productivity

| Command | File | Description |
|---------|------|-------------|
| `/handoff` | [productivity/handoff.md](productivity/handoff.md) | Compact session summary for next chat |
| `/factory-update` | [productivity/factory-update.md](productivity/factory-update.md) | Pull latest kit + refresh symlinks |

## Deprecated

| Command | Replacement |
|---------|-------------|
| `/po-breakdown` | [po-breakdown.md](po-breakdown.md) → use `/to-plan` |

## Typical flow

```
/align → /to-prd → /to-backlog → /bootstrap-branches → /run-sprint S001 → /milestone-review M001
```

Or: `/to-plan` → `/run-sprint S001`
