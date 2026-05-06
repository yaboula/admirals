---
description: Promover contrato DRAFT v0.x a LOCKED v1.0 con sign-off triple
---

Ejecuta cuando contrato DRAFT haya iterado v0.1 → v0.2 → v0.3 y está listo para LOCK.

## 1. Pre-lock checklist universal

Per `03_CROSS_TEAM_CONTRACTS.md` §9:

- [ ] Documentación 100% en español.
- [ ] Code samples 100% en inglés.
- [ ] Cross-references blueprint citadas con `@path:LINE`.
- [ ] Cuestionamientos blueprint documented `🟡 Deviation` blocks.
- [ ] Decisiones founder Q1-Q16 relevantes referenced.
- [ ] CP1-CP8 relevantes referenced (donde aplica).
- [ ] Performance benchmarks o targets explícitos (donde aplica).
- [ ] Edge cases identificados + mitigations.
- [ ] Open questions resolved o marked deferred con rationale.
- [ ] Anti-patterns dominio-específicos documented.
- [ ] Cross-team contracts dependencies satisfied.
- [ ] Versioning explícito en header + changelog.

## 2. Sign-off triple obtain

Per matriz RACI `03_CROSS_TEAM_CONTRACTS.md` §3:

- **Founder:** ✅ explicit en mensaje conversación o SESSION_LOG.
- **Owner Lead (tú):** ✅ implícit por producir.
- **Consumer Lead(s):** ✅ explicit review consultative comment + sign.

Si algún sign-off pending → STOP, resuelve.

## 3. Update version header

Edit contrato file:
- Header version: `v0.x` → `v1.0`.
- Status: `DRAFT` → `🟢 LOCKED`.
- Footer: `**LOCKED v1.0** post founder green-light YYYY-MM-DD.`

## 4. Update changelog table

```markdown
| **v1.0** | YYYY-MM-DD | LOCKED. {breve resumen scope} |
```

## 5. Update manifest pipeline status

// turbo
Edit `docs/agents/teams/00_HANDOFF_MANIFEST.md` §10 estado pipeline tabla — marcar contrato `🟢 LOCKED v1.0`.

## 6. SESSION_LOG entry

Append `progress/SESSION_LOG.md`:

```markdown
---

### CONTRACT-LOCK — {C-XX-NN} v1.0

- Fecha: YYYY-MM-DD
- Contrato: {ID + path canonical}
- Owner Lead: {Lead}
- Sign-off: founder ✅ / owner ✅ / consumer(s) ✅
- Resumen: {1 línea}
- Próximo: {handoff Hx ready / next contract draft}
```

## 7. Commit

// turbo
`git add` contract file + manifest + SESSION_LOG.

Mensaje commit: `BANK-A.{M} lock {C-XX-NN} v1.0` — ej. `BANK-A.1 lock C-DB-01 schema v1.0`.

Pregunta founder antes push.

## 8. Si todos contratos owner LOCKED → handoff ceremony

Si tu set completo de contratos owner están LOCKED → aplica `/handoff-ceremony` para transferir al Lead to.
