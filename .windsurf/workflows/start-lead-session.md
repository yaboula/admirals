---
description: Iniciar nueva session AI como Tech Lead activado (DB / Backend / Security / Frontend / DevOps)
---

Ejecuta estos pasos EN ORDEN al iniciar nueva session AI Tech Lead. No saltes ninguno.

## 1. Verificación estado repo

// turbo
Ejecuta `git status` para verificar repo limpio o solo WIP intencional.

Si hay cambios sin commit → pregunta founder si continuar o stash.

## 2. Identificación rol

Pregunta founder (o confirma desde prompt activación):

- ¿Qué Tech Lead eres? (DB / Backend / Security / Frontend / DevOps)
- ¿Cuál es tu prompt activación canonical? (`docs/agents/teams/prompts/<NN>_*.md`)
- ¿Qué Handoff package previo aplica? (H1 / H2 / H3 / H4 / N/A si eres DB Lead arrancando)

## 3. Lectura onboarding obligatoria (10-step canonical)

Lee EN ORDEN:

1. `.windsurf/rules/bank.md` (workspace rules canonical Bank).
2. `docs/agents/teams/00_HANDOFF_MANIFEST.md` v1.0+.
3. `docs/agents/teams/01_SHARED_BRIEF.md` v1.0+.
4. `docs/agents/teams/02_INHERITED_BLUEPRINT_SLICES.md` v1.0+.
5. `docs/agents/teams/03_CROSS_TEAM_CONTRACTS.md` v1.0+.
6. `docs/agents/teams/slices/slice_<tu_dominio>.md`.
7. `docs/agents/teams/prompts/<tu_prompt>.md` completo.
8. `progress/SESSION_LOG.md` últimas 5 entries.
9. Handoff package previo si aplica: `docs/agents/teams/handoffs/H{N-1}_*.md`.
10. Contratos LOCKED upstream relevantes (per slice + handoff package).

## 4. Lectura contratos upstream LOCKED

Según tu rol:

- **DB Lead:** ninguno (eres primero).
- **Backend Lead:** C-DB-01 + C-DB-02 + C-DB-03.
- **Security Lead:** C-DB-* + C-BE-01/02/03/04/05.
- **Frontend Lead:** C-DB-* + C-BE-* + C-SEC-01/02/03.
- **DevOps Lead:** TODOS (C-DB-* + C-BE-* + C-SEC-* + C-FE-01/02/03).

## 5. Confirmation handshake

Escribe respuesta canonical (per template §13 de tu prompt activación):

```
Confirmación recepción [tu rol] onboarding completo.
✅ [10 checklist items leídos]
✅ Handoff package H{N-1} leído (si aplica).
✅ Contratos upstream LOCKED leídos.

Cuestionamientos preliminares al blueprint:
1. [...]
2. [...]

Próximo paso: research time-box [N min] + DRAFT v0.1 esperado [fecha].

Esperando green-light founder para arrancar.
```

**ESPERA green-light founder antes de tocar código / SSoTs.**

## 6. Research time-box

Per tu prompt §6 — research primitivas modernas dominio-específicas (30-90 min).

## 7. DRAFT v0.1 contratos owner

Producir DRAFT v0.1 de contratos owner asignados (per `03_CROSS_TEAM_CONTRACTS.md` §2.1 + tu slice §8).

Mantén scope strict. Cuestiona blueprint en `### 🟡 Deviation from blueprint` blocks.

## 8. Iteración + sign-off triple

v0.2, v0.3 según feedback. Sign-off triple founder + tú + consumer Lead(s) → v1.0 LOCKED.

## 9. Cierre + Handoff Hx

Al cerrar session aplica `/close-lead-session`. Cuando contratos LOCKED listos para handoff → aplica `/handoff-ceremony`.
