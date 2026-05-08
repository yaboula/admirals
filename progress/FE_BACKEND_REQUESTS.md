# 📋 Frontend Lead → Backend Lead — Peticiones consolidadas Phase A

> **Owner:** Frontend & UX Premium Lead (Cascade BANK-FE.*).
> **Consumer:** Backend Money & Compatibility Lead (Standby — reactivation trigger Round 2 amendment cycle).
> **Status:** 🟡 **OPEN — DRAFTING active BANK-FE.0** — añade requests durante drafting C-FE-01/02/03 v0.1.
> **Versionado:** v0.1 (BANK-FE.0 inicial). Bump v0.2/v0.3 cada vez que añada/cierre items.
> **Cierre:** al cierre BANK-FE.LOCK, founder decide path:
>   - **Path A** — Backend Lead Standby reactivation Round 2 amendment cycle (incorporate items HIGH+MEDIUM al pre-LOCK Phase A).
>   - **Path B** — Diferir items a Phase A.1 / Phase B (post-LOCK Phase A).
>   - **Path C** — Resolver UI-side workaround (mock-only, accept gap como tradeoff aceptable).

---

## 0. Filosofía + protocolo

### 0.1 Por qué este archivo existe

El Frontend Lead opera bajo **Contract-Driven Parallel Development** (founder directive BANK-FE.0): drafting C-FE-01/02/03 contra contratos C-BE-01..05 v1.0.1 R1 LOCKED como única fuente de verdad, con Mock Data layer simulando backend real. Durante drafting + futura implementación UI, Frontend Lead **detectará gaps** — callbacks ausentes, shapes incompletas, eventos sin payload suficiente, ACE perms no granulares, etc.

**Política inquebrantable:** Frontend Lead **NO modifica unilateralmente** contratos Backend LOCKED. Cualquier gap detectado se registra aquí con severity + fundamentación + propuesta concreta. Al cierre BANK-FE.LOCK, founder decide path.

### 0.2 Severity classification

| Severity | Criterio | Decision path típico |
|---|---|---|
| 🔴 **HIGH** | Gap bloquea funcionalidad core Phase A — sin workaround mock realista. UI no puede entregarse sin amendment Backend. | Path A (Round 2 amendment Backend) mandatory. |
| 🟡 **MEDIUM** | Gap permite workaround mock funcional pero degrada UX final (extra latency, flicker, fricción usuario). | Path A preferred / Path B aceptable founder decision. |
| 🟢 **LOW** | Nice-to-have UX improvement — UI Phase A funciona perfectamente sin esto. | Path B/C — defer Phase B routine. |

### 0.3 Item template

Cada request sigue:

```
### [REQ-FE-XXX] Título corto
- **Severity:** 🔴 HIGH / 🟡 MEDIUM / 🟢 LOW
- **Detected during:** BANK-FE.X drafting <archivo>.md sección §Y.Z
- **Backend contract afectado:** C-BE-XX vY.Y.Y §X.Y
- **Gap concreto:** descripción técnica precisa
- **Workaround mock UI:** qué hace el Frontend mientras tanto
- **Propuesta resolución (Backend amendment):** spec concreta deseada
- **Criterio aceptación:** test/definition of done
- **Path recomendado:** A/B/C
- **Status:** OPEN / IN-DISCUSSION / RESOLVED-PATH-X / DEFERRED-PATH-B
```

---

## 1. Items abiertos

### REQ-FE-001 — Bootstrap snapshot consolidado UI mount

