# /factory-update

Update the factory kit and re-copy `.cursor/` files.

## Usage

```text
/factory-update
```

## What it does

1. `git submodule update --remote --merge .factory/kit` — pulls latest kit
2. Re-copies kit files to `.cursor/` (rules, commands, hooks, skills/factory)
3. Syncs Pi model routing: `.factory/pi/` → `.pi/agents.policy.yaml` (via `sync-pi-config.sh`)
4. Re-syncs `.factory/rules/project-*.mdc` → `.cursor/rules/`
5. Runs pending migrations from `migrations/` (e.g. `001-pi-config.sh`)
6. Updates `.kit-meta.json`
7. Reports commits pulled and the `git add` command to pin the update

## When to run

- After factory gets new skills, rules, hooks, or bug fixes
- After cloning a project (ensures submodule is initialised + `.cursor/` files copied)
- When a new project rule has been added to `.factory/rules/`

## Run directly

```bash
./.factory/kit/update.sh
```

## After running

```bash
git add .factory/kit .cursor/ .kit-meta.json
# If Pi harness is set up, also commit policy changes:
git add .factory/pi/ .pi/agents.policy.yaml .env
git commit -m "chore: update factory kit to [sha]"
```

## Pi model routing

Kit ships `templates/pi/agents.policy.yaml`. On update, Factory scaffolds `.factory/pi/` (non-destructive) and syncs to `.pi/agents.policy.yaml` when `.pi/` exists.

To reset policy from kit defaults:

```bash
.factory/kit/scripts/sync-pi-config.sh --force-policy
```

## Do not

- Skip the commit step — without it the submodule pointer stays on the old version
