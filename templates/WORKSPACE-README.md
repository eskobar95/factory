# .factory/ — Project workspace

This folder holds **your project's** planning data, specs, and logs. The Factory **kit** lives in `kit/` (git submodule — do not edit here).

## Structure

```
.factory/
  kit/           Factory kit submodule (commands, skills, rules, hooks)
  context/       Product & technical context
  planning/      Milestones, sprints, tasks
  specs/         BDD feature files (executable behavior specs)
  logs/          Diary and decision log
  skills/        Project-specific Cursor skill overrides
  README.md      This file
```

## context/

| File | Purpose |
|------|---------|
| `CONTEXT.md` | Living project context — stack, constraints, glossary |
| `PRD.md` | Product requirements |
| `TECHSPEC.md` | Technical specification |
| `STACK.md` | Dependencies and infra choices |
| `ADR/` | Architecture Decision Records (why + enforcement) |
| `DESIGN-SYSTEM.md` | Optional UI tokens and component rules |

**Commands:** `/align` → `/to-prd`

## planning/

| File | Purpose |
|------|---------|
| `milestones.md` | Major delivery milestones (M001, M002, …) |
| `sprints.md` | Sprint definitions (S001, S002, …) |
| `tasks.md` | Task YAML blocks — source of truth for harness |

**Commands:** `/to-backlog` · `/run-sprint S001` · `/run-task T003`

## specs/

| File | Purpose |
|------|---------|
| `*.feature` | Gherkin BDD scenarios linked to PRD journeys (J001…) |
| `README.md` | How to write and run executable specs |

**See:** `docs/INSPIRATION.md` · link scenarios in `tasks.md` → **BDD scenarios**

## logs/

| File | Purpose |
|------|---------|
| `diary.md` | Dev diary — task entries, hook logs, retros |
| `decisions.md` | Lightweight decision log |

Written by harness (`log-task`, `retro`) and hooks (security audit).

## skills/

Drop project-specific `SKILL.md` folders here. They symlink to `.cursor/skills/project/` after install.

## Maintenance

```bash
# Refresh .cursor/ symlinks after kit update
./kit/update.sh

# Or in Cursor
/factory-update
```

Do **not** commit changes inside `kit/` from this project — open PRs in `eskobar95/factory` instead.
