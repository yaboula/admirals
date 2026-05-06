# SONAR Bank — Cross-Team Contracts Matrix v1.0

> **Documento de contratos cruzados entre Tech Leads.** Define qué interfaces formales debe entregar cada Lead, qué consume de cada otro, cómo se firman, cómo se versionan y cómo se resuelven los conflictos.
>
> **Modelo industria:** Contract-Driven Development (CDD) + RACI + Handoff System.
>
> **Audiencia:** los 5 Tech Leads + founder.
>
> **Fecha:** 2026-05-06.
> **Status:** 🟢 Locked post founder green-light.

---

## 1. Principios CDD aplicados a SONAR Bank

### 1.1 Contrato = artefacto inmutable post-firma

Un contrato firmado es **inmutable** hasta amendment formal. No se modifica unilateralmente.

### 1.2 Owner único

Cada contrato tiene **un único Lead owner**. El owner produce, mantiene, versiona y propone amendments. Los consumers consumen + objetan + firman acceptance.

### 1.3 Sign-off triple

Para LOCKED: founder yaboula ✅ + Lead owner ✅ + Lead(s) consumer ✅.

### 1.4 Versioning semántico

- `v0.x` — DRAFT iterativo durante review window.
- `v1.0` — primer LOCKED firmado.
- `v1.x` — amendments minor (no-breaking changes).
- `v2.0` — breaking changes (requiere triple sign-off completo de nuevo + impact analysis cross-team).

---

## 2. Matriz contratos canonical SONAR Bank

### 2.1 Contratos firmados durante Phase A

| ID | Contrato | Owner Lead | Consumer Leads | Artefacto canonical | Handoff trigger |
|---|---|---|---|---|---|
| **C-DB-01** | Database Schema v1.x | DB Lead | Backend, Security | `docs/technical/03_db_schema.md` v1.2 | H1 |
| **C-DB-02** | Migrations DDL files | DB Lead | DevOps (deploy ordering) | `migrations/<NNN>_*.sql` numbered | H1 |
| **C-DB-03** | Performance Benchmarks | DB Lead | Backend, DevOps, Founder | `docs/technical/03_db_schema.md` §performance + `progress/BENCHMARK_BANK_DB_v1.md` | H1 |
| **C-BE-01** | Events Catalog v1.3 | Backend Lead | Frontend, DevOps, Security | `docs/technical/02_events_catalog.md` v1.3 | H2 |
| **C-BE-02** | API Contracts (Callbacks) v1.3 | Backend Lead | Frontend, Security | `docs/technical/04_api_contracts.md` v1.3 | H2 |
| **C-BE-03** | State Machines v1.1 | Backend Lead + DB Lead joint | Security, Frontend | `docs/technical/05_state_machines.md` v1.1 | H2 |
| **C-BE-04** | Bridges Layer Spec v1.1 | Backend Lead | DevOps, Security | `docs/technical/07_bridges_compatibility.md` v1.1 | H2 |
| **C-BE-05** | StateBags Global Publishers Spec | Backend Lead | Frontend (consumers) | `docs/technical/02_events_catalog.md` §statebags-global-publishers | H2 |
| **C-SEC-01** | Audit Hooks Catalog | Security Lead | Backend (implementa hooks), DB (audit ledger queries) | `docs/technical/08_audit_hooks.md` v1.0 NEW | H3 |
| **C-SEC-02** | ACE Permissions Matrix | Security Lead | Backend (enforce server-side), Frontend (UI gating) | `docs/technical/08_audit_hooks.md` §ace-matrix | H3 |
| **C-SEC-03** | Autoraise Rules Canonical | Security Lead | Backend (compliance flags raiser), DB (compliance_flags table fixtures) | `docs/technical/08_audit_hooks.md` §autoraise-rules | H3 |
| **C-FE-01** | UI Component Contracts | Frontend Lead | Backend (signatures consumed), DevOps (builds) | `docs/design/03_bank_app_ui_contracts.md` v1.0 NEW | H4 |
| **C-FE-02** | Design Tokens JSON | Frontend Lead | All (visual consistency) | `resources/sonar_bank_app/web-src/design-tokens.json` | H4 |
| **C-FE-03** | UI Component Inventory | Frontend Lead | DevOps (Vite build matrix), Backend (callbacks consumed mapping) | `docs/design/03_bank_app_ui_contracts.md` §inventory | H4 |
| **C-DO-01** | Smoke Test Matrix | DevOps Lead | All (audit + signoff each test category) | `progress/SMOKE_BANK_PHASE_A_v1.md` v1.0 NEW | H5 |
| **C-DO-02** | fxmanifest + Load Order Spec | DevOps Lead | All (pre-coding alignment) | `docs/technical/06_fivem_standards.md` extends + per-resource fxmanifest reviews | H5 |
| **C-DO-03** | README Install Phase A | DevOps Lead | Founder (commercial), All (reference) | `resources/sonar_bank_app/README.md` + `resources/sonar_bridges/README.md` extends | H5 |
| **C-DO-04** | Sprint Plan Bank Phase A | DevOps Lead | All (orchestration) | `progress/SPRINT_PLAN_BANK_PHASE_A.md` v1.0 NEW | (orchestrate cross-team) |

