# Sonar Bank — Public API Specification

**Status:** DRAFT v0.2 — Phase 5 Pivot (Ecosystem-Closed Model) — Founder LOCK Q1-Q8 + §9 path (a) ratified 2026-05-12.
**Replaces:** Phase 4 "Core Override" approach (DEPRECATED, see `_archive/`).
**Authors:** Founder + AI Tech Lead Backend Phase 5 (BANK-BE.PHASE_5.1).
**Target consumers:** Any FiveM server resource that needs to debit/credit a
citizen's bank balance (vehicle shops, jobs, taxes, ATMs, businesses, etc).
**Promotes from:** v0.1 DRAFT 2026-05-12 (pre-LOCK Founder decisions).
**Promotion target:** v1.0 LOCKED post Phase 5 implementation 4.1-4.8 + ST-024 PASS + Phase 6 sign-off ceremony.

---

## 0. Executive summary

Sonar Bank is a **standalone closed ecosystem**. The canonical source of truth
for every citizen's bank balance is the `sonar_bank_accounts` table. Third-party
resources that mutate money **MUST** do so through the Sonar Bank public API
(`exports.sonar_bank_app:<Op>`) instead of calling `Player.Functions.AddMoney`
or equivalents in the underlying framework (qb-core / qbx_core / ESX).

The framework's own bank slot (`players.money.bank` in qb-core, `accounts` JSON
in ESX, etc.) is maintained **downstream** by Sonar Bank for read-only display
compatibility with HUDs / phones / pause menus that still read from it. It is
never the source of truth.

### Why this pivot

Phase 4 ("Core Override") attempted to intercept framework-native money
functions and redirect them to Sonar. That approach failed because:

- FiveM serializes player objects across resource boundaries → wrappers installed
  from `sonar_bridges` operate on deep-copy snapshots, not the real player.
- Third-party scripts do not consistently check the return value of `RemoveMoney`
  (e.g. qb-vehicleshop ignores `false` and delivers the vehicle anyway → free
  vehicles when Sonar vetoes).
- Admin tooling (`/givemoney`, `/setmoney`) operates on qb-core's real player in
  qb-core's Lua state and is unreachable from any sibling resource.

Phase 5 accepts the friction of asking the server operator to re-route their
resources through Sonar's API in exchange for runtime reliability and audit
completeness.

---

## 1. Design principles

1. **Single source of truth.** `sonar_bank_accounts.balance` is authoritative.
   The framework bank slot is a denormalized mirror, rebuilt on every login +
   every mutation.

2. **Fail loud, fail early.** Every export returns `ok: boolean, error: string`.
   Callers MUST check `ok` before continuing their business logic (e.g. delivering
   the vehicle). Silent failures forbidden.

3. **Server-only surface.** No client-facing exports. All client flows go through
   existing ox_lib callbacks (`sonar:bank:*`) which already enforce rate limits,
   ACL, ownership, and idempotency.

4. **Idempotency first.** Mutations support an optional `idempotency_key`. Repeat
   calls with the same key return the prior result without double-applying.

5. **Audit everything.** Every mutation writes a row to `sonar_bank_audit` with
   `invoker_resource`, `actor_citizen_id`, `target_citizen_id`, `delta_minor`,
   `reason`, `correlation_id`, `idempotency_key`.

6. **Stable error taxonomy.** Error codes are strings from a closed enum
   (§5). Never expose raw SQL errors or stack traces. Callers can switch on
   error codes deterministically.

7. **Minor units on exports surface — split convention Phase A.** All amounts
   on the **public exports surface** (Tier 1/2 — §3 below) are integers in
   MINOR units (cents). Float math is banned end-to-end at the wrapper
   boundary and downstream. 1 USD = 100 minor.

   **Boundary helpers mandate (Q1 LOCKED):** the surface boundary helpers
   `sonar_bank_app/server/lib/units.lua` (`to_minor` / `from_minor`,
   HALF_UP rounding) convert between INTEGER minor (exports surface) and
   DECIMAL major (legacy DB columns DECIMAL(19,2) + callbacks C001-C040 +
   Frontend display + StateBag/NetEvent payload Phase A — path (a)
   Founder §9 LOCKED 2026-05-12).

   **Phase A+1 commitment:** holistic migration end-to-end DB DECIMAL →
   BIGINT + callback signatures + Frontend types + StateBag payloads to
   INTEGER minor. Roadmap canonical
   `@docs/planning/roadmap_phase_a_plus_1_minor_units_migration.md`.
   Until then, split convention is the explicit contract.

