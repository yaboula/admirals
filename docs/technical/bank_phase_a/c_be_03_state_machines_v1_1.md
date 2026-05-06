# C-BE-03 — State Machines v1.1 Bank Phase A (LOCKED v1.0.1 R1)

> **Owners:** Backend Money & Compatibility Lead + Database & Data Integrity Lead (joint).
> **Consumer Leads:** Security Lead (audit transitions) + Frontend Lead (UI badges per state).
> **Status:** � **v1.0.1 R1 LOCKED 2026-05-06** (BANK-BE.LOCK.R1 ceremony — Round 1 amendment promoted post Security Lead PASS veredicto BANK-SEC.1).
> **Fecha:** 2026-05-06 (BANK-BE.0 → BANK-BE.LOCK → BANK-BE.AMEND.1 → BANK-BE.LOCK.R1).
> **Path canonical:** `docs/technical/bank_phase_a/c_be_03_state_machines_v1_1.md` v1.0.1 R1 LOCKED. Pointer §X.NEW `docs/technical/05_state_machines.md` v1.3.1.
> **Joint authoring:** DB Lead aporta persistence column + DDL constraints. Backend Lead aporta runtime logic + transition guards + side effects + lib spec.

---

## 1. Filosofía FSMs Bank Phase A

### 1.1 8 FSMs LOCKED (Q-BE-pre-01 founder approved)

Founder approval 2026-05-06: **8 FSMs Phase A** consolidados. `credit_score_recompute` + `audit_archive` **DEFERRED Phase B**.

| # | FSM | Persistence (DB tabla / column) | Migration source | Lib runtime owner |
|---|---|---|---|---|
| 1 | `escrow_lifecycle` | `sonar_bank_escrows.state` ENUM | 006 + 008 (existing) + 027 (releases log) | `sonar_bank/server/escrow.lua` (existing extends) + `sonar_bank/server/fsm_escrow.lua` |
| 2 | `loan_lifecycle` | `sonar_bank_loans.state` ENUM | 018 | `sonar_bank_app/server/loans.lua` (NEW) |
| 3 | `recurring_lifecycle` | `sonar_bank_recurring_payments.state` ENUM | 021 | `sonar_bank_app/server/recurring.lua` (NEW) |
| 4 | `physical_card_lifecycle` | `sonar_bank_physical_cards.state` ENUM | 023 | `sonar_bank_app/server/physical_cards.lua` (NEW) |
| 5 | `election_lifecycle` | `sonar_govt_elections.phase` ENUM | 017 | `sonar_bank_app/server/elections.lua` (NEW) |
| 6 | `business_treasury_approval_lifecycle` | `sonar_bank_business_treasury_approvals.state` ENUM | 026 | `sonar_bank_app/server/business_treasury.lua` (NEW) |
| 7 | `sonar_bank_status` (CP8) | `sonar_bank_status.state` ENUM single-row | 012 | `sonar_bridges/lib/bank_status.lua` (NEW lib canonical) |
| 8 | `idempotency_key_lifecycle` | `sonar_bank_idempotency_keys.state` ENUM | 028 | `sonar_bridges/lib/idempotency_keys.lua` (NEW lib canonical) |

### 1.2 Deferred Phase B (NO scope C-BE-03 v1.1)

- ❌ `credit_score_recompute_state` — credit score recompute es **derivable on-demand** desde `sonar_bank_credit_scores.last_recomputed_at` + cron trigger lazy. NO requiere FSM Phase A.
- ❌ `audit_archive_lifecycle` — audit ledger archival old partitions es **DevOps cron strategy** post-Phase-D. NO entidad runtime FSM Phase A.
- ❌ `contract_lifecycle` separado — consolidado dentro de `escrow_lifecycle` como sub-states. Si Phase B add separate B2B contract entity → FSM separado entonces.
- ❌ `dispute_lifecycle` separado — consolidado dentro de `escrow_lifecycle` state `disputed`. Si Phase B add separate dispute resolution workflow → FSM separado.

### 1.3 FSM principles inherited (per `05_state_machines.md` v1.2 §1.1 F1-F8)

