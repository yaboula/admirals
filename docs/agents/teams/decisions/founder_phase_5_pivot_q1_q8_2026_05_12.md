# Founder Decisions LOCKED — Phase 4 → Phase 5 Pivot

> **Status:** LOCKED v1.0 — immutable post-emission
> **Emitted by:** Founder yaboula
> **Recorded by:** PM Cascade
> **Date:** 2026-05-12
> **Context:** Pivot from Phase 4 Core Override (parasite model) to Phase 5 Ecosystem Closed Public API (ox_inventory-style precedent). See `docs/design/04_sonar_bank_api.md` v0.1 DRAFT and commit `c4ea87a` for Phase 4 frozen baseline.

---

## Decision matrix (8 open questions raised by `04_sonar_bank_api.md` v0.1 §11 + PM Cascade contractual gaps)

### Q1 — Minor units vs major units convention boundary

**Decision:** **Split convention with explicit boundary helpers.**

| Surface | Convention | Status |
|---|---|---|
| DB `sonar_bank_*` money columns | DECIMAL(19,2) major units | LOCKED Phase A (no touch) |
| Service layer internal math | INTEGER minor units | Boundary conversion at wrapper |
| Tier 1/2 Exports (NEW) | INTEGER minor units | Per Phase 5 design |
| Callbacks C001-C040 (LEGACY) | DECIMAL major units | LOCKED C-BE-02 (no touch Phase A) |
| Frontend display + input | DECIMAL major units | LOCKED Phase A (no touch) |

**Mandate:** boundary conversion helpers `lib/units.lua` with `to_minor(decimal)` / `from_minor(int)` exposed for ALL Tier 1/2 wrappers. Helpers MUST use `math.floor` with HALF_UP rounding for input, integer division for output. NO float math in service layer internals once converted.

**Phase A+1 roadmap (post-LOCK):** full minor units migration end-to-end (DB DECIMAL→BIGINT, callbacks signature change, Frontend types). Tracked separately in `docs/planning/roadmap_phase_a_plus_1_minor_units_migration.md` (to be emitted by amendment agent Phase 1).

**Rationale:** scope of full refactor (10-15 days) blocks Phase A LOCK timeline. Split convention is pragmatic compromise honoring SSoT mathematical purity at API surface while deferring DB/Frontend migration. Founder accepts boundary helper as temporary technical debt with explicit roadmap commitment.

---

### Q2 — StateBag CP1-B mandate confirmation

**Decision:** **CONFIRMED mandatory.**

All Tier 1/2 mutation exports MUST invoke `Publish.BalanceUpdate(citizen_id, new_balance_minor, new_savings_minor)` canonical helper per C-BE-05 v1.0.1 R1 §2.2.1 after successful mutation, BEFORE return to caller.

Atomically updates StateBag global keys:
- `bank.balance.<cid>` = new_balance_minor (INTEGER)
- `bank.savings.<cid>` = new_savings_minor (INTEGER)

Additional `sonar:bank:balance_updated` net event remains optional for legacy NUI consumers. StateBag is the canonical channel per CP1-B mandate.

**Anti-pattern AP-CP1-1 prohibited:** no parallel state propagation paths. If wrapper does NOT call `Publish.BalanceUpdate`, mission CLOSED criteria fail.

---

### Q3 — Audit shape canonical full enumeration

**Decision:** **CONFIRMED mandatory full 10-field shape per C-SEC-01 v0.2 §1.2.**

Every Tier 1/2 mutation MUST insert row in `sonar_audit_log` with:

