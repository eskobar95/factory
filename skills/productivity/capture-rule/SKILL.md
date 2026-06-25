---
name: capture-rule
description: Turn a learned project pattern into a persistent Cursor rule in .factory/rules/ and .cursor/rules/
---

# Capture-rule skill

Turn a project-specific convention into an enforceable Cursor rule, written to both `.factory/rules/` (tracked) and `.cursor/rules/` (active).

## Inputs

- Pattern description (from command argument or conversation)
- `.factory/context/CONTEXT.md` (terminology reference)
- `.factory/context/ADR/` (check if pattern already covered by an ADR)

## Procedure

### 1. Validate the pattern

Check:
- Is it already covered by a kit rule (architecture, security, git, etc.)? If yes: tell user, do not duplicate.
- Is it specific to this project (not generic best practice)? Generic rules belong in the kit, not here.
- Can it be expressed as a negative ("never do X") or positive ("always do Y") constraint?

### 2. Draft the rule

```markdown
---
description: [one-line summary of what this rule enforces]
alwaysApply: true
---

# [Rule title]

[2–3 sentence explanation of WHY this pattern matters in this project]

## Constraint

[Explicit do/don't with a minimal code example if helpful]

## Examples

Bad:
```[lang]
[bad example]
```

Good:
```[lang]
[good example]
```

## Enforcement

[How to detect violations: ESLint rule / TypeScript / manual review / CI check]
```

### 3. Name the file

Use kebab-case: `project-[short-slug].mdc`

Examples:
- `project-db-query-only.mdc`
- `project-no-hardcoded-tenant-id.mdc`
- `project-zod-on-api-routes.mdc`

Never use generic names like `project-001.mdc`.

### 4. Write files

Write to **both** locations:
1. `.factory/rules/project-[slug].mdc` — tracked in git with project workspace
2. `.cursor/rules/project-[slug].mdc` — active immediately in Cursor

### 5. Output to user

```markdown
## Rule captured — project-[slug]

**File:** `.factory/rules/project-[slug].mdc` (+ synced to `.cursor/rules/`)
**Constraint:** [one-line summary]
**Active:** yes — Cursor will enforce this rule in the current session

Commit when ready:
  git add .factory/rules/project-[slug].mdc .cursor/rules/project-[slug].mdc
  git commit -m "chore: capture rule project-[slug]"
```

## Rules

- Never overwrite existing kit rules (`architecture.mdc`, `security.mdc`, etc.)
- All project rules must use `project-` prefix
- Do not capture rules that are already in an ADR unless the ADR needs automated enforcement
- Ask user to confirm before writing if the rule modifies existing behavior
