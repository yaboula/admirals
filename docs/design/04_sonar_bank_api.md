# Sonar Bank — Public API Specification

**Status:** DRAFT v0.1 — Phase 5 Pivot (Ecosystem-Closed Model)
**Replaces:** Phase 4 "Core Override" approach (DEPRECATED, see `_archive/`).
**Authors:** Founder + AI Tech Lead
**Target consumers:** Any FiveM server resource that needs to debit/credit a
citizen's bank balance (vehicle shops, jobs, taxes, ATMs, businesses, etc).

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

7. **Minor units only.** All amounts on the API surface are integers in MINOR
   units (cents). Float math is banned end-to-end. 1 USD = 100 minor.

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

### Tier 1 — Public mutation API

For day-to-day integrations (vehicle shops, jobs, taxes, ATMs). These are the
exports that third-party resources SHOULD use.

| Export | Purpose |
|---|---|
| `AddMoney(source, amount_minor, reason, opts?)` | Credit source's primary IBAN. |
| `RemoveMoney(source, amount_minor, reason, opts?)` | Debit source's primary IBAN. Fails if insufficient. |
| `CanAfford(source, amount_minor)` | Returns `ok, balance_minor`. Cheap read. |
| `GetBalance(source)` | Returns `ok, balance_minor, savings_minor`. |
| `TransferBySource(from_src, to_src, amount_minor, reason, opts?)` | Atomic P2P. |
| `TransferByIban(from_iban, to_iban, amount_minor, reason, opts?)` | Atomic by IBAN. |

### Tier 2 — Admin/operator API

Restricted. Intended for admin panels, in-game admin commands, sysops tooling.
Requires caller to pass an explicit `actor_citizen_id` for audit; optionally
allowlisted by invoker resource via convar.

| Export | Purpose |
|---|---|
| `AdminCredit(actor_src, target, amount_minor, reason)` | Gift money (bypasses insufficient-funds rules). |
| `AdminDebit(actor_src, target, amount_minor, reason)` | Seize money. |
| `AdminSetBalance(actor_src, target, new_balance_minor, reason)` | Overwrite balance. |
| `Freeze(actor_src, target_iban, reason)` | Block debits on an IBAN. |
| `Unfreeze(actor_src, target_iban, reason)` | Restore. |

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
---@param opts table|nil { idempotency_key?, correlation_id?, account_iban?, allow_overdraft? }
---@return boolean ok
---@return string|nil error    'INSUFFICIENT_FUNDS' | 'ACCOUNT_FROZEN' | 'ACCOUNT_NOT_FOUND' | ...
---@return table|nil data      { new_balance_minor, iban, tx_id }
exports.sonar_bank_app:RemoveMoney(source, amount_minor, reason, opts)
```

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

### 4.5 `AdminCredit` (Tier 2)

```lua
---@param actor_src integer|nil    src of admin caller; 0 or nil = console
---@param target integer|string    src (number) or citizen_id (string)
---@param amount_minor integer     may be negative (then it's AdminDebit)
---@return boolean ok
---@return string|nil error
---@return table|nil data  { iban, new_balance_minor, new_total_balance_minor }
exports.sonar_bank_app:AdminCredit(actor_src, target, amount_minor, reason)
```

Requires one of:
- `actor_src == 0` (server console), OR
- Player at `actor_src` has ACE `sonar.bank.admin`, OR
- Invoking resource is in the convar-configured allowlist `sonar:admin_allowlist`.

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
| `AUTH_ACE_DENIED` | Caller lacks required ACE. |
| `AUTH_ALLOWLIST_DENIED` | Invoking resource not in admin allowlist. |
| `RATE_LIMITED` | Too many requests (only applies if export is backed by rate limiter). |
| `IDEMPOTENCY_REPLAY` | Returning cached result from prior identical call. **NOT an error**; `ok=true`, `data` populated. |
| `INTERNAL_ERROR` | DB failure or unexpected exception. Logged with stack trace server-side; sanitized string returned. |

---

## 6. Mirror to framework bank slot

After every successful mutation, Sonar Bank asynchronously publishes the new
aggregate balance to the active framework's bank slot, if any. This is **best
effort** — the framework slot is a read-only mirror for HUD/phone compatibility.
If the mirror fails (framework down, player offline, etc.), the Sonar ledger
remains authoritative and the mirror will retry on the player's next login.

Clients can subscribe to `sonar:bank:balance_updated` for real-time balance
updates independent of framework slot.

---

## 7. Idempotency

Tier 1 mutations accept `opts.idempotency_key`. Recommended format: UUIDv4 or
resource-prefixed unique string.

- First call with key `K`: executes, stores `{result, key}` in `sonar_bank_idem`
  table with 24h TTL.
- Subsequent calls with same `K`: returns cached `result` with
  `error=IDEMPOTENCY_REPLAY`, `ok=true`.

Use case: vehicle shop resource pattern:
```lua
local idem_key = ('vehshop|%s|%s'):format(plate, os.time())
local ok, err = exports.sonar_bank_app:RemoveMoney(src, price, 'vehicle', { idempotency_key = idem_key })
```

If the resource crashes and restarts mid-transaction, retrying with the same key
will not double-debit.

---

## 8. Migration path for existing resources

### 8.1 Compatibility shim (optional, ship-or-drop decision)

We CAN ship a `sonar_compat` resource that re-hooks `Player.Functions.AddMoney`
to call `exports.sonar_bank_app:AddMoney` when money_type == 'bank'. This would
require the same qb-core patch we're now removing. **Recommendation: do NOT ship
it.** The entire point of Phase 5 is to stop fighting the framework. Forcing
explicit migration gives the server operator visibility into which of their
resources actually touch bank, which is security-positive.

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

## 11. Open questions

1. Do we expose `RemoveMoney` with `allow_overdraft=true` for specific use cases
   (fines, negative salary correction)? Default false.
2. Do we support `*ByCitizen` variants for offline players, or require the player
   to be online?
3. Fee policy on transfers — configurable per reason/actor?
4. What happens when `source` is a player that's loading (PRE-PlayerLoaded)?
   Probably `PLAYER_NOT_FOUND` with retry hint.

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