| Field | Type | Notes |
|---|---|---|
| `actor_account_id` | VARCHAR(64) NULL | Resolved from `actor_src` (Tier 2) or `source` (Tier 1). NULL si console (`actor_src=0`). |
| `target_account_id` | VARCHAR(64) NOT NULL | Target citizen/account UUID. |
| `event_type` | ENUM | `bank_credit | bank_debit | bank_transfer | admin_credit | admin_debit | admin_set_balance | account_freeze | account_unfreeze | bank_overdraft` |
| `delta_minor` | BIGINT | Signed minor units (negative for debit). |
| `previous_flag_snapshot` | JSON NULL | `{frozen, closed, ...}` ANTES del cambio. NULL for credit/debit/transfer. MANDATORY for freeze/unfreeze. |
| `request_nonce` | VARCHAR(36) | `opts.idempotency_key` OR generated UUIDv4 if caller absent. |
| `correlation_id` | VARCHAR(36) | `opts.correlation_id` OR same as `request_nonce` if absent. |
| `invoker_resource` | VARCHAR(64) | `GetInvokingResource()` result OR `'console'` si actor_src=0. |
| `reason` | VARCHAR(255) | Free-text sanitized server-side. |
| `created_at` | INT (epoch) | Server timestamp. |

**Audit completion atomic:** insert MUST happen inside the same SQL transaction as the balance mutation (no separate audit_complete async path). Aligned with C-BE-02 §9 atomic audit hardening (BANK-DO.2.2).

---

### Q4 — Compatibility shim ship/drop

**Decision:** **DROP shim. Forced operator-side migration.**

No `sonar_compat` resource shipped. No qb-core re-patch. Operator MUST manually migrate every money-touching resource via `MIGRATION.md` and `/sonar_scan_legacy` helper.

**Roadmap post-LOCK Phase A+N (NOT Phase A scope):** opcional Python auto-fixer script para clientes B2B futuros. Sin commitment timeline.

**README + MIGRATION.md mandatory:** SONAR Bank is NOT a drop-in replacement for qb-banking. Migration friction declarada upfront. Premium-grade product positioning.

---

### Q5 — Overdraft flag exposure

**Decision:** **Tier 2 only via `opts.allow_overdraft = true`.**

| Tier | `allow_overdraft` permitido? |
|---|---|
| Tier 1 (`RemoveMoney`, `TransferBy*`, *ByCitizen variants) | NO — always rejects with `INSUFFICIENT_FUNDS` |
| Tier 2 (`AdminDebit`, `AdminSetBalance`, *ByCitizen variants) | YES — flag honored, audit row `event_type='bank_overdraft'` |

Default Tier 2: `allow_overdraft=false` (must opt-in explicitly per call).

---

### Q6 — *ByCitizen variants for offline players

**Decision:** **CONFIRMED 11 *ByCitizen variants required.**

For each Tier 1 export (6 baseline) + Tier 2 export (5 baseline), provide a `*ByCitizen` sibling that accepts `citizen_id` (string) instead of `source` (integer). Total: **22 exports**.

```lua
-- Tier 1 baseline (by source, requires player online):
exports.sonar_bank_app:AddMoney(source, amount_minor, reason, opts)
exports.sonar_bank_app:RemoveMoney(source, amount_minor, reason, opts)
exports.sonar_bank_app:CanAfford(source, amount_minor)
exports.sonar_bank_app:GetBalance(source)
exports.sonar_bank_app:TransferBySource(from_src, to_src, amount_minor, reason, opts)
exports.sonar_bank_app:TransferByIban(from_iban, to_iban, amount_minor, reason, opts)

-- Tier 1 *ByCitizen siblings (offline-safe):
exports.sonar_bank_app:AddMoneyByCitizen(citizen_id, amount_minor, reason, opts)
exports.sonar_bank_app:RemoveMoneyByCitizen(citizen_id, amount_minor, reason, opts)
exports.sonar_bank_app:CanAffordByCitizen(citizen_id, amount_minor)
exports.sonar_bank_app:GetBalanceByCitizen(citizen_id)
exports.sonar_bank_app:TransferByCitizen(from_cid, to_cid, amount_minor, reason, opts)
-- TransferByIban already citizen-agnostic, no *ByCitizen variant needed (5 not 6 Tier 1 by-citizen)

-- Tier 2 baseline + *ByCitizen siblings (5 + 5 = 10):
exports.sonar_bank_app:AdminCredit(actor_src, target, amount_minor, reason)         -- target = source OR citizen_id polymorphic
exports.sonar_bank_app:AdminDebit(actor_src, target, amount_minor, reason)
exports.sonar_bank_app:AdminSetBalance(actor_src, target, new_balance_minor, reason)
exports.sonar_bank_app:Freeze(actor_src, target_iban, reason)
exports.sonar_bank_app:Unfreeze(actor_src, target_iban, reason)
```