- **Severity:** 🟡 MEDIUM
- **Detected during:** BANK-FE.0 design lifecycle UI mount race-condition analysis (cuestionamiento Q6 founder APPROVED 2026-05-06).
- **Backend contract afectado:** C-BE-02 v1.0.1 R1 §9 (40+1 callbacks individuales) + C-BE-05 v1.0.1 R1 §2.2.2 (lazy publish balance per `playerJoining`).
- **Gap concreto:** UI mount Bank app requiere paralelizar ~5-7 callbacks separados para hydratar shell completo (C001b balance snapshot + C005 accounts list + C022 stocks list + C019 loans list + C027 recurring list + C039 business treasury list + C036 compliance flags self). Esto causa **flicker skeleton 200-500ms** durante settle de promesas async, contradiciendo art direction Tactile UI premium "fluidez espectacular sin parpadeos" (founder Q10).
- **Workaround mock UI:** Mock Data Layer simula respuesta consolidada determinística instant-resolved (`useBootstrapSnapshot()` hook) — mientras servidor real expone N callbacks separados, Frontend Lead implementa paralelización + cache TanStack Query con `staleTime: 30000` minimizing re-fetch. Aceptable Phase A, degradación inevitable bajo latencia red real.
- **Propuesta resolución (Backend amendment R2 sugerida):**
  ```
  Callback NEW: sonar:bank:bootstrap:snapshot
  Auth: AUTH-OWNER (citizen own bootstrap data only).
  Rate-limit: budget HIGH (capacity 30, refill 5/sec) — UI mount frequent acceptable.
  Idempotency: NO required (read-only).
  Request payload: { include?: ['accounts', 'stocks', 'loans', 'recurring', 'business', 'compliance'] (default all), schema_version: '1.0' }
  Response payload (200 OK):
  {
    status: 'ok',
    data: {
      balances: { main: number, savings: number },
      accounts: [{ account_id, account_class, balance, iban_masked, ... }, ...],
      stocks: { holdings_count: number, total_value_estimated: number },
      loans: { active_count: number, next_payment_at: epoch_ms | null, total_owed: number },
      recurring: { active_count: number, next_payment_at: epoch_ms | null },
      business_memberships: [{ company_id, role, treasury_visible: boolean }, ...],
      compliance: { has_active_flags: boolean, count: number },
      bridges_status: 'native_full' | 'lite_mode_active' | 'compromised_load_order' | 'framework_missing',
      schema_version: '1.0'
    },
    correlation_id: uuid_v4
  }
  Performance target p99: < 80ms (single round-trip vs 7 callbacks paralelos).
  ```
- **Criterio aceptación:**
  - Single callback retorna bundle completo sub-100ms p99 bajo carga 50 sessions concurrent.
  - Frontend `useBootstrapSnapshot()` hook mantiene mismo signature mock→real (1-line config swap).
  - Audit trail: 1 single audit ledger entry por bootstrap (vs 7 separadas) — mejora signal/noise ratio.
- **Path recomendado:** Path A (Round 2 amendment) post BANK-FE.LOCK si founder aprueba scope expansion Phase A. Path B (Phase A.1) aceptable degradation.
- **Status:** OPEN — anotado founder Q6 APPROVED 2026-05-06 BANK-FE.0.

---

### REQ-FE-002 — Recent recipients para Transfer Wizard Express mode

- **Severity:** 🟡 MEDIUM
- **Detected during:** BANK-FE.0 design Transfer Wizard 4-step vs 2-step express mode (cuestionamiento Q5 founder APPROVED 2026-05-06).
- **Backend contract afectado:** C-BE-02 v1.0.1 R1 §9.1 (C001 transfer) — sin endpoint para historial recipients.
- **Gap concreto:** UX premium "frictionless" requiere colapsar wizard 4-step → 2-step (`amount` + `confirm`) cuando recipient IBAN ya recibió transferencia del usuario en últimos 30 días. Sin endpoint, Frontend Lead debe (a) filtrar histórico C-BE-02 §9.X transactions list client-side (latencia + payload waste) o (b) renunciar a feature. Founder priorizó "rapidez ante todo" + Q5 APPROVED → backend support requerido para implementación clean.
- **Workaround mock UI:** Mock Data Layer expone `useRecentRecipients()` hook retornando array determinístico fixture (`[{ iban_masked, alias, last_used_at, count_30d }, ...]`). Frontend Lead implementa wizard adaptive UI completa contra mock.
- **Propuesta resolución (Backend amendment R2 sugerida):**
  ```
  Callback NEW: sonar:bank:transfer:recentRecipients
  Auth: AUTH-OWNER (own recent recipients only — privacy strict).
  Rate-limit: budget HIGH (capacity 30, refill 5/sec).
  Idempotency: NO required (read-only).
  Request payload: { window_days?: number (default 30), max_results?: number (default 10), schema_version: '1.0' }
  Response payload (200 OK):
  {
    status: 'ok',
    data: {
      recipients: [
        {
          iban_masked: string,        // 'ES12 ****  ****  3245' formato display-ready
          recipient_alias: string?,   // alias custom usuario o nombre player resolved
          last_used_at: epoch_ms,
          count_30d: number,
          last_amount: number
        },
        ...
      ],
      schema_version: '1.0'
    }
  }
  Performance target p99: < 50ms (DB query indexed, ya hay INDEX (sender_id, recipient_id, occurred_at)).
  ```
