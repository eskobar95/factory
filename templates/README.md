# Templates

Scaffold files copied into **project workspace** (`.factory/`) on first install.

`install.sh` uses `copy_if_missing` — **never overwrites** existing files.

## Workspace templates

Copied to `.factory/` in target projects:

| Template | Destination | Purpose |
|----------|-------------|---------|
| [WORKSPACE-README.md](WORKSPACE-README.md) | `.factory/README.md` | Workspace guide |
| [CONTEXT.md](CONTEXT.md) | `.factory/context/CONTEXT.md` | Project context |
| [PRD.md](PRD.md) | `.factory/context/PRD.md` | Product requirements |
| [TECHSPEC.md](TECHSPEC.md) | `.factory/context/TECHSPEC.md` | Technical spec |
| [STACK.md](STACK.md) | `.factory/context/STACK.md` | Stack & infra |
| [ADR.md](ADR.md) | `.factory/context/ADR/ADR-000-template.md` | ADR template |
| [milestones.md](milestones.md) | `.factory/planning/milestones.md` | Milestone tracker |
| [sprints.md](sprints.md) | `.factory/planning/sprints.md` | Sprint definitions |
| [tasks.md](tasks.md) | `.factory/planning/tasks.md` | Task YAML blocks |
| [specs/README.md](specs/README.md) | `.factory/specs/README.md` | BDD folder guide |
| [specs/example.feature](specs/example.feature) | `.factory/specs/example.feature` | Gherkin example |
| [DESIGN-SYSTEM.md](DESIGN-SYSTEM.md) | `.factory/context/DESIGN-SYSTEM.md` | Optional UI consistency |

## Logs (created empty)

- `.factory/logs/diary.md` — header only if missing
- `.factory/logs/decisions.md` — touched if missing

## Editing templates

Changes here affect **new installs only**. Existing projects keep their scaffolded files.

To refresh a template in a project, copy manually or delete the target file and re-run install (only if you accept losing local content).
