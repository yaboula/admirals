---
description: Cerrar session AI con sign-off + SESSION_LOG entry + commit
---

Ejecuta estos pasos EN ORDEN al cerrar session. No saltes ninguno.

## 1. Verificación done criteria

Revisa cada bullet done criteria de la session (del SPRINT_PLAN_S{N}.md o prompt inicial).

Escribe tabla:
| Done criterion | Estado | Nota |
|---|---|---|
| Criterion 1 | ✅/🔴 | Detalle |
| ... | ... | ... |

Si algún 🔴 → explica al founder qué falta + propone (a) fix ahora, (b) mover próxima session.

## 2. Smoke check

Ejecuta smoke check definido en SPRINT_PLAN session. Reporta resultado.

## 3. Entry SESSION_LOG

Append al final de `progress/SESSION_LOG.md` con formato exacto playbook §5.3:

```md
### S{N}.{M} — {Session title}

- **Fecha:** YYYY-MM-DD
- **Duración:** {estimada real}
- **Founder + Agent:** yaboula + {AI model name}
- **Sprint:** S{N} — {sprint name}
- **Perfil:** 🏗️/🔧/🔍/🎨/⚡/📝
- **Modelo:** {Opus 4.7 / Sonnet 4.6 / Gemini 3.1 Pro / GPT-5.3 Codex}
- **Goal:** {1 frase}
- **Status:** ✅ Done / 🟡 Partial / 🔴 Blocked

### Cambios
- Created: {list}
- Modified: {list}
- Deleted: {list}

### Decisiones tomadas
- {≤3 bullets}

### Issues pendientes
- {list o "ninguno"}

### Handoff próxima sesión ({next_session_id})
- **Modelo recomendado:** {model}
- **Goal:** {1 frase}
- **Pre-requisitos:** {docs a leer}
- **Files in scope:** {list breve}
- **Notas especiales:** {cualquier cosa que next AI necesita saber}

### Files in scope respetados
✅ / 🔴 {explica si hubo desviación}

---
```

Muestra la entry al founder para validación.

## 4. Founder valida entry

**ESPERA confirmación founder.** Si founder pide cambios → aplica + re-muestra.

## 5. Commit

// turbo
`git add .`

Muestra el diff al founder para revisión:
// turbo
`git status`

Commit con formato:
`git commit -m "S{N}.{M} {imperative description}"`

Pregunta founder si push ahora o esperar:
- Si sí: `git push`
- Si no: mantén local, commit queda listo.

## 6. Cierre

Imprime:
- "Session {ID} cerrada ✅."
- "Próxima session: {next_id}. Modelo recomendado: {model}. Duración estim: {h}."
- "Descanso recomendado antes de próxima."

**No continúes trabajando.** Session terminada. Founder decidirá cuándo próxima.
