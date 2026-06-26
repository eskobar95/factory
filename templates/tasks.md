# Tasks

> Atomic tasks for harness execution. One task = one PR.
> Status: `todo` | `in-progress` | `blocked` | `done`
> Mode: `AFK` (agent runs alone) | `HITL` (human checkpoint required)
> Engine: `cursor` (Cursor cloud agent) | `pi` (Pi / ultimate-pi harness)

---

## T001 — [Task title]

**Sprint:** S001
**Milestone:** M001
**Status:** todo
**Mode:** AFK
**Engine:** cursor
**Parallel group:** A
**Blocked by:** none
**Branch:** feature/S001/T001-task-slug
**PRD:** context/features/[feature].md (or context/PRD.md)
**ADRs:** ADR-001

### Slice objective

[One sentence describing what the user can do when this is done.]

### Layers in scope

- DB: no changes
- Service: no changes
- API: no changes
- UI: no changes
- Tests: [what must be tested]

### Acceptance criteria

- [ ] [Criterion 1]
- [ ] [Criterion 2]

### Out of scope

- [What is intentionally not solved in this task]

### Context for implementing agent

- [Relevant files, patterns, existing code to follow]
- For **HITL** tasks: state checkpoint and what human must approve before PR
- For **Engine: pi** tasks: complexity level, estimated files changed, architectural risk

### Definition of done

- [ ] `pnpm typecheck` passes
- [ ] `pnpm lint` passes
- [ ] Tests written and passing
- [ ] No secrets or debug artifacts
- [ ] PR description filled in

---

<!-- Add more tasks below. Task IDs: T001, T002, ... -->
<!-- Engine: cursor  → dispatched as Cursor Task subagent (parallel)           -->
<!-- Engine: pi      → dispatched via MCP bridge (harness_auto) → Pi runs      -->
<!--                   plan → execute → review in background → /ship in Cursor -->
