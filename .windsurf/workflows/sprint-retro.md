---
description: Cerrar sprint con retro + tag + bump roadmap
---

Ejecuta al cerrar un sprint (después de la última session del sprint). Todo en una sola session corta ~30min.

## 1. Verificación sprint done criteria

Revisa `progress/SPRINT_PLAN_S{N}.md` sección "Done criteria SPRINT". Tabla estado per bullet.

Si algún 🔴 bloqueante → STOP, no cierres sprint. Plan: (a) slip sprint 1 sem extra, (b) mover item a S{N+1}.

## 2. Smoke test sprint-level

Ejecuta smoke test end-to-end de las features shipped este sprint según:
- `docs/qa/01_testing_protocol.md` (protocolo general).
- Sprint-specific smoke del SPRINT_PLAN si existe.

Reporta resultado.

## 3. Escribir retro

Crea `progress/SPRINT_RETRO_S{N}.md` con:

```md
# 📊 Sprint S{N} — Retrospectiva

- **Fecha cierre:** YYYY-MM-DD
- **Duración real:** {X} semanas (estimado: {Y})
- **Sessions ejecutadas:** {N} (estimado: {M})
- **Modelo más usado:** {model}
- **Founder time total aprox:** {H}h

## ✅ Qué fue bien

- Bullet 1
- Bullet 2
- Bullet 3

## 🔴 Qué fue mal

- Bullet 1
- Bullet 2

## 🔄 Qué cambio para próximo sprint

- Acción concreta 1
- Acción concreta 2

## 📈 Velocity

- Sessions: ejecutadas vs estimadas.
- Tiempo: horas reales vs estimadas.
- Ajuste factor: {1.0 = on-target, >1 = subestimamos, <1 = sobreestimamos}.

## 🎯 Next sprint

- S{N+1} — {nombre}.
- Foco: {prioridad}.
- Risks detectados: {list}.

---

**FIN RETRO S{N}**
```

## 4. Founder valida retro

Espera confirmación founder. Aplica cambios si pide.

## 5. Update roadmap

Edita `docs/planning/01_roadmap.md` §4.2 sprint correspondiente:
- Checkmark done criteria ✅ con fecha.
- Estado sprint: 🟢 ✅ CERRADO.
- Changelog entry nueva.

Si roadmap v bump necesario (p.ej. de v1.2 a v1.3) → consulta founder.

## 6. Update BOOTSTRAP si aplica

Si el sprint cambió estado proyecto significativamente (nueva oleada, nuevo pivot, etc.):
- Edita `docs/agents/00_BOOTSTRAP.md` §2.1 fase actual.
- Bump versión BOOTSTRAP si aplica.

Si no hay cambio significativo → skip.

## 7. Tag + commit

// turbo
`git add .`

Commit:
`git commit -m "S{N} sprint close — retro + roadmap update"`

Tag:
`git tag v0.{N}.0 -m "Sprint {N} complete"`

Push todo:
`git push --follow-tags`

## 8. Cierre

Imprime:
- "Sprint S{N} CERRADO ✅."
- "Tag v0.{N}.0 pushed."
- "Retro: `progress/SPRINT_RETRO_S{N}.md`."
- "Próximo sprint: S{N+1}. Planning Día 1 recomendado antes de empezar sessions."
- "Descanso recomendado 1-2 días antes S{N+1} kickoff."