---

## 2. Trust model

FiveM server-side `exports` are invocable **only by other server resources**.
Clients have no direct channel to call them. Therefore:

- We do NOT use HMAC / JWT / signed tokens on the export surface. These would be
  theater: any resource on the server is equally trusted by the FiveM runtime.
- We DO use `GetInvokingResource()` for audit and — for Tier 2 admin exports —
  for optional allowlisting against a configured set of resources.
- Client-triggered flows (NUI buttons, in-game commands) are handled exclusively
  through `sonar:bank:*` net events / ox_lib callbacks with ACL + rate limit +
  ownership checks. Those layers are unchanged.

### Attack surface table

| Surface | Callable from client? | Validation |
|---|---|---|
| `exports.sonar_bank_app:*` | NO | Strict arg checks + audit |
| `sonar:bank:*` callbacks | YES (via NUI) | ACL + rate limit + ownership + idempotency |
| Direct SQL | NO (DB only) | Not exposed |

---

## 3. Tier structure

### Tier 1 — Public mutation API (11 exports — Q6 LOCKED)

For day-to-day integrations (vehicle shops, jobs, taxes, ATMs). These are the
exports that third-party resources SHOULD use.

**Tier 1 base (6 — by-source, requires player online):**

| Export | Purpose |
|---|---|
| `AddMoney(source, amount_minor, reason, opts?)` | Credit source's primary IBAN. |
| `RemoveMoney(source, amount_minor, reason, opts?)` | Debit source's primary IBAN. Fails if insufficient (always — Tier 1 NEVER admits `allow_overdraft`). |
| `CanAfford(source, amount_minor)` | Returns `ok, balance_minor`. Cheap read. |
| `GetBalance(source)` | Returns `ok, balance_minor, savings_minor`. |
| `TransferBySource(from_src, to_src, amount_minor, reason, opts?)` | Atomic P2P. |
| `TransferByIban(from_iban, to_iban, amount_minor, reason, opts?)` | Atomic by IBAN — citizen-agnostic, no `*ByCitizen` sibling needed. |

**Tier 1 *ByCitizen siblings (5 — offline-safe, Q6 LOCKED):**

| Export | Purpose |
|---|---|
| `AddMoneyByCitizen(citizen_id, amount_minor, reason, opts?)` | Idem AddMoney; resolves citizen → primary IBAN; mirror sync deferred to next PlayerLoaded if offline. |
| `RemoveMoneyByCitizen(citizen_id, amount_minor, reason, opts?)` | Idem RemoveMoney offline-safe. |
| `CanAffordByCitizen(citizen_id, amount_minor)` | Idem CanAfford. |
| `GetBalanceByCitizen(citizen_id)` | Idem GetBalance. |
| `TransferByCitizen(from_cid, to_cid, amount_minor, reason, opts?)` | Idem TransferBySource. |

### Tier 2 — Admin/operator API (10 exports — Q5 + Q6 + Q7 LOCKED)

Restricted. Intended for admin panels, in-game admin commands, sysops tooling.
Requires caller to pass an explicit `actor_src` (or `0` for console) for audit;
optionally allowlisted by invoker resource via convar `sonar:admin_allowlist`.

**Tier 2 admits `opts.allow_overdraft = true` (Q5 LOCKED) — Tier 1 NEVER admits it.**

**Tier 2 honors rigid fees (Q7 LOCKED) — NO `opts.skip_fees` / `opts.fee_override_minor`.**

**Tier 2 base (5 — by-source):**

| Export | Purpose |
|---|---|
| `AdminCredit(actor_src, target_src, amount_minor, reason, opts?)` | Gift money (bypasses Tier 1 insufficient-funds rules). |
| `AdminDebit(actor_src, target_src, amount_minor, reason, opts?)` | Seize money. `opts.allow_overdraft` permitido. |
| `AdminSetBalance(actor_src, target_src, new_balance_minor, reason, opts?)` | Overwrite balance. `opts.allow_overdraft` permitido. |
| `Freeze(actor_src, target_iban, reason)` | Block debits on an IBAN. |
| `Unfreeze(actor_src, target_iban, reason)` | Restore. |

**Tier 2 *ByCitizen siblings (5 — offline-safe):**

