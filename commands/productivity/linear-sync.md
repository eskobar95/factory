# /linear-sync

Sync `tasks.md` state to Linear — create/update issues with labels, cycles, blocking relations, and close done tasks.

## Usage

```text
/linear-sync
```

## Prerequisites

Run `/linear-setup` first (one-time) to fetch IDs, create labels, and create sprint cycles.

```bash
# .env (never commit)
LINEAR_API_KEY=lin_api_xxxxxxxxxxxx
```

```yaml
# .factory/factory.config.yaml (populated by /linear-setup)
linear:
  enabled: true
  team_id: "..."
  project_id: "..."
  sync_close: true
  label_ids: { engine_cursor: "...", engine_pi: "...", mode_afk: "...", mode_hitl: "...", blocked: "..." }
  state_ids: { todo: "...", in_progress: "...", blocked: "...", done: "..." }
  cycle_ids: { S001: "...", S002: "..." }
```

## What it does

1. Reads all tasks from `tasks.md`
2. Fetches existing Linear issues
3. Shows a diff plan (create / update / close / no-op) — asks for confirmation
4. Creates missing issues with Engine + Mode labels and sprint Cycle
5. Updates state + labels for changed tasks
6. Adds blocking relations for `Blocked by:` dependencies
7. Closes `done` tasks (if `sync_close: true`)
8. Writes `**Linear:** LIN-NNN` back to `tasks.md`

## SSOT contract

`tasks.md` → Linear (one direction only). Linear status is never pulled back into `tasks.md`.

## Also runs automatically

- `/to-backlog` creates Linear issues when `linear.enabled: true`
- `log-task` updates Linear state on every status change during `/run-sprint`

## Loads

`skills/productivity/linear-sync/SKILL.md`
