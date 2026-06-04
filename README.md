# Factory — Personal AI Dev OS

Private GitHub repo (`eskobar/factory`) — Cursor commands, skills, rules, and hooks for solo multi-project development.

## Two tracks

### Planning track (before code)

Align and spec **before** the harness runs.

| Command | Skill | Output |
|---------|-------|--------|
| `/align` | `planning/align` | `CONTEXT.md`, ADRs |
| `/to-prd` | `planning/to-prd` | `PRD.md`, `TECHSPEC.md` |
| `/to-backlog` | `planning/to-backlog` | milestones, sprints, `tasks.md` |
| `/to-plan` | all three (fast path) | same as full pipeline |
| `/handoff` | `productivity/handoff` | temp session summary |

Inspired by [Matt Pocock's skills](https://www.aihero.dev/skills.md): `grill-with-docs` → `to-prd` → `to-issues`. Factory uses `.ai/` + `tasks.md` instead of GitHub issues.

**Deprecated:** `/po-breakdown` → `/to-plan`

### Harness track (execution)

| Command | Skill | Output |
|---------|-------|--------|
| `/run-sprint S001` | `harness/harness` + implement/verify/review/close | PRs to `dev` |

Review runs **two phases**: task fit + **thermo-nuclear** maintainability.

Task pipeline: `implement → verify → review → close → **fix-ci**` (PR must be green before `done`).

`/run-sprint` dispatches parallel Task subagents; `/run-task T00x` for single tasks; `/bootstrap-branches` before first sprint.
| `/milestone-review M001` | `harness/milestone-ci` | `dev → staging` PR |

Tasks use **vertical slices**, **parallel groups** (A, B, C…), and **Mode: AFK | HITL**.

## Repo layout

```
factory/
  commands/
    planning/       align, to-prd, to-backlog, to-plan
    harness/        run-sprint, milestone-review
    productivity/   handoff
  skills/
    harness/        implement, verify, review, close, retro, milestone-ci
    planning/       align, to-prd, to-backlog
    productivity/   handoff
    catalog/        README for third-party skills
  rules/
  hooks/
  templates/
  install.sh
```

## Install / update

```bash
# First install in a project
git submodule add git@github.com:eskobar/factory.git .factory
./.factory/install.sh

# Update factory in an existing project
.factory/update.sh
git add .factory && git commit -m "chore: update factory"
```

```
[project]/
  .factory/
  .ai/
    context/     PRD, TECHSPEC, CONTEXT, ADR/
    planning/    milestones, sprints, tasks
    logs/
    skills/      project-specific overrides
  .cursor/       symlinks → .factory/*
```

## End-to-end workflow

```mermaid
flowchart LR
  idea[Macro idea]
  align[/align/]
  prd[/to-prd/]
  backlog[/to-backlog/]
  sprint[/run-sprint/]
  milestone[/milestone-review/]
  idea --> align --> prd --> backlog --> sprint --> milestone
```

Or: `idea → /to-plan → /run-sprint → /milestone-review`

You only approve **`staging → main`** and milestone PRs to staging.

## Skill index

See [`skills/INDEX.md`](skills/INDEX.md) for a full quick-reference of every skill, hook, and rule.

## Additional skills

- **Project:** `.ai/skills/` → `.cursor/skills/project/`
- **Vendor:** `npx skills add mattpocock/skills` — see [skills/catalog/README.md](skills/catalog/README.md)

## Branch model

```
main ← you merge staging here
  └── staging ← milestone PR
        └── dev ← task PRs
              └── feature/[sprint]/[task-id]-[slug]
```

## Requirements

- Cursor 3.3+ (subagents, Build in Parallel)
- Cursor 3.5+ (milestone Background Agents)
- pnpm projects (`typecheck`, `lint`, `test`)

## License

Private — solo use.
