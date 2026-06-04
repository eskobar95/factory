# Architecture

How Factory separates **kit** (shared, versioned) from **workspace** (project-specific).

## Mental model

```
┌─────────────────────────────────────────────────────────────┐
│  your-project/                                              │
│                                                             │
│  .factory/kit/     ← submodule (eskobar95/factory)            │
│    commands/       read-only kit — update via submodule     │
│    skills/                                                  │
│    rules/                                                   │
│    hooks/                                                   │
│    templates/                                               │
│                                                             │
│  .factory/         ← your project workspace (commit this)   │
│    context/        PRD, TECHSPEC, CONTEXT, ADR, STACK       │
│    planning/       milestones, sprints, tasks               │
│    specs/          BDD .feature files (optional)            │
│    logs/           diary, decisions                         │
│    skills/         overrides → .cursor/skills/project      │
│                                                             │
│  .cursor/          ← symlinks only (gitignored)             │
│    rules/          → .factory/kit/rules                     │
│    commands/       → .factory/kit/commands                  │
│    hooks/          → .factory/kit/hooks                     │
│    skills/factory/ → .factory/kit/skills                    │
│    skills/project/ → .factory/skills                        │
└─────────────────────────────────────────────────────────────┘
```

**Rule of thumb:** Never edit files inside `.factory/kit/` in a project. Propose changes in the `eskobar95/factory` repo, then `update.sh`.

## Planning track

Purpose: turn a macro idea into executable vertical-slice tasks **before** code.

| Stage | Command | Primary outputs |
|-------|---------|-----------------|
| Align | `/align` | `.factory/context/CONTEXT.md`, ADRs |
| Spec | `/to-prd` | `.factory/context/PRD.md`, `TECHSPEC.md` |
| Backlog | `/to-backlog` | `.factory/planning/milestones.md`, `sprints.md`, `tasks.md` |

Skills load from `.cursor/skills/factory/planning/*`. They read and write **workspace paths only** (`.factory/context`, `.factory/planning`).

## Harness track

Purpose: execute sprint tasks via parallel Cursor subagents with quality gates.

```
Lead agent (/run-sprint)
  │
  ├── Group A (parallel Task subagents)
  │     implement → verify → review → close → fix-ci
  ├── Group B (after A unblocks)
  └── retro + diary entries
```

| Role | Skill | Writes to |
|------|-------|-----------|
| Lead | `harness/harness` | dispatches tasks, `log-task` → diary |
| Subagent | `harness/implement` | feature branch, commits |
| Subagent | `harness/verify` | pass/fail report |
| Subagent | `harness/review` | Phase 1 + thermo-nuclear |
| Subagent | `harness/close` | PR to `dev`, updates `tasks.md` |
| Subagent | `harness/fix-ci` | CI green before `done` |

Task definitions live in `.factory/planning/tasks.md` (YAML blocks per task).

## Hooks & rules

**Rules** (`.cursor/rules/*.mdc`) — always-on agent constraints: TypeScript strictness, branch protection, security patterns.

**Hooks** (`.cursor/hooks/`) — shell scripts triggered by Cursor events:

| Event | Script | Effect |
|-------|--------|--------|
| `afterFileEdit` | `run-typecheck.sh` | Block on TS errors |
| `afterFileEdit` | `run-security-audit.sh` | Log npm audit to diary |
| `stop` | `run-stop-checks.sh` | Lint + secret scan at end of turn |
| `beforeShellExecution` | `guard-branches.sh` | Block force push / protected branch commits |
| `beforeShellExecution` | `guard-secrets.sh` | Block committing secrets |

Hooks resolve via `.cursor/hooks.json` symlink → kit.

## Branch model

```
main
 └── staging          ← /milestone-review opens PR here
       └── dev        ← task PRs land here
             └── feature/S001/T003-slug
```

Protected branches (`dev`, `staging`, `main`) — no direct commits; PRs only.

## Skill resolution order

1. **Project skills** — `.factory/skills/` (if symlink exists)
2. **Factory skills** — `.factory/kit/skills/`
3. **Vendor skills** — installed via `npx skills add` (see catalog)

Cursor loads skills from `.cursor/skills/factory` and `.cursor/skills/project`.

## File ownership summary

| Location | Owner | Updated by |
|----------|-------|------------|
| `.factory/kit/` | Factory repo | `update.sh` / submodule bump |
| `.factory/context/` | You | planning commands |
| `.factory/planning/` | You | planning + harness close |
| `.factory/specs/` | You | BDD scenarios linked to PRD journeys |
| `.factory/logs/` | You + agents | hooks, log-task, retro |
| `.factory/skills/` | You | manual / project needs |
| `.cursor/*` | Generated | install.sh / update.sh |