| Export | Purpose |
|---|---|
| `AdminCreditByCitizen(actor_src, citizen_id, amount_minor, reason, opts?)` | Idem AdminCredit offline-safe. |
| `AdminDebitByCitizen(actor_src, citizen_id, amount_minor, reason, opts?)` | Idem AdminDebit. |
| `AdminSetBalanceByCitizen(actor_src, citizen_id, new_balance_minor, reason, opts?)` | Idem AdminSetBalance. |
| `FreezeByCitizen(actor_src, citizen_id, reason)` | Resolves citizen → primary IBAN → freezes. |
| `UnfreezeByCitizen(actor_src, citizen_id, reason)` | Idem unfreeze. |

**Total surface = 22 mutation exports** (Tier 1 11 + Tier 2 10) + 1 informational (`GetApiVersion()`) = 23 exports.

### Tier 3 — Internal (NOT exported)

Business services consumed only by Tier 1/2 wrappers: `AccountService`,
`TransferService`, `LoanService`, `AdminService`, repos, validators, audit.
Direct access denied to third parties.

---

## 4. Canonical export signatures (Lua-style)

### 4.1 `AddMoney`

```lua
---@param source integer    server player id (NOT citizen_id — use *ByCitizen variant for that)
---@param amount_minor integer  positive integer in minor units
---@param reason string     free-text, sanitized server-side (audit trail)
---@param opts table|nil    optional { idempotency_key?, correlation_id?, account_iban? }
---@return boolean ok
---@return string|nil error   nil on success, error code on failure
---@return table|nil data     { new_balance_minor, iban, tx_id } on success
exports.sonar_bank_app:AddMoney(source, amount_minor, reason, opts)
```

**Example (migration from qb-core):**
```lua
-- OLD (Phase 4 compatible, now blocked):
Player.Functions.AddMoney('bank', 500, 'paycheck')

-- NEW (Phase 5):
local ok, err, data = exports.sonar_bank_app:AddMoney(source, 50000, 'paycheck')
if not ok then
    print(('paycheck failed: %s'):format(err))
    return
end
```

### 4.2 `RemoveMoney`

```lua
---@param source integer
---@param amount_minor integer  positive; debit amount
---@param reason string
---@param opts table|nil { idempotency_key?, correlation_id?, account_iban?, reason_meta? }
---@return boolean ok
---@return string|nil error    'INSUFFICIENT_FUNDS' | 'ACCOUNT_FROZEN' | 'ACCOUNT_NOT_FOUND' | 'PLAYER_NOT_LOADED' | ...
---@return table|nil data      { new_balance_minor, iban, tx_id }
exports.sonar_bank_app:RemoveMoney(source, amount_minor, reason, opts)
```

**Note (Q5 LOCKED):** Tier 1 `RemoveMoney` does NOT accept `opts.allow_overdraft`.
If caller needs overdraft, they must use Tier 2 `AdminDebit` with `opts.allow_overdraft = true`.
Tier 1 RemoveMoney always rejects with `INSUFFICIENT_FUNDS` if `balance < amount_minor`.

**Example (vehicle shop migration):**
```lua
-- OLD:
if Player.Functions.RemoveMoney('bank', vehicle.price, 'vehicle-bought') then
    GiveVehicle(source, vehicle)
end

-- NEW:
local ok, err = exports.sonar_bank_app:RemoveMoney(
    source, vehicle.price_minor, 'vehicle-bought-in-showroom'
)
if not ok then
    if err == 'INSUFFICIENT_FUNDS' then
        TriggerClientEvent('ox_lib:notify', source, { type='error', title='Not enough funds' })
    else
        TriggerClientEvent('ox_lib:notify', source, { type='error', title='Bank error', description=err })
    end
    return
end
GiveVehicle(source, vehicle)
```

### 4.3 `CanAfford`

```lua
---@return boolean ok   true if balance >= amount_minor
---@return integer balance_minor  current balance
---@return string|nil error
exports.sonar_bank_app:CanAfford(source, amount_minor)
```

### 4.4 `TransferBySource`

```lua
---@return boolean ok
---@return string|nil error
---@return table|nil data  { from_iban, to_iban, amount_minor, tx_id, fee_minor }
exports.sonar_bank_app:TransferBySource(from_src, to_src, amount_minor, reason, opts)
```

Atomic. Uses an SQL transaction internally. On failure, no partial state.

### 4.5 `AdminCredit` / `AdminDebit` / `AdminSetBalance` (Tier 2)