**Implementation note (PM Cascade):** Tier 2 already polymorphic on `target` (source OR citizen_id). Tier 1 needs explicit `*ByCitizen` variants since first arg is typed (source: integer).

**Offline-safe semantics:** *ByCitizen variants do NOT update PlayerData mirror if citizen offline. Mirror sync deferred to next `QBCore:Server:PlayerLoaded` event (or framework equivalent). StateBag publish OK even offline (state global persists).

---

### Q7 — Fee policy on transfers

**Decision:** **Rigid fees, NO overrides even in Tier 2.**

Reuse existing `Config.FeePolicies` from `config.lua` (LOCKED Phase A). All Tier 1/2 mutations honor config automatically. NO `opts.skip_fees` flag. NO `opts.fee_override_minor` flag.

**Rationale (founder):** matemáticas simples + reglas aplican a todos. Simpler audit shape (no `fees_skipped`/`fee_override` columns). Cleaner contract. Operator can change config to adjust fees globally; per-call exceptions invite abuse.

**Override on PM Cascade recommendation:** PM proposed Tier 2 overrides for admin gifts + business custom rates. Founder rejected — simplicity wins over flexibility.

---

### Q8 — PRE-PlayerLoaded race semantics

**Decision:** **NEW error code `PLAYER_NOT_LOADED` with retry hint.**

Add to error taxonomy §5:

```
PLAYER_NOT_LOADED — Player source exists but framework PlayerData not yet loaded.
                    Caller SHOULD retry after framework PlayerLoaded event.
                    Hint provided in error data: { retry_after_event = '<framework-specific>' }
```

Differs from `PLAYER_NOT_FOUND` (source does not exist in server / dropped before lookup).

**Implementation note:** wrapper detects PRE-load state by checking `Bridges.Identity.IsLoaded(source)` (new bridge function NEW) or framework-specific equivalent.

**MIGRATION.md guidance:** "Subscribe to your framework's PlayerLoaded event before invoking SONAR Bank exports for newly joined players. Calling during the load window returns `PLAYER_NOT_LOADED` which you should treat as a retry signal."

---

## Cross-decision constraints (PM Cascade synthesis)

1. **Boundary helpers mandatory:** `lib/units.lua` `to_minor()` + `from_minor()` exposed for ALL wrappers. Property tested.

2. **StateBag publish + audit insert + balance mutation = atomic same TX.** If any of the three fails, ALL roll back. No partial state.

3. **Idempotency table `sonar_bank_idem`:** 24h TTL cron purge. INSERT IGNORE pattern (PRIMARY KEY on `idem_key`). Stored result_json includes full tuple `{ok, error_code, data}`.

4. **Reconciliation Phase A+1:** since dual-convention can drift if Frontend or callback flows write directly to DB without going through new wrappers, reconciliation pass at boot + periodic. Out of Phase 5 implementation scope but tracked for Phase A+1.

5. **Migration script (Phase 5 implementation):** `migration_036_sonar_bank_idem.sql` NEW. No DB migration for money columns Phase A (per Q1 split convention).

---

## Affected LOCKED contracts (amendment Round 2 scope)

