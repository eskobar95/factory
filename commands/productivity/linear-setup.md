# /linear-setup

Guided one-time setup of Linear integration — fetches all IDs, creates labels and cycles, writes `factory.config.yaml`.

## Usage

```text
/linear-setup
```

## Prerequisites

```bash
# .env (never commit)
LINEAR_API_KEY=lin_api_xxxxxxxxxxxx
```

Linear team and project must already exist.

## What it does

1. Fetches your Linear teams → asks which to use
2. Fetches projects → maps to this workspace
3. Fetches workflow states → maps todo / in-progress / blocked / done
4. Creates missing labels: `engine:cursor`, `engine:pi`, `mode:AFK`, `mode:HITL`, `blocked`
5. Creates Linear Cycles for each sprint in `sprints.md` (optional)
6. Writes all IDs to `.factory/factory.config.yaml`
7. Offers to run `/linear-sync` immediately

## After setup

All subsequent syncs use `/linear-sync` (or run automatically via `/to-backlog` and `log-task`).

To add a new sprint cycle later: re-run `/linear-setup` — it skips already-configured items.

## Loads

`skills/productivity/linear-setup/SKILL.md`
