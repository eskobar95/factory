# Migration guide

Move from legacy layouts to the current **`.factory/kit` + `.factory/` workspace** structure.

## Current layout (v2)

```
.factory/
  kit/           ← submodule (eskobar95/factory)
  context/
  planning/
  logs/
  skills/
.cursor/         ← symlinks to kit
```

## Legacy layout v1 — `.ai/` workspace

If your project used `.ai/context`, `.ai/planning`, etc.:

**Automatic:** Re-run install — it moves `.ai/*` → `.factory/*` when targets don't exist.

```bash
./.factory/kit/install.sh
```

Verify:

```bash
ls .factory/context .factory/planning
# .ai/ should be gone or empty
```

## Legacy layout v1 — submodule at `.factory/` (not `.factory/kit/`)

Older installs added the submodule directly at `.factory/`:

```
.factory/          ← entire submodule (commands, skills, …)
.ai/               ← project workspace
```

**Problem:** Project workspace cannot live inside the submodule without polluting the kit repo.

### Manual migration steps

From your **project root**:

```bash
# 1. Note current submodule commit
OLD_SHA=$(git -C .factory rev-parse HEAD)

# 2. Deinit old submodule
git submodule deinit -f .factory
git rm -f .factory
rm -rf .git/modules/.factory

# 3. Preserve workspace if it was mixed in .ai/
#    (skip if you already use .ai/ separately)
mkdir -p .factory/context .factory/planning .factory/logs .factory/skills
# move .ai/* if present — install.sh does this too

# 4. Re-add at new path
git submodule add git@github.com:eskobar95/factory.git .factory/kit
git -C .factory/kit checkout "$OLD_SHA"  # optional: pin same version

# 5. Install symlinks + scaffold
./.factory/kit/install.sh

# 6. Commit
git add .gitmodules .factory
git commit -m "chore: migrate factory to .factory/kit layout"
```

### Update `.gitmodules`

Before:

```ini
[submodule ".factory"]
  path = .factory
  url = git@github.com:eskobar95/factory.git
```

After:

```ini
[submodule ".factory/kit"]
  path = .factory/kit
  url = git@github.com:eskobar95/factory.git
```

## Path reference changes

All skills and commands now use `.factory/` instead of `.ai/`:

| Old | New |
|-----|-----|
| `.ai/context/PRD.md` | `.factory/context/PRD.md` |
| `.ai/planning/tasks.md` | `.factory/planning/tasks.md` |
| `.ai/logs/diary.md` | `.factory/logs/diary.md` |
| `.ai/skills/` | `.factory/skills/` |
| `.factory/install.sh` | `.factory/kit/install.sh` |
| `.factory/update.sh` | `.factory/kit/update.sh` |

After migrating, run `/factory-update` or `./.factory/kit/update.sh` to ensure symlinks match the latest kit.

## Verify migration

```bash
test -f .factory/kit/install.sh && echo "kit OK"
test -f .factory/context/CONTEXT.md && echo "workspace OK"
test -L .cursor/rules && echo "symlinks OK"
grep -r '\.ai/' .factory/kit 2>/dev/null && echo "WARN: old paths in kit" || echo "paths OK"
```