### 2.2 Total contratos Phase A

**18 contratos formales** + sus dependencies. 5 owners + 5 handoffs + N cross-references.

---

## 3. Matriz RACI per contrato

**Leyenda:**
- **R** = Responsible (Lead que ejecuta el work).
- **A** = Accountable (Lead que firma + responde por la calidad).
- **C** = Consulted (Lead consultado durante draft).
- **I** = Informed (Lead notificado al sign-off).

| Contrato | DB Lead | Backend Lead | Security Lead | Frontend Lead | DevOps Lead | Founder |
|---|---|---|---|---|---|---|
| **C-DB-01** Schema | RA | C | C | I | I | A (sign) |
| **C-DB-02** Migrations | RA | I | I | I | C | A (sign) |
| **C-DB-03** Perf Benchmarks | RA | C | I | I | C | A (sign) |
| **C-BE-01** Events Catalog | C | RA | C | C | I | A (sign) |
| **C-BE-02** API Contracts | C | RA | C | C | I | A (sign) |
| **C-BE-03** State Machines | RA (joint) | RA (joint) | C | C | I | A (sign) |
| **C-BE-04** Bridges Spec | I | RA | C | I | C | A (sign) |
| **C-BE-05** StateBags Global | C | RA | I | C | I | A (sign) |
| **C-SEC-01** Audit Hooks | C | C | RA | I | I | A (sign) |
| **C-SEC-02** ACE Matrix | I | C | RA | C | C | A (sign) |
| **C-SEC-03** Autoraise Rules | C | C | RA | I | I | A (sign) |
| **C-FE-01** UI Components | I | C | C | RA | C | A (sign) |
| **C-FE-02** Design Tokens | I | I | I | RA | C | A (sign) |
| **C-FE-03** UI Inventory | I | C | I | RA | C | A (sign) |
| **C-DO-01** Smoke Matrix | C | C | C | C | RA | A (sign) |
| **C-DO-02** fxmanifest | I | C | C | C | RA | A (sign) |
| **C-DO-03** README Install | I | C | C | C | RA | A (sign) |
| **C-DO-04** Sprint Plan | C | C | C | C | RA | A (sign) |

---

## 4. Dependencies cross-contrato (DAG visual)

