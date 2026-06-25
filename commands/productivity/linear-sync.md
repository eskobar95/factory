# /linear-sync

Sync `tasks.md` state to Linear — create missing issues, close done tasks.

## Usage

```text
/linear-sync
```

## Prerequisites

```bash
# .env (never commit)
LINEAR_API_KEY=lin_api_xxxxxxxxxxxx
```

```yaml
# .factory/factory.config.yaml
linear:
  enabled: true
  team_id: "your-team-id"
  project_id: "your-project-id"   # optional
  sync_close: true
```

## What it does

1. Reads all tasks from `tasks.md`
2. Fetches existing Linear issues for the team/project
3. Shows you a diff plan (create / close / update / no-op)
4. Asks for confirmation before applying
5. Creates missing Linear issues
6. Closes done tasks in Linear (if `sync_close: true`)
7. Writes `**Linear:** LIN-NNN` back to each task in `tasks.md`

## SSOT contract

`tasks.md` → Linear (one direction only). Linear status is never pulled back into `tasks.md`.

## Loads

`skills/productivity/linear-sync/SKILL.md`

## Also runs automatically

- `/to-backlog` creates Linear issues when `linear.enabled: true`
- `/ship` close step marks Linear issue done when task closes
