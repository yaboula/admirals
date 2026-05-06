# C-BE-01 — Events Catalog v1.3 Bank Phase A (LOCKED v1.0.1 R1) — 54 events

> **Owner:** Backend Money & Compatibility Lead.
> **Consumer Leads:** Frontend Lead (consume NetEvents client-side handlers + StateBag change handlers) + Security Lead (audit events + ACE check checkpoints).
> **Status:** � **v1.0.1 R1 LOCKED 2026-05-06** (BANK-BE.LOCK.R1 ceremony — Round 1 amendment promoted post Security Lead PASS veredicto BANK-SEC.1).
> **Fecha:** 2026-05-06 (BANK-BE.1 → BANK-BE.LOCK → BANK-BE.AMEND.1 → BANK-BE.LOCK.R1).
> **Path canonical:** `docs/technical/bank_phase_a/c_be_01_events_catalog_v1_3.md` v1.0.1 R1 LOCKED. Pointer §X.NEW `docs/technical/02_events_catalog.md` v1.3.1.
> **Cross-ref:** C-BE-02 v1.0.1 R1 (40+1 callbacks — C001b NEW M004) + C-BE-03 v1.0.1 R1 (FSM hardening) + C-BE-04 v1.0.1 R1 (Bridges) + C-BE-05 v1.0.1 R1 (CP1-A → CP1-B M004 architectural).

---

## 1. Filosofía Events Catalog Bank Phase A extends

### 1.1 Inherited principles (per `02_events_catalog.md` v1.2 §1.1 E1-E10)

- **E1** Cada event es un contrato (schema fijo + tier + naming + governance).
- **E2** Naming canonical `sonar:<domain>:<entity>:<verb>` (lowercase + colon-delimited).
- **E3** Schemas tipados — payload shape documentado.
- **E4** 4 tipos canonical: NetEvent client→server / NetEvent server→client / AddEventHandler resource-internal / TriggerLatentClientEvent (>1.5KB payloads).
- **E5** Tier system 1-4 priorización testing (1=critical, 4=ornament).
- **E6** RFC governance changes significativos.

### 1.2 NEW principles Bank Phase A (Q-BE-pre integration)

- **E11 (CP1-A)** Bank state público propaga via **StateBag GlobalState**. Cualquier event que duplicaría un StateBag CP1-A es **anti-pattern prohibido**.
- **E12 (CP1-B)** Events sensibles privacy (compliance detail / escrow state / audit ledger raw) usan `TriggerLatentClientEvent(target_source, payload)` con **ACE check server-side ANTES de fire** (per C-BE-05 §2.2).
- **E13 (CP2)** Server-internal events emitidos por Bridges Layer (Lite Mode + Core Override) **incluyen `correlation_id` UUID v4** en payload — propagación cross-resource para audit trail.
- **E14 (CP8)** Events emitidos por FSM transitions (`<FSM>.Transition`) carry **transition metadata** (`from_state` + `to_state` + `triggered_by` + `correlation_id` + `idempotency_key`).
- **E15** Events Bank Phase A NUNCA broadcast a -1 (all clients). Siempre target específico (single source / list of sources / restricted via ACE).

---

## 2. Event categories Bank Phase A

| Categoría | Pattern | Cantidad Phase A |
|---|---|---|
| **2.1 NetEvents server→client (público)** | `TriggerClientEvent` o `TriggerLatentClientEvent` a target source(s). | **24 events** (22 + 2 NEW v1.0.1 R1 M004: `balance:update` + `savings:update`) |
| **2.2 NetEvents server→admin (restringido ACE)** | `TriggerLatentClientEvent` con ACE check `sonar.bank.govt.audit.full`. | **9 events** (8 + 1 NEW v1.0.1 R1 M004: `balance:adminAudit`) |
| **2.3 NetEvents client→server (callbacks user-initiated)** | `RegisterServerEvent` + `lib.callback.register` ox_lib pattern. | **40+1** (40 callbacks C-BE-02 + C001b NEW v1.0.1 R1 M004 `balance:snapshot` fallback) — detalle full en C-BE-02. |
| **2.4 AddEventHandler resource-internal (cross-resource sin network roundtrip)** | `AddEventHandler` server-side coordinación entre `sonar_bridges` ↔ `sonar_bank` ↔ `sonar_bank_app`. | ~12 events |
| **2.5 StateBag change handlers (CP1-A consumption pattern)** | Frontend Lead consume vía `AddStateBagChangeHandler('global', 'bank.<key>', handler)`. | **7 keys** (9 − 2 v1.0.1 R1 M004: `bank.balance.<cid>` + `bank.savings.<cid>` REMOVED — migrated CP1-B NetEvent). Ver C-BE-05 v1.0.1 R1 §2.1. |

