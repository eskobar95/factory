---
name: retro
description: Structured sprint diary entry and factory improvement suggestions
---

# Retro skill

Run at **end of sprint** (after harness or `/run-sprint` completes).

## Inputs

- Sprint ID (e.g. `S001`)
- `.ai/planning/tasks.md` — final statuses for sprint tasks
- `.ai/planning/sprints.md`
- Memory of revision loops, blocked tasks, verify/review failures

## Diary entry

Append to `.ai/logs/diary.md` (never overwrite prior entries):

```markdown
---

## Sprint retro — S[id] — [YYYY-MM-DD]

**Milestone:** M[id]
**Duration:** [estimate or "session"]
**Tasks:** [done]/[total] done, [blocked] blocked

### What went well
- [Bullet]

### What failed or slowed down
- [Bullet — e.g. T003 verify failed twice on lint]

### Revision loops
| Task | Cycles | Resolved by |
|------|--------|-------------|
| T00x | 2 | [fix summary] or — |

### Harness notes
- Parallel groups used: A, B, …
- Subagent issues: [none / describe]

### Factory improvement suggestions
| Area | Suggestion | Target file |
|------|------------|-------------|
| skill | [e.g. add monorepo note to verify] | skills/verify/SKILL.md |
| rule | [e.g. stricter API validation] | rules/base.mdc |
| command | [e.g. clarify sprint ID format] | commands/run-sprint.md |

### Next actions
- [ ] /run-sprint S00y
- [ ] /milestone-review M00x
- [ ] Human: review open PRs on `dev`
```

## Self-improve loop (v1)

- Suggestions are **documentation only** — do not auto-open PRs to `eskobar/factory` unless user asks (v2 question in PRD)
- If user approves, they can copy suggestions into factory repo manually

## Optional: decisions log

For significant technical choices made during sprint, append short entries to `.ai/logs/decisions.md`:

```markdown
## [date] — [title]
**Context:** …
**Decision:** …
```

## Output to user

```markdown
## Retro complete — S[id]

Diary updated: `.ai/logs/diary.md`
Factory suggestions: [count] (see diary)
```
