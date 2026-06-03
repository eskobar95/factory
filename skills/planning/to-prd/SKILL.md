---
name: to-prd
description: Write PRD and TECHSPEC from aligned understanding — no tasks yet (Matt Pocock to-prd pattern)
---

# To-PRD skill

Turn aligned understanding into **product and technical spec files**. Does not create milestones or tasks.

## Prerequisites

- `/align` completed or user provided explicit brief
- Factory installed; `.ai/` exists

## Outputs

| File | Content |
|------|---------|
| `.ai/context/PRD.md` | Problem, goals, non-goals, success metrics, users, deliverables |
| `.ai/context/TECHSPEC.md` | Stack, constraints, integrations, branch model, scripts, ADR log |
| `.ai/context/STACK.md` | Short bullet mirror of stack |

Use templates: `templates/PRD.md`, `templates/TECHSPEC.md`.

## Procedure

1. Read `.ai/context/CONTEXT.md` and ADRs — terminology must match
2. Read repo: `package.json`, structure, env example
3. Ask **at most 1–2** blocking questions; otherwise document assumptions in TECHSPEC
4. Write PRD — tight v1 scope; extras → non-goals or open questions
5. Write TECHSPEC — include `pnpm typecheck`, `lint`, `test` commands
6. Add or update **ADR-001** for the primary architectural choice (if not already in ADR/)

## Quality bar

- Success metrics are measurable
- Non-goals explicit
- No invented secrets or API keys

## Output to user

```markdown
## To-PRD complete

**Files:** PRD.md, TECHSPEC.md, STACK.md
**ADRs touched:** [list]
**Suggested next:** `/to-backlog` then `/run-sprint S001`
```

## Do not

- Write `tasks.md` or milestones (that's `to-backlog`)
- Implement code