---

## 3. NetEvents server→client público (categoría 2.1)

### 3.1 Tabla canonical Phase A

| Event name | Tier | Trigger fuente | Target audience | Payload shape | Cross-ref |
|---|---|---|---|---|---|
| `sonar:bank:transfer:complete` | 1 | C001 transfer success post-commit | payer source + payee source | `{ correlation_id, movement_id_payer, movement_id_payee, amount, balance_after_payer, balance_after_payee, reason, occurred_at }` | C-BE-02 C001 + C-BE-04 §3 |
| `sonar:bank:transfer:failed` | 2 | C001 error path | payer source only | `{ correlation_id, error: { code, message }, attempted_amount }` | C-BE-02 C001 |
| `sonar:bank:savings:depositComplete` | 2 | C002 savings deposit success | owner source | `{ correlation_id, movement_id, amount, balance_main_after, balance_savings_after }` | C-BE-02 C002 |
| `sonar:bank:savings:withdrawComplete` | 2 | C003 savings withdraw success | owner source | mismo shape simétrico | C-BE-02 C003 |
| `sonar:bank:account:closed` | 3 | C006 close account (Phase B mostly) | owner + admin | `{ correlation_id, account_id, account_class, final_balance_redirected_to }` | C-BE-02 C006 |
| `sonar:bank:escrow:created` | 1 | C007 escrow create success | payer + payee | `{ correlation_id, escrow_id, amount, currency, expires_at, state }` | C-BE-02 C007 |
| `sonar:bank:escrow:funded` | 1 | C009 escrow fund success | payer + payee | `{ correlation_id, escrow_id, amount_funded, state_new }` | C-BE-02 C009 + C-BE-03 §2.4 |
| `sonar:bank:escrow:stateChanged` (CP1-B) | 1 | C-BE-03 FSM transition any | payer + payee + admin (3 fires separados ACE-checked) | `{ correlation_id, escrow_id, state_from, state_to, triggered_by, amount_remaining, occurred_at }` | C-BE-05 §2.2 |
| `sonar:bank:escrow:released` | 1 | C010 escrow release success | payer + payee | `{ correlation_id, escrow_id, amount_released, balance_remaining, state_new }` | C-BE-02 C010 |
| `sonar:bank:escrow:refunded` | 2 | C012 escrow refund admin | payer + admin | `{ correlation_id, escrow_id, amount_refunded, reason, admin_id }` | C-BE-02 C012 |
| `sonar:bank:escrow:disputeOpened` | 2 | C011 dispute open | payer + payee + admin | `{ correlation_id, escrow_id, dispute_reason, opened_by, state_new }` | C-BE-02 C011 |
| `sonar:bank:loan:applied` | 2 | C019 loan apply success | applicant | `{ correlation_id, loan_id, principal, term_days, state }` | C-BE-02 C019 |
| `sonar:bank:loan:decisionResult` (CP1-B) | 1 | C020 loan approve/reject | applicant + admin | `{ correlation_id, loan_id, decision: 'approved' \| 'rejected', reason?, principal_disbursed?, repayment_schedule? }` | C-BE-02 C020 + C-BE-05 §2.2 |
| `sonar:bank:loan:repaymentRecorded` | 2 | C021 repayment success | borrower + admin | `{ correlation_id, loan_id, amount_paid, balance_remaining, state }` | C-BE-02 C021 |
| `sonar:bank:loan:defaulted` | 1 | Cron tick missed_payments threshold | borrower + admin | `{ correlation_id, loan_id, missed_count, total_owed, state_new = 'defaulted' }` | C-BE-03 §3.2 |
| `sonar:bank:recurring:created` | 3 | C027 recurring create | owner | `{ correlation_id, recurring_id, amount, period, next_payment_at }` | C-BE-02 C027 |
| `sonar:bank:recurring:tickFailed` | 2 | Cron tick fail balance insufficient | owner only | `{ correlation_id, recurring_id, amount_due, balance_current, state_new = 'failed_insufficient_funds' }` | C-BE-03 §4.3 |
| `sonar:bank:recurring:cancelled` | 3 | C028 cancel | owner | `{ correlation_id, recurring_id, mode: 'pause' \| 'cancel' }` | C-BE-02 C028 |
| `sonar:bank:card:pinFailure` (CP1-B) | 2 | PIN verify fail | card owner only | `{ correlation_id, card_id_masked, fail_count, frozen: bool }` | C-BE-05 §2.2 |
| `sonar:bank:elections:phaseChanged` | 2 | FSM #5 phase transition | broadcast all (phase change is public) | `{ election_id, phase_from, phase_to, ends_at, candidate_count }` | C-BE-03 §6.3 |
| `sonar:bank:business:approvalPending` (CP1-B) | 2 | C040 multi-signer create | signers list per ACE | `{ correlation_id, approval_id, action, amount?, expires_at, signers_required }` | C-BE-02 C040 + C-BE-05 §2.2 |
| `sonar:bank:business:approvalResolved` | 2 | C040 quorum reached / expired / cancelled | initiator + signers + admin | `{ correlation_id, approval_id, resolution: 'approved' \| 'rejected' \| 'expired' \| 'cancelled' }` | C-BE-03 §7.3 |
| `sonar:bank:balance:update` (CP1-B) **NEW v1.0.1 R1 M004** | 1 | Backend `publish_balance_update(cid, balance, 'main', opts)` post-commit (C001 transfer / C002 savings deposit / C006 close / C009 escrow fund / C010 escrow release / C012 escrow refund / C016 subsidy grant / C018 subsidy claim / C020 loan decide / C021 loan repay / C023 stocks buy / C024 stocks sell / C031 ATM / C032 card request / reconciliation pipeline / Lite Mode AddMoney) | **Owner source ONLY** — single target resolved from `Bridges.Player.GetSourceByCitizenId(citizen_id)` + ownership defensive check | `{ citizen_id, balance, account_class='main', occurred_at, correlation_id, schema_version }` | C-BE-05 v1.0.1 R1 §2.2.1 + C-BE-02 v1.0.1 R1 §6.1 |
| `sonar:bank:savings:update` (CP1-B) **NEW v1.0.1 R1 M004** | 1 | Backend `publish_balance_update(cid, balance, 'savings', opts)` post-commit (C002 / C003 / C006 / Round-Up auto-deposit) | Owner source ONLY — same target resolution + ownership check | `{ citizen_id, balance, account_class='savings', occurred_at, correlation_id, schema_version }` | C-BE-05 v1.0.1 R1 §2.2.1 |