- **Criterio aceptación:**
  - Top 10 recipients ordered by `count_30d DESC, last_used_at DESC`.
  - Privacy: NO leak full IBAN — siempre masked display-ready format.
  - Frontend Lead activa "Express mode" wizard si recipient seleccionado ∈ recipients ∧ `count_30d >= 2`.
- **Path recomendado:** Path A (Round 2 amendment) — feature impactful UX founder APPROVED.
- **Status:** OPEN — anotado founder Q5 APPROVED 2026-05-06 BANK-FE.0.

---

### REQ-FE-003 — Compliance flag dismiss/acknowledge endpoint (badge UX)

- **Severity:** 🟢 LOW
- **Detected during:** BANK-FE.0 design Compliance Console UX (vista 5 — slice §4.5).
- **Backend contract afectado:** C-BE-02 v1.0.1 R1 §9.36 (C036 listFlags self) + §9.38 (C038 resolveFlag admin) — sin endpoint user-side dismiss/acknowledge "vi este aviso".
- **Gap concreto:** Usuario non-admin que tiene flag activo (e.g. AR-P01 large_transfer raised contra él) actualmente solo puede listarlo (C036) pero NO marcarlo "leído". UI Compliance Console muestra badge counter persistente hasta admin resuelve via C038, generating notification noise indefinida. UX premium 2026 espera "marcar como leído" pattern (Apple Notification Center class).
- **Workaround mock UI:** Frontend Lead implementa client-side `localStorage` flag `flag_acknowledged_<flag_id>` para hide badge temporary. Sobrevive reload mismo cliente, NO sync cross-device — aceptable Phase A degradation.
- **Propuesta resolución (Backend amendment R2 sugerida — PHASE B candidate):**
  ```
  Callback NEW (Phase B target): sonar:bank:compliance:acknowledge
  Auth: AUTH-OWNER (own flag only).
  Rate-limit: NORMAL.
  Idempotency: MANDATORY (avoid double-ack).
  Request payload: { flag_id: number, schema_version: '1.0' }
  Response payload: { status: 'ok', data: { flag_id, acknowledged_at } }
  Side effects:
    - DB UPDATE sonar_bank_compliance_flags SET user_acknowledged_at = NOW() WHERE flag_id = ? AND citizen_id = <auth>;
    - NO change a flag.status (sigue 'active' hasta admin resolve C038).
    - Audit hook NEW: 'compliance_flag_user_acknowledged' (LOW severity).
  ```
- **Criterio aceptación:**
  - Flag activo + user_acknowledged_at != null → UI hide badge counter (admin sigue viendo flag full).
  - Cross-device sync via DB.
  - Audit trail user-ack visibility para admin investigations.
- **Path recomendado:** Path B (Phase B feature). Path C (mock-only localStorage) Phase A acceptable.
- **Status:** OPEN — DEFERRED Phase B candidate.

---

### REQ-FE-004 — Server-side i18n message catalog para error codes ENUM §3.1