- **F1** Un solo `state` per entidad (no boolean flags paralelos).
- **F2** Transiciones explícitas only — cualquier otra → `INVALID_TRANSITION` error.
- **F3** Guards validados server-side ANTES de transition.
- **F4** Actions atómicas — transition + side effects en MISMA DB transaction.
- **F5** Eventos emitidos POST-transition (NetEvent + bag emit per CP1-A/B).
- **F6** Idempotency — same transition + same `correlation_id` 2nd attempt = no-op return same result.
- **F7** Terminal states inmutables (no transitions salientes).
- **F8** Audit log entry per transition (BankAuditLedger.Append).

---

## 2. FSM #1 — `escrow_lifecycle`

### 2.1 States (6 valores)

| State | Descripción | Terminal |
|---|---|---|
| `pending_funding` | Escrow created, payer no ha funded amount aún. | NO |
| `funded` | Payer fondeo completado. Funds in escrow account. Ready release. | NO |
| `released_partial` | Release parcial ejecutado. Remaining balance >0. | NO (puede transit a `released_full` o `disputed`). |
| `released_full` | Release total ejecutado. Balance = 0. | **YES** |
| `disputed` | Disputa abierta. Pending admin/govt resolution. | NO |
| `refunded` | Refund full ejecutado a payer. | **YES** |

### 2.2 Transitions

| From | To | Trigger event | Guard | Action atomic |
|---|---|---|---|---|
| `pending_funding` | `funded` | C009 `bank.escrow.fund` callback success | payer_balance ≥ escrow_amount, idempotency_key fresh | UPDATE escrows.state, UPDATE bank_accounts.balance (payer + escrow), INSERT 2 movements + audit |
| `funded` | `released_partial` | C010 `bank.escrow.release` callback (partial mode) | **`release_amount > 0` AND `release_amount < escrow_amount`** AND payer/payee/admin permission AND `escrow_amount > 0` (defensive) | INSERT releases, UPDATE escrows.balance + state, UPDATE accounts, audit |
| `funded` | `released_full` | C010 `bank.escrow.release` callback (full mode) | **`release_amount > 0` AND `release_amount == escrow_amount`** AND `escrow_amount > 0` | INSERT release row terminal, UPDATE state, audit |
| `released_partial` | `released_full` | C010 final release | **`release_amount > 0` AND `release_amount == remaining_balance`** AND `remaining_balance > 0` | INSERT release final, audit |
| `released_partial` | `disputed` | C011 `bank.escrow.dispute` callback | requester ∈ {payer, payee} OR admin | UPDATE state, INSERT dispute_reason, audit |
| `funded` | `disputed` | C011 `bank.escrow.dispute` | mismo | mismo |
| `disputed` | `released_full` | admin resolution C010 force | admin role check | audit + state |
| `disputed` | `refunded` | C012 `bank.escrow.refund` admin | admin role check | UPDATE accounts (refund payer), state, audit |
| `funded` | `refunded` | C012 `bank.escrow.refund` (admin override pre-dispute) | admin role + reason mandatory | mismo |

### 2.3 Invariants

- `escrows.balance` == sum(release events remaining) — pre-Q12 post-T4 escrow balance derivable desde releases log Q-DB-I-style. **Backend Lead Phase A:** persistir `balance` material + verify on every transition (defensive).
- Sum(payer_account.delta + payee_account.delta + escrow_account.delta) per transition == 0 (zero-sum money movement).
- Solo terminal states `released_full` + `refunded` cierran escrow row (post-terminal cualquier callback retorna `INVALID_TRANSITION`).
- **NEW v1.0.1 R1 (H005 fix):** Todos los release transitions del FSM #1 escrow_lifecycle DEBEN guardar `release_amount > 0` explicit + `escrow_amount > 0` o `remaining_balance > 0` defensive check. Zero-value releases prohibidos — error code `INVALID_PAYLOAD` con field=`release_amount` y reason `must_be_positive`. Esto previene movement spam + audit noise + token bucket drainage attack.

### 2.4 Side effects per transition

