# /factory-update

Update the factory submodule in the current project and refresh all symlinks.

## Usage

```text
/factory-update
```

## What it does

1. `git submodule update --remote --merge .factory` — pulls latest factory
2. Re-chmodds any new hook scripts
3. Verifies / re-creates broken symlinks (rules, commands, hooks, skills)
4. Migrates plain `hooks.json` copy → symlink if needed
5. Reports commits pulled and the `git add` command to pin the new pointer

## When to run

- After factory gets new skills, rules, hooks, or bug fixes
- After cloning a project that uses factory (to ensure submodule is initialized)
- If symlinks break after a `git clean` or IDE reset

## Run directly

```bash
.factory/update.sh
```

## Do not

- Skip the `git add .factory && git commit` step — without it the project's submodule pointer still points to the old version