- **Severity:** 🟢 LOW
- **Detected during:** BANK-FE.0 design error handling canonical (C-FE-03 §error-codes).
- **Backend contract afectado:** C-BE-02 v1.0.1 R1 §3.1 (20 error codes ENUM canonical) — payloads response retornan `error.code` + opcional `error.message` (descripción human-readable EN baseline).
- **Gap concreto:** Frontend Lead i18n estrategia 4 locales (ES + EN + FR + DE) per slice §4.9 → mapping `error.code` ENUM a localized message implementado client-side `react-i18next` resource files. **Sin gap funcional bloqueante.** Refinement opcional: si Backend retorna también `error.message_key` ENUM (e.g. `'errors.bank.insufficient_funds'`) coordinated entre Backend Lead + Frontend Lead, evita drift entre catalog client + server logs (DevOps observability single message catalog).
- **Workaround mock UI:** Frontend Lead define 20 keys ENUM canonical en `web-src/i18n/<locale>/errors.json` mapeadas 1:1 a §3.1 codes. Aceptable Phase A.
- **Propuesta resolución (Backend amendment opcional Phase B):**
  ```
  Backend response shape extension (NON-breaking addition):
  error.message_key?: 'errors.bank.<domain>.<code_lowercase>'  // optional canonical key for i18n resolve client-side.

  Frontend Lead consume key via:
  i18n.t(error.message_key ?? `errors.${error.code.toLowerCase()}`)
  ```
- **Criterio aceptación:**
  - Backend Lead + Frontend Lead share canonical message_key catalog en docs/design/06_i18n_catalog.md (futuro Phase B).
  - DevOps observability logs incluyen `message_key` para grep cross-locale.
- **Path recomendado:** Path B (Phase B routine) — no urgente.
- **Status:** OPEN — DEFERRED Phase B candidate.

---

### REQ-FE-005 — `bank.status.transition` payload exposed metric for UI badge tooltip

- **Severity:** 🟢 LOW
- **Detected during:** BANK-FE.0 design CP8 UI badge footer always visible (cuestionamiento Q11 founder APPROVED 2026-05-06).
- **Backend contract afectado:** C-BE-01 v1.0.1 R1 §4.1 row `sonar:bank:status:transition` payload `{ correlation_id, state_from, state_to, reason, watchdog_metrics, occurred_at }` — admin-only ACE `sonar.bank.govt.audit.full` OR `sonar.devops.bank.diagnostics`.
- **Gap concreto:** UI badge footer **non-admin** debe mostrar SOLO el estado actual (`bank.bridges.status` StateBag CP1-A) con tooltip texto simple per Q11 founder. **Sin gap funcional.** Refinement: si admin/devops connectado, podría enriquecer tooltip con `watchdog_metrics` (correlation-id ratio + sample size) para diagnostic rapid sin abrir Government Console — feature DevOps-tier nice-to-have.
- **Workaround mock UI:** Tooltip non-admin = texto simple ENUM mapeado i18n (`'Servicio bancario disponible'` / `'Modo seguro'` / `'Modo comprometido — contacta admin'` / `'Servicio no disponible'`). Tooltip admin/devops Phase B consume `sonar:bank:status:transition` event.
- **Propuesta resolución:** NO amendment Backend necesario. Phase A: text-only tooltip. Phase B: admin tooltip enriquecido reactive a NetEvent — Frontend Lead implementa sin Backend changes.
- **Path recomendado:** Path C (mock + Phase B feature non-admin). NO amendment Backend.
- **Status:** OPEN — RESOLVED-PATH-C no Backend amendment necesario.

---

### REQ-FE-006 — `gov.census.list` consolidated registry endpoint (Treasury Bureau Census Lens)