- DB: tablas afectadas listed §2.2.
- StateBag: NO publish (CP1-B per Q-BE-pre-03 → NetEvent directo).
- NetEvent: `sonar:bank:escrow:stateChanged` fire a {payer_source, payee_source, admin_sources_active}.
- Audit ledger: 1 entry per transition con event_type `escrow_state_change` + correlation_id + before/after state + amount.
- Compliance flags raise check: `large_transfer` pattern (Security Lead C-SEC-03 spec post-H2) si amount > €10k threshold.
- **NEW v1.0.1 R1 (H005 callback-level enforcement):** C010 `bank.escrow.release` (`@docs/technical/bank_phase_a/c_be_02_api_contracts_v1_3.md` §9.10) DEBE validar `payload.release_amount > 0` ANTES del FSM transition attempt. FSM guard es defensive secondary line. Validation order:
  1. Schema validation (`release_amount` is number).
  2. Positive check (`release_amount > 0`).
  3. Auth check (payer/payee/admin per AUTH-OWNER_OR_PARTICIPANT or AUTH-ROLE_OR_OWNER).
  4. FSM guard re-validates positive (defensive double-check) + boundary check vs `remaining_balance`.
  5. Atomic transaction execute.

---

## 3. FSM #2 — `loan_lifecycle`

### 3.1 States

| State | Descripción | Terminal |
|---|---|---|
| `applied` | Loan request submitted (C019). Pending review. | NO |
| `approved` | Govt/business approver granted (C020). Funds disbursed. | NO |
| `rejected` | Application denied. | **YES** |
| `active_repaying` | Funds disbursed, repayment schedule running. | NO |
| `defaulted` | Missed repayments threshold (configurable convar default 3 missed payments). | NO |
| `paid_off` | All repayments completed (sum repayments == principal + interest). | **YES** |
| `written_off` | Admin write-off post-default (debt forgiven, audit trail kept). | **YES** |

### 3.2 Transitions (resumen)

| From | To | Trigger | Guard |
|---|---|---|---|
| `applied` | `approved` | C020 admin approve | applicant_credit_score ≥ threshold |
| `applied` | `rejected` | C020 admin reject | reason mandatory |
| `approved` | `active_repaying` | Auto post-disbursement | funds transferred OK |
| `active_repaying` | `paid_off` | C021 final repayment | sum repayments == principal + interest |
| `active_repaying` | `defaulted` | Cron tick missed_payments ≥ threshold | configurable threshold |
| `defaulted` | `active_repaying` | C021 catch-up payment | sum recent payments cubre missed |
| `defaulted` | `written_off` | Admin C020 write-off | admin role + audit reason |

### 3.3 Side effects

- DB: `sonar_bank_loans` UPDATE state + UPDATE `sonar_bank_credit_scores` (recompute lazy via `Stocks.RecomputeHoldings`-style pattern — DEFERRED Phase B FSM but credit score column updated inline).
- NetEvent: `sonar:bank:loan:decisionResult` a applicant + admin.
- StateBag: NO bag (CP1-B — loan state is sensitive financial data).
- Audit ledger: entry per transition + amount + interest rate + state.

---

## 4. FSM #3 — `recurring_lifecycle`

### 4.1 States

| State | Descripción | Terminal |
|---|---|---|
| `active` | Recurring payment schedule running. | NO |
| `paused` | Pausado por owner (C028 `bank.recurring.cancel` con `mode = pause`). | NO |
| `cancelled` | Cancelado definitivamente. | **YES** |
| `failed_insufficient_funds` | Payment tick fail por balance insuficiente. Auto-pause hasta resolver. | NO (puede transit `active` post-fund). |
| `expired` | End date reached. | **YES** |

### 4.2 Transitions

| From | To | Trigger | Guard |
|---|---|---|---|
| `active` | `paused` | C028 `mode=pause` | owner check |
| `paused` | `active` | C028 `mode=resume` | owner check |
| `active` | `cancelled` | C028 `mode=cancel` | owner check |
| `active` | `failed_insufficient_funds` | Cron tick fail | balance < amount_due |
| `failed_insufficient_funds` | `active` | Cron retry post-fund | balance >= amount_due |
| `active` | `expired` | Cron tick end_date reached | end_date <= now |

