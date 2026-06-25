---
name: migrate-to-2.0
description: Audit an existing Factory 1.0 project and produce a clean 2.0 structure — non-destructive, no files deleted
---

# Migrate-to-2.0 skill

Analyse an existing Factory 1.0 project and non-destructively introduce 2.0 structure. No existing files are deleted or overwritten.

## Inputs

- Project root (current directory)
- `.factory/` workspace (existing)
- `.cursor/` (may contain symlinks — legacy 1.0)
- `.factory/kit/` submodule

## Phase 1 — Audit

### 1a. PRD audit

List all PRD-like files:
```bash
ls .factory/context/PRD*.md .factory/context/features/*.md 2>/dev/null
```

For each file:
- Is it a root product PRD or a feature-scoped PRD?
- Is its content still current (referenced by active tasks/milestones)?
- Is there duplicate content across multiple PRD files?

Produce a table:

```markdown
| File | Type | Status | Action |
|------|------|--------|--------|
| context/PRD.md | root | active | keep — consolidate duplicates here |
| context/PRD-notification.md | feature | stale | move to context/features/ or archive |
```

### 1b. Commands and skills audit

List all installed commands and skills:
```bash
ls .cursor/commands/**/*.md 2>/dev/null
ls .cursor/skills/**/*.md 2>/dev/null
```

Check each command:
- Does it contain implementation logic (bad) or only load a skill (good)?
- Does it have a matching skill in `skills/`?
- Is the skill path correct for 2.0 (`.cursor/skills/factory/...`)?

Flag commands that duplicate skill logic.

### 1c. Symlinks audit

```bash
ls -la .cursor/rules .cursor/skills .cursor/commands .cursor/hooks 2>/dev/null
```

Identify all symlinks — these need to be converted to real files by running `install.sh`.

### 1d. factory.config.yaml

Check if `.factory/factory.config.yaml` exists. If not: it needs to be created.

### 1e. Engine field audit

Scan `.factory/planning/tasks.md` for tasks missing `**Engine:**` field.

## Phase 2 — Report

Produce a migration report:

```markdown
## Migration audit — [project name]

### PRDs
- [x] Root PRD exists: context/PRD.md
- [ ] Feature PRDs need consolidation: [list]
- [ ] Duplicate content found: [list]

### Commands/Skills
- [ ] Commands with embedded logic (need cleanup): [list]
- [ ] Skill paths need updating to .cursor/skills/factory/: [list]

### Infrastructure
- [ ] Symlinks in .cursor/ (need re-install): [list]
- [ ] factory.config.yaml missing
- [ ] tasks.md missing Engine: fields on N tasks

### What will be added (non-destructive)
1. `.factory/factory.config.yaml`
2. `.factory/rules/` directory
3. `.factory/handoff/` directory
4. `.factory/policies/` directory
5. Updated `.cursor/` files (copy, not symlink)
6. Engine: cursor field on all tasks missing it

### What will NOT be touched
- All existing PRD, TECHSPEC, CONTEXT, ADR files
- All existing tasks.md, sprints.md, milestones.md entries
- All diary.md, decisions.md logs
- All existing git history
```

Ask user to confirm before proceeding.

## Phase 3 — Apply (after confirmation)

### 3a. Scaffold missing directories

```bash
mkdir -p .factory/rules .factory/handoff .factory/policies .factory/context/features
```

### 3b. Add factory.config.yaml if missing

Copy from kit template. Set `git.integration_branch` by reading existing `sprints.md` to infer current branch convention.

### 3c. Add Engine field to tasks missing it

For each task in `tasks.md` without `**Engine:**`:
- Add `**Engine:** cursor` immediately after `**Mode:**` line
- This is a non-breaking addition

### 3d. Fix symlinks → real files

If symlinks exist in `.cursor/`:
```
Run: .factory/kit/install.sh
(This will remove symlinks and copy real files)
```

Print this as instruction — do NOT run it automatically during migration.

### 3e. Consolidate duplicate PRDs

Only if user confirmed in Phase 2. Move feature PRDs under `context/features/`:
- `PRD-[feature].md` → `context/features/[feature].md`
- Update any references in `tasks.md` (PRD journey field)

### 3f. Fix skill paths in commands

Update old skill paths (`skills/harness/...`) to new paths (`.cursor/skills/factory/harness/...`) in any commands that were customised.

## Phase 4 — Summary

```markdown
## Migration complete

**Added:**
- .factory/factory.config.yaml
- .factory/rules/ (empty — use /capture-rule to add rules)
- .factory/handoff/ (for Pi TaskBriefs)
- .factory/policies/ (add security-reviewer.md, quality.gates.yaml)
- Engine: cursor field on [N] tasks

**Next steps:**
1. Run: .factory/kit/install.sh   (convert symlinks to real files)
2. Commit: git add .factory/ .cursor/ && git commit -m "chore: migrate to Factory 2.0"
3. Optional: .factory/kit/scripts/bootstrap-pi.sh   (add Pi + Graphify + Sentrux)
4. Set factory.config.yaml git.integration_branch to your actual branch
```

## Rules

- Never delete existing files
- Never overwrite existing content
- Never touch git history
- Always confirm with user before Phase 3