- **Severity:** 🔴 HIGH
- **Detected during:** BANK-A.GOVT NODO 2 implementation — `src/govt/routes/Census.tsx` + `src/govt/data/queries/govtCensus.ts` mock-backed.
- **Backend contract afectado:** NEW callback (no precedent en C-BE-02 v1.0.1 R1). ACE consumer: `sonar.bank.govt.audit.full` (P04). Adjacent: existing `sonar.bank.govt.audit.full` ya cubre lectura ledger pero NO expone índice consolidado de citizens con métricas agregadas.
- **Gap concreto:** Census Lens muestra una tabla paginable de ciudadanos con: `cid, alias, status, taxCompliance, riskScore, riskLevel, totalHoldings, accountCount, flagCount, lastActivityAt, residencyDays`. Consumir 8+ callbacks por fila × 50+ filas violaría perf budget + abriría amplification attack surface. Necesario callback **consolidated read** del registro.
- **Workaround mock UI:** `listCensusMock(filters)` en `src/govt/data/mock/govtCensus.ts` — 56 ciudadanos deterministas via splitmix32 PRNG, filtrado in-memory por `search/status/compliance/riskLevel`. Cumple Phase A demo, no soporta paginación real ni cardinalidad de servidor.
- **Propuesta resolución (Backend amendment / NEW Phase A.GOVT contract):**
  ```
  Callback NEW: sonar:bank:gov:census:list
  Auth: AUTH-ROLE — IsPlayerAceAllowed(source, 'sonar.bank.govt.audit.full').
  Rate-limit: budget MEDIUM (capacity 12, refill 2/sec) — typical operator pulls registry every 30-60s.
  Idempotency: NO (read-only).
  Request payload: {
    filters: { search?: string<=64, status?: 'active'|'flagged'|'sanctioned'|'exempt'|'all', compliance?: 'current'|'overdue'|'pending'|'exempt'|'all', risk_level?: 'low'|'medium'|'high'|'critical'|'all' },
    pagination: { offset?: int>=0 (default 0), limit?: int<=100 (default 50) },
    sort?: 'risk_desc' | 'last_activity_desc' | 'flag_count_desc' (default 'risk_desc'),
    schema_version: '1.0'
  }
  Response payload (200 OK): {
    status: 'ok',
    data: {
      items: [{ cid, alias_masked, status, tax_compliance, risk_score: int 0-100, risk_level, total_holdings_cents: bigint, account_count: int, flag_count: int, last_activity_at: epoch_ms, residency_days: int }, ...],
      total_count: int,    // unfiltered universe size
      filtered_count: int, // matches before pagination
      schema_version: '1.0'
    },
    correlation_id: uuid_v4
  }
  Side effects: append audit ledger entry { actor: govt_operator_cid, action: 'CENSUS_QUERY', filter_hash, result_count, occurred_at }.
  Perf target p99: <= 80ms with 5000 citizens (DB index on status + risk_score composite).
  ```
- **Criterio aceptación:** Backend retorna 50 items en <= 80ms p99 con filtros activos. UI swap mock → real sin cambios shape (`GovtCitizenSummary` contract estable). Audit hook CENSUS_QUERY fired per request.
- **Path recomendado:** Path A (Phase A.GOVT extension) — bloquea persistencia real del NODO 2.
- **Status:** OPEN — awaiting Backend Lead reactivation Phase A.GOVT cycle.

---

### REQ-FE-007 — `gov.census.detail` consolidated citizen profile endpoint

