# SONAR Bank — Handoff Manifest v1.0

> **Documento maestro de transferencia.** Define la organización Tech Leads, el protocolo CDD (Contract-Driven Development), el Handoff System de relevos, y el orden de arranque de cada dominio.
>
> **Audiencia:** los 5 sub-agentes Tech Leads + founder yaboula + futuros agentes que se incorporen al pipeline SONAR Bank.
>
> **Fecha:** 2026-05-06.
> **Author packaging:** Cascade Sonnet 4.6 (rol Documentation Packaging Manager — post Q16 RESOLVED).
> **Status:** 🟢 Locked — green-light founder 2026-05-06.

---

## 1. Misión SONAR Bank — recordatorio

Construir la **infraestructura financiera más sólida del ecosistema FiveM**, con ambición técnica acercándose a Stripe / Revolut y superando ampliamente competidores actuales (NeedForScript Banking, RX Advanced Banking, Renewed-Banking, Codesign-bank, etc.).

**No es un MVP.** Phase A-E son slices técnicos de troceado de trabajo, no releases incrementales. El shipping milestone real es el tag final único `sonar-bank-v1` en Phase E.

**Blueprint heredado:** `@docs/design/proposals/03_bank_app_blueprint_v1.md` v1.2 (Q1-Q16 ✅ all resolved).

---

## 2. Roster Tech Leads (5 dominios financial-grade)

Cada Tech Lead es un agente AI dedicado con autonomía profesional + scope aislado + responsabilidad documental + accountability cruzada.

| Orden arranque | Lead | Dominio | Prompt bootstrap | Slice cherry-pick |
|---|---|---|---|---|
| **1º** | **Database & Data Integrity Lead** | DDL, migrations, indexes, partitioning, audit ledger inmutable, perf chaos 200 concurrent. | `prompts/01_database_integrity_lead.md` | `slices/slice_database.md` |
| **2º** | **Backend Money & Compatibility Lead** | Lua server, Bridges Layer, Core Override + Lite Mode, callbacks, mutex correlation-id, reconciliation, FSMs runtime. | `prompts/02_backend_money_compatibility_lead.md` | `slices/slice_backend.md` |
| **3º** | **Security, Compliance & Audit Lead** | Patrones autoraise, audit ledger queries, ACE permissions, anti-cheat, exploit prevention rate-limit + idempotency, watchdog Core Override. | `prompts/03_security_compliance_audit_lead.md` | `slices/slice_security.md` |
| **4º** | **Frontend & UX Premium Lead** | React NUI, Bank app 10 vistas, wireframes, motion 12 presets, sound canonical, identity SONAR ADR-017 paleta extendida, Vite dev page. | `prompts/04_frontend_premium_ux_lead.md` | `slices/slice_frontend.md` |
| **5º** | **DevOps, Integration & QA Lead** | fxmanifest, load order, smoke chaos engineering, CI/CD, README install + convars, release sub-tags, multi-framework matrix testing. | `prompts/05_devops_integration_qa_lead.md` | `slices/slice_devops.md` |

**Justificación orden:**

1. **DB primero** — fundación que todos consumen. Schema lock antes que callbacks.
2. **Backend segundo** — implementa contratos contra schema DB ya cerrado.
3. **Security tercero** — audita Backend + DB sin ser el constructor (segregación funciones).
4. **Frontend cuarto** — consume API contracts ya firmados Backend + DB (sin churn).
5. **DevOps quinto** — orquesta integración multi-resource + chaos test final.

---

## 3. Protocolo CDD — Contract-Driven Development

**Modelo de la industria adoptado oficialmente para SONAR Bank.** Los 5 Tech Leads NO escriben código hasta que sus contratos estén firmados.

### 3.1 Definición

> Un **Contrato** es un acuerdo formal entre dos dominios que especifica una interfaz inmutable: shape de datos, signature de funciones/callbacks, eventos, schema de tabla, autorizaciones, rate limits, idempotency keys, side effects, error codes.
>
> **Una vez firmado un contrato, ninguna de las partes puede modificarlo unilateralmente.** Modificaciones requieren propuesta formal + aceptación contraparte + version bump.

### 3.2 Tipos de contratos en SONAR Bank

