# /migrate-to-2.0

Audit an existing Factory 1.0 project and non-destructively migrate it to Factory 2.0.

## Usage

```text
/migrate-to-2.0
```

Run this **once** on an existing project when upgrading from Factory 1.0 to 2.0.

## What it does

1. **Audits** existing PRDs, commands, skills, and symlinks
2. **Reports** what will change — nothing is modified yet
3. **Asks for confirmation** before applying any changes
4. **Applies** changes non-destructively (no existing files deleted)

## Safe to run multiple times

The migration is idempotent. Re-running only applies missing pieces.

## Loads

`skills/productivity/migrate-to-2.0/SKILL.md`
