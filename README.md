# Factory — Personal AI Dev OS

Private GitHub repo (`eskobar/factory`) that acts as a catalog of Cursor commands, skills, rules, and hooks. Install into any project via git submodule and `install.sh`.

## What it provides

- **Commands** — explicit triggers (`/po-breakdown`, `/run-sprint`, `/milestone-review`)
- **Skills** — procedural playbooks for agents (harness, implement, verify, review, close, retro, milestone-ci)
- **Rules** — declarative, always-on code standards
- **Hooks** — event-driven automation (typecheck on save, security on package change)
- **Templates** — scaffolding for `.ai/` in new projects

## Install in a project

```bash
# From your project root
curl -sSL https://raw.githubusercontent.com/eskobar/factory/main/install.sh | bash
# Or clone and run locally:
git submodule add git@github.com:eskobar/factory.git .factory
./.factory/install.sh
```

After install, your project has:

```
[project]/
  .factory/          ← submodule (this repo)
  .ai/               ← PRD, techspec, planning, logs
  .cursor/           ← symlinks to factory rules/skills/commands/hooks
```

## Workflow

1. Give a macro idea in Composer
2. `/po-breakdown` → PRD, techspec, milestones, atomic tasks
3. `/run-sprint [sprint-id]` → harness runs tasks in parallel via subagents
4. `/milestone-review [milestone-id]` → CI gates + `dev → staging` PR for your approval

## Branch model (in target projects)

```
main
  └── staging      ← you merge here when milestone is approved
        └── dev    ← task PRs merge here automatically
              └── feature/[sprint]/[task-id]-[slug]
```

Factory never touches `main`. You merge `staging → main` yourself.

## Requirements

- Cursor 3.3+ (subagents + Build in Parallel)
- Cursor 3.5+ for milestone Background Agents
- pnpm-based projects (typecheck, lint, test scripts)

## License

Private — solo use only.
