# /capture-rule

Persist a learned project-specific pattern as an enforceable Cursor rule.

## Usage

```text
/capture-rule "Always use db.query() not db.execute() for read operations"
/capture-rule   (interactive — agent asks what pattern to capture)
```

## When to use

- After fixing the same mistake twice in the same project
- After `/align` produces a project convention worth enforcing
- When a code review surfaces a recurring pattern
- When an ADR implies a coding constraint worth automating

## Loads

`skills/productivity/capture-rule/SKILL.md`

## Outputs

- `.factory/rules/project-[slug].mdc` — new project rule
- `.cursor/rules/project-[slug].mdc` — synced immediately (active in Cursor)

## Notes

- Rules use names `project-*.mdc` to avoid conflicts with kit rules
- Kit rules (`architecture.mdc`, `security.mdc`, etc.) are never overwritten
- Run `/factory-update` after adding rules to ensure they are synced