```lua
---@param actor_src integer    src of admin caller; 0 = server console
---@param target_src integer   target player src (use AdminCreditByCitizen for offline)
---@param amount_minor integer positive integer minor units
---@param reason string        free-text sanitized server-side
---@param opts table|nil       { idempotency_key?, correlation_id?, allow_overdraft?, reason_meta? }
---@return boolean ok
---@return string|nil error
---@return table|nil data  { iban, new_balance_minor, tx_id }
exports.sonar_bank_app:AdminCredit(actor_src, target_src, amount_minor, reason, opts)
exports.sonar_bank_app:AdminDebit(actor_src, target_src, amount_minor, reason, opts)
exports.sonar_bank_app:AdminSetBalance(actor_src, target_src, new_balance_minor, reason, opts)
```

**Auth gate (one of, Q4 LOCKED):**
- `actor_src == 0` (server console), OR
- Player at `actor_src` has ACE `sonar.bank.admin`, OR
- Invoking resource is in the convar-configured allowlist `sonar:admin_allowlist`.

**Overdraft policy (Q5 LOCKED, Tier 2 only):** `opts.allow_overdraft = true`
permits resulting balance to go negative. Default `false`. Tier 1 NEVER admits
this flag (silently ignored if passed; `RemoveMoney` always rejects with
`INSUFFICIENT_FUNDS`). When overdraft is authorized, the audit row uses
`event_type = 'bank_overdraft'` (NEW C-SEC-01 v0.3 R2 enum entry).

**Fees policy (Q7 LOCKED):** rigid — `opts.skip_fees` and `opts.fee_override_minor`
NOT supported. Tier 2 honors `Config.FeePolicies` automatically same as Tier 1.
Operator adjusts fees globally via config — per-call exceptions invite abuse.

---

## 5. Error taxonomy

Closed enum. Callers can switch deterministically.

| Code | Meaning |
|---|---|
| `INVALID_ARGUMENT` | Malformed input (wrong type, negative where positive required, etc). |
| `INVALID_AMOUNT` | Amount is 0, negative, or overflows safe integer. |
| `PLAYER_NOT_FOUND` | `source` has no active citizen identity. |
| `ACCOUNT_NOT_FOUND` | Citizen has no active account. |
| `ACCOUNT_FROZEN` | IBAN is frozen; mutations blocked. |
| `ACCOUNT_CLOSED` | IBAN is closed. |
| `INSUFFICIENT_FUNDS` | Balance < amount for debit. |
| `LIMIT_EXCEEDED` | Per-transaction / daily / per-citizen limit breached. |
| `AUTH_ACE_DENIED` | Caller lacks required ACE (`sonar.bank.admin` for Tier 2). |
| `AUTH_ALLOWLIST_DENIED` | Tier 2 export invoked but `GetInvokingResource()` not in `sonar:admin_allowlist` convar AND no ACE granted AND not console. Distinct from `AUTH_ACE_DENIED` (player lacks ACE). |
| `RATE_LIMITED` | Too many requests (only applies if export is backed by rate limiter). |
| `IDEMPOTENCY_REPLAY` | Returning cached result from prior identical call. **NOT an error**; `ok=true`, `data` populated. |
| `INTERNAL_ERROR` | DB failure or unexpected exception. Logged with stack trace server-side; sanitized string returned. |
| `PLAYER_NOT_LOADED` | (Q8 LOCKED) Player `source` exists but framework PlayerData not yet loaded (PRE-PlayerLoaded race). Caller SHOULD retry after framework `PlayerLoaded` event. Hint provided in error data: `{ retry_after_event = '<framework-specific>' }`. Distinct from `PLAYER_NOT_FOUND` (source dropped or invalid). Detection via `Bridges.Identity.IsLoaded(source)` helper (NEW C-BE-04 §3.2 amendment Round 2). |
| `IBAN_INVALID` | `TransferByIban` with malformed/non-existent IBAN. |
| `CITIZEN_NOT_FOUND` | `*ByCitizen` variants where citizen_id has no record in DB (ever existed). Distinct from `PLAYER_NOT_FOUND` (citizen exists in DB but no active session). |
| `ACCOUNT_ALREADY_FROZEN` | `Freeze` on already-frozen IBAN. |
| `ACCOUNT_NOT_FROZEN` | `Unfreeze` on non-frozen IBAN. |

---

## 6. Reactive balance propagation — CP1-B mandatory (Q2 LOCKED) + framework wallet mirror best-effort

### 6.1 CP1-B canonical channel — `publish_balance_update` (Q2 + §9 LOCKED)