### 4.3 Side effects

- DB: `sonar_bank_recurring_payments` UPDATE state.
- StateBag: emit `bank.recurring.<citizen_id>.summary` (CP1-A — counts + next_payment_at scalar).
- NetEvent: `sonar:bank:recurring:tickFailed` a owner solo on `failed_insufficient_funds`.
- Audit ledger: entry per transition + tick failure reason.

---

## 5. FSM #4 — `physical_card_lifecycle`

### 5.1 States

| State | Descripción | Terminal |
|---|---|---|
| `pending_request` | Card requested via C030. Pending issue. | NO |
| `active` | Card issued + PIN set. Usable. | NO |
| `frozen_pin_failures` | 3+ PIN failures. Auto-frozen. | NO (admin unfreeze possible). |
| `lost_reported` | Owner reported lost via callback (TBD spec C-BE-02 v0.2). | NO |
| `cancelled` | Cancelled by owner / admin / expiry. | **YES** |

### 5.2 Transitions (resumen)

| From | To | Trigger | Guard |
|---|---|---|---|
| `pending_request` | `active` | Admin issue | PIN hash set |
| `active` | `frozen_pin_failures` | Cron / lib detect 3+ fails | `PhysicalCards.HashPIN/VerifyPIN` lib (handoff §3.2) |
| `frozen_pin_failures` | `active` | Admin unfreeze | admin role |
| `active` | `lost_reported` | Owner callback | owner check |
| any (non-terminal) | `cancelled` | Admin / owner / expiry | per source role |

### 5.3 Side effects

- DB: `sonar_bank_physical_cards` UPDATE state + INSERT pin failure log row.
- NetEvent: `sonar:bank:card:pinFailure` a owner only.
- StateBag: NO (sensitive — PII card status).
- Audit ledger: entry per transition + PIN attempt count.

---

## 6. FSM #5 — `election_lifecycle` (Q1 govt mode configurable)

### 6.1 States (6 valores per blueprint Q1)

| State | Descripción | Terminal |
|---|---|---|
| `idle` | No election active. | NO |
| `nomination_open` | Nominations period (citizen self-nominate via C059). | NO |
| `voting_open` | Voting period (C060 cast vote). | NO |
| `vote_count` | Tally in progress. | NO |
| `term_active` | Winner declared, term running. | NO |
| `term_expired` | Term ended, transit back idle pending next election. | NO (loops to `idle`). |

### 6.2 Transitions

| From | To | Trigger | Guard |
|---|---|---|---|
| `idle` | `nomination_open` | C058 `elections:start` admin | admin role + config election period |
| `nomination_open` | `voting_open` | Auto cron / admin | nomination period elapsed (configurable convar) |
| `voting_open` | `vote_count` | Auto cron | voting period elapsed |
| `vote_count` | `term_active` | Auto post-tally | tally complete + winner declared |
| `term_active` | `term_expired` | Auto cron / C062 admin force | term duration elapsed |
| `term_expired` | `idle` | Auto post grace period | grace elapsed |

### 6.3 Side effects

- DB: `sonar_govt_elections.phase` UPDATE + dual-atomic write to `sonar_govt_votes` + `sonar_govt_votes_audit` (Q-DB-H privacy dual-layer) on vote cast.
- StateBag: emit `bank.elections.<election_id>` (CP1-A — phase + ends_at + candidate_count public-safe).
- NetEvent: `sonar:bank:elections:phaseChanged` broadcast all clients (phase change is public).
- Audit ledger: entry per phase transition.
- Compliance: NO autoraise (elections fuera de scope monetary patterns).

---

## 7. FSM #6 — `business_treasury_approval_lifecycle` (multi-signer M-of-N)

### 7.1 States

| State | Descripción | Terminal |
|---|---|---|
| `pending_approvals` | Approval request created. Awaiting M-of-N signers. | NO |
| `approved_executed` | M-of-N signatures collected, action executed. | **YES** |
| `rejected_quorum` | N-M+1 rejections received (impossible to reach M approvals). | **YES** |
| `expired_timeout` | Approval window elapsed sin reach M (default 48h configurable). | **YES** |
| `cancelled_initiator` | Initiator cancelled before quorum. | **YES** |

