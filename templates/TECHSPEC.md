# Technical specification — [Project name]

> Aligns with `.ai/context/PRD.md`. Update when stack or constraints change.

---

## Stack

| Layer | Choice | Notes |
|-------|--------|-------|
| Runtime | Node.js [version] | |
| Framework | Next.js [version] App Router | |
| Language | TypeScript (strict) | |
| Package manager | pnpm | |
| Database | [e.g. PostgreSQL + Drizzle] | |
| Auth | [e.g. none / Clerk / custom] | |
| Hosting | [e.g. Vercel] | |
| CI | [e.g. GitHub Actions] | |

---

## Constraints

- [Hard constraint 1 — e.g. no external orchestrator in v1]
- [Hard constraint 2 — e.g. EU data residency]
- [Performance / bundle budget if any]

---

## Integrations

| Service | Purpose | Auth / secrets |
|---------|---------|----------------|
| [API name] | [Why] | `ENV_VAR_NAME` in server only |

---

## Repository layout

[Brief map of important directories the agent should know.]

---

## Branch model

```
main
  └── staging
        └── dev
              └── feature/[sprint]/[task-id]-[slug]
```

---

## Commands (project scripts)

| Script | Command | When |
|--------|---------|------|
| Typecheck | `pnpm typecheck` | Every task |
| Lint | `pnpm lint` | Every task |
| Test | `pnpm test` | Every task |
| Audit | `npm audit` or `pnpm audit` | Milestone review |

---

## ADR log

| ID | Date | Decision | Status |
|----|------|----------|--------|
| ADR-001 | [date] | [Title — e.g. Use Drizzle over Prisma] | accepted |

### ADR-001 — [Title]

**Context:** [Why we had to decide]

**Decision:** [What we chose]

**Consequences:** [Trade-offs]

---

## Security notes

- Secrets only in server contexts (Route Handlers, Server Actions, env).
- Validate inbound data at API boundaries.
- No secrets in logs or client bundles.