After every successful mutation, Sonar Bank invokes the canonical helper
`publish_balance_update(citizen_id, balance, account_class, opts)`
(C-BE-05 §2.2.1 LOCKED v1.0.1 R1) — **mandatory**, **post-COMMIT atomic**, **before
returning to the caller**. AP-CP1-1 prohibits parallel state propagation
channels (no custom `TriggerClientEvent`, no `GlobalState` writes, no shadow
NetEvent invented by wrappers).

The helper fires NetEvent CP1-B targeted at the balance owner only:
- `sonar:bank:balance:update` for `account_class == 'main'`
- `sonar:bank:savings:update` for `account_class == 'savings'`

One call per `account_class` affected. Cross-account internal transfer = 2
calls (main + savings). P2P transfer between 2 citizens = 2 calls (1 per
citizen, both `account_class = 'main'` typically).

**Path (a) value type Phase A LOCKED (Founder §9 2026-05-12):** the `balance`
argument is **DECIMAL major** (string lossless `"1234.56"` or number 1234.56)
during Phase A. Wrapper Tier 1/2 converts INTEGER minor → DECIMAL major via
`units.from_minor()` BEFORE invoking the helper. Frontend consumers
(`web-src/src/lib/bankStateBags.ts`) parse `balance` as DECIMAL and format with
`useI18n().money(value)`. Phase A+1 migrates the value type holistically
(roadmap `@docs/planning/roadmap_phase_a_plus_1_minor_units_migration.md`).

### 6.2 Atomicity guarantee (cross-decision #2 Founder)

The SQL transaction commits the following atomically:
1. Balance mutation (`sonar_bank_accounts.balance`).
2. Movement append-only row (`sonar_bank_movements`).
3. Audit row 10-field shape (`sonar_audit_log`) per C-SEC-01 §1.2.
4. Idempotency upsert (`sonar_bank_idem`) if `opts.idempotency_key` present.

If any of steps 1-4 fail → rollback total + return error to caller.

Post-COMMIT (best-effort, NO rollback if they fail):
5. `publish_balance_update(...)` NetEvent CP1-B (this section).
6. Framework wallet mirror sync.

### 6.3 Framework wallet mirror (best-effort)

