# /pi-status

Check Pi harness status from Cursor.

## Usage

```text
/pi-status
```

## What this command does

1. Call MCP tool `harness_status()`
2. Print a human-readable summary of current Pi state
3. If completed: also call `harness_artifacts()` to list available artifacts

## Output format

```
## Pi harness status

**Process:** running | completed | not started
**Phase:** plan | execute | review | done
**Started:** [timestamp]
**Run ID:** [id]

**Recent output:**
[last 10 lines from Pi]

**Artifacts:** [list if completed]
```

## If Pi is running

Suggest: "Run `/pi-status` again in ~30s for an update, or continue other work."

## If Pi completed with block_merge

Print adversary findings and suggest next step:
- Fix findings then `/pi-run` again
- Or override by editing `.factory/pi/agents.policy.yaml` adversary threshold

## If Pi completed cleanly

Suggest: `/ship T[id]` to apply Cursor quality gate and open PR.