- **Severity:** 🔴 HIGH
- **Detected during:** BANK-A.GOVT NODO 2 — `CitizenDetail.tsx` consume `useGovtCitizenDetailQuery(cid)` mock-backed.
- **Backend contract afectado:** NEW callback. Auth: `sonar.bank.govt.audit.full` (P04). Cross-domain: cruza con `bank.audit.self` (citizen-self) pero scope opera DIFERENTE — operator govt mirando OTRO cid.
- **Gap concreto:** El detail panel del Census necesita en una sola llamada: `summary fields + primary_iban_masked + recent_activity[]<=20 + flags_open[]<=10 + tax_status_snapshot`. 4-5 callbacks separados causarían flicker similar al gap REQ-FE-001 sobre bootstrap consumer.
- **Workaround mock UI:** `getCensusDetailMock(cid)` retorna estructura completa instantánea — soporta UX target sin latencia red real.
- **Propuesta resolución (Backend amendment / NEW Phase A.GOVT contract):**
  ```
  Callback NEW: sonar:bank:gov:census:detail
  Auth: AUTH-ROLE — IsPlayerAceAllowed(source, 'sonar.bank.govt.audit.full').
  Rate-limit: budget MEDIUM (capacity 20, refill 4/sec) — operator may sweep multiple citizens.
  Idempotency: NO (read-only).
  Request payload: { cid: string<=32, schema_version: '1.0' }
  Response payload (200 OK): {
    status: 'ok',
    data: {
      summary: { /* same shape as gov.census.list item */ },
      primary_iban_masked: string,    // never raw; reveal via separate AUTH-ROLE_OR_OWNER if needed Phase B
      recent_activity: [{ id, timestamp_ms, type: 'transfer_out|transfer_in|card_charge|tax_payment|flag_raised|sanction_applied|subsidy_received', amount_cents: bigint signed, description, counterparty_cid_masked? }, ...up_to_20],
      flags: [{ id, raised_at_ms, severity: 'info|low|medium|high|critical', status: 'open|reviewing|resolved|dismissed', summary }, ...up_to_10_open_first],
      tax_status: { bracket_code, period_obligation_cents, paid_cents, outstanding_cents },
      schema_version: '1.0'
    },
    correlation_id: uuid_v4
  }
  Error codes: CITIZEN_NOT_FOUND (404), AUTH_ACE_DENIED (403).
  Side effects: append audit ledger { actor: govt_operator_cid, action: 'CENSUS_DETAIL_VIEW', target_cid, occurred_at }.
  Perf target p99: <= 120ms (joins citizen+accounts+ledger+flags+tax).
  ```
- **Criterio aceptación:** Single-roundtrip detail load. Audit ledger fires CENSUS_DETAIL_VIEW (Security Lead requirement — operator accountability). UI swap mock → real sin cambios shape (`GovtCitizenDetail` contract estable).
- **Path recomendado:** Path A — bloquea persistencia real NODO 2.
- **Status:** OPEN — awaiting Backend Lead reactivation.

---

### REQ-FE-008 — Risk score computation contract (Backend authoritative)

- **Severity:** 🟡 MEDIUM
- **Detected during:** BANK-A.GOVT NODO 2 — risk gauge en `CitizenDetail.tsx` muestra score 0-100 + level enum.
- **Backend contract afectado:** NEW spec — risk score formula must be Backend-authoritative (Security Lead jurisdiction probably). Frontend never computes or guesses.
- **Gap concreto:** Mock genera `riskScore` arbitrario (`splitmix32` deterministic). En producción, fórmula compuesta debe considerar: velocity 24h, compliance overdue ratio, exposure aggregate, historic flag count, dormancy reactivation. Source of truth = Backend (probably Security Lead audit ledger crons). Frontend SOLO pinta.
- **Workaround mock UI:** Mock score arbitrario; UI ya respeta contract `risk_score: int 0-100, risk_level: derived buckets <25 low / <55 medium / <80 high / >=80 critical`.
- **Propuesta resolución:** Backend Lead + Security Lead jointly especifican fórmula + cron periódico (sugerencia: cada 5min update risk_score per citizen activo). Frontend lee field — no calcula nada. Bucketing low/medium/high/critical via thresholds DOCUMENTADOS centralmente (NO Frontend hardcoded).
- **Criterio aceptación:** `c_be_XX_risk_scoring_v1.md` published spec con fórmula + buckets + recompute cadence. UI elimina hardcoded bucketing si Backend retorna `risk_level` directo.
- **Path recomendado:** Path A (joint Backend + Security spec) preferido / Path B aceptable si Phase A.GOVT inicial usa formula simplificada.
- **Status:** OPEN — joint spec required.

---

### REQ-FE-009 — `gov.sanction.*` mutation callbacks (Sanctions module — NODO 6 imminent)

