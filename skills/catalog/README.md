# Skill catalog (vendor & extensions)

Factory ships **three skill tracks**. Additional skills install here or via `npx skills add`.

## Tracks

| Track | Path | Purpose |
|-------|------|---------|
| **Harness** | `skills/harness/` | Execute tasks: implement → verify → review → close |
| **Thermo-nuclear** | `skills/harness/thermo-nuclear-code-quality-review/` | Strict maintainability audit (built into review Phase 2) |
| **Planning** | `skills/planning/` | Align → PRD → backlog before sprint |
| **Productivity** | `skills/productivity/` | Session tools (handoff, etc.) |

## Recommended third-party skills

Install globally or per-project (Cursor / Claude skills CLI):

```bash
npx skills add mattpocock/skills -y
```

Useful complements to Factory:

| Skill | Use when |
|-------|----------|
| `grill-me` | No codebase (life, greenfield idea) |
| `grill-with-docs` | Reference only — Factory `/align` replaces for `.ai/` layout |
| `to-prd` | Reference — Factory `planning/to-prd` writes to `.ai/` |
| `to-issues` | Reference — Factory `to-backlog` → `tasks.md` not GitHub issues |
| `tdd` | Behavior-first implementation inside a task |
| `triage` | Bug/issue hygiene |
| `handoff` | Reference — Factory `productivity/handoff` included |

## Project overrides

Put project-specific skills in:

```
.ai/skills/
```

`install.sh` symlinks them to `.cursor/skills/project/`.

## Vendor directory (optional)

Clone or submodule extra skills under:

```
skills/catalog/vendor/<author>/<skill>/
```

Do not mix vendor skills into `harness/` — keeps upgrade path clear.