### 7.2 Transitions

| From | To | Trigger | Guard |
|---|---|---|---|
| `pending_approvals` | `approved_executed` | Cron evaluate signers count | approve_count ≥ M |
| `pending_approvals` | `rejected_quorum` | Cron evaluate | reject_count ≥ (N - M + 1) |
| `pending_approvals` | `expired_timeout` | Cron tick window elapsed | now > expires_at |
| `pending_approvals` | `cancelled_initiator` | Initiator callback | source.citizen_id == initiator_id |

### 7.3 Side effects

- DB: `sonar_bank_business_treasury_approvals` UPDATE state + execution side effects (e.g. transfer if approval = transfer action).
- NetEvent: `sonar:bank:business:approvalPending` a signers list, `sonar:bank:business:approvalResolved` a initiator + signers.
- StateBag: NO bag (sensitive empresa internal).
- Audit ledger: entry per state transition + signers list snapshot.

---

## 8. FSM #7 — `sonar_bank_status` (CP8 server-global)

### 8.1 States (4 valores per CP8)

| State | Descripción | Terminal |
|---|---|---|
| `native_full` | QBox/QBCore + Core Override aplicado correctamente. Full performance native. | NO |
| `lite_mode_active` | ESX 1.10+ + Lite Mode triple capa active. Reconciliation pipeline running. | NO |
| `compromised_load_order` | Watchdog detected Core Override compromised (sentinel attribute B missing OR métrica C esx events sin correlation-id sonar inyectado). | NO |
| `framework_missing` | Defensive boot CP4 detected no framework (or ESX <1.10 cut). Bank disabled. | NO |

### 8.2 Transitions

| From | To | Trigger | Guard |
|---|---|---|---|
| (boot) | `native_full` | `onResourceStart('sonar_bridges')` + framework_detect == QBox\|QBCore + Core Override applied OK | watchdog T+30s sentinel_attribute == TRUE |
| (boot) | `lite_mode_active` | `onResourceStart('sonar_bridges')` + framework_detect == ESX 1.10+ | esx version check pass |
| (boot) | `framework_missing` | `onResourceStart('sonar_bridges')` + framework_detect == NONE / ESX <1.10 | defensive abort + KVP `sonar_bank_disabled` set |
| `native_full` | `compromised_load_order` | Watchdog tier check fail (T+5min OR T+30min — sentinel missing OR métrica C indirect) | watchdog detection logic per ADR-018 §6 |
| `lite_mode_active` | `compromised_load_order` | Watchdog métrica C (esx events sin correlation-id sonar) > threshold | métrica fail |

### 8.3 Side effects

- DB: `sonar_bank_status` single-row UPDATE state (PK fixed `id=1` per Q-DB-J).
- StateBag: emit `bank.bridges.status` (CP1-A — public transparency by design Q16.3).
- NetEvent: NO (UI consume via bag — per CP8 + Frontend Lead C-FE-* badge).
- Audit ledger: entry per transition + reason + watchdog metrics snapshot.
- Resource KVP: `SetResourceKvp('sonar_bank_disabled', reason_code)` si transit a `framework_missing` o `compromised_load_order`.
- Defensive UX: si state ∈ {`compromised_load_order`, `framework_missing`} → all callbacks Bank retornan `{ status: 'error', error: { code: 'BANK_DISABLED', reason: <kvp> } }`.

### 8.4 Persistence detail (joint DB Lead)

`sonar_bank_status` migration 012 — single-row table PK fijo `id=1` (Q-DB-J LOCKED). Backend lib `sonar_bridges/lib/bank_status.lua` provee:

```lua
Bridges.BankStatus.GetState() → string
Bridges.BankStatus.Transition(new_state, reason, watchdog_metrics) → success | error
Bridges.BankStatus.IsDisabled() → boolean (state ∈ disabled_set)
Bridges.BankStatus.RegisterChangeHandler(fn) → unregister_fn
```