### 3.2 Privacy classification per CP1-A/B

- **CP1-A público (broadcast acceptable)**: events sin marca explícita. State publicado en GlobalState también — event es notificación discrete redundante para latency-sensitive UX (toast notifications + sound effects).
- **CP1-B restricted (ACE check before fire)**: marcados `(CP1-B)` en tabla §3.1. Server fires solo a target source(s) post ACE check (per C-BE-05 §2.2 pattern).

### 3.3 Frontend consumption pattern

```javascript
// Frontend Lead — consume NetEvents client-side
RegisterNetEvent('sonar:bank:transfer:complete')
AddEventHandler('sonar:bank:transfer:complete', function(payload)
  // payload: { correlation_id, movement_id_payer, ..., balance_after_payer, ... }
  -- UI toast notification + sound + bag re-render (StateBag will also update reactively).
end)
```

---

## 4. NetEvents server→admin (categoría 2.2 — ACE-checked)

### 4.1 Tabla

| Event name | Trigger fuente | Target audience | Payload shape | ACE perm required |
|---|---|---|---|---|
| `sonar:bank:compliance:detail` (CP1-B) | C037 query / autoraise raise | Admin govt clients only | `{ correlation_id, citizen_id, flags: [{ flag_id, type, severity, evidence, raised_at, resolved? }, ...] }` | `sonar.bank.govt.audit.full` |
| `sonar:bank:audit:queryResult` (CP1-B) | C035 audit ledger query | Requester per scope | `{ correlation_id, scope, rows: [...], pagination }` | Per scope (`sonar.bank.audit.self` / `sonar.bank.empresas.<id>` / `sonar.bank.govt.audit.full`) |
| `sonar:bank:elections:votesRaw` (CP1-B) | C063 admin query raw votes (Q-DB-H privacy dual-layer) | Admin govt clients only | `{ correlation_id, election_id, votes: [{ vote_id, candidate_id, cast_at, audit_signature }, ...] }` | `sonar.bank.govt.audit.full` |
| `sonar:bank:reconciliation:flagRaised` | Reconciliation pipeline §7 (CP5 above-threshold) | Admin clients with `sonar.bank.govt.audit.full` | `{ correlation_id, citizen_id, delta, sonar_balance, esx_balance, threshold_amount, queued_at }` | `sonar.bank.govt.audit.full` |
| `sonar:bank:status:transition` | FSM #7 `sonar_bank_status` transition | Admin + DevOps roles | `{ correlation_id, state_from, state_to, reason, watchdog_metrics, occurred_at }` | `sonar.bank.govt.audit.full` OR `sonar.devops.bank.diagnostics` |
| `sonar:bank:tax:bracketsUpdated` | C015 admin update brackets | Admin govt clients (broadcast confirmation) | `{ correlation_id, brackets_new, updated_by, occurred_at }` | `sonar.bank.govt.tax.write` |
| `sonar:bank:subsidy:granted` | C016 admin grant subsidy | Recipient + admin | `{ correlation_id, subsidy_id, recipient_citizen_id, amount, category, expires_at }` | `sonar.bank.govt.subsidy.write` |
| `sonar:bank:cron:tickReport` (Tier 4) | Cron tick recurring + business approvals | DevOps clients only | `{ correlation_id, tick_type, processed_count, errors_count, duration_ms }` | `sonar.devops.bank.diagnostics` |
| `sonar:bank:balance:adminAudit` (CP1-B) **NEW v1.0.1 R1 M004** | C035 audit query scope='govt_full' on-demand response | Admin govt clients only (audit query response — NO push automatic on every mutation) | `{ correlation_id, citizen_id, balance_main, balance_savings, occurred_at, schema_version }` | `sonar.bank.govt.audit.full` (P11) |

