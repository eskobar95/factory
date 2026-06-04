# Skills

Agent skills live here. Installed to projects via `.cursor/skills/factory` → symlink to `.factory/kit/skills`.

Each skill is a folder with a `SKILL.md` file (Cursor convention).

## Quick index

See **[INDEX.md](INDEX.md)** for the full reference table (planning, harness, hooks, rules).

## Layout

```
skills/
  planning/       align, to-prd, to-backlog, adr-lookup
  harness/        harness (lead), implement, verify, review, close, fix-ci, …
  productivity/   handoff
  catalog/        pointers to third-party skills
  INDEX.md        quick lookup
```

## Planning skills

Load when running `/align`, `/to-prd`, `/to-backlog`, or `/to-plan`.

| Skill | Path |
|-------|------|
| Align | [planning/align/SKILL.md](planning/align/SKILL.md) |
| To PRD | [planning/to-prd/SKILL.md](planning/to-prd/SKILL.md) |
| To backlog | [planning/to-backlog/SKILL.md](planning/to-backlog/SKILL.md) |
| ADR lookup | [planning/adr-lookup/SKILL.md](planning/adr-lookup/SKILL.md) |

## Harness skills

| Skill | Path | Role |
|-------|------|------|
| Lead orchestrator | [harness/harness/SKILL.md](harness/harness/SKILL.md) | Dispatch parallel subagents |
| Implement | [harness/implement/SKILL.md](harness/implement/SKILL.md) | Code + commit |
| Verify | [harness/verify/SKILL.md](harness/verify/SKILL.md) | typecheck / lint / test |
| Review | [harness/review/SKILL.md](harness/review/SKILL.md) | Task fit + thermo-nuclear |
| Close | [harness/close/SKILL.md](harness/close/SKILL.md) | PR + tasks.md update |
| Fix CI | [harness/fix-ci/SKILL.md](harness/fix-ci/SKILL.md) | Green checks before done |
| Log task | [harness/log-task/SKILL.md](harness/log-task/SKILL.md) | Diary entries |
| Retro | [harness/retro/SKILL.md](harness/retro/SKILL.md) | Sprint retrospective |
| Milestone CI | [harness/milestone-ci/SKILL.md](harness/milestone-ci/SKILL.md) | Milestone gates |
| HITL checkpoint | [harness/hitl-checkpoint/SKILL.md](harness/hitl-checkpoint/SKILL.md) | Human approval |
| Thermo-nuclear | [harness/thermo-nuclear-code-quality-review/SKILL.md](harness/thermo-nuclear-code-quality-review/SKILL.md) | Deep code quality |

## Project overrides

Add skills under **`.factory/skills/`** in your project. They appear at `.cursor/skills/project/` after install.

## Vendor skills

See [catalog/README.md](catalog/README.md) for third-party skills (e.g. Matt Pocock).