---

## 9. FSM #8 — `idempotency_key_lifecycle`

### 9.1 States

| State | Descripción | Terminal |
|---|---|---|
| `locked` | Key inserted con `INSERT IGNORE`. Operation in flight. **NEW v1.0.1 R1 (M005):** TTL 10min `ttl_expires_at` defensive — orphan keys post-crash reclaimable via cron. | NO (transient — debe transit a `completed`/`failed` o ser orphan-cleaned). |
| `completed` | Operation finished success. `result_payload` JSON cached. | **YES** (until TTL 7d expiry purge). |
| `failed` | Operation finished error. `result_payload` JSON contains error details. | **YES** (until TTL 7d expiry purge). |
| `orphan_purged` | **NEW v1.0.1 R1 (M005):** transient marker for keys que estuvieron en `locked` past TTL → cron cleanup transition. Logged + audited. Row eligible for reuse with same key (rare scenario — fresh `INSERT IGNORE` succeeds). | **YES** (immediately purged). |

### 9.2 Transitions

| From | To | Trigger | Guard |
|---|---|---|---|
| (insert) | `locked` | `IdempotencyKeys.Lock(key, domain, payload_hash)` | INSERT IGNORE (key not exist) — **set `ttl_expires_at = NOW() + 10min`** (v1.0.1 R1 M005) |
| `locked` | `completed` | `IdempotencyKeys.Complete(key, result_payload)` | operation success path — set `ttl_expires_at = NOW() + 7d` |
| `locked` | `failed` | `IdempotencyKeys.Fail(key, error_payload)` | operation error path — set `ttl_expires_at = NOW() + 7d` |
| `locked` | `orphan_purged` | **NEW v1.0.1 R1 (M005):** Cron `IdempotencyKeys.PurgeOrphans()` tick — query `WHERE state='locked' AND ttl_expires_at < NOW()` → delete rows + audit entry per row | `ttl_expires_at < NOW()` (10min stale) |

**Replay logic** (Q-BE-pre-06 founder approved storage `result_payload` JSON):

- 2nd call con mismo key:
  - If state == `locked` → wait short (50ms) + recheck. Si still `locked` después de 1s → return `{ status: 'error', error: { code: 'IDEMPOTENCY_INFLIGHT' } }` (defensive: caller debe retry timeout).
  - If state == `completed` → return cached `result_payload` directly. **NO recompute.**
  - If state == `failed` → return cached error payload. **NO recompute.**

### 9.3 Side effects

- DB: `sonar_bank_idempotency_keys` UPDATE state + result_payload JSON.
- StateBag: NO (internal).
- NetEvent: NO (internal).
- Audit ledger: **NEW v1.0.1 R1 (M005):** entry `event_type='idempotency_key_orphan_purged'` por cada row purged orphan post-crash. Forensics shape `{key, domain, payload_hash, locked_at, ttl_expires_at, purged_at, source_resource}`.
- Cron:
  - **TTL purge 7d** (existing): `WHERE state IN ('completed','failed') AND ttl_expires_at < NOW()` daily tick.
  - **NEW v1.0.1 R1 (M005) Orphan purge 10min:** cron tick **frequency 5min** runs `IdempotencyKeys.PurgeOrphans()`:
    - Query `WHERE state='locked' AND ttl_expires_at < NOW()`.
    - For each orphan: DELETE row + INSERT audit ledger entry `event_type='idempotency_key_orphan_purged'`.
    - Log warn `idempotency: purged N orphan keys (post-crash recovery)`.
  - DevOps Lead H4 deploy schedule both crons.

### 9.4 Schema impact (v1.0.1 R1 M005)

**DB Schema v2.0 LOCKED PROVISIONAL** `sonar_bank_idempotency_keys` (migration 028) ya tiene column `ttl_expires_at` — reusable. Patch v1.0.1 R1 reusa columna existente sin migration adicional:

- `state='locked'` rows: `ttl_expires_at = NOW() + 10min` (overload semantic — column purpose extends para locked TTL también).
- `state='completed'/'failed'` rows: `ttl_expires_at = NOW() + 7d` (existing).