| Contract | Change | Severity |
|---|---|---|
| **C-BE-04 Bridges v1.0.1 R1** | NULLIFY §H003 Core Override entirely + replace with §H003' "Server-to-Server Integration API surface" | MAJOR |
| **C-BE-02 API Contracts v1.0.1 R1** | ADDITIVE §NEW Server-to-Server Exports (22 exports) | MAJOR additive |
| **C-BE-05 StateBags Publishers v1.0.1 R1** | Clarify mirror MUST `Publish.BalanceUpdate()` per CP1-B mandate (no semantic change, explicit confirmation) | MINOR |
| **C-SEC-01 Audit Hooks v0.2** | Reaffirm 10-field shape applies to exports surface (no semantic change) | MINOR |

---

## Sign-off

| Role | Status | Date |
|---|---|---|
| **Founder yaboula** | LOCKED ✅ | 2026-05-12 |
| **PM Cascade** | Recorded + verified scope impact + amendment package mandate emitted | 2026-05-12 |
| **Backend Lead (Phase 5)** | Pending — receives via prompt 08 mission spec | — |
| **Security Lead (BANK-SEC.2)** | Pending — consumer review during amendment LOCK ceremony | — |

---

> **Audit reference:** PM Cascade Round 1 contractual gap analysis (chat 2026-05-12 22:05 UTC+02) flagged 4 LOCKED contracts affected + 8 open questions. Founder review + Path Y compromise reasoning (chat 2026-05-12 22:30 UTC+02). Final LOCK 2026-05-12.

---

## 9. Clarification 2026-05-12 22:50 UTC+02 — StateBag value type semantic (Phase A scope)

### Origin

PM Cascade drafting of Q2 LOCK (§2) included literal `bank.balance.<cid> = new_balance_minor (INTEGER)`. This created drafting conflict with Q1 split convention (§1) stating "Frontend display + input | DECIMAL major units | LOCKED Phase A (no touch)". Frontend reads StateBag values directly via `web-src/src/lib/bankStateBags.ts` formatted with `useI18n().money(value)` expecting DECIMAL major units.

BANK-BE.PHASE_5.1 Phase 0 onboarding flagged conflict 2026-05-12 22:30 UTC+02.

### Resolution (LOCKED Phase A)

**Path (a) confirmed:** StateBag values preserve **DECIMAL major units** Phase A, consistent with Q1 split convention. Boundary conversion `from_minor()` happens **inside the export wrapper, BEFORE invoking `Publish.BalanceUpdate()`**.

Canonical signature C-BE-05 v1.0.1 R1 §2.2.1 **unchanged Phase A**:

```lua
Publish.BalanceUpdate(citizen_id, balance_major_decimal, savings_major_decimal)
```

Wrapper internal flow:

1. Mutation in service layer (minor units integer math).
2. Convert result to DECIMAL major via `lib.units.from_minor(new_balance_minor)`.
3. Invoke `Publish.BalanceUpdate(cid, balance_major, savings_major)`.
4. StateBag keys `bank.balance.<cid>` + `bank.savings.<cid>` receive DECIMAL major (Phase A baseline preserved).
5. Frontend consumers unaffected.

### Phase A+1 commitment

When `docs/planning/roadmap_phase_a_plus_1_minor_units_migration.md` executes, StateBag value type migrates DECIMAL major → INTEGER minor as part of holistic Frontend + DB + callback migration. Phase A+1 amendment to C-BE-05 will revise §2.2.1 signature semantically.

### Intent preserved

Q2 LOCK intent preserved 100%:

- CP1-B mandate (atomic StateBag publish every mutation path) ✓
- AP-CP1-1 prohibition (no parallel state propagation channels) ✓

Only the value TYPE clarified for Phase A scope. No semantic change to ATOMICITY or CHANNEL.

### Sign-off

| Role | Status | Date |
|---|---|---|
| Founder yaboula | ✅ SIGNED | 2026-05-12 |
| PM Cascade | ✅ Drafted clarification | 2026-05-12 |
| Backend Lead (BANK-BE.PHASE_5.1) | ✅ Recommended path (a) Phase 0 | 2026-05-12 |

> **Audit trail:** append-only addendum. Q2 body §2 NOT edited. Founder decisions doc immutability stamp preserved.