```
                                  ┌─────────────────────────────┐
                                  │  Founder green-light Phase A │
                                  └──────────────┬──────────────┘
                                                 ▼
                                  ┌─────────────────────────────┐
                                  │  C-DB-01 Schema v1.2        │ (DB Lead)
                                  │  C-DB-02 Migrations         │
                                  │  C-DB-03 Perf Benchmarks    │
                                  └──────────────┬──────────────┘
                                                 │ H1 handoff
                                                 ▼
              ┌──────────────────────────────────┴──────────────────────────────────┐
              ▼                                                                      ▼
    ┌────────────────────────┐                                          ┌────────────────────────┐
    │  C-BE-01 Events v1.3   │                                          │  C-BE-03 FSMs v1.1     │ (joint DB+BE)
    │  C-BE-02 API v1.3      │                                          └────────────────────────┘
    │  C-BE-04 Bridges v1.1  │
    │  C-BE-05 StateBags     │
    └────────────┬───────────┘
                 │ H2 handoff
                 ▼
    ┌────────────────────────┐
    │  C-SEC-01 Audit Hooks  │ (Security Lead audits BE + DB)
    │  C-SEC-02 ACE Matrix   │
    │  C-SEC-03 Autoraise    │
    └────────────┬───────────┘
                 │ H3 handoff
                 ▼
    ┌────────────────────────┐
    │  C-FE-01 UI Components │ (Frontend Lead consumes API + ACE + audit hooks)
    │  C-FE-02 Tokens        │
    │  C-FE-03 Inventory     │
    └────────────┬───────────┘
                 │ H4 handoff
                 ▼
    ┌────────────────────────┐
    │  C-DO-01 Smoke Matrix  │ (DevOps audits ALL + chaos test)
    │  C-DO-02 fxmanifest    │
    │  C-DO-03 README        │
    │  C-DO-04 Sprint Plan   │
    └────────────┬───────────┘
                 │ H5 handoff (Phase A done)
                 ▼
    ┌────────────────────────┐
    │  Founder green-light   │
    │  → Coding Phase A.1    │
    └────────────────────────┘
```

**Critical path:** DB → Backend → Security → Frontend → DevOps → Coding. Cualquier delay en un Lead bloquea downstream.

---

## 5. Protocolo Handoff (Hx)

### 5.1 Pre-handoff checklist (responsible: Lead from)

- [ ] Todos los contratos owner del Lead from están en versión `v1.0` LOCKED.
- [ ] Sign-off triple obtenido (founder + owner + consumer).
- [ ] Artefactos canonical existen en paths definidos en §2.1.
- [ ] Cross-references blueprint citadas con `@path:LINE`.
- [ ] Performance benchmarks documentados (donde aplica).
- [ ] Edge cases identificados + mitigations documentadas.
- [ ] Open questions resolved (o explicitamente marked deferred con rationale).

### 5.2 Handoff ceremony

1. **Lead from** publica handoff package en `docs/agents/teams/handoffs/Hx_<from>_to_<to>.md` con:
   - Lista contratos LOCKED + versions.
   - Resumen ejecutivo decisiones tomadas.
   - Cuestionamientos al blueprint + amendments propuestos al founder.
   - Lista de assumptions hechas + verificaciones pendientes.
   - Performance test results.
   - Pre-handoff checklist marked.
2. **Founder** review + green-light en SESSION_LOG entry.
3. **Lead to** confirma recepción + arranca onboarding (manifest §7).
4. **SESSION_LOG entry** ambos Leads:
   ```markdown
   ### HANDOFF-Hx — [from] → [to]
   - Fecha: YYYY-MM-DD
   - Artefactos LOCKED: [paths]
   - Sign-off: founder yaboula ✅ / [from] Lead ✅ / [to] Lead ✅
   - Pendientes blocker: [si los hay]
   - Próximo Lead arranca: [fecha tentativa]
   ```

### 5.3 Post-handoff responsibilities

- **Lead from:** disponible para Q&A consumer Lead durante 7 días post-handoff. Después de eso → escalation founder si surgen issues.
- **Lead to:** lee handoff package + slice + prompt + brief antes de tocar nada. NO pregunta cosas que están claras en docs.

---

## 6. Protocolo Conflictos cross-team

### 6.1 Cuando se activa

- Dos Leads no logran consenso sobre interfaz contractual.
- Lead A propone diseño que Lead B considera bloqueante (perf / seguridad / UX / arquitectura).
- Decisión tomada por un Lead afecta scope de otro Lead sin notificación previa.

### 6.2 Round 1 — Discusión técnica directa