**DB Lead consultative confirmation:** column `ttl_expires_at` schema permits both semantics ✅. No DB Lead reactivation needed.

**Cross-cutting C-BE-02 §6.2 audit ENUM addition:** entry `idempotency_key_orphan_purged` (forensics).

---

## 10. Cross-FSM cascade rules

### 10.1 `sonar_bank_status` global → all FSMs

Si `sonar_bank_status.state` transit a `framework_missing` o `compromised_load_order`:

- Todos callbacks Bank retornan early con `BANK_DISABLED`.
- FSMs runtime transitions **PAUSED** (no nuevas transitions hasta recovery).
- Cron jobs (recurring tick + business approvals expiry) **PAUSED**.
- Existing in-flight operations completan sus DB transactions atómicas (no abort mid-transaction) pero NO inicia nuevas.

### 10.2 `escrow_lifecycle.refunded` → cascade `business_treasury_approval` if applicable

Si escrow refunded fue triggered por business treasury approval rejection → approval marked `rejected_quorum` consistent.

### 10.3 `loan_lifecycle.defaulted` → cascade `physical_card`

Founder option Phase B: si loan defaulted + amount > threshold → auto-freeze physical cards owner. **Phase A:** NO cascade (defer Phase B per scope creep avoidance).

---

## 11. Persistence pattern (joint DB Lead)

Cada FSM table tiene:

- Column `state` ENUM persisted (canonical state).
- Column `state_changed_at` DATETIME persisted (transition timestamp).
- Column `state_changed_by` (citizen_id / admin_id / 'system') optional traceability.
- Triggers SIGNAL append-only on UPDATE/DELETE inappropriate (per Q-DB-F).
- Indexes per state column si query patterns frecuentes (DB Lead schema doc §22-§29).

---

## 12. Lib runtime spec (Backend Lead implementation)

Cada FSM tendrá lib Lua canonical:

```lua
-- pseudo-code C-BE-03 lib pattern
-- e.g. sonar_bank_app/server/escrow.lua
function Escrow.Transition(escrow_id, target_state, opts)
  -- 1. Lock idempotency key (opts.correlation_id)
  -- 2. Read current state DB
  -- 3. Validate transition target_state allowed from current_state (whitelist transitions §2.2)
  -- 4. Validate guards (§F3)
  -- 5. BEGIN transaction:
  --    - UPDATE state column + state_changed_at + state_changed_by
  --    - apply side effects (DB writes per §2.4)
  --    - INSERT audit ledger entry
  -- 6. COMMIT
  -- 7. Emit NetEvents / StateBags post-commit (per CP1-A/B)
  -- 8. IdempotencyKeys.Complete(correlation_id, result_payload)
  -- 9. Return success result
end
```

---

## 13. Testing matrix (DevOps Lead H5 input)

Cada FSM requires smoke test cases:

- Happy path each transition.
- Guard fail cases (INVALID_TRANSITION).
- Idempotency replay (Q-BE-pre-06 — replay returns cached result).
- Concurrent transitions (200 simultaneous on same entity → only 1 succeeds).
- Server restart mid-transition (atomic transaction guarantees).
- `sonar_bank_status` global override (BANK_DISABLED early return).

---

## 14. Anti-patterns prohibidos

- ❌ Transitions sin guard validation server-side.
- ❌ Side effects fuera de transaction (race condition).
- ❌ Update state directo (sin lib `<FSM>.Transition`) — bypassa audit + idempotency.
- ❌ Boolean flags paralelos (e.g. `is_paid` + `state`) — F1 violation.
- ❌ Skip audit log entry on transition.
- ❌ Multiple FSMs persistidos en mismo column (e.g. mezclar escrow + loan en single state column).

---

## 15. Open questions BANK-BE.0

