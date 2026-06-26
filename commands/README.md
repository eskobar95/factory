# Commands — Factory 2.0

Cursor slash commands installed to `.cursor/commands/` (real files, tracked in git).

Each command is a markdown file. Cursor loads it when you type `/command-name`.

## Planning

| Command | Description |
|---------|-------------|
| `/align` | Align on idea; update CONTEXT + ADRs |
| `/to-prd` | Update or create PRD + TECHSPEC (never recreates) |
| `/to-backlog` | Milestones, sprints, tasks with Engine field |
| `/to-plan` | All three planning steps (fast path) |

**Outputs:** `.factory/context/`, `.factory/planning/`

## Harness

| Command | Description |
|---------|-------------|
| `/bootstrap-branches` | Create integration + staging branches |
| `/run-sprint S001` | Execute sprint — routes tasks to Cursor or Pi by Engine field |
| `/run-task T003` | Run a single task |
| `/hitl-checkpoint T005` | Approve HITL task before implement |
| `/ship T001` | Full quality gate → open PR |
| `/review-pr [url]` | Fetch PR comments, fix, re-push |
| `/milestone-review M001` | CI gates + integration → staging PR |

**Engine routing:** tasks with `Engine: cursor` → Cursor Task subagent. `Engine: pi` → `/pi-run` via MCP bridge.

| Command | Description |
|---------|-------------|
| `/pi-run T001` | Start Pi harness via MCP — monitors in this chat session, runs `/ship` when done |
| `/pi-status` | Check current Pi phase, output, and available artifacts |

## Productivity

| Command | Description |
|---------|-------------|
| `/handoff` | Compact session summary |
| `/factory-update` | Pull latest kit + re-copy `.cursor/` files + sync Pi config |
| `/capture-rule` | Persist project pattern as `.factory/rules/project-*.mdc` |
| `/migrate-to-2.0` | Audit + migrate Factory 1.0 project (non-destructive) |
| `/linear-setup` | One-time guided setup: fetch IDs, create labels + cycles, write config |
| `/linear-sync` | Sync tasks.md → Linear (create/update/close with labels, cycles, relations). `tasks.md` is SSOT. |

## Typical flow — Cursor engine

```
/align → /to-prd → /to-backlog → /bootstrap-branches → /run-sprint S001 → /ship T001 → /milestone-review M001
```

## Typical flow — Pi engine

```
/to-backlog          (sæt Engine: pi på tunge tasks)
/pi-run T003         (Pi starter via MCP — denne session monitorerer)
  [Pi kører: plan → execute → review]
  → adversary-report vises
  → /ship T003       (automatisk hvis review passed)
/milestone-review M001
```