| Tipo | Owner | Consumer(s) | Artefacto canonical |
|---|---|---|---|
| **Schema DB** | Database Lead | Backend Lead, Security Lead | `docs/technical/03_db_schema.md` (post promotion) |
| **API Contracts (Callbacks)** | Backend Lead | Frontend Lead, Security Lead | `docs/technical/04_api_contracts.md` (post promotion) |
| **Events Catalog** | Backend Lead | Frontend Lead, DevOps Lead | `docs/technical/02_events_catalog.md` (post promotion) |
| **State Machines (FSMs)** | Backend Lead + DB Lead jointly | Security Lead, Frontend Lead | `docs/technical/05_state_machines.md` (post promotion) |
| **Bridges Layer Spec** | Backend Lead | DevOps Lead, Security Lead | `docs/technical/07_bridges_compatibility.md` (post promotion) |
| **UI Component Contracts** | Frontend Lead | Backend Lead (callback signatures consumed) | `docs/design/03_bank_app_ui_contracts.md` (NEW post Frontend phase) |
| **Smoke Test Matrix** | DevOps Lead | All | `progress/SMOKE_BANK_PHASE_A_v1.md` (NEW post DevOps phase) |
| **Audit Hook Contracts** | Security Lead | All | `docs/technical/08_audit_hooks.md` (NEW post Security phase) |

### 3.3 Ciclo de vida contrato

```
DRAFT → REVIEW → SIGN-OFF → LOCKED → (futuro) AMENDMENT
```

- **DRAFT:** owner Lead propone v0.x. Discusión interna dominio.
- **REVIEW:** owner notifica consumer Lead(s). Review window mínima 24h. Comentarios + objeciones documentadas.
- **SIGN-OFF:** founder yaboula + Lead owner + Lead consumer(s) firman explícitamente.
- **LOCKED:** v1.0 publicado en SSoT path canonical. Inmutable hasta amendment.
- **AMENDMENT:** propose v1.x change + sign-off triple cycle de nuevo.

### 3.4 Anti-pattern explícitamente prohibido

❌ **"Yo escribo mi código, luego que se adapten los demás."** — esto rompe CDD. Cualquier Lead que escriba código sin contrato firmado es bloqueado por DevOps Lead en la fase smoke.

---

## 4. Handoff System — Sistema de Relevos formal

Cada transición de scope entre Leads es un **handoff documentado** con artefactos entregables + sign-off founder + actualización SESSION_LOG.

### 4.1 Tipos de handoff

| Handoff | From → To | Trigger | Artefactos entregables |
|---|---|---|---|
| **H1** Schema lock | DB Lead → Backend Lead | DB v1.0 LOCKED firmado | `03_db_schema.md` v1.x + migrations DDL files + perf benchmarks doc |
| **H2** API lock | Backend Lead → Security Lead | API contracts v1.0 LOCKED + FSMs v1.0 LOCKED | `04_api_contracts.md` v1.x + `05_state_machines.md` v1.x + `02_events_catalog.md` v1.x + `07_bridges_compatibility.md` v1.x |
| **H3** Audit hook lock | Security Lead → Frontend Lead | Audit hooks v1.0 LOCKED + ACE permissions matrix LOCKED | `08_audit_hooks.md` v1.x + audit ledger query patterns + autoraise rules canonical |
| **H4** UI contract lock | Frontend Lead → DevOps Lead | UI components v1.0 LOCKED + design tokens LOCKED + Vite dev page LIVE | `03_bank_app_ui_contracts.md` v1.x + design tokens JSON + component inventory |
| **H5** Smoke pass | DevOps Lead → Founder | Smoke chaos test PASS multi-framework matrix | `SMOKE_BANK_PHASE_A_v1.md` results + chaos test reports + release sub-tag candidate |

### 4.2 Handoff sign-off ceremony

Cada handoff requiere entry SESSION_LOG con formato:

```markdown
### HANDOFF-Hx — [from] → [to]
- Fecha: YYYY-MM-DD
- Artefactos: [paths]
- Sign-off: founder yaboula ✅ / [from] Lead ✅ / [to] Lead ✅
- Pendientes blocker: [si los hay]
- Próximo Lead arranca: [fecha tentativa]
```

### 4.3 Escalation protocol — conflictos cross-team

Si dos Leads no logran consenso sobre un contrato:

