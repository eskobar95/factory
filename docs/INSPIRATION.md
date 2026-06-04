# Inspiration — capturing decisions for humans and AI

Factory patterns draw from solo and team experience with agentic development. Key external reference:

## Talk: BDD, ADR, PRD, WTF

**Speaker:** Michal Cichra (Safe Intelligence)  
**Event:** AI Engineer Europe 2026  
**Video:** [youtube.com/watch?v=504PvfXou5Y](https://www.youtube.com/watch?v=504PvfXou5Y)  
**Length:** ~13 min

### Core idea

Humans and LLMs share **limited context**. Decisions decay unless captured in durable, lookup-friendly documents — and **enforced** by tools, not prompts.

### How Factory maps to the talk

| Michal's concept | Factory implementation |
|------------------|------------------------|
| ADR (why + enforcement) | `.factory/context/ADR/` with Scope, Enforcement, How to fix — `adr-lookup` skill |
| PRD (light, journey-focused) | `.factory/context/PRD.md` with User journeys J001… |
| BDD (executable specs) | `.factory/specs/*.feature` + TECHSPEC testing section |
| Git hooks + CI parity | `.cursor/hooks/` + `fix-ci` skill |
| Skills shift loop focus | Planning vs harness skills; verify uses focused tests |
| Design system for UI agents | Optional `DESIGN-SYSTEM.md` template |
| Context compacts OK | `.factory/` files + `/handoff` — agents re-read docs |

### The harness loop (shared philosophy)

```
work → commit/push → hook/CI rejects → read ADR/doc → fix → iterate
```

Factory implements this via:

- **Hooks:** typecheck, lint, secrets, branch guards
- **Skills:** implement → verify → review → close → fix-ci
- **ADR lookup:** when enforcement fails, read why before guessing

### What Factory does not include (yet)

| Gap | Option |
|-----|--------|
| Cucumber wired by default | Project chooses runner in TECHSPEC |
| Spec27 agent validation | External product — different layer (runtime agent testing) |
| Automatic ADR id in lint messages | Configure per-project architecture linter |

### Related reading

- [ARCHITECTURE.md](ARCHITECTURE.md) — kit vs workspace
- [templates/specs/README.md](../templates/specs/README.md) — BDD folder
- [skills/planning/adr-lookup/SKILL.md](../skills/planning/adr-lookup/SKILL.md)

---

*May the spec be with you.*