After every successful mutation, Sonar Bank asynchronously publishes the new
balance to the active framework's bank slot (`players.money.bank` qb-core,
`accounts.bank` ESX) via `MirrorSync.SetBalance(...)` (`sonar_bridges/server/core_override.lua`
simplified post Phase 5 cleanup — see C-BE-04 v1.0.2 R2 §4'.4). This is
**best effort** — the framework slot is a denormalized read-only mirror for
HUD/phone compatibility. If the mirror fails (framework down, player offline,
etc.), the Sonar ledger remains authoritative and the mirror retries on the
player's next login via `QBCore:Server:PlayerLoaded` (or framework equivalent)
handler.

---

## 7. Idempotency

Tier 1 + Tier 2 mutations accept `opts.idempotency_key`. Recommended format:
UUIDv4 or resource-prefixed unique string. Max 128 chars.

- First call with key `K`: executes, stores `{result, key, invoker_resource,
  created_at}` in `sonar_bank_idem` table (Phase 5 NEW migration
  `@resources/sonar_core/migrations/036_sonar_bank_idem.sql`) with 24h TTL +
  cron purge.
- Subsequent calls with same `K`: returns cached `result` with
  `error=IDEMPOTENCY_REPLAY`, `ok=true`. Same `K` is also persisted as
  `request_nonce` field in audit row (C-SEC-01 §1.2 10-field shape Q3 LOCKED).

**Note:** the existing `sonar_bank_idempotency_keys` table (LOCKED v1.0.1 R1
FSM #8 idempotency_lifecycle for callbacks C001-C040) is preserved for
callbacks. Exports surface uses the simpler `sonar_bank_idem` table without
FSM (INSERT IGNORE + cached result_json), suitable for atomic export semantic.

Use case: vehicle shop resource pattern:
```lua
local idem_key = ('vehshop|%s|%s'):format(plate, os.time())
local ok, err = exports.sonar_bank_app:RemoveMoney(src, price, 'vehicle', { idempotency_key = idem_key })
```

If the resource crashes and restarts mid-transaction, retrying with the same key
will not double-debit.

---

## 8. Migration path for existing resources

### 8.1 Compatibility shim — DROP (Q4 LOCKED 2026-05-12)

**Founder LOCKED 2026-05-12:** NO `sonar_compat` resource shipped. NO qb-core
re-patch. The operator MUST manually migrate every money-touching resource via
`MIGRATION.md` and `/sonar_scan_legacy` helper.

Forcing explicit migration gives the server operator visibility into which of
their resources actually touch bank — **security-positive**.

**Roadmap Phase A+N (no commitment):** opcional Python auto-fixer script for
future B2B clients. Not Phase 5 scope.

**README + MIGRATION.md mandatory:** SONAR Bank is NOT a drop-in replacement
for qb-banking. Migration friction declared upfront. Premium-grade product
positioning.

### 8.2 Operator-facing migration guide

Ship a `MIGRATION.md` with the resource that lists every common pattern and its
Sonar equivalent:

- `Player.Functions.AddMoney('bank', X, R)` → `exports.sonar_bank_app:AddMoney(src, X*100, R)`
- `Player.Functions.RemoveMoney('bank', X, R)` → ...
- `exports.qbx_core:AddMoney(src, 'bank', X, R)` → ...
- `xPlayer.addAccountMoney('bank', X)` → ...

### 8.3 Detection helper

Ship a dev command `/sonar_scan_legacy` that greps loaded resources' Lua files
for `\.Functions\.(Add|Remove|Set)Money.*bank` and prints a report so operators
know what to migrate.

---

## 9. Versioning & stability

- Public API follows SemVer. Breaking changes (signature, return shape, error
  codes removed) bump MAJOR.
- New error codes are MINOR bumps (callers should have a default branch).
- `opts` tables are additive-only.
- `GetApiVersion()` export returns `{major, minor, patch}` for consumers that
  want to feature-detect.

---

## 10. Out of scope (for this doc)

- Savings accounts (covered in existing `account_service.lua`, reuse).
- Loans (existing `loan_service.lua`).
- Business accounts (existing `business_service.lua`).
- Govt freeze/audit (existing, expose via Tier 2 exports in a follow-up doc).
- Multi-account semantics (which IBAN is "primary"? — ListByCitizen ASC default).

---

## 11. Resolved decisions (Founder LOCK 2026-05-12 — Q1-Q8 + §9)

All open questions in v0.1 resolved. Canonical reference:
`@docs/agents/teams/decisions/founder_phase_5_pivot_q1_q8_2026_05_12.md` v1.0.

| Q | Topic | Decision |
|---|---|---|
| Q1 | Minor vs major units boundary | Split convention. Exports surface INTEGER minor; DB + callbacks + Frontend + StateBag DECIMAL major Phase A. Boundary helpers `units.lua` mandatory. Phase A+1 migrates holistically. |
| Q2 | StateBag CP1-B mandate | CONFIRMED — `publish_balance_update` mandatory post-COMMIT before return. AP-CP1-1 prohibition reaffirmed. |
| Q3 | Audit shape | CONFIRMED 10-field shape per C-SEC-01 §1.2 + atomic same-TX insert. |
| Q4 | Compatibility shim | DROP. Operator migrates explicitly. |
| Q5 | Overdraft | Tier 2 only via `opts.allow_overdraft`. Tier 1 always rejects with `INSUFFICIENT_FUNDS`. |
| Q6 | *ByCitizen variants | CONFIRMED — 11 *ByCitizen siblings (5 Tier 1 + 5 Tier 2 + 1 Tier 1 not needed `TransferByIban`). Total surface = 22 mutation exports. Offline-safe. |
| Q7 | Fee policy overrides | Rigid. NO `opts.skip_fees`/`opts.fee_override_minor`. Reuse `Config.FeePolicies`. |
| Q8 | PRE-PlayerLoaded race | NEW error code `PLAYER_NOT_LOADED` distinct from `PLAYER_NOT_FOUND` with `retry_after_event` hint. |
| §9 | StateBag value type Phase A (Q1 ↔ Q2 conflict resolution) | Path (a) — `publish_balance_update` `balance` arg preserves DECIMAL major Phase A. Wrapper converts via `units.from_minor()` before helper invoke. |

---

## 12. Next steps

1. Delete Phase 4 deadwood (see cleanup plan in Task 3).
2. Implement Tier 1 exports as thin wrappers around existing services:
   `server/exports/public_api.lua`.
3. Implement Tier 2 admin exports: `server/exports/admin_api.lua`.
4. Write integration tests (console commands) covering every error code path.
5. Draft `MIGRATION.md` with concrete examples for qb-vehicleshop, qb-banking,
   qb-phone, esx_jobs, most common offenders.
6. Ship `/sonar_scan_legacy` grep helper.
