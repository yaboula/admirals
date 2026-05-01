---
description: Iniciar nueva session AI con onboarding Admirals completo
---

Ejecuta estos pasos EN ORDEN al iniciar nueva session AI. No saltes ninguno.

## 1. Verificación estado repo

// turbo
Ejecuta `git status` para verificar repo limpio o solo WIP intencional.

Si hay cambios sin commit → pregunta founder si continuar o stash.

## 2. Lectura onboarding obligatoria

Lee EN ORDEN:

1. `docs/agents/00_BOOTSTRAP.md` (últimas secciones §2 estado actual + §4 mapa).
2. `docs/agents/03_founder_playbook.md` §4 (anatomía session) + §5 (SESSION_LOG protocol) + §6 (prompt template).
3. `progress/SESSION_LOG.md` últimas 3 entries (bottom of file).
4. `progress/SPRINT_PLAN_S{N}.md` del sprint activo.

## 3. Identificación session actual

Pregunta founder:
- ¿Cuál es el Session ID? (ej. S0.1, S2.3)
- ¿Confirma goal y scope del SPRINT_PLAN_S{N}.md?
- ¿Files in/out scope según SPRINT_PLAN?
- ¿Docs específicos adicionales a leer?

## 4. Lectura específica session

Lee los docs listed por el founder + aquellos referenciados en SPRINT_PLAN para esta session.

## 5. Confirmación de plan

Escribe resumen ≤200 palabras:
- "He leído [docs]. La session {ID} tiene goal {G}. Plan: 1) A, 2) B, 3) C. Files in scope: {list}. Files OUT: {list}. Done criteria: {N} bullets. ¿Procedo?"

**ESPERA green-light founder antes de tocar código.**

## 6. Ejecución

Procede ejecutando scope strict. No expandir sin permiso explícito.