- **Severity:** 🔴 HIGH
- **Detected during:** BANK-A.GOVT NODO 2 closing — `CitizenDetail` action footer expone `Open sanction` + `Issue subsidy` botones disabled awaiting backend.
- **Backend contract afectado:** NEW callbacks. Auth: existing ACE `sonar.bank.govt.compliance.admin` per C-BE-02 §2.2 OR new `sonar.bank.govt.sanction.write`.
- **Gap concreto:** Sanctions module (NODO 6) necesita 4 mutations: freeze account/card, lift freeze, apply fine (debit citizen → state account), close flag with verdict. Cada una tiene side effects DB + audit ledger + StateBag broadcast invalidación al consumer Bank UI del afectado.
- **Workaround mock UI:** N/A — NODO 6 entrega UI con buttons disabled hasta callbacks reales. Spike puede mockearse pero side-effects DB requieren backend real para reflejar en consumer Bank app del afectado (StateBag invalidación cross-resource).
- **Propuesta resolución (Backend amendment / NEW Phase A.GOVT contract):**
  ```
  Callbacks NEW (4):
  1. sonar:bank:gov:sanction:freeze_account
     Request: { target_cid, account_id, reason: string<=200, idempotency_key }
     Side effects: UPDATE accounts SET frozen=true, frozen_by=operator_cid, frozen_at=NOW. Audit { action: 'SANCTION_FREEZE_ACCOUNT' }. StateBag broadcast `sonar:bank:account:frozen` consume by consumer Bank UI of target.
     Perf p99: <= 60ms.
  2. sonar:bank:gov:sanction:lift_freeze
     Request: { target_cid, account_id, reason, idempotency_key }
     Symmetric inverse.
  3. sonar:bank:gov:sanction:apply_fine
     Request: { target_cid, amount_cents > 0, reason, idempotency_key }
     Side effects: atomic DB tx — debit target main account, credit state treasury account, append ledger entries both sides, audit { action: 'SANCTION_FINE' }. NetEvent target citizen for client toast.
     Errors: INSUFFICIENT_FUNDS, ACCOUNT_FROZEN, AUTH_ACE_DENIED.
     Perf p99: <= 90ms.
  4. sonar:bank:gov:sanction:close_flag
     Request: { flag_id, verdict: 'resolved' | 'dismissed', notes?: string<=500, idempotency_key }
     Side effects: UPDATE flags SET status=verdict, closed_by, closed_at, notes. Audit.
     Perf p99: <= 50ms.
  
  All 4: Auth AUTH-ROLE 'sonar.bank.govt.compliance.admin'. Rate-limit budget LOW (capacity 6, refill 1/sec) — sanctions infrequent + manual review expected. Idempotency MANDATORY (mutations).
  ```
- **Criterio aceptación:** 4 callbacks LOCKED + audit ledger entries verifiable + StateBag broadcasts received by consumer Bank UI of target within <= 200ms. Frontend NODO 6 ships con buttons disabled si Backend no listo (graceful) o functional si Backend ready.
- **Path recomendado:** Path A (Phase A.GOVT mandatory) — sin esto NODO 6 no es funcional, solo shell.
- **Status:** OPEN — awaiting Backend Lead reactivation.

---

### REQ-FE-010 — `gov.subsidy.disburse` + `gov.subsidy.grant` callbacks (Subsidies module — NODO 7)