### 4.2 ACE fire pattern boilerplate

```lua
-- Per C-BE-05 §2.2 boilerplate
local function fire_admin_event(event_name, payload, ace_perm)
  for _, src in ipairs(GetPlayers()) do
    if IsPlayerAceAllowed(tonumber(src), ace_perm) then
      TriggerLatentClientEvent(event_name, tonumber(src), 64 * 1024, payload)
    end
  end
end
```

---

## 5. NetEvents client→server (categoría 2.3 — callbacks user-initiated)

Los ~40 callbacks Bank Phase A se registran formalmente en **C-BE-02 API Contracts v1.3 DRAFT v0.1**. Resumen integrado aquí solo a nivel naming canonical:

```
sonar:bank:transfer                  C001
sonar:bank:savings:deposit           C002
sonar:bank:savings:withdraw          C003
sonar:bank:account:getInfo           C004
sonar:bank:account:list              C005
sonar:bank:account:close             C006

sonar:bank:escrow:create             C007
sonar:bank:escrow:getDetail          C008
sonar:bank:escrow:fund               C009
sonar:bank:escrow:release            C010
sonar:bank:escrow:dispute            C011
sonar:bank:escrow:refund             C012

sonar:bank:tax:getBrackets           C013
sonar:bank:tax:calculate             C014
sonar:bank:tax:setBrackets           C015 (admin)
sonar:bank:subsidy:grant             C016 (admin)
sonar:bank:subsidy:list              C017
sonar:bank:subsidy:claim             C018

sonar:bank:loan:apply                C019
sonar:bank:loan:decide               C020 (admin)
sonar:bank:loan:repay                C021
sonar:bank:stocks:list               C022
sonar:bank:stocks:buy                C023
sonar:bank:stocks:sell               C024
sonar:bank:stocks:getPortfolio       C025
sonar:bank:stocks:recomputeHoldings  C026 (admin/cron)

sonar:bank:recurring:create          C027
sonar:bank:recurring:cancel          C028
sonar:bank:crypto:list               C029
sonar:bank:crypto:swap               C030

sonar:bank:atm:getMinigameSession    C031
sonar:bank:card:requestPhysical      C032
sonar:bank:card:setPin               C033
sonar:bank:card:verifyPin            C034
sonar:bank:audit:query               C035

sonar:bank:compliance:listFlags      C036
sonar:bank:compliance:queryDetail    C037 (admin)
sonar:bank:compliance:resolveFlag    C038 (admin)

sonar:bank:business:treasuryGet      C039
sonar:bank:business:approvalCreate   C040

sonar:bank:balance:snapshot          C001b  -- NEW v1.0.1 R1 M004 (M004 fallback path post-connect UI mount, AUTH-OWNER own balances only)
```

**Detalle full (request schema + response schema + auth + rate-limit + idempotency + side effects + error codes + perf target + test scenarios) en `c_be_02_api_contracts_v1_3.md`.**

---

## 6. AddEventHandler resource-internal (categoría 2.4)

### 6.1 Cross-resource coordination Bank Phase A

