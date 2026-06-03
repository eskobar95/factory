---
name: review
description: Review implementation against acceptance criteria, edge cases, security, definition of done
---

# Review skill

Code review for **one task**. Assume verify already passed unless noted otherwise.

## Inputs

- Task section in `.ai/planning/tasks.md`
- Git diff: `git diff dev...HEAD` (or merge-base with `dev`)
- Changed files list

## Review checklist

### 1. Acceptance criteria

For each checkbox in **Acceptance criteria**:

- [ ] Met — cite file/line or test
- [ ] Not met — explain gap

### 2. Slice objective

Does the change deliver what **Slice objective** promises to the user?

### 3. Scope

- Nothing from **Out of scope** implemented?
- Only **Layers in scope** touched?

### 4. Edge cases

- Error paths handled (network, validation, empty state)?
- Loading/disabled states for UI tasks?

### 5. Security (from TECHSPEC + base rules)

- No secrets, tokens, or PII in logs
- Authz on sensitive mutations if applicable
- Input validation at API boundaries
- No unsafe `dangerouslySetInnerHTML` without sanitization

### 6. Definition of done

Confirm each DoD checkbox in task:

- typecheck / lint / tests (verify skill)
- no debug artifacts
- PR description will be needed at close

## Verdict

- **PASS** — all acceptance criteria met, no red security issues, scope respected
- **FAIL** — list concrete findings with severity

```markdown
## Review — T[id]

**Result:** PASS | FAIL

### Acceptance criteria
| # | Criterion | Status | Notes |
|---|-----------|--------|-------|
| 1 | ... | pass/fail | |

### Findings
| Severity | Finding | Suggested fix |
|----------|---------|---------------|
| high | ... | ... |
| medium | ... | ... |
| low | ... | ... |

### Security
[pass / issues]

### Scope
[pass / drift noted]

### Recommended action
[Proceed to close | Return to implement with numbered fixes]
```

## Revision guidance

On FAIL, findings must be **actionable** for implement agent (file + change). Max 2 revision cycles enforced by harness.

## Do not

- Merge PR
- Approve scope creep as "nice to have" without new task
