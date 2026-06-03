---
name: verify
description: Run typecheck, lint, and test — return structured pass/fail for harness
---

# Verify skill

Run project quality scripts and return a **structured** result for harness. Fix failures only if harness sent you back from implement with revision; otherwise report only.

## Prerequisites

- Implementation committed on task branch
- `package.json` scripts exist (from TECHSPEC or discover):

| Check | Command (prefer) | Fallback |
|-------|------------------|----------|
| Typecheck | `pnpm typecheck` | `pnpm exec tsc --noEmit` |
| Lint | `pnpm lint` | `pnpm exec eslint .` |
| Test | `pnpm test --run` | `pnpm test:unit --run` |

> **`--run` is mandatory in agent/subagent context.** Without it Vitest starts in watch mode and the subagent hangs indefinitely.

Read `.ai/context/TECHSPEC.md` **Commands** table for project-specific commands.

## Procedure

1. `git status` — ensure on correct task branch
2. Run typecheck → capture stdout/stderr
3. Run lint → capture output
4. Run tests → capture output
5. If task specifies narrow test path (e.g. one file), run narrowest command first, then full suite if harness requires

## Pass/fail rules

- **PASS:** all three exit code 0
- **FAIL:** any non-zero exit or missing script (treat missing script as fail with note)

## Output format (required)

Harness parses this block:

```markdown
## Verify — T[id]

**Result:** PASS | FAIL

### Typecheck
- **Status:** pass | fail
- **Details:** [first 20 lines of errors or "ok"]

### Lint
- **Status:** pass | fail
- **Details:** [summary]

### Test
- **Status:** pass | fail
- **Details:** [failed test names / counts]

### Recommended action
[If FAIL: specific fix hints for implement agent. If PASS: proceed to review.]
```

## Do not

- Open PR or merge branches
- Skip tests without documenting reason in Recommended action
- Mark task done in tasks.md