- Lead que detecta el conflicto crea `docs/agents/teams/conflicts/conflict_<id>.md` con:
  - Descripción del problema.
  - Posición Lead A (con argumentos técnicos).
  - Posición Lead B (con argumentos técnicos).
  - Trade-offs identificados.
- Window 24h para discusión asincrónica + propuesta consensuada.
- Si llegan a consensus → updated docs + cierre conflict file con resolution.

### 6.3 Round 2 — Propuestas formales

- Si Round 1 no resuelve, ambos Leads escriben **propuesta formal** (max 1 página cada uno):
  - Diseño propuesto.
  - Trade-offs explicit.
  - Impact downstream.
  - Coste implementación.
  - Alternative considered + rejected (con razones).
- Founder review ambas propuestas.

### 6.4 Round 3 — Decisión founder vinculante

- Founder yaboula decide final.
- Decisión registrada en ADR nuevo si arquitectónica.
- ADR firmado + SSoTs actualizados + SESSION_LOG entry conflict resolved.

### 6.5 Tiempo máximo

- **Round 1:** 24h.
- **Round 2:** 24h.
- **Round 3:** 24h máx desde escalation.
- **Total max:** 72h conflict open. Pasado eso → bloqueo critical path → founder force resolution.

---

## 7. Amendments protocol (post-LOCKED)

### 7.1 Tipos de amendments

| Tipo | Descripción | Sign-off requerido |
|---|---|---|
| **Patch (v1.0 → v1.0.1)** | Typo / clarification / non-binding doc improvement. | Lead owner sólo. |
| **Minor (v1.0 → v1.1)** | Add field / new optional callback / new enum value. Non-breaking. | Lead owner + founder. |
| **Major (v1.0 → v2.0)** | Remove field / change signature / breaking schema change. | Founder + owner + ALL consumer Leads. |

### 7.2 Cuando proponer amendment

- Bug detected post-LOCKED requiere correction.
- Founder requirement change post-LOCKED.
- Performance issue surfaced en chaos test requiere refactor contract.
- New FiveM primitive published que mejora contract significativamente.

### 7.3 Procedure

1. Proposer Lead crea `docs/agents/teams/amendments/AMD_<contract>_<date>.md` con:
   - Contrato afectado + version current.
   - Tipo amendment (patch/minor/major).
   - Cambio propuesto + diff.
   - Razón.
   - Impact downstream.
2. Notify consumer Leads + founder.
3. Review window según tipo (patch: 24h, minor: 48h, major: 72h).
4. Sign-off según matrix §7.1.
5. Version bump + SSoT updated + SESSION_LOG entry.

---

## 8. Anti-patterns cross-team prohibidos

### 8.1 ❌ Side-channel agreements

Dos Leads NO acuerdan cambios fuera del protocolo CDD. Ej. Backend Lead pregunta a Frontend "¿podemos cambiar la signature de C012?" → Frontend dice "OK" → cambian sin amendment formal. **PROHIBIDO**.

### 8.2 ❌ Implicit assumptions

Lead asume comportamiento de otro dominio sin contrato explícito. Ej. "Asumo que DB returns rows ordenadas por created_at DESC" → no está en contrato → bug en Frontend cuando DB cambia order. **PROHIBIDO**. Toda assumption se documenta + verifica.

### 8.3 ❌ Scope creep cross-team

Lead resuelve problema de otro dominio "ya que estamos". Ej. Backend Lead añade UI hint para Frontend en API response. **PROHIBIDO** (M4 mandato Aislamiento).

### 8.4 ❌ Amendment unilateral post-LOCKED

Modificar contrato firmado sin amendment formal. **PROHIBIDO**, escalation immediate founder.

### 8.5 ❌ Founder approval skip

Sign-off implicit "creo que founder estaría de acuerdo". **PROHIBIDO**. Sign-off requiere acción explícita founder en SESSION_LOG.

### 8.6 ❌ Idioma mixing

Comentar código en español o documentar SSoT en inglés. **PROHIBIDO** per M5.

---

## 9. Checklist universal pre-firma contrato