1. **Round 1:** Lead owner propone, Lead consumer objeta con argumentos técnicos. Doc la conversación en `docs/agents/teams/conflicts/conflict_<id>.md`.
2. **Round 2:** ambos Leads presentan propuestas formales con trade-offs. Founder revisa.
3. **Round 3 (final):** founder yaboula decide vinculante. Decisión registrada en ADR nuevo si arquitectónica.

**Tiempo máximo conflicto open:** 48h. Pasado eso → escalation automática founder.

---

## 5. Idiomas — regla absoluta

| Artefacto | Idioma |
|---|---|
| Documentación SSoT (md files) | **Español** |
| Discusión Tech Lead ↔ founder ↔ Tech Lead | **Español** |
| Issue trackers / SESSION_LOG entries | **Español** |
| Comentarios en código (Lua, JS/TS, SQL) | **Inglés** |
| Variables, funciones, classes, módulos | **Inglés** (snake_case Lua, camelCase JS/TS, PascalCase modules) |
| Git commit messages | **Inglés** (per `MEMORY[admirals.md]` — formato `S{N}.{M} {imperative present}`) |
| Strings UI player-facing | **Inglés default** + i18n bundle ES/FR/DE/PT (Frontend Lead define tooling) |
| Logs server (`print`) | **Inglés** (debugging cross-team) |
| Console banners ACE / errors | **Inglés** |

**Razón:** maximizar alcance comercial internacional + facilitar code review por terceros (open-source contributors potential) + estándar industry FiveM resources.

---

## 6. Hard rules globales (heredadas + nuevas)

### 6.1 Heredadas de `MEMORY[admirals.md]` (workspace rules canonical)

- Nunca llamar `exports['qb-*']`, `ESX.*`, `QBCore.*` directo fuera de `resources/sonar_bridges/adapters/*`.
- Nunca crear/modificar files en `docs/*` sin instrucción explícita founder (excepción: docs propios del Tech Lead en su scope dominio aprobado).
- Nunca modificar entries antiguas en `progress/SESSION_LOG.md` (append-only).
- Nunca ejecutar comandos destructivos sin aprobación founder explícita.
- Nunca push código que rompe boot del server (smoke check OBLIGATORIO).
- No XP genérico, no PvP combat, no pay-to-win, no QTEs obligatorios.
- No hallucinate numbers — todo número económico cita SSoT con `@path/to/file.md:LINE`.
- No hallucinate APIs — verificar con grep/fd antes de inventar function/export.
- Anti-pattern preámbulos validación ("¡Tienes razón!", "Excelente pregunta!", etc.) — **prohibido**, jump straight a la respuesta.

### 6.2 Nuevas — específicas SONAR Bank

- **CDD-first:** ningún Lead escribe código antes que su contrato esté firmado.
- **Cross-team contract immutability:** modificar contrato firmado requiere triple sign-off (owner + consumer + founder).
- **Idioma estricto:** docs ES + code EN. Mezclar dentro mismo artefacto = bloqueante review.
- **Anti-tech-debt commitments Phase A** (heredado §11.9.4 blueprint):
  - ❌ NO hash-based mutex code path.
  - ❌ NO ESX <1.10 fallback paths.
  - ❌ NO `TriggerClientEvent` manual publishers Bank state.
  - ❌ NO hot-patch sin defensive boot check.
  - ✅ Solo correlation-id metadata + StateBags global + reconciliation async + watchdog + transparency UX.

---

## 7. Lectura obligatoria onboarding (todos los Leads)

Orden estricto pre-arranque:

1. **Este manifest** — `docs/agents/teams/00_HANDOFF_MANIFEST.md` (al completo).
2. **Brief compartido** — `docs/agents/teams/01_SHARED_BRIEF.md` (visión + mandatos + Q1-Q16 + ADRs + reglas).
3. **Slices index** — `docs/agents/teams/02_INHERITED_BLUEPRINT_SLICES.md` (mapa cherry-picks).
4. **Cross-team contracts** — `docs/agents/teams/03_CROSS_TEAM_CONTRACTS.md` (matriz contratos + RACI + protocolo conflictos).
5. **Slice propio** — `docs/agents/teams/slices/slice_<dominio>.md` (cherry-pick blueprint de tu área).
6. **Prompt propio** — `docs/agents/teams/prompts/0X_<role>_lead.md` (tu mandato específico).
7. **Workspace rules** — `MEMORY[admirals.md]` (workspace identity + hard rules).
8. **Bootstrap canonical** — `docs/agents/00_BOOTSTRAP.md` v1.6+.
9. **Founder playbook** — `docs/agents/03_founder_playbook.md` §4-§6.
10. **SESSION_LOG últimas 5 entries** — `progress/SESSION_LOG.md` (BANK-DESIGN.0 → BANK-DESIGN.2 + handoffs anteriores si los hay).

