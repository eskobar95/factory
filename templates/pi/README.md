# Factory Pi configuration

Project-owned Pi/ultimate-pi settings. Initialized from the Factory kit on install or update.

## Files

| File | Purpose |
|------|---------|
| `agents.policy.yaml` | Per-agent model + thinking level (ultimate-pi SSOT) |
| `models.profile.yaml` | Human-readable model matrix (reference only) |

## Sync flow

```
.factory/kit/templates/pi/     kit template (read-only)
        ↓ copy_if_missing on install/update
.factory/pi/                   project SSOT — edit here
        ↓ scripts/sync-pi-config.sh
.pi/agents.policy.yaml         ultimate-pi reads this at runtime
```

## Customize

1. Edit `.factory/pi/agents.policy.yaml` for your project's model choices
2. Run `.factory/kit/scripts/sync-pi-config.sh` (or `/factory-update`)
3. Commit `.factory/pi/` — not `.pi/harness/runs/` artifacts

## Prerequisites

- Pi installed (`https://pi.dev`)
- `pi install npm:ultimate-pi`
- `pi install npm:@offbynan/pi-cursor-provider` + `/login cursor`
- OpenRouter key in `.env` (`OPENROUTER_API_KEY`)
- Project harness: `pi` → `/harness-setup`
- Cursor MCP: reload MCP servers after install (Settings → MCP → reload)

## Cursor MCP bridge

After `install.sh`, `.cursor/mcp.json` wires up `scripts/pi-mcp-server.js` as a local MCP server. Cursor agents can call Pi directly:

```
harness_auto("implement login flow")   # starts Pi, returns immediately
harness_status()                       # poll: phase, output, alive?
harness_artifacts("executor-summary") # read Pi's work summary
harness_artifacts("adversary-report") # read adversary findings
harness_abort()                        # stop if needed
```

Pi runs in the background — `harness_status` returnerer `process.alive`, `harness.phase` og `recent_output` (seneste 30 linjer fra Pi).

## Executor tiers (Cursor subscription)

| Tier | Model | When |
|------|-------|------|
| **default** | `cursor/composer-2.5` | Standard implementation |
| **heavy** | `cursor/glm-5.2` | Complex refactors, deep multi-file work |

Only one is active in `agents.policy.yaml` at a time (`harness/running/executor`).

To switch to heavy:

```bash
# 1. Edit .factory/pi/agents.policy.yaml → executor model: cursor/glm-5.2
# 2. Sync
.factory/kit/scripts/sync-pi-config.sh
```

Or pick `cursor/glm-5.2` in Pi's `/model` menu before `/harness-run` (parent session).

## Session workflow

```bash
# Planning — OpenRouter (cheap, no Cursor quota)
pi --provider openrouter --model tencent/hy3-preview
/harness-plan "..."

# Run — default executor (composer-2.5 in policy)
/model cursor/composer-2.5
/harness-run

# Review — adversary uses different family than executor
/model cursor/grok-4.3
/harness-review
```

Subagents inherit `model:` from `agents.policy.yaml` for executor, adversary, and evaluator.
