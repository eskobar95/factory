---
name: linear-setup
description: Guided one-time Linear workspace setup — fetch IDs, create labels, create cycles per sprint, write config
---

# Linear setup skill

Guided first-time setup of Linear integration for Factory 2.0.
Fetches all required IDs from the Linear API and writes them to `factory.config.yaml`.

## Prerequisites

- `LINEAR_API_KEY` in `.env` (never committed)
- Linear team and project already exist
- `factory.config.yaml` accessible

## Linear API helper

All calls use:

```bash
linear_gql() {
  local query="$1"
  curl -s -X POST https://api.linear.app/graphql \
    -H "Authorization: ${LINEAR_API_KEY}" \
    -H "Content-Type: application/json" \
    -d "{\"query\": \"${query}\"}"
}
```

Always check for `"errors"` in the response before continuing. Stop and report if any API call fails.

---

## Phase 1 — Fetch teams

```bash
linear_gql "{ teams { nodes { id name } } }"
```

Print teams to user. Ask which team to use if multiple. Set `TEAM_ID`.

---

## Phase 2 — Fetch projects

```bash
linear_gql "{ team(id: \"${TEAM_ID}\") { projects { nodes { id name } } } }"
```

Print projects. Ask user which project maps to this Factory workspace. Set `PROJECT_ID`.
If no projects exist: ask user to create one in Linear first, then re-run.

---

## Phase 3 — Fetch workflow states

```bash
linear_gql "{ team(id: \"${TEAM_ID}\") { states { nodes { id name type } } } }"
```

Map to Factory statuses:

| Factory status | Linear state type | Pick the state named |
|----------------|-------------------|----------------------|
| `todo` | `unstarted` | "Todo", "Backlog", or first unstarted |
| `in-progress` | `started` | "In Progress" or first started |
| `blocked` | `unstarted` | "Blocked" if exists, else same as todo |
| `done` | `completed` | "Done" or first completed |
| `cancelled` | `cancelled` | "Cancelled" if exists |

Print the mapping to user for confirmation.

---

## Phase 4 — Ensure labels exist

Factory uses these labels on Linear issues:

| Label | Purpose |
|-------|---------|
| `engine:cursor` | Task dispatched to Cursor subagent |
| `engine:pi` | Task dispatched to Pi harness |
| `mode:AFK` | Agent runs without human checkpoint |
| `mode:HITL` | Requires human checkpoint |
| `blocked` | Task is blocked by another |

### Fetch existing labels

```bash
linear_gql "{ team(id: \"${TEAM_ID}\") { labels { nodes { id name } } } }"
```

### Create missing labels

For each label that doesn't exist:

```bash
linear_gql "mutation {
  issueLabelCreate(input: {
    name: \"engine:cursor\"
    color: \"#6366f1\"
    teamId: \"${TEAM_ID}\"
  }) { success issueLabel { id name } }
}"
```

Suggested colors:
- `engine:cursor` → `#6366f1` (indigo)
- `engine:pi` → `#8b5cf6` (violet)
- `mode:AFK` → `#10b981` (emerald)
- `mode:HITL` → `#f59e0b` (amber)
- `blocked` → `#ef4444` (red)

Collect all label IDs into a map. Print to user.

---

## Phase 5 — Create cycles for sprints (optional)

Ask user: "Create Linear Cycles for each sprint in sprints.md?"

If yes:

1. Parse `.factory/planning/sprints.md` — extract sprint IDs, names, dates
2. Fetch existing cycles:

```bash
linear_gql "{ team(id: \"${TEAM_ID}\") { cycles { nodes { id name number } } } }"
```

3. For each sprint not yet a cycle:

```bash
linear_gql "mutation {
  cycleCreate(input: {
    teamId: \"${TEAM_ID}\"
    name: \"S001 — Sprint name\"
    startsAt: \"2026-06-01T00:00:00Z\"
    endsAt: \"2026-06-14T23:59:59Z\"
  }) { success cycle { id name number } }
}"
```

Map sprint ID → cycle ID. Print results.

---

## Phase 6 — Write config

Update `.factory/factory.config.yaml` — set all IDs:

```yaml
linear:
  enabled: true
  team_id: "TEAM_ID"
  project_id: "PROJECT_ID"
  sync_close: true
  label_ids:
    engine_cursor: "LABEL_ID"
    engine_pi: "LABEL_ID"
    mode_afk: "LABEL_ID"
    mode_hitl: "LABEL_ID"
    blocked: "LABEL_ID"
  state_ids:
    todo: "STATE_ID"
    in_progress: "STATE_ID"
    blocked: "STATE_ID"
    done: "STATE_ID"
  cycle_ids:
    S001: "CYCLE_ID"
    S002: "CYCLE_ID"
```

Print confirmation of what was written.

---

## Phase 7 — Initial sync

After writing config, ask: "Run `/linear-sync` now to create issues for all existing tasks?"

If yes: proceed with `skills/productivity/linear-sync/SKILL.md`.

---

## Output to user

```markdown
## Linear setup complete

**Team:** [name] ([id])
**Project:** [name] ([id])

**States mapped:**
- todo → [state name]
- in-progress → [state name]
- blocked → [state name]
- done → [state name]

**Labels:** engine:cursor ✅ | engine:pi ✅ | mode:AFK ✅ | mode:HITL ✅ | blocked ✅

**Cycles created:** S001, S002 (or: skipped)

**Config:** .factory/factory.config.yaml updated

**Next:**
- `/linear-sync` — sync all existing tasks to Linear
- Add `LINEAR_API_KEY` to .env (if not already done)
- Reload .env or restart shell
```

## Do not

- Commit `LINEAR_API_KEY` or any Linear API tokens
- Overwrite `team_id` / `project_id` if already set and user did not confirm change
- Create duplicate labels (check existing first)
