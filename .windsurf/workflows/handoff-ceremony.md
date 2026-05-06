---
description: Ejecutar Handoff Hx ceremony entre Tech Leads (DB→BE→SEC→FE→DO→Founder)
---

Ejecuta cuando contratos owner del Lead from están LOCKED y listos transferir al Lead to.

## 1. Pre-handoff checklist (responsibility Lead from)

Verifica per `03_CROSS_TEAM_CONTRACTS.md` §5.1:

- [ ] Todos contratos owner LOCKED v1.0.
- [ ] Sign-off triple obtenido (founder + owner + consumer).
- [ ] Artefactos canonical en paths definidos.
- [ ] Cross-references blueprint citadas con `@path:LINE`.
- [ ] Performance benchmarks documentados (donde aplica).
- [ ] Edge cases identificados + mitigations.
- [ ] Open questions resolved/deferred con rationale.
- [ ] Anti-tech-debt commitments respected.

Si algún check no pasa → STOP. Resuelve antes de handoff.

## 2. Crear handoff package file

// turbo
Crear archivo `docs/agents/teams/handoffs/H{N}_<from>_to_<to>.md` con template `03_CROSS_TEAM_CONTRACTS.md` §10.1:

```markdown
# Handoff H{N} — [From Lead] → [To Lead]

> Date: YYYY-MM-DD
> Status: 🟡 Pending sign-off

## 1. Contracts LOCKED en este handoff
- [ ] C-XX-NN v1.0 — `{path}` — {resumen 1 línea}
...

## 2. Resumen ejecutivo decisiones tomadas
...

## 3. Cuestionamientos blueprint + amendments propuestos al founder
...

## 4. Assumptions hechas + verificaciones pendientes
...

## 5. Performance test results
...

## 6. Pre-handoff checklist
- [x] Todos contratos LOCKED
- [x] Sign-off triple completo
- [x] Performance benchmarks
- [x] Edge cases documented
- [x] Open questions resolved/deferred

## 7. Sign-off
- Founder yaboula: ☐
- [From] Lead: ☐
- [To] Lead: ☐

## 8. Pendientes blocker / observaciones
...
```

## 3. Founder review + green-light

Founder review handoff package. Si green-light → SESSION_LOG entry HANDOFF-Hx con triple sign-off explícito.

Si rechaza → fix issues + retry.

## 4. SESSION_LOG entry HANDOFF-Hx

// turbo
Append `progress/SESSION_LOG.md`:

```markdown
---

### HANDOFF-H{N} — {From Lead} → {To Lead}

- Fecha: YYYY-MM-DD
- Artefactos LOCKED: {paths con citas @path}
- Sign-off: founder yaboula ✅ / {From} Lead ✅ / {To} Lead ✅
- Pendientes blocker: {si los hay}
- Próximo Lead arranca: {fecha tentativa}
- Handoff package: `docs/agents/teams/handoffs/H{N}_*.md`
```

## 5. Notificar Lead to

Lead from notifica al Lead to (vía founder o canal coordinación):

- "H{N} firmado. Tu onboarding arranca con prompt `prompts/<NN>_*.md`. Lectura crítica handoff package + contratos LOCKED upstream antes de tocar nada."

## 6. Post-handoff responsibilities

- **Lead from:** disponible Q&A 7 días post-handoff. Después → escalation founder si surgen issues.
- **Lead to:** lee handoff package + slice + prompt + brief antes de tocar nada. NO pregunta cosas claras en docs.

## 7. Commit

// turbo
`git add docs/agents/teams/handoffs/H{N}_*.md progress/SESSION_LOG.md`

Mensaje commit: `BANK-A handoff H{N} <from> to <to> signed`

Pregunta founder antes push.
