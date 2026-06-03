# /run-sprint [sprint-id]

Execute all tasks for a sprint using the **harness** skill and parallel subagents.

## Usage

```text
/run-sprint S001
```

## Prerequisites

- `.ai/planning/tasks.md` populated with tasks for the sprint
- Git branch `dev` exists on remote (or create locally per project policy)
- Factory harness skills at `.cursor/skills/factory/harness/`
- HITL tasks require human checkpoint before implementation
- Cursor 3.3+ with subagents / Build in Parallel

## Procedure

1. **Validate sprint ID**
   - Read `.ai/planning/sprints.md` — confirm sprint exists
   - If sprint status is `done`, report and exit unless user forces rerun

2. **Load harness playbook**
   - Apply `skills/harness/harness/SKILL.md` as lead agent behavior for this session

3. **Collect tasks**
   - Parse `.ai/planning/tasks.md` for all tasks where `**Sprint:**` matches `[sprint-id]`
   - Build parallel groups A, B, C… per harness rules
   - List runnable tasks (status `todo`, blockers satisfied)

4. **Update sprint status**
   - Set sprint to `active` in `.ai/planning/sprints.md` when starting

5. **Execute by parallel group**
   - For each group in order (A → B → C …):
     - Launch **Build in Parallel** — one subagent per task in group
     - Each subagent runs: implement → verify → review → close (max 2 revision cycles)
   - Wait for group completion before starting next group

6. **Update tasks.md** continuously as harness specifies

7. **Sprint end**
   - Run `skills/harness/retro/SKILL.md` for the sprint
   - Set sprint status `done` or `blocked` in `sprints.md`
   - Print harness summary table (tasks, PRs, blockers)

## Composer summary (required)

```markdown
## Sprint S[id] run finished

| Metric | Value |
|--------|-------|
| Tasks done | n |
| Tasks blocked | n |
| PRs opened | n |

**PRs:** [links]
**Blocked:** [Txxx — reason] or none
**Next:** /run-sprint S00y | /milestone-review M00x
```

## Failure handling

- Single task blocked after 2 cycles: continue other parallel tasks in same group if independent
- If all tasks in a group fail, stop and report; do not advance to next group without user ack

## Do not

- Merge to `staging` or `main`
- Run milestone CI (use `/milestone-review`)
