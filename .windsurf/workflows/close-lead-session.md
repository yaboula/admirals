---
description: Cerrar session AI Tech Lead con sign-off + SESSION_LOG entry + commit
---

Ejecuta EN ORDEN al cerrar session Tech Lead.

## 1. Resumen done criteria

Para cada done criterion del prompt activación + scope sesión:
- ✅ done — evidencia (file path + linea / sign-off / chaos test result).
- 🟡 partial — qué falta + bloqueador.
- 🔴 not done — razón + escalation needed.

## 2. Anti-tech-debt verification

Confirma respeto reglas:

- ✅ NO ESX legacy <1.10 fallback.
- ✅ NO multidivisa Phase A.
- ✅ NO TriggerClientEvent manual Bank state.
- ✅ NO hash-mutex code path.
- ✅ NO reconciliation sync inline.
- ✅ NO server boot sin defensive check.
- ✅ Idiomas docs ES + code EN estricto.
- ✅ Cross-references blueprint citadas con `@path:LINE`.
- ✅ Cuestionamientos blueprint documented `🟡 Deviation` blocks.
- ✅ Sin scope creep cross-team.

## 3. Open questions / deferred

Lista OQ resueltas + deferred a future session/Phase con rationale.

## 4. SESSION_LOG entry append

// turbo
Append entry al final `progress/SESSION_LOG.md` con formato:

```markdown
---

### BANK-{PHASE}.{N} — {Tech Lead role} — {short title}

- **Fecha:** YYYY-MM-DD
- **Duración:** ~Xh
- **Founder + Agent:** yaboula + Cascade ({modelo})
- **Sprint / Phase:** Phase A / sub-tag {bank-A.X}
- **Perfil:** {DB / BE / SEC / FE / DO}
- **Goal:** {goal}
- **Status:** ✅ Done / 🟡 Partial / 🔴 Blocked

#### Outcomes

- {outcome 1}
- ...

#### Done criteria

- [x] {criterion} ✅ evidence
- [ ] {criterion} 🟡 falta {X}

#### Anti-tech-debt verification

- [x] All commitments respected.

#### Files in scope respetados

- ✅ NO toco: {list out-of-scope}
- ✅ Modificados: {list in-scope}

#### Pendientes próximos

1. {next step}
2. ...

#### Próxima sesión sugerida

- Session ID: BANK-{PHASE}.{N+1}
- Goal: {goal}
- Modelo sugerido: {Sonnet 4.6 / GPT-5 / etc.}
- Files in scope: {list}
```

## 5. Commit

// turbo
`git add` files modified.

Mensaje commit format: `BANK-A.{M} {imperative present}` — ej.:
- `BANK-A.1 lock db schema v1.2 + immutable audit ledger triggers`
- `BANK-A.2 add core override module qbox + watchdog 30s`

Pregunta founder antes push.

## 6. Confirmación final

Mensaje final al founder:

```
Session [Lead role] cerrada.
✅ {N} done criteria PASS.
🟡 {N} partial.
🔴 {N} blocked → escalation.
SESSION_LOG entry appended.
Commit ready (waiting push approval).
Próxima session: BANK-{X}.{Y} — {goal}.
```

**Standby hasta founder green-light próxima session o handoff ceremony.**