- **Severity:** 🔴 HIGH
- **Detected during:** BANK-A.GOVT NODO 2 closing — Subsidies module (NODO 7) plan.
- **Backend contract afectado:** NEW callbacks. Auth: existing ACE `sonar.bank.govt.subsidy.write` per C-BE-02 §2.2 (already provisioned in matrix).
- **Gap concreto:** Subsidies module necesita 2 mutations: disburse to citizen (state → citizen account) y grant to business (state → business treasury). Side effects atomic DB tx + audit + StateBag broadcasts.
- **Workaround mock UI:** N/A. NODO 7 ship con buttons functional contra backend real, o disabled awaiting.
- **Propuesta resolución:**
  ```
  Callbacks NEW (2):
  1. sonar:bank:gov:subsidy:disburse_to_citizen
     Auth: AUTH-ROLE 'sonar.bank.govt.subsidy.write'.
     Request: { target_cid, amount_cents > 0, program_code: string<=32, reason: string<=200, idempotency_key }
     Side effects: atomic DB tx — debit state treasury account, credit target main account, append ledger entries both sides, audit { action: 'SUBSIDY_DISBURSE', program_code }. NetEvent target citizen toast.
     Errors: STATE_TREASURY_INSUFFICIENT, TARGET_FROZEN, INVALID_PROGRAM.
     Perf p99: <= 90ms.
  2. sonar:bank:gov:subsidy:grant_to_business
     Auth: AUTH-ROLE 'sonar.bank.govt.subsidy.write'.
     Request: { target_company_id, amount_cents > 0, program_code, reason, idempotency_key }
     Symmetric for business treasury account.
  
  Both: Rate-limit budget MEDIUM (capacity 10, refill 1/sec) — disbursements common during programs. Idempotency MANDATORY.
  ```
- **Criterio aceptación:** 2 callbacks LOCKED + audit ledger SUBSIDY_DISBURSE entries + StateBag broadcasts. Frontend NODO 7 functional.
- **Path recomendado:** Path A — bloquea NODO 7 functional.
- **Status:** OPEN — awaiting Backend Lead reactivation.

---

## 2. Items resueltos / cerrados

_(empty — drafting BANK-FE.0)_

---

## 3. Estadísticas

| Métrica | Valor |
|---|---|
| Total items | 10 |
| HIGH abiertos | 4 (REQ-FE-006, REQ-FE-007, REQ-FE-009, REQ-FE-010) |
| MEDIUM abiertos | 3 (REQ-FE-001, REQ-FE-002, REQ-FE-008) |
| LOW abiertos | 3 (REQ-FE-003, REQ-FE-004, REQ-FE-005) |
| RESOLVED | 0 (REQ-FE-005 path-C self-resolved) |
| Path A target (Backend amendment / Phase A.GOVT cycle) | 6 (REQ-FE-001, REQ-FE-002, REQ-FE-006, REQ-FE-007, REQ-FE-009, REQ-FE-010) |
| Path A/B target (joint spec) | 1 (REQ-FE-008) |
| Path B target (Phase B defer) | 2 (REQ-FE-003, REQ-FE-004) |
| Path C target (UI workaround) | 1 (REQ-FE-005) |

---

## 4. Cross-references

- **Contratos Backend upstream consumed:** `@docs/technical/bank_phase_a/c_be_01..05_*.md` v1.0.1 R1 LOCKED.
- **Contrato Security upstream consumed:** `@docs/technical/08_audit_hooks.md` v0.2 RE-AUDIT PASS.
- **Contratos Frontend en drafting:** `@docs/design/03_bank_app_ui_contracts.md` v0.1 + `@docs/design/04_bank_app_design_system.md` v0.1 + `@docs/design/05_bank_app_data_integration.md` v0.1.
- **Manifest amendments protocol:** `@docs/agents/teams/03_CROSS_TEAM_CONTRACTS.md` §amendments.

---

## 5. Versioning

| Versión | Fecha | Cambios |
|---|---|---|
| v0.1 | 2026-05-06 | BANK-FE.0 inicial — 5 items registrados (2 MEDIUM Path A + 2 LOW Path B + 1 LOW Path C self-resolved). |
| v0.2 | 2026-05-08 | BANK-A.GOVT NODO 1+2 closing — 5 nuevos items govt-scope (REQ-FE-006..010): 4 HIGH (Census list/detail + Sanctions + Subsidies callbacks) + 1 MEDIUM (joint risk score spec con Security Lead). Govt panel mock-only hasta Backend Lead reactivación Phase A.GOVT cycle. |

---

**FIN `FE_BACKEND_REQUESTS.md` v0.2 — BANK-A.GOVT drafting active.** Govt panel (Treasury Bureau) requiere Backend Lead Phase A.GOVT cycle para items HIGH. Frontend continúa drafting NODOs siguientes con mock layer.
