# Executable specs (BDD)

Human-readable, optionally **executable** behavior specs. Closes the loop between PRD user journeys and verification.

## Why this folder exists

Markdown PRDs describe intent. BDD scenarios (Gherkin) describe **observable behavior** in plain language — easier to review than typical AI-generated unit tests.

Inspired by [Michal Cichra's talk on ADR/PRD/BDD](https://www.youtube.com/watch?v=504PvfXou5Y) — see `docs/INSPIRATION.md`.

## Layout

```
.factory/specs/
  J001-checkout.feature    ← links to PRD journey J001
  J002-onboarding.feature
  README.md                ← this file
```

## Naming

- Prefix with PRD journey ID: `J001-short-slug.feature`
- One feature file per critical user journey (not per task)

## Gherkin template

See [example.feature](example.feature).

Each scenario should:

- Reference PRD journey ID in a comment or tag (`@J001`)
- Describe behavior a human can review without reading test code
- Map to step definitions in your test runner (Cucumber, Playwright BDD, etc.)

## When to write specs

| Phase | Action |
|-------|--------|
| `/to-prd` | Define journeys J001, J002 in PRD |
| `/to-backlog` | Note which tasks implement which journey |
| Before sprint | Add `.feature` files for critical paths |
| Harness verify | Run focused tests tied to changed journeys |

## Tooling (project choice)

Factory does not mandate a runner. Common options:

| Stack | Tool |
|-------|------|
| Node / Next.js | `@cucumber/cucumber` + Playwright |
| Node | `jest-cucumber` |
| Any | Playwright BDD-style specs in plain `.spec.ts` mirroring Gherkin |

Document the chosen runner in `.factory/context/TECHSPEC.md` under **Testing → BDD**.

## Linking to tasks

In `tasks.md`, add under each task:

```markdown
**PRD journey:** J001
**BDD scenarios:** J001-checkout.feature — "User completes checkout"
```

Harness `verify` runs focused tests when these fields are set.
