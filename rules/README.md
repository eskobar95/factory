# Rules

Cursor rules (`.mdc` files) installed via `.cursor/rules` → symlink to `.factory/kit/rules`.

Rules apply automatically based on `globs` and `alwaysApply` in each file.

## Files

| Rule | File | Scope | Purpose |
|------|------|-------|---------|
| Base | [base.mdc](base.mdc) | All files | Strict TS, commits, branch naming |
| Next.js | [nextjs.mdc](nextjs.mdc) | `*.ts`, `*.tsx` | RSC defaults, no client secrets |
| Drizzle | [drizzle.mdc](drizzle.mdc) | Schema/migrations | Transactions, migration naming |
| Git | [git.mdc](git.mdc) | Always | Protected branches, PR format |
| Testing | [testing.mdc](testing.mdc) | Test files | Vitest, co-location |
| Security | [security.mdc](security.mdc) | Always | Secrets, webhooks, SSRF, authz |
| Architecture | [architecture.mdc](architecture.mdc) | Always | ADR enforcement loop, import boundaries |

## How rules interact with hooks

- **Rules** guide agent behavior (what to write, how to commit)
- **Hooks** enforce at edit/shell time (typecheck blocks, branch guards)

Both load from the kit symlink — update via `./.factory/kit/update.sh`.

## Customizing for a project

Prefer **project rules** in your repo's `.cursor/rules/` (non-symlinked files) for one-off overrides. Factory kit rules stay read-only in `.factory/kit/rules/`.

If you need a permanent Factory-wide change, edit here and open a PR in `eskobar-dev/factory`.