Antes de proponer contrato como `v1.0` LOCKED, el owner Lead verifica:

- [ ] Documentación 100% en español.
- [ ] Code samples (si existen) 100% en inglés.
- [ ] Cross-references blueprint citadas con `@path:LINE`.
- [ ] Cuestionamientos al blueprint documentados (§Deviation from blueprint).
- [ ] Decisiones founder Q1-Q16 relevantes referenced.
- [ ] CP1-CP8 relevantes referenced (donde aplica).
- [ ] Performance benchmarks o targets explícitos (donde aplica).
- [ ] Edge cases identificados + mitigations.
- [ ] Open questions resolved o marked deferred con rationale.
- [ ] Anti-patterns dominio-específicos documentados.
- [ ] Cross-team contracts dependencies satisfied.
- [ ] Versioning explícito en header + changelog.
- [ ] Sign-off section con names placeholders ready (founder ✅ / owner ✅ / consumer ✅).

---

## 10. Templates rápidos

### 10.1 Template handoff package

Archivo: `docs/agents/teams/handoffs/Hx_<from>_to_<to>.md`

```markdown
# Handoff Hx — [From Lead] → [To Lead]

> Date: YYYY-MM-DD
> Status: 🟡 Pending sign-off / 🟢 Signed / 🔴 Blocked

## 1. Contracts LOCKED en este handoff
- [ ] C-XX-NN v1.0 — [path] — [resumen 1 línea]
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
- [ ] Todos los contratos LOCKED
- [ ] Sign-off triple completo
- [ ] Performance benchmarks
- [ ] Edge cases documented
- [ ] Open questions resolved/deferred

## 7. Sign-off
- Founder yaboula: ☐
- [From] Lead: ☐
- [To] Lead: ☐

## 8. Pendientes blocker / observaciones
...
```

### 10.2 Template conflict file

Archivo: `docs/agents/teams/conflicts/conflict_<id>.md`

```markdown
# Conflict #<id> — [Lead A] vs [Lead B]

> Opened: YYYY-MM-DD HH:MM
> Status: 🟡 Round 1 / 🟠 Round 2 / 🔴 Round 3 / 🟢 Resolved

## 1. Descripción del problema
...

## 2. Posición [Lead A]
**Diseño propuesto:** ...
**Argumentos técnicos:** ...

## 3. Posición [Lead B]
**Diseño propuesto:** ...
**Argumentos técnicos:** ...

## 4. Trade-offs identificados
...

## 5. Round 1 discusión (24h)
...

## 6. Round 2 propuestas formales (24h)
...

## 7. Round 3 founder decision (vinculante)
...

## 8. Resolution
**Adoptado:** [Lead A / Lead B / Hybrid]
**ADR firmado:** [si arquitectónica → ADR-XXX]
**Closed:** YYYY-MM-DD HH:MM
```

### 10.3 Template amendment

Archivo: `docs/agents/teams/amendments/AMD_<contract>_<date>.md`

```markdown
# Amendment <contract> — <date>

> Proposer: [Lead]
> Type: patch / minor / major
> Status: 🟡 Pending review / 🟢 Accepted / 🔴 Rejected

## 1. Contrato afectado
- ID: C-XX-NN
- Version actual: v1.x
- Version propuesta: v1.x+1 / v2.0

## 2. Cambio propuesto
**Antes:** ...
**Después:** ...
**Diff:** ...

## 3. Razón
...

## 4. Impact downstream
- [Lead consumer 1]: ...
- [Lead consumer 2]: ...

## 5. Sign-off
- Founder: ☐
- Owner Lead: ☐
- Consumer Lead 1: ☐
- Consumer Lead 2: ☐

## 6. Resolution
...
```

---

## 11. Versioning

| Version | Fecha | Cambios |
|---|---|---|
| **v1.0** | 2026-05-06 | Initial release. 18 contratos + RACI matrix + DAG dependencies + handoff/conflict/amendment protocols. |

— **Cross-Team Contracts Matrix LOCKED** post founder green-light 2026-05-06.
