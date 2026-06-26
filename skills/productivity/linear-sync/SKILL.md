---
name: linear-sync
description: Sync tasks.md state to Linear — create/update issues with labels, cycles, blocking relations
---

# Linear sync skill

`tasks.md` is the **SSOT**. Linear is the human overview. This skill syncs Linear to match `tasks.md` — never the other way around.

## Prerequisites

- `factory.config.yaml` has `linear.enabled: true` + IDs populated (run `/linear-setup` first)
- `LINEAR_API_KEY` in environment (`.env` — never committed)

First-time setup → run `/linear-setup` (fetches all IDs, creates labels and cycles).

## Linear API helper

```bash
linear_gql() {
  local query="$1"
  curl -s -X POST https://api.linear.app/graphql \
    -H "Authorization: ${LINEAR_API_KEY}" \
    -H "Content-Type: application/json" \
    -d "{\"query\": \"${query}\"}"
}
```

Always check the response for `"errors"` before continuing.

## Phase 1 — Read config and state

Load `factory.config.yaml`:

```yaml
linear:
  team_id, project_id, sync_close
  label_ids:   engine_cursor, engine_pi, mode_afk, mode_hitl, blocked
  state_ids:   todo, in_progress, blocked, done
  cycle_ids:   S001 → cycle_id, S002 → cycle_id, ...
```

Parse `tasks.md` → for each task extract:

| Field | Source |
|-------|--------|
| Task ID | `## T001` |
| Title | heading |
| Status | `**Status:**` |
| Engine | `**Engine:**` |
| Mode | `**Mode:**` |
| Sprint | `**Sprint:**` |
| Blocked by | `**Blocked by:**` |
| Linear ID | `**Linear:** LIN-NNN` (if present) |
| PR URL | `**PR:**` |

Fetch existing Linear issues:

```bash
linear_gql "{ issues(filter: { team: { id: { eq: \"TEAM_ID\" } }, project: { id: { eq: \"PROJECT_ID\" } } }) { nodes { id identifier title state { id name type } labelIds cycleId } } }"
```

## Phase 2 — Diff and plan

Build a sync plan per task:

```markdown
| Task | Status | Engine | Mode | Linear | Action |
|------|--------|--------|------|--------|--------|
| T001 | done | cursor | AFK | LIN-42 | close + label engine:cursor |
| T002 | in-progress | pi | AFK | LIN-43 | update state + label engine:pi |
| T003 | todo | cursor | HITL | missing | create + labels |
| T004 | blocked | cursor | AFK | missing | create + blocked label + relation |
| T005 | done | pi | AFK | LIN-45 | already closed — no-op |
```

Print plan. Ask for confirmation before applying.

## Phase 3 — Apply

### Create missing issues

```bash
linear_gql "mutation {
  issueCreate(input: {
    title: \"[T003] Task title\"
    description: \"Sprint: S001 | Milestone: M001 | Engine: cursor | Mode: HITL\n\nSlice objective here.\n\nAcceptance criteria:\n- criterion 1\"
    teamId: \"TEAM_ID\"
    projectId: \"PROJECT_ID\"
    stateId: \"TODO_STATE_ID\"
    cycleId: \"CYCLE_ID_FOR_SPRINT\"
    labelIds: [\"engine:cursor label id\", \"mode:HITL label id\"]
    priority: 2
  }) {
    success
    issue { id identifier url }
  }
}"
```

- `cycleId`: look up `linear.cycle_ids[sprint_id]` from config — skip if not set
- `labelIds`: always set Engine + Mode labels; add `blocked` label if Status is `blocked`
- `priority`: 1=urgent, 2=high, 3=medium, 4=low (default 3)

After creating: write `**Linear:** LIN-NNN` back to `tasks.md`.

### Update existing issues

On every sync, update state + labels for changed tasks:

```bash
linear_gql "mutation {
  issueUpdate(id: \"ISSUE_ID\", input: {
    stateId: \"STATE_ID\"
    labelIds: [\"LABEL_IDS\"]
    cycleId: \"CYCLE_ID\"
  }) { success }
}"
```

State mapping:

| tasks.md | Linear state |
|----------|-------------|
| `todo` | `state_ids.todo` |
| `in-progress` | `state_ids.in_progress` |
| `blocked` | `state_ids.blocked` (or todo if no blocked state) |
| `done` | `state_ids.done` (only if `sync_close: true`) |

### Add blocking relations

For tasks with `**Blocked by:** T00x` that have Linear IDs on both sides:

```bash
linear_gql "mutation {
  issueRelationCreate(input: {
    issueId: \"BLOCKED_ISSUE_ID\"
    relatedIssueId: \"BLOCKER_ISSUE_ID\"
    type: blocks
  }) { success }
}"
```

Only create if relation doesn't already exist. Skip if either issue has no Linear ID yet.

### Add PR URL to description (if present)

When a task has `**PR:** url`, append to Linear issue description:

```
PR: https://github.com/...
```

Use `issueUpdate` with updated description field.

## Phase 4 — Report

```markdown
## Linear sync complete

| Action | Count |
|--------|-------|
| Issues created | N |
| Issues closed | N |
| Issues updated (state/labels) | N |
| Blocking relations added | N |
| No-op (already in sync) | N |

**Linear project:** [url]
**tasks.md:** updated with Linear issue IDs
```

## tasks.md format

After sync each task has a `**Linear:**` field:

```markdown
## T001 — Task title

**Sprint:** S001
**Milestone:** M001
**Status:** done
**Mode:** AFK
**Engine:** cursor
**Linear:** LIN-42
**PR:** #103
```

## Rules

- `tasks.md` is SSOT — never pull status from Linear back into `tasks.md`
- Only modify `**Linear:**` and `**PR:**` fields in `tasks.md` — never touch task content
- `linear.enabled: false` → skip silently
- On API error: report, do not partially apply — stop and let user retry
- `LINEAR_API_KEY` must come from environment only, never hardcoded
- If `label_ids` or `state_ids` are empty in config: run `/linear-setup` first