| OQ | Tema | Resolution target |
|---|---|---|
| **OQ-CBE03-01** | `loan_lifecycle.defaulted` threshold misses configurable convar default? Founder valor canonical. | Default 3 misses. Founder confirma o ajusta. |
| **OQ-CBE03-02** | `business_treasury_approval` window expiry default 48h? | Default 48h. Founder confirma. |
| **OQ-CBE03-03** | `escrow_lifecycle` admin force release sin participant consent — ¿permitido? | Default YES con audit reason mandatory. Founder confirma. |
| **OQ-CBE03-04** | `physical_card_lifecycle.frozen_pin_failures` threshold (default 3 PIN fails)? | Default 3. Founder confirma. |
| **OQ-CBE03-05** | `sonar_bank_status.compromised_load_order` recovery path — ¿automatic re-verify vía watchdog progressive checks o manual admin command? | Default automatic (watchdog re-checks T+30min repeated). Manual admin override via console command `sonar_bank reset_status`. |

---

## 16. Sign-off matrix C-BE-03 v1.1 LOCKED target (joint Backend + DB)

| Stakeholder | Scope | Status DRAFT v0.1 |
|---|---|---|
| ☐ **Founder yaboula** | Final approval 8 FSMs + transitions + invariants + cascades | **PENDIENTE** review window |
| ☐ **Backend Lead (joint owner)** | Self-attest spec runtime logic + libs + transition guards + idempotency integration | **DRAFT v0.1 self-signed BANK-BE.0** |
| ☐ **DB Lead (joint owner)** | Self-attest persistence columns + DDL constraints + triggers SIGNAL + migration source refs | **PENDIENTE** review (DB Lead Standby reactivation) |
| ☐ **Security Lead (consumer consultative)** | Acepta audit ledger entries per transition + ACE checks + threat model | **PENDIENTE** activation post-H2 |
| ☐ **Frontend Lead (consumer consultative)** | Acepta state ENUM values for UI badges (e.g. CP8 4 states) | **PENDIENTE** activation post-H3 |

---

## 17. Versioning C-BE-03

| Version | Fecha | Cambios |
|---|---|---|
| **v0.1 DRAFT** | 2026-05-06 | BANK-BE.0 — DRAFT inicial post Q-BE-pre-01 founder LOCKED 8 FSMs. credit_score_recompute + audit_archive deferred Phase B. |
| **v1.0 LOCKED** | 2026-05-06 (BANK-BE.LOCK) | Promotion atomic. Sign-off ratificado: founder yaboula APPROVED + Backend Lead self-attested. **DB Lead joint sign-off DEFERRED** — trigger formal post-H2 Security Lead audit. Promoted: `drafts/be_phase_a/c_be_03_*` → `docs/technical/bank_phase_a/c_be_03_*`. Pointer §X.NEW en `docs/technical/05_state_machines.md` v1.2 → v1.3 LOCKED. |
| **v1.0.1 R1 LOCKED** | 2026-05-06 (BANK-BE.LOCK.R1) | BANK-BE.AMEND.1 surgical patches Round 1 reactive a Security Lead audit C-SEC-01/02/03 v0.1 (founder APPROVED 2026-05-06): **H005** (FSM #1 escrow zero-amount release guard — `release_amount > 0` + defensive `escrow_amount > 0` boundary checks across 3 transitions; callback C010 enforcement order §2.4) + **M005** (FSM #8 idempotency_lifecycle — `locked` orphan TTL 10min via column `ttl_expires_at` reuse + cron `PurgeOrphans` 5min frequency + new state `orphan_purged` + audit ENUM `idempotency_key_orphan_purged`). Sin schema migration impact (DB Lead consultative confirmed column reuse). DB Lead joint endorsement deferred trigger preserved per v1.0. Security Lead BANK-SEC.1 re-audit ✅ PASS veredicto + `08_audit_hooks.md` v0.2. Sign-off ratificado: founder yaboula APPROVED + Backend Lead self-attested + Security Lead PASS + DB Lead consultative endorsed. |

— **C-BE-03 v1.0.1 R1 LOCKED** 2026-05-06 (BANK-BE.LOCK.R1 ceremony). Sign-off founder + Backend Lead + Security Lead PASS + DB Lead consultative. **DB Lead joint endorsement formal deferred** preserved. Amendments adicionales require formal Round 2/3 protocol.
