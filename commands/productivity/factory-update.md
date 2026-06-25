# /factory-update

Update the factory kit and re-copy `.cursor/` files.

## Usage

```text
/factory-update
```

## What it does

1. `git submodule update --remote --merge .factory/kit` — pulls latest kit
2. Re-copies kit files to `.cursor/` (rules, commands, hooks, skills/factory)
3. Re-syncs `.factory/rules/project-*.mdc` → `.cursor/rules/`
4. Runs pending migrations from `migrations/`
5. Updates `.kit-meta.json`
6. Reports commits pulled and the `git add` command to pin the update

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
git commit -m "chore: update factory kit to [sha]"
```

## Do not

- Skip the commit step — without it the submodule pointer stays on the old version