| Event name | Emisor | Listener(s) | Payload | Razón resource-internal |
|---|---|---|---|---|
| `sonar:bank:internal:movementRecorded` | `sonar_bank/server/movements.lua` post movement INSERT | `sonar_bridges/lib/audit_ledger.lua` (audit append) + `sonar_bank_app/server/round_up.lua` (Round-Up hook) | `{ correlation_id, movement_id, citizen_id, amount, category, balance_after }` | Audit + Round-Up triggers no requieren network roundtrip — same server. |
| `sonar:bank:internal:fsmTransition` | `<FSM>.Transition` lib post-commit | `sonar_bridges/lib/audit_ledger.lua` + Security Lead C-SEC-01 audit hooks | `{ fsm_name, entity_id, state_from, state_to, triggered_by, correlation_id }` | Centralized audit hook listener. |
| `sonar:bank:internal:bankStatusChanged` | `Bridges.BankStatus.Transition` | Cron job manager (pause/resume) + StateBag publisher (`bank.bridges.status` emit) + admin notification fire | `{ state_from, state_to, reason, watchdog_metrics }` | FSM #7 cascade trigger. |
| `sonar:bank:internal:reconciliationApplied` | Reconciliation pipeline §7 batch process | `sonar_bridges/lib/audit_ledger.lua` (batch append) + **v1.0.1 R1 M004** `publish_balance_update()` per item (CP1-B NetEvent — replaces deprecated `bank.balance.<cid>` StateBag emit) | `{ batch_id, applied_count, citizen_ids, deltas }` | Batch coordination. |
| `sonar:bank:internal:reconciliationFlagged` | Reconciliation pipeline (CP5 above-threshold) | `sonar_bank_app/server/compliance_publisher.lua` (raise flag `reconciliation_delta_above_threshold`) + admin event fire `sonar:bank:reconciliation:flagRaised` | `{ citizen_id, delta, threshold }` | Compliance integration. |
| `sonar:bank:internal:complianceFlagRaised` | `sonar_bank_app/server/compliance_publisher.lua` (autoraise rules) | `sonar_bridges/lib/audit_ledger.lua` + StateBag emit (`bank.compliance.<cid>.public` reduced shape per CP1-A) + admin event fire `sonar:bank:compliance:detail` (CP1-B per ACE) | `{ flag_id, citizen_id, flag_type, severity, evidence }` | Triple downstream coordination. |
| `sonar:bank:internal:idempotencyKeyCommitted` | `IdempotencyKeys.Complete` lib | Audit ledger (optional metadata trace) | `{ key, domain, status: 'completed' \| 'failed' }` | Idempotency observability. |
| `sonar:bank:internal:cronTickCompleted` | Cron managers (recurring + approvals + idempotency_purge) | DevOps observability listener | `{ tick_type, processed, errors, duration_ms }` | Metrics aggregation. |
| `sonar:bank:internal:roundUpAccrued` | `RoundUp.OnMovement` hook (sonar_bridges/lib/round_up.lua) | `sonar_bank_app/server/savings.lua` (auto-deposit savings) | `{ correlation_id, citizen_id, source_movement_id, round_up_amount }` | Round-Up auto-savings. |
| `sonar:bank:internal:auditLedgerAppended` | `BankAuditLedger.Append` post commit | Security Lead C-SEC-01 audit hooks (downstream Phase B+) | `{ audit_id, event_type, occurred_at, payload_summary }` | Audit observability. |
| `sonar:bank:internal:bridgesEchoDropped` | `MutexEcho.drop_echo` (CP2 path #1 echo detection) | DevOps observability listener (cardinalidad métrica watchdog C) | `{ correlation_id, source: 'esx_external' }` | Watchdog métrica C feed. |
| `sonar:bank:internal:bridgesEchoOrphaned` | `MutexEcho.register_pending_echo` GC defensive (echo never received post 60s TTL) | DevOps observability + log_warn | `{ correlation_id, payload_snapshot }` | Anomaly detection lite mode. |

### 6.2 Pattern listener boilerplate

```lua
-- Resource-internal listener — sonar_bridges/lib/audit_ledger.lua
AddEventHandler('sonar:bank:internal:movementRecorded', function(payload)
  BankAuditLedger.Append({
    event_type = 'movement_recorded',
    citizen_id = payload.citizen_id,
    correlation_id = payload.correlation_id,
    amount = payload.amount,
    metadata = { movement_id = payload.movement_id, balance_after = payload.balance_after, category = payload.category },
  })
end)
```

---

## 7. StateBag change handlers (categoría 2.5 — CP1-A consumption pattern)

### 7.1 Frontend consumption pattern (referencia C-BE-05 §2.1)

```javascript
// Frontend Lead — Bank app NUI consume StateBags reactively
const handler = AddStateBagChangeHandler('global', `bank.balance.${selfCitizenId}`, (bagName, key, value, _replicated, _serverIdent) => {
  // value: number (DECIMAL atomic balance)
  setBalance(value);  // React state update → re-render UI
});

// Cleanup on unmount
return () => {
  RemoveStateBagChangeHandler(handler);
};
```

### 7.2 Tabla resumen (full detail en C-BE-05 v1.0.1 R1 §2.1)

| StateBag key pattern | Type | Frontend consumer widget |
|---|---|---|
| ~~`bank.balance.<citizen_id>`~~ **REMOVED v1.0.1 R1 M004** | ~~number~~ → migrated to CP1-B NetEvent `sonar:bank:balance:update` (§3.1) | Bank app overview balance display — consume vía `RegisterNetEvent('sonar:bank:balance:update')` + C001b `balance:snapshot` fallback (§5 + C-BE-02 §9.5b). |
| ~~`bank.savings.<citizen_id>`~~ **REMOVED v1.0.1 R1 M004** | ~~number~~ → migrated to CP1-B NetEvent `sonar:bank:savings:update` (§3.1) | Savings widget — consume vía `RegisterNetEvent('sonar:bank:savings:update')` + C001b fallback. |
| `bank.business_treasury.<company_id>` | number | Empresas Dashboard treasury widget |
| `bank.compliance.<citizen_id>.public` | `{ has_active_flags, count }` | Compliance badge UI |
| `bank.govt.taxBrackets` | `[{ income_min, income_max, rate }, ...]` | Tax calculator |
| `bank.govt.subsidies.active` | `[{ category, amount, expires_at }, ...]` | Government info widget |
| `bank.bridges.status` | string ENUM (CP8 4 states) | Sidebar footer badge always visible |
| `bank.elections.<election_id>` | `{ phase, ends_at, candidate_count }` | Elections widget |
| `bank.recurring.<citizen_id>.summary` | `{ active_count, next_payment_at }` | Recurring widget |

**v1.0.1 R1 M004 deprecation note:** `bank.balance.<cid>` y `bank.savings.<cid>` REMOVIDOS de CP1-A por financial-grade privacy (Zero-Knowledge para terceros, founder APPROVED 2026-05-06). Frontend consumption pattern post-R1 documentado §3.1 NEW rows + C-BE-05 v1.0.1 R1 §2.2.1 helper canonical `publish_balance_update()`.

---

## 8. Tier classification testing matrix Bank Phase A

| Tier | Cantidad | Eventos | Testing requirement |
|---|---|---|---|
| **Tier 1 (critical — money correctness)** | **9** (7 + 2 NEW M004) | `transfer:complete` + `escrow:created/funded/stateChanged/released` + `loan:decisionResult/defaulted` + **`balance:update`** (NEW v1.0.1 R1 M004) + **`savings:update`** (NEW v1.0.1 R1 M004) | 100% test coverage. Smoke chaos test C-DO-01 mandatory. Idempotency replay verified per E14 transition metadata. M004 events: privacy boundary T-AMEND-M004.1–7 (C-BE-05 v1.0.1 R1 §1.10). |
| **Tier 2 (important — UX critical)** | **13** (12 + 1 NEW M004) | `transfer:failed` + `savings:depositComplete/withdrawComplete` + `escrow:disputeOpened/refunded` + `loan:applied/repaymentRecorded` + `recurring:tickFailed/cancelled` + `card:pinFailure` + `elections:phaseChanged` + `business:approvalPending/approvalResolved` + **`balance:adminAudit`** (NEW v1.0.1 R1 M004 admin response) | 80% coverage. Manual smoke test scenarios. |
| **Tier 3 (informational — nice-to-have)** | 5 | `account:closed` + `recurring:created` + `tax:bracketsUpdated` + `subsidy:granted` + `compliance:detail` | 50% coverage. Visual confirmation only. |
| **Tier 4 (ornament — Phase A optional)** | 4 | `cron:tickReport` + `bridgesEchoDropped` + `bridgesEchoOrphaned` + `auditLedgerAppended` (DevOps observability) | 0% coverage Phase A. Phase B telemetry feed. |

**Total events Phase A v1.0.1 R1:** 24 server→client público + 9 server→admin + 12 resource-internal + 7 StateBag keys (consumed via handlers, 2 removed M004) + C001b client→server new callback ref C-BE-02 = **54 events catalogados** (51 baseline v1.0 + 3 NEW v1.0.1 R1 M004 — `balance:update` + `savings:update` + `balance:adminAudit`).

---

## 9. Naming convention canonical (refresh C-BE-01 v1.3)

### 9.1 Pattern formal

```
sonar:<domain>:<entity>:<verb_or_state>
```

| Componente | Valores válidos | Ejemplo |
|---|---|---|
| `sonar` | Prefijo fijo (per ADR-013 namespace migration). | `sonar:bank:transfer:complete` |
| `<domain>` | `bank` (Phase A scope). Otros dominios SONAR (`tablet`, `phone`, `inventory`) en otros catalogs. | mismo |
| `<entity>` | `transfer`, `savings`, `account`, `escrow`, `tax`, `subsidy`, `loan`, `stocks`, `recurring`, `crypto`, `atm`, `card`, `audit`, `compliance`, `business`, `elections`, `status`, `reconciliation`, `cron`, `balance` (NEW v1.0.1 R1 M004), `internal` (resource-internal sub-namespace). | mismo |
| `<verb_or_state>` | Verb past tense (`complete`, `failed`, `applied`, `recorded`) o noun state change (`stateChanged`, `phaseChanged`, `approvalPending`). | mismo |

### 9.2 Anti-patterns prohibidos

- ❌ ~~`sonar:bank:transferComplete`~~ — falta separador `:` entre entity + verb.
- ❌ ~~`bank:transfer:complete`~~ — falta prefijo `sonar:`.
- ❌ ~~`sonar:Bank:Transfer:Complete`~~ — PascalCase (rompe convention).
- ❌ ~~`sonar:bank:transfer:done`~~ — verb genérico (preferir `complete` standard SONAR).
- ❌ ~~`sonar:bank:transfer-complete`~~ — kebab-case (rompe convention).
- ❌ Namespace `internal:` usado fuera resource-internal events (categoría 2.4 only).

---

## 10. Schema versioning + governance

### 10.1 Schema embed conventional

Cada NetEvent payload includes mandatory fields:

```typescript
interface BaseNetEventPayload {
  correlation_id: string;       // UUIDv4 — propagation trace audit
  occurred_at?: number;         // epoch ms (optional — emit-side timestamp)
  schema_version: number;       // 1 (Phase A baseline). Bump RFC governance per E6.
}
```

### 10.2 Backwards compatibility

- **Adding new optional fields:** non-breaking. Schema version bump optional.
- **Removing fields:** breaking. RFC governance + schema_version bump mandatory + Frontend Lead cross-team coordination.
- **Renaming fields:** breaking. Same.
- **Changing field types:** breaking. Same.

### 10.3 RFC governance trigger

Cualquier change Tier 1-2 events post-LOCKED v1.0 requires:

1. Backend Lead drafts RFC en `docs/agents/teams/rfcs/RFC_C-BE-01_<event_name>_<change>.md`.
2. Cross-team review window 48h.
3. Triple sign-off founder + Backend Lead + Frontend Lead (consumer).
4. Bump schema_version + emit dual-event (old + new) durante transition window 1 sprint.

---

## 11. Cross-references contratos

- C-BE-02 API Contracts v1.3 — callbacks user-initiated (~40 events client→server detalle full).
- C-BE-03 State Machines v1.1 — FSM transitions emitten events §3.1 (`escrow:stateChanged` + `loan:defaulted` + `recurring:tickFailed` + `elections:phaseChanged` + `business:approvalResolved` + `status:transition`).
- C-BE-04 Bridges Compatibility v1.1 — `Bridges.BankStatus.Transition` emite `sonar:bank:internal:bankStatusChanged` + `sonar:bank:status:transition` admin.
- C-BE-05 StateBags Global Publishers v0.1 — privacy classification CP1-A/B referenciado §3.2 + §4.
- C-SEC-01 Audit Hooks (Security Lead H2) — `sonar:bank:internal:auditLedgerAppended` + `fsmTransition` + `complianceFlagRaised` consumed.
- C-FE-01 (Frontend Lead H4) — NUI consume NetEvents §3.3 + StateBags §7.1.
- ADR-018 — events fired by Bridges Layer (Lite Mode + Core Override) carry correlation_id (E13).

---

## 12. Open questions BANK-BE.1

| OQ | Tema | Resolution target |
|---|---|---|
| **OQ-CBE01-01** | `sonar:bank:elections:phaseChanged` broadcast all clients OK o restringir a citizens del govt server? | Default broadcast all (phase change is public knowledge — public ballot system). Founder confirma. |
| **OQ-CBE01-02** | Tier 4 observability events (`cron:tickReport` + `bridgesEcho*`) — ¿enable Phase A o defer Phase B? | Default enabled Phase A pero NO target audience clients (DevOps role only). Mínimo overhead. |
| **OQ-CBE01-03** | Schema embed `schema_version` field mandatory en TODOS events o solo Tier 1-2? | Default mandatory all events (consistencia vale el byte extra). Founder confirma. |
| **OQ-CBE01-04** | `sonar:bank:internal:auditLedgerAppended` — emit per individual append o batch per cron tick (perf optimization)? | Default per individual append. Phase B revisión post real metrics. |

---

## 13. Sign-off matrix C-BE-01 v1.3 LOCKED target

| Stakeholder | Scope | Status DRAFT v0.1 |
|---|---|---|
| ☐ **Founder yaboula** | Final approval 51 events catalogados + 9 StateBag keys + Tier classification | **PENDIENTE** review window |
| ☐ **Backend Lead (owner)** | Self-attest spec coherente con C-BE-02..05 + privacy refinement CP1-A/B | **DRAFT v0.1 self-signed BANK-BE.1** |
| ☐ **Frontend Lead (consumer consultative)** | Acepta NetEvent payloads + StateBag handlers consumption pattern | **PENDIENTE** activation post-H3 |
| ☐ **Security Lead (consumer consultative)** | Acepta ACE checks pattern §4 + audit observability hooks §6 | **PENDIENTE** activation post-H2 |

---

## 14. Versioning C-BE-01

| Version | Fecha | Cambios |
|---|---|---|
| **v0.1 DRAFT** | 2026-05-06 (BANK-BE.1) | DRAFT inicial extends v1.2 con ~22 server→client público + 8 server→admin ACE-checked + 12 resource-internal + 9 StateBag keys consumed. Tier classification (7+12+5+4 = 28 NetEvents +9 bags + ~40 callbacks ref C-BE-02 + 12 internal = **51 events catalogados**). |

| **v1.0 LOCKED** | 2026-05-06 (BANK-BE.LOCK) | Promotion atomic post-DRAFT v0.1 review window. Sign-off triple ratificado: founder yaboula APPROVED + Backend Lead self-attested + Frontend Lead (consumer consultative consumer-of-events) acknowledged via H4 future. Promoted DRAFT → canonical: `docs/agents/teams/drafts/be_phase_a/c_be_01_events_catalog_v1_3.md` → `docs/technical/bank_phase_a/c_be_01_events_catalog_v1_3.md`. Pointer §X.NEW Bank Phase A added en `docs/technical/02_events_catalog.md` v1.2 → v1.3 LOCKED. |
| **v1.0.1 R1 LOCKED** | 2026-05-06 (BANK-BE.LOCK.R1) | BANK-BE.AMEND.1 cross-cutting LOCK-time impact reactive a M004 architectural founder APPROVED 2026-05-06 (CP1-A → CP1-B migration `bank.balance.<cid>` + `bank.savings.<cid>`): **3 NEW NetEvents** — `sonar:bank:balance:update` Tier 1 (CP1-B owner-only §3.1 NEW row + emisor §6.1 reconciliation refactor) + `sonar:bank:savings:update` Tier 1 (CP1-B owner-only §3.1 NEW row, parity savings) + `sonar:bank:balance:adminAudit` Tier 2 (§4.1 NEW row admin govt audit query response P11 ACE on-demand). **+1 NEW callback ref** — C001b `sonar:bank:balance:snapshot` §5 (AUTH-OWNER fallback path post-connect UI mount, detail full C-BE-02 v1.0.1 R1 §9.5b). **2 StateBag keys REMOVED** — §2 categorías ajustada (9 → 7 keys consumed) + §7.2 deprecation note + Frontend consumption pattern reescrito. **Tier classification refresh:** Tier 1 7 → 9 events + Tier 2 12 → 13 events. **Total events catalogados:** 51 → **54** (+3 NEW M004). Cross-cutting impacts: C-BE-02 v1.0.1 R1 (~14 callbacks side effects refactor + C001b NEW) + C-BE-04 v1.0.1 R1 (§7.1 reconciliation emit refactor + §5 Lite Mode AddMoney) + C-BE-05 v1.0.1 R1 (architectural owner contract). Sin schema migration impact (DB Lead consultative confirmed). Security Lead BANK-SEC.1 re-audit ✅ PASS veredicto + `08_audit_hooks.md` v0.2. Sign-off ratificado: founder yaboula APPROVED + Backend Lead self-attested + Security Lead PASS. |

— **C-BE-01 v1.0.1 R1 LOCKED** 2026-05-06 (BANK-BE.LOCK.R1 ceremony). Sign-off founder + Backend Lead + Security Lead PASS. **Effective immediately.** Frontend Lead recibe vía H3 futuro (54 events canonical — incluye 3 NEW M004 + C001b ref). Amendments adicionales require formal Round 2/3 protocol per `@docs/agents/teams/03_CROSS_TEAM_CONTRACTS.md` §amendments.
