# Tasks

> Atomic tasks for harness execution. One task = one PR to `dev`.
> Status values: `todo` | `in-progress` | `blocked` | `done`  
> Mode values: `AFK` (agent runs alone) | `HITL` (human checkpoint required before/during implement)

---

## T001 — [Task title]

**Sprint:** S001
**Milestone:** M001
**Status:** todo
**Mode:** AFK
**Parallel group:** A
**Blocked by:** none
**Branch:** feature/S001/T001-task-slug

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

### Definition of done

- [ ] `pnpm typecheck` passes
- [ ] `pnpm lint` passes
- [ ] Tests written and passing
- [ ] No secrets or debug artifacts
- [ ] PR description filled in

---

<!-- Add more tasks below using the same format. Task IDs: T001, T002, ... -->