**Tiempo estimado onboarding:** 60-90 minutos lectura + 30 minutos preguntas a founder antes de iniciar trabajo dominio.

---

## 8. Estado actual del pipeline

| Phase | Status | Owner | Outputs |
|---|---|---|---|
| **Q1-Q16 design** | ✅ DONE | PM Cascade | Blueprint v1.2 |
| **Packaging org** | 🟡 IN PROGRESS | PM Cascade (este edit) | 14 archivos `docs/agents/teams/` |
| **DB Lead arranque** | ⏳ PENDING | DB Lead (next agent) | `03_db_schema.md` v1.2 + migrations files |
| **Backend Lead arranque** | ⏸ BLOCKED por H1 | Backend Lead | `04_api_contracts.md` v1.3 + `05_state_machines.md` v1.1 + `02_events_catalog.md` v1.3 + `07_bridges_compatibility.md` v1.1 |
| **Security Lead arranque** | ⏸ BLOCKED por H2 | Security Lead | `08_audit_hooks.md` v1.0 + ACE matrix + autoraise rules canonical |
| **Frontend Lead arranque** | ⏸ BLOCKED por H3 | Frontend Lead | `03_bank_app_ui_contracts.md` v1.0 + design tokens + Vite dev page |
| **DevOps Lead arranque** | ⏸ BLOCKED por H4 | DevOps Lead | `SMOKE_BANK_PHASE_A_v1.md` + chaos test reports + sub-tag |
| **Coding Phase A.1** | ⏸ BLOCKED por todos contratos LOCKED | All Leads | `resources/sonar_bank_app/` + `resources/sonar_bridges/` extends |
| **Phase A done** | ⏸ BLOCKED por H5 | DevOps Lead → founder | Tag `bank-phase-a` candidate |

---

## 9. Próximos pasos inmediatos

1. **Founder green-light** este manifest + brief + slices + prompts (review opcional pero recomendado).
2. **DB Lead activation** — founder spawnea agente con prompt `prompts/01_database_integrity_lead.md` + lectura onboarding.
3. **DB Lead delivers v0.1 draft** → review window 24h → SIGN-OFF v1.0 → H1 handoff.
4. **Backend Lead activation** — repeat ciclo.
5. ... (cadena hasta DevOps).

---

## 10. Versioning + changelog manifest

| Version | Fecha | Author | Cambios |
|---|---|---|---|
| **v1.0** | 2026-05-06 | Cascade PM | Initial release post Q16 RESOLVED. 5 Tech Leads + CDD + Handoff system + idiomas + onboarding 10-step. |

**Próximas amendments esperadas:**
- v1.1 post DB Lead onboarding feedback.
- v1.2 post primer handoff H1 ejecutado (lessons learned).
- v1.3 post Phase A done (retrospective).

---

## 11. Contacto + escalation

| Rol | Persona/Agente | Cuándo contactar |
|---|---|---|
| **Founder** | yaboula | Sign-offs handoffs + decisiones arquitectónicas + conflict escalation Round 3. |
| **PM Documentation** | Cascade Sonnet 4.6 (rol packaging) | Solo durante Phase setup. Post-handoff H1 inicia, PM sale del pipeline. |
| **DB Lead** | TBD agent (next session) | Schema queries + migrations + perf optimization. |
| **Backend Lead** | TBD agent | Money flow + Bridges + callbacks + FSMs runtime. |
| **Security Lead** | TBD agent | Audit + ACE + exploit prevention + autoraise. |
| **Frontend Lead** | TBD agent | UI/UX premium + NUI React + identity SONAR. |
| **DevOps Lead** | TBD agent | Smoke + chaos + CI + release engineering. |

---

— **Manifest LOCKED** post founder green-light 2026-05-06 (este edit). Cualquier modificación posterior requiere amendment formal + version bump.
