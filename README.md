# Factory — Personal AI Dev OS

Public GitHub repo (`eskobar95/factory`) — Cursor commands, skills, rules, and hooks for solo multi-project development.

## What is Factory?

Factory is a **kit** you install into each project via git submodule. It gives you:

- **Planning commands** — align, PRD, backlog before code
- **Harness commands** — parallel subagent sprint execution with CI gates
- **Skills** — structured agent behavior for each step
- **Rules & hooks** — always-on guardrails (typecheck, secrets, branch protection)

Project-specific data (PRD, tasks, diary) lives in **`.factory/`** in each project. The kit itself lives in **`.factory/kit/`**.

## Two tracks

### Planning track (before code)

| Command | Skill | Output |
|---------|-------|--------|
| `/align` | `planning/align` | `CONTEXT.md`, ADRs |
| `/to-prd` | `planning/to-prd` | `PRD.md`, `TECHSPEC.md` |
| `/to-backlog` | `planning/to-backlog` | milestones, sprints, `tasks.md` |
| `/to-plan` | all three (fast path) | same as full pipeline |
| `/handoff` | `productivity/handoff` | temp session summary |

Inspired by [Matt Pocock's skills](https://www.aihero.dev/skills.md) and [decision-capture patterns](docs/INSPIRATION.md). Factory uses `.factory/` workspace + `tasks.md` instead of GitHub issues.

**Deprecated:** `/po-breakdown` → `/to-plan`

### Harness track (execution)

| Command | Skill | Output |
|---------|-------|--------|
| `/bootstrap-branches` | — | `dev` + `staging` branches |
| `/run-sprint S001` | `harness/harness` + pipeline | PRs to `dev` |
| `/run-task T00x` | same pipeline | single task |
| `/hitl-checkpoint T00x` | `harness/hitl-checkpoint` | human approval gate |
| `/milestone-review M001` | `harness/milestone-ci` | `dev → staging` PR |

Review runs **two phases**: task fit + **thermo-nuclear** maintainability.

Task pipeline: `implement → verify → review → close → fix-ci` (PR must be green before `done`).

Tasks use **vertical slices**, **parallel groups** (A, B, C…), and **Mode: AFK | HITL**.

## Repo layout (this kit)

```
factory/                    ← you are here (eskobar95/factory)
  commands/
    planning/               align, to-prd, to-backlog, to-plan
    harness/                run-sprint, run-task, milestone-review, …
    productivity/           handoff, factory-update
  skills/
    harness/                implement, verify, review, close, …
    planning/               align, to-prd, to-backlog
    productivity/           handoff
    catalog/                third-party skill pointers
  rules/                    base, nextjs, drizzle, git, testing, security, architecture
  hooks/                    typecheck, audit, guards
  templates/                scaffold files for project workspace
  docs/                     INSTALL, ARCHITECTURE, MIGRATION
  install.sh
  update.sh
```

See also: [commands/README.md](commands/README.md) · [skills/README.md](skills/README.md) · [rules/README.md](rules/README.md) · [hooks/README.md](hooks/README.md) · [templates/README.md](templates/README.md)

## Install / update

```bash
# From your project root (first time)
git submodule add https://github.com/eskobar95/factory.git .factory/kit
./.factory/kit/install.sh

# Update kit in an existing project
./.factory/kit/update.sh
git add .factory/kit && git commit -m "chore: update factory kit"
```

Or use `/factory-update` in Cursor.

Full guide: [docs/INSTALL.md](docs/INSTALL.md)

## Project layout (after install)

```
your-project/
  .factory/
    kit/           ← submodule (eskobar95/factory — do not edit)
    context/       PRD, TECHSPEC, CONTEXT, ADR/, STACK
    planning/      milestones.md, sprints.md, tasks.md
    specs/         BDD .feature files (optional)
    logs/          diary.md, decisions.md
    skills/        project-specific skill overrides
    README.md      workspace guide (from template)
  .cursor/         symlinks → .factory/kit (rules, skills, commands, hooks)
  src/             your app
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

- **Project:** `.factory/skills/` → `.cursor/skills/project/`
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

Public — solo use.
