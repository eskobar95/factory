---
name: linear-sync
description: Sync tasks.md state to Linear — create missing issues, close done tasks, report drift
---

# Linear sync skill

`tasks.md` is the **SSOT**. Linear is the human overview. This skill syncs Linear to match `tasks.md` — never the other way around.

## Prerequisites

- `factory.config.yaml` has `linear.enabled: true`, `team_id`, and optionally `project_id`
- `LINEAR_API_KEY` set in environment (`.env` or shell — never committed)
- Linear team and project exist

## Setup (one-time)

### Get your API key

1. Linear → Settings → API → Personal API Keys → Create key
2. Add to project `.env` (never commit):
   ```
   LINEAR_API_KEY=lin_api_xxxxxxxxxxxx
   ```

### Get team ID

```bash
curl -s -X POST https://api.linear.app/graphql \
  -H "Authorization: ${LINEAR_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"query": "{ teams { nodes { id name } } }"}' \
  | python3 -m json.tool
```

Copy the `id` for your team → `factory.config.yaml linear.team_id`.

### Get "Done" state ID (needed for close sync)

```bash
curl -s -X POST https://api.linear.app/graphql \
  -H "Authorization: ${LINEAR_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"query\": \"{ team(id: \\\"TEAM_ID\\\") { states { nodes { id name type } } } }\"}" \
  | python3 -m json.tool
```

Find state with `"type": "completed"` → note its `id` as `LINEAR_DONE_STATE_ID`.

## Linear API helpers

All API calls use this pattern:

```bash
linear_gql() {
  local query="$1"
  curl -s -X POST https://api.linear.app/graphql \
    -H "Authorization: ${LINEAR_API_KEY}" \
    -H "Content-Type: application/json" \
    -d "{\"query\": \"${query}\"}"
}
```

## Procedure

### Phase 1 — Read state

1. Load `factory.config.yaml`:
   - `linear.team_id`
   - `linear.project_id` (optional)
   - `linear.sync_close`

2. Parse `tasks.md` → extract all tasks with:
   - Task ID (`T001`)
   - Title
   - Status (`todo` | `in-progress` | `blocked` | `done`)
   - Sprint + Milestone
   - PR URL (if present)
   - Linear issue ID (from `**Linear:** LIN-123` field if present in tasks.md)

3. Fetch existing Linear issues for the team/project:

```bash
linear_gql "{ issues(filter: { team: { id: { eq: \"TEAM_ID\" } } }) { nodes { id identifier title state { name type } } } }"
```

### Phase 2 — Diff and plan

Build a sync plan:

```markdown
| Task | tasks.md status | Linear issue | Action |
|------|-----------------|--------------|--------|
| T001 | done | LIN-42 (open) | close |
| T002 | in-progress | LIN-43 (started) | no-op |
| T003 | todo | missing | create |
| T004 | blocked | missing | create (blocked label) |
```

Print plan to user. Ask for confirmation before applying.

### Phase 3 — Apply

#### Create missing issues

```bash
linear_gql "mutation {
  issueCreate(input: {
    title: \"[T001] Task title\"
    description: \"Sprint: S001\\nMilestone: M001\\n\\nSlice objective here.\"
    teamId: \"TEAM_ID\"
    projectId: \"PROJECT_ID\"
    stateId: \"TODO_STATE_ID\"
    priority: 2
  }) {
    success
    issue { id identifier }
  }
}"
```

After creating, write back to `tasks.md` — add `**Linear:** LIN-NNN` field under task metadata.

#### Close done tasks (if `linear.sync_close: true`)

```bash
linear_gql "mutation {
  issueUpdate(id: \"ISSUE_ID\", input: {
    stateId: \"DONE_STATE_ID\"
  }) {
    success
  }
}"
```

#### Mark in-progress

```bash
linear_gql "mutation {
  issueUpdate(id: \"ISSUE_ID\", input: {
    stateId: \"IN_PROGRESS_STATE_ID\"
  }) {
    success
  }
}"
```

### Phase 4 — Report

```markdown
## Linear sync complete

| Action | Count |
|--------|-------|
| Issues created | N |
| Issues closed | N |
| Issues updated (in-progress) | N |
| No-op (already in sync) | N |

**Linear project:** [url]
**tasks.md:** updated with Linear issue IDs
```

## tasks.md format addition

After sync, tasks gain a `**Linear:**` field:

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

- Never modify task content in tasks.md (status, title, criteria) — only add/update `**Linear:**` field
- Never pull status from Linear → tasks.md (Linear is read-only intake)
- If `linear.enabled: false` in factory.config.yaml: skip silently
- On API error: report, do not partially apply — retry or skip
- `LINEAR_API_KEY` must come from environment, never hardcoded
