# Factory 2.0 — Personal AI Dev OS

**Kit:** installeres i hvert projekt via git submodule. Giver Cursor + Pi et fælles workflow — planlægning, sprint-execution, quality gates, og Pi harness.

---

## Hvad Factory giver dig

| Komponent | Hvad |
|-----------|------|
| **Planlægning** | `/align → /to-prd → /to-backlog` — PRD, TECHSPEC, tasks.md |
| **Sprint-execution** | `/run-sprint` — parallelle subagents, revision loop, CI gate |
| **Pi harness** | ultimate-pi (plan → execute → review) via MCP bridge i Cursor |
| **Quality gates** | deslop → thermo → check-compiler → sentrux → `/ship` |
| **Linear sync** | tasks.md er SSOT — `/linear-sync` synker til Linear |
| **Regler & hooks** | TypeScript, secrets, branch protection — altid aktive |

---

## To execution engines

Hvert task i `tasks.md` har et `**Engine:**`-felt:

```markdown
**Engine:** cursor   ← standard Cursor subagent (default)
**Engine:** pi       ← Pi/ultimate-pi harness (tungere, governed)
```

Pi-tasks kræver `.pi/` harness bootstrapped. Se [Pi-sektion](#pi-harness) nedenfor.

---

## Planlægnings-track

```
/align       → CONTEXT.md, ADRs
/to-prd      → PRD.md, TECHSPEC.md
/to-backlog  → milestones.md, sprints.md, tasks.md
/to-plan     → alle tre i én kommando
```

---

## Sprint-track (Cursor engine)

```
/bootstrap-branches   → dev + staging branches
/run-sprint S001      → parallelle tasks → PRs til dev
/run-task T003        → enkelt task
/ship T003            → quality gate + åbn PR
/milestone-review M01 → dev → staging PR
```

Task-pipeline: `implement → verify → review → close → fix-ci`

---

## Pi harness

ultimate-pi kører plan → execute → review med isolerede subagents og review gates.

### Forudsætninger

```bash
# Pi installeres manuelt fra https://pi.dev
pi install npm:ultimate-pi
pi install npm:@offbynan/pi-cursor-provider
pi → /login cursor          # Cursor OAuth
# OpenRouter key i .env: OPENROUTER_API_KEY=...

# Bootstrap per projekt
.factory/kit/scripts/bootstrap-pi.sh
pi → /harness-setup         # bootstrap .pi/ harness
```

### Model routing

```
.factory/kit/templates/pi/   ← kit defaults (read-only)
        ↓ install/update
.factory/pi/agents.policy.yaml  ← projekt SSOT (rediger her)
        ↓ sync-pi-config.sh
.pi/agents.policy.yaml          ← ultimate-pi runtime
```

**Standard model-setup:**

| Phase | Agent | Model |
|-------|-------|-------|
| Planning | decompose, synthesizer, author… | `openrouter/hy3-preview` |
| Planning research | implementation-researcher | `openrouter/glm-5.2` |
| Execution | executor (default) | `cursor/composer-2.5` |
| Execution | executor (heavy) | `cursor/glm-5.2` |
| Review | adversary | `cursor/grok-4.3` |
| Review | evaluator | `cursor/glm-5.2` |
| Review | tie-breaker | `cursor/gpt-5.5` |

Skift til heavy executor: sæt `harness/running/executor.model: cursor/glm-5.2` i `.factory/pi/agents.policy.yaml` → `sync-pi-config.sh`.

### MCP bridge (Cursor ↔ Pi)

`install.sh` kopierer `.cursor/mcp.json` med `pi-harness` MCP-server. Cursor-agenter kan kalde Pi direkte:

```
harness_auto("implement login flow")   # starter Pi i baggrunden
harness_status()                       # poll: phase, alive, recent output
harness_artifacts("executor-summary")  # læs Pi's arbejde
harness_artifacts("adversary-report")  # adversary findings
harness_abort()                        # stop Pi
```

MCP-server kræver `node` og Pi i PATH. Aktivér: Cursor → Settings → MCP → reload.

---

## Install / update

```bash
# Første gang — fra dit projekt-root
git submodule add https://github.com/eskobar95/factory.git .factory/kit
./.factory/kit/install.sh

# Opdater eksisterende projekt
./.factory/kit/update.sh
# Eller i Cursor: /factory-update

# Pin opdateringen
git add .factory/kit .cursor/ .kit-meta.json
git commit -m "chore: update factory kit"
```

---

## Projekt-layout (efter install)

```
dit-projekt/
  .factory/
    kit/                 ← submodule (read-only kit)
    context/             PRD.md, TECHSPEC.md, CONTEXT.md, ADR/, STACK.md
    planning/            milestones.md, sprints.md, tasks.md
    pi/                  agents.policy.yaml, models.profile.yaml
    policies/            security-reviewer.md, quality.gates.yaml
    handoff/             Pi task artifacts (auto-managed af MCP bridge)
    logs/                diary.md, decisions.md
    rules/               projekt-specifikke regler (project-*.mdc)
  .cursor/
    mcp.json             pi-harness MCP bridge
    rules/               kit + projekt regler
    commands/            slash commands
    skills/factory/      kit skills
    hooks/               typecheck, audit, guard scripts
  .pi/
    agents.policy.yaml   ← synket fra .factory/pi/ (ultimate-pi runtime)
    harness/             run artifacts, active-run.json
  .kit-meta.json         kit version + migration pointer
```

---

## Konfiguration

`.factory/factory.config.yaml` — commit denne fil:

```yaml
git:
  integration_branch: dev

execution:
  default_engine: cursor     # cursor | pi

pi:
  enabled: false             # true efter bootstrap-pi.sh
  session:
    run_model: composer-2.5  # heavy: glm-5.2

graphify:
  enabled: false

sentrux:
  enabled: false

linear:
  enabled: false
  team_id: ""

policies:
  security_reviewer: .factory/policies/security-reviewer.md
  quality_gates:     .factory/policies/quality.gates.yaml
  approval_policy:   .factory/policies/approval.policy.yaml
```

---

## Branch model

```
main ← du merger staging her
  └── staging ← milestone PR (/milestone-review)
        └── dev ← task PRs (/run-sprint)
              └── feature/S001/T003-slug
```

---

## Repo layout (dette kit)

```
factory/
  commands/
    planning/           align, to-prd, to-backlog, to-plan
    harness/            run-sprint, run-task, milestone-review
    productivity/       factory-update, capture-rule, linear-sync
  skills/
    harness/            implement, verify, review, close, fix-ci, ship
    planning/           align, to-prd, to-backlog
    productivity/       migrate-to-2.0, capture-rule, linear-sync
  templates/
    pi/                 agents.policy.yaml, models.profile.yaml
    policies/           security-reviewer.md, quality.gates.yaml
    mcp.json            Cursor MCP config template
  scripts/
    bootstrap-pi.sh     Graphify + Sentrux + Pi + MCP setup
    sync-pi-config.sh   Sync .factory/pi/ → .pi/
    install-pi-user-deps.sh   Fix ultimate-pi peer deps
    pi-mcp-server.js    Pi harness MCP server
  migrations/           Versionsmigrationer (001-pi-config.sh, …)
  rules/                base, nextjs, drizzle, git, security
  hooks/                typecheck, audit, guard scripts
  install.sh
  update.sh
```

---

## Skill-index

[`skills/INDEX.md`](skills/INDEX.md) — fuldt overblik over alle skills, hooks og regler.

---

## Krav

- Cursor (nyeste version anbefales)
- Node.js 18+ (til Pi MCP-server og harness)
- Pi installeret fra [pi.dev](https://pi.dev) (kun nødvendigt for Pi engine)
- pnpm (til `typecheck`, `lint`, `test` hooks)

---

## Licens

Public — solo brug.
