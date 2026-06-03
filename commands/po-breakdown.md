# /po-breakdown

Break down a **macro idea** from the user into planning artifacts under `.ai/`.

## When to use

- Starting a new project or major feature
- User provides a product idea, problem statement, or v1 scope in Composer
- `.ai/context/PRD.md` is empty or user asks to replan from scratch

## Prerequisites

- Factory installed (`install.sh` run); `.ai/` exists
- User has stated the macro idea in this conversation (or points to an existing brief)

## Inputs

- User macro idea (problem, goals, constraints, stack hints)
- Optional: existing repo context (read `package.json`, README, folder structure)

## Outputs (write these files)

| File | Purpose |
|------|---------|
| `.ai/context/PRD.md` | Problem, goals, non-goals, success metrics, users, deliverables |
| `.ai/context/TECHSPEC.md` | Stack, constraints, integrations, ADR log, security notes |
| `.ai/planning/milestones.md` | Milestones M001+, sprint overview, dependencies |
| `.ai/planning/sprints.md` | Sprint table S001+ linked to milestones |
| `.ai/planning/tasks.md` | Atomic tasks T001+ using [templates/tasks.md](../templates/tasks.md) format |

## Procedure

1. **Read context**
   - Scan project root: `package.json`, existing app structure, env example if any
   - Read `.ai/context/STACK.md` if populated
   - Read factory template: `templates/tasks.md` for exact task shape

2. **Clarify only if blocking**
   - Ask at most 1–2 critical questions (stack choice, auth, v1 scope boundary)
   - Otherwise infer reasonable defaults and document assumptions in TECHSPEC

3. **Write PRD** (`.ai/context/PRD.md`)
   - Sections: Problem, Goals, Non-goals (v1), Success metrics, Users, System overview, Deliverables, Open questions
   - Keep v1 scope tight; push extras to non-goals or open questions

4. **Write TECHSPEC** (`.ai/context/TECHSPEC.md`)
   - Stack table, constraints, integrations, branch model, project scripts (`pnpm typecheck`, etc.)
   - Add ADR-001 for the most important architectural choice
   - Update `.ai/context/STACK.md` with a short bullet list mirroring stack

5. **Write milestones** (`.ai/planning/milestones.md`)
   - M001 = first shippable slice; further milestones build on it
   - Each milestone lists sprints and high-level task IDs
   - Include mermaid dependency graph if multiple milestones

6. **Write sprints** (`.ai/planning/sprints.md`)
   - Table: ID, Milestone, Goal, Status (`planned` | `active` | `done`)

7. **Write tasks** (`.ai/planning/tasks.md`)
   - One task = one PR to `dev`
   - Assign **Parallel group** A, B, C, D… Tasks in the same letter can run in parallel; later letters wait on earlier groups or explicit `Blocked by`
   - Every task must have: slice objective, layers in scope, acceptance criteria, out of scope, context for agent, definition of done
   - Branch: `feature/[sprint]/[task-id]-[slug]` (e.g. `feature/S001/T001-add-auth-form`)
   - Initial status: `todo`; `Blocked by: none` or `T00x` list

8. **Summarize in Composer** (reply to user)

```markdown
## PO breakdown complete

- **Milestones:** [count] (M001 …)
- **Sprints:** [count] (S001 …)
- **Tasks:** [count] (T001 …)

**Parallel groups (first sprint):**
- Group A: T001, T002
- Group B: T003 (blocked by T001)

**Suggested next step:** Run `/run-sprint S001` after creating `dev` branch and confirming tasks.
```

## Quality bar

- Tasks are **atomic** (typically < 1 day of agent work)
- No task mixes unrelated layers without justification
- Acceptance criteria are testable checkboxes
- Non-goals in PRD match "Out of scope" in tasks

## Do not

- Implement code in this command (planning only)
- Commit secrets or invent API keys
- Create tasks without sprint/milestone IDs
