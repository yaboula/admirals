# C-BE-04 — Bridges Compatibility Layer v1.1 Bank Phase A (LOCKED v1.0.2 R2)

> **Owner:** Backend Money & Compatibility Lead.
> **Consumer Leads:** DevOps Lead (fxmanifest + load order + boot sequence) + Security Lead (audit watchdog + ACE checks + exploit prevention).
> **Status:** 🟢 **v1.0.2 R2 LOCKED 2026-05-12** (BANK-BE.PHASE_5.1.LOCK.R2 ceremony — Round 2 amendment promoted post Founder LOCK Q1-Q8 + §9 path (a)).
> **Fecha:** 2026-05-12 (BANK-BE.0 → BANK-BE.LOCK → BANK-BE.AMEND.1 → BANK-BE.LOCK.R1 → BANK-BE.PHASE_5.1.LOCK.R2).
> **Path canonical:** `docs/technical/bank_phase_a/c_be_04_bridges_v1_1.md` v1.0.2 R2 LOCKED. Pointer §X.NEW `docs/technical/07_bridges_compatibility.md` v1.3.1.
> **ADR anchor:** ADR-018 (Bank Lite mode hybrid 3-layer + correlation-id mutex + cut ESX legacy + 8 mitigation patterns) — ratificado BANK-BE.LOCK + R1 hardening Round 1.

---

## 1. Filosofía Bridges Layer extends Bank Phase A

### 1.1 Inherited principles (per `07_bridges_compatibility.md` v1.2 §1.1 B1-B7)

- **B1** Nunca llamar external direct fuera `bridges/adapters/*`.
- **B2** Interface estable, implementación variable.
- **B3** Detection + fallback, nunca crash.
- **B4** Single-responsibility bridges.
- **B5** Async-by-default, sync opt-in.
- **B6** Idempotent siempre que sea posible.
- **B7** Logged at boundary.

### 1.2 NEW principles Bank Phase A (Q16 + 8 CP integrated)

- **B8 (CP1)** Bank state mutations **emit StateBag global** (CP1-A) o **discrete NetEvent** (CP1-B per privacy classification C-BE-05). NO `TriggerClientEvent` manual broadcast.
- **B9 (CP2)** Inter-framework money sync via **correlation-id metadata**. NO TTL-based mutex. NO hash-fallback.
- **B10 (CP3)** Reconciliation pipeline **async queue + batch SQL**. Inline sync prohibido (latency).
- **B11 (CP4)** Defensive boot **3-method framework detect** + **watchdog progressive (B+C combined)** + **KVP graceful disable** + **console banner crítico**.
- **B12 (CP5)** Auto-apply delta threshold default **€1000**. Sobre threshold → admin flag queue.
- **B13 (CP6)** Reconciliation scope **`account_class = 'main'` only**. Premium tiers (savings + escrow + business_treasury + crypto_wallet) son **SONAR-only by design** — fuera scope reconciliation.
- **B14 (CP8)** Resource exposes `Bridges.BankStatus.GetState()` reactive — FSM 4 states (`native_full` / `lite_mode_active` / `compromised_load_order` / `framework_missing`).
- **B15** **Cut ESX legacy <1.10 oficial**. Defensive boot abort si detected. **NO hash-fallback code paths** (Q16 LOCKED).
- **B16 (Q-BE-pre-12)** Resource scope split: libs core (mutex + reconciliation + idempotency + audit ledger + bank status + uuid) viven en `sonar_bridges/lib/`. Callbacks Bank Phase A NEW viven en `sonar_bank_app/server/`. Existing `sonar_bank/server/*` extends in-place sin migration.

---

## 2. Architecture overview Bank Phase A extends

### 2.1 Resource topology

```
┌──────────────────────────────────────────────────────────────────────────────┐
│  sonar_bridges/  (Bridges Layer canonical)                                    │
│  ├── adapters/                                                                │
│  │   ├── qbox/         (existing T1)                                          │
│  │   ├── qbcore/       (existing T1)                                          │
│  │   ├── esx/          (existing T2)                                          │
│  │   ├── ox_inventory/ (existing T1)                                          │
│  │   └── ...                                                                  │
│  ├── bridges/                                                                 │
│  │   ├── bank.lua       (extends NEW Phase A — extends API)                   │
│  │   ├── inventory.lua                                                        │
│  │   ├── phone.lua                                                            │
│  │   └── ...                                                                  │
│  ├── lib/                                                                     │
│  │   ├── uuid.lua             (NEW — UUIDv4 random)                           │
│  │   ├── mutex_echo.lua       (NEW — CP2 correlation-id mutex)                │
│  │   ├── reconciliation.lua   (NEW — CP3 async queue + batch SQL)             │
│  │   ├── idempotency_keys.lua (NEW — Q-BE-pre-06 DB persistent + result_payload cached) │
│  │   ├── audit_ledger.lua     (NEW — BankAuditLedger.Append per handoff §3.2) │
│  │   ├── bank_status.lua      (NEW — CP8 FSM transition lib)                  │
│  │   ├── companies.lua        (NEW — Q-BE-pre-07 Companies.exists passthrough)│
│  │   └── round_up.lua         (NEW — RoundUp.OnMovement hook)                 │
│  └── server/                                                                  │
│      ├── init.lua             (existing — extends defensive boot CP4)         │
│      ├── detect.lua           (existing — extends 3-method framework detect)  │
│      ├── core_override.lua    (NEW — QBox/QBCore monkey-patch RAM)            │
│      ├── lite_mode.lua        (NEW — ESX 1.10+ Triple Capa)                   │
│      └── watchdog.lua         (NEW — B+C combined sentinel + métrica)         │
└──────────────────────────────────────────────────────────────────────────────┘
                                     │
                                     │ depends on
                                     ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│  sonar_bank/  (existing — extends in-place)                                   │
│  ├── server/                                                                  │
│  │   ├── callbacks.lua       (extends C001-C005 existing)                     │
│  │   ├── transfer.lua        (extends correlation-id mutex CP2 + audit)       │
│  │   ├── escrow.lua          (extends FSM #1 escrow_lifecycle 6 states)       │
│  │   ├── accounts.lua        (extends multi-account Q-DB-D 2-col split)       │
│  │   ├── movements.lua       (extends ENUM category Q-DB-J)                   │
│  │   └── ...                                                                  │
│  └── ...                                                                      │
└──────────────────────────────────────────────────────────────────────────────┘
                                     │
                                     │ depends on
                                     ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│  sonar_bank_app/  (NEW Phase A — Q4 separated)                                │
│  ├── server/                                                                  │
│  │   ├── callbacks_app.lua   (NEW C006-C035 + C058-C062)                      │
│  │   ├── compliance_publisher.lua  (NEW reduced-shape bag CP1-A)              │
│  │   ├── elections.lua             (NEW FSM #5 election_lifecycle)            │
│  │   ├── loans.lua                 (NEW FSM #2 loan_lifecycle)                │
│  │   ├── recurring.lua             (NEW FSM #3 recurring_lifecycle)           │
│  │   ├── physical_cards.lua        (NEW FSM #4 physical_card_lifecycle)       │
│  │   ├── business_treasury.lua     (NEW FSM #6 business_treasury_approval)    │
│  │   ├── crypto.lua                (NEW Tier 4 crypto)                        │
│  │   ├── stocks.lua                (NEW Tier 4 stocks + RecomputeHoldings)    │
│  │   ├── atm_minigame.lua          (NEW Tier 4)                               │
│  │   └── ...                                                                  │
│  ├── web-src/                (Frontend Lead H4 scope — NUI standalone)        │
│  └── ...                                                                      │
└──────────────────────────────────────────────────────────────────────────────┘
```

### 2.2 Boot sequence

```
1. oxmysql start (dependency)
2. ox_lib start (dependency)
3. sonar_core start (foundation)
4. sonar_bridges onResourceStarting:
   - Load adapters/ + bridges/ + lib/
5. sonar_bridges onResourceStart:
   - detect.lua: 3-method framework detect (CP4)
     - Method 1: getResourceState('qb-core') / ('qbx_core') / ('es_extended')
     - Method 2: exports['qb-core'] / ESX existence check
     - Method 3: native fallback (no framework → SONAR native mode flag)
   - Decision tree:
     - QBox detected → core_override.lua install + bank_status transit `native_full`
     - QBCore detected → core_override.lua install + bank_status transit `native_full`
     - ESX 1.10+ detected → lite_mode.lua install + bank_status transit `lite_mode_active`
     - ESX <1.10 detected → SetResourceKvp('sonar_bank_disabled', 'unsupported_esx_legacy') + bank_status `framework_missing` + console banner ABORT
     - NO framework detected → KVP set + bank_status `framework_missing` + console banner ABORT
   - watchdog.lua schedule progressive checks (T+30s, T+5min, T+30min)
6. sonar_bank onResourceStarting:
   - Check Bridges.BankStatus.IsDisabled() — if YES, skip register callbacks (graceful)
7. sonar_bank onResourceStart:
   - Register C001-C005 callbacks extends
   - Hydrate bank_movements partitions ready (DB Lead handoff)
8. sonar_bank_app onResourceStarting:
   - Check BankStatus.IsDisabled() — same graceful path
9. sonar_bank_app onResourceStart:
   - Register C006-C035 + C058-C062 callbacks
   - Hydrate StateBag global publishers (per C-BE-05 §4.1)
   - Cron jobs schedule (recurring tick + business approvals expiry + idempotency TTL purge)
   - log_info '[SONAR][bank] Phase A ready: <bank_status>'
```

---

## 3. Bridges API canonical Bank Phase A (extends)

### 3.1 Existing API (preserved — NO breaking changes per Q-BE-pre-11)

```lua
-- Existing API current sonar_bridges/bridges/bank.lua (estado v1.2):
Bridges.Bank.AddMoney(citizen_id, amount, reason)                 → success | error
Bridges.Bank.RemoveMoney(citizen_id, amount, reason)              → success | error
Bridges.Bank.GetBalance(citizen_id)                               → number | error
Bridges.Bank.Transfer(from_iban, to_iban, amount, reason)         → success | error
```

### 3.2 NEW API extends Bank Phase A v1.1

```lua
-- NEW signatures additive (Q-BE-pre-11 — no breaking).
-- All NEW APIs accept opts table additionally.

Bridges.Bank.AddMoney(citizen_id, amount, reason, opts)           → result
Bridges.Bank.RemoveMoney(citizen_id, amount, reason, opts)        → result
Bridges.Bank.GetBalance(citizen_id, account_class)                → number | error  -- account_class default 'main'
Bridges.Bank.Transfer(from_iban, to_iban, amount, reason, opts)   → result
Bridges.Bank.GetStatus()                                          → string  -- CP8 FSM 4 states
Bridges.Bank.IsDisabled()                                         → boolean
Bridges.BankStatus.GetState()                                     → string  -- READ-ONLY public (no auth gate)
Bridges.BankStatus.Transition(new_state, reason, metrics, opts)   → success | error  -- ⚠️ AUTH-GATED v1.0.1 R1 (H002): caller MUST be source=0 (console) OR P12 ACE OR whitelisted internal_call. opts.caller_source mandatory non-nil. See §3.2.1.
Bridges.BankStatus.IsDisabled()                                   → boolean  -- READ-ONLY public (no auth gate)
Bridges.BankStatus.RegisterChangeHandler(fn)                      → unregister_fn  -- READ-ONLY listener registration. Handler runs in caller resource sandbox. NO mutation capability.
Bridges.UUID.v4()                                                 → string  -- v1.0.1 R1 multi-entropy PRNG mix per §3.3.1 (M002 fix)

-- opts table canonical shape:
opts = {
  correlation_id = 'uuid_v4_string',  -- auto-generated if missing (CP2)
  idempotency_key = 'string',          -- DB persisted Q-BE-pre-06
  metadata = { ... },                   -- arbitrary metadata audit ledger
  source_caller = 'string',             -- e.g. 'sonar_bank_app:transfer' for audit trail
}

-- result table canonical shape:
result = {
  status = 'ok' | 'error',
  data = { balance_after = number, movement_id = number, audit_id = number },
  error = { code = 'ERROR_CODE', message = 'human-readable' } | nil,
  correlation_id = 'echo_back_uuid',
}
```

### 3.2.1 `Bridges.BankStatus.Transition` auth gate (NEW v1.0.1 R1 — H002 fix)

Export crítico — fuerza transitions FSM Bank Status (§4.x compromised_load_order / lite_mode_active / framework_missing). DoS-capable si exposed sin gate.

**Auth contract:**

```lua
function Bridges.BankStatus.Transition(new_state, reason, metrics, opts)
  -- opts.caller_source: number (mandatory v1.0.1 R1) — player handle of caller. 0 = console.
  -- opts.internal_call: boolean (optional) — true si caller es internal SONAR resource (whitelist).
  if not opts or type(opts.caller_source) ~= 'number' then
    return { status = 'error', error = { code = 'AUTH_GATE_REQUIRED', message = 'caller_source mandatory in opts' } }
  end

  -- Allowed paths:
  -- 1. Internal call from sonar_* resources (whitelisted).
  if opts.internal_call and is_whitelisted_resource(GetInvokingResource()) then
    -- Whitelist: sonar_bridges, sonar_bank, sonar_bank_app, sonar_core (defined convar `sonar_status_transition_whitelist`).
    return _do_transition(new_state, reason, metrics)
  end

  -- 2. Console invocation (server-only command, e.g. txAdmin / sysadmin).
  if opts.caller_source == 0 then
    return _do_transition(new_state, reason, metrics)
  end

  -- 3. Player with P12 ACE permission (DevOps diagnostics).
  if IsPlayerAceAllowed(opts.caller_source, 'sonar.devops.bank.diagnostics') then
    return _do_transition(new_state, reason, metrics)
  end

  -- Reject: log security incident + audit hook
  log_security_alert('bankstatus_transition_unauthorized', {
    caller_source = opts.caller_source,
    invoking_resource = GetInvokingResource(),
    attempted_state = new_state,
  })
  audit_hook_auth_fail({
    callback_id = 'Bridges.BankStatus.Transition',
    source = opts.caller_source,
    citizen_id_attempted = Bridges.Player.GetCitizenId(opts.caller_source),
    reason = 'unauthorized_status_mutation_attempt',
    timestamp = os.time() * 1000,
  })
  return { status = 'error', error = { code = 'AUTH_FORBIDDEN', message = 'P12 ACE required or console call' } }
end
```

**Whitelist convar:** `sonar_status_transition_whitelist` default `"sonar_bridges,sonar_bank,sonar_bank_app,sonar_core"` (CSV). Sysadmin can adjust if custom resource extensions.

**Internal callsites:** all sonar_bridges code paths (defensive_abort, watchdog_check_tier) call with `opts={caller_source=0, internal_call=true}`.

**Audit hook integration:** every Transition call (success OR fail) generates `audit_hook_watchdog_status_change` if state actually changed. Unauthorized attempts log `audit_hook_auth_fail`.

### 3.3 Backwards compatibility

Existing callsites `Bridges.Bank.AddMoney(cid, 100, 'reason')` (3-arg) → continúan funcionando. `opts` parameter optional (default `nil`). Si `opts == nil` → mutex correlation-id auto-generated + idempotency_key auto-generated (UUID v4) + metadata empty.

**Impact existing code:** **ZERO breaking** — solo adds opts capability.

### 3.3.1 `Bridges.UUID.v4` PRNG entropy spec (NEW v1.0.1 R1 — M002 fix)

`Bridges.UUID.v4()` es la **única canonical UUID source** en SONAR Bank — correlation_id (CP2 mutex), idempotency_key fallback (C-BE-02 §5.2), audit hook correlation_id, sentinel signatures (§4.2 H003).

**Implementation spec (`sonar_bridges/lib/uuid.lua`):**

```lua
-- sonar_bridges/lib/uuid.lua (v1.0.1 R1 hardened entropy mix)
local M = {}

-- Per-call entropy mix:
--   1. os.clock() — sub-second monotonic (process-local).
--   2. GetGameTimer() — FiveM-internal monotonic ms.
--   3. os.time()*1000 — wall-clock epoch ms.
--   4. math.random(1, 2^31-1) — re-seeded each call.
--   5. (optional) GetPlayerPing(source) if source > 0 (network-derived noise).
-- All combined → SHA256 → first 32 hex chars → formatted RFC 4122 v4 (8-4-4-4-12).

local function reseed_random()
  math.randomseed(os.clock() * 1e9 + GetGameTimer() + os.time())
end

function M.v4(opts)
  reseed_random()
  local entropy_blob = string.format(
    '%f|%d|%d|%d|%d',
    os.clock(),
    GetGameTimer(),
    os.time() * 1000,
    math.random(1, 2147483647),
    (opts and opts.source and opts.source > 0) and (GetPlayerPing(opts.source) or 0) or 0
  )
  local hash = sha256_hex(entropy_blob)  -- 64 hex chars
  local version_nibble = '4'
  local variant_nibble_choices = { '8', '9', 'a', 'b' }
  local variant_nibble = variant_nibble_choices[(tonumber(hash:sub(17, 17), 16) % 4) + 1]
  return string.format(
    '%s-%s-%s%s-%s%s-%s',
    hash:sub(1, 8),
    hash:sub(9, 12),
    version_nibble, hash:sub(14, 16),
    variant_nibble, hash:sub(18, 20),
    hash:sub(21, 32)
  )
end

return M
```

**Performance budget:** <0.5ms p99 per call (1KB string SHA256 ~negligible).

**Anti-patterns:**
- ❌ **AP-UUID-1 (v1.0.1 R1):** `string.format('%x%x%x', math.random(), os.time(), os.clock())` — entropy mix naïve insuficiente, predictable post-boot.
- ❌ `math.random()` plain sin reseed — deterministic per state-shared.
- ❌ External library no-canonical — rompe SSoT.

**Phase B target:** migrate to FFI native crypto (`require('crypto.random_bytes')(16)` if available) — eliminates pure-Lua SHA256 dependency.

---

## 4. Core Override module — DEPRECATED Phase 5 pivot (2026-05-12)

> **Status:** 🚫 DEPRECATED — Phase 5 architectural pivot Founder LOCKED 2026-05-12.
>
> Esta sección describía el módulo Core Override (monkey-patch runtime de
> `Player.Functions.AddMoney/RemoveMoney/SetMoney/GetMoney` en QBox/QBCore).
> El modelo "parásito invisible" fue abandonado por bloqueos arquitectónicos
> insuperables (FiveM resource-boundary serialization, third-party scripts
> ignoran return values, admin tooling Lua-isolated, qb-core patch GPL-coupling).
>
> **Reemplazo canónico:** §4' Server-to-Server Integration API surface (abajo).
> **Design SSoT:** `@docs/design/04_sonar_bank_api.md` v0.2.
> **Phase 4 freeze baseline:** commit `c4ea87a` (rollback point).
> **Migration path operator-side:** `MIGRATION.md` (Phase 4.7) + `/sonar_scan_legacy` helper (Phase 4.8). Q4 LOCKED — NO `sonar_compat` shim.
> **Authority:** `@docs/agents/teams/decisions/founder_phase_5_pivot_q1_q8_2026_05_12.md` v1.0.
>
> Contenido original v1.0.1 R1 preservado en bloque siguiente para audit trail.
> NO consume este pseudo-código; queda como artefacto histórico únicamente.

<details>
<summary>Audit trail — contenido §4 v1.0.1 R1 (DEPRECATED, do not consume)</summary>

### 4.1 Approach decision (per Q-BE-pre-05 founder green-light) — DEPRECATED

**Hybrid B + C combined:**

- **B) Sentinel attribute** post-monkey-patch — `QBCore.__sonar_patched = { applied_at = epoch_ms, version = '1.0' }`.
- **C) Métrica indirecta** — listener on framework events (e.g. `esx:setAccountMoney`) verifies correlation-id sonar inyectado en metadata. Si X minutos pasan sin events con correlation-id sonar AND money mutations occurring → suspect compromise.

### 4.2 Pseudo-code spec — DEPRECATED

```lua
-- sonar_bridges/server/core_override.lua
-- Core Override module — runtime monkey-patch QBox/QBCore Player.Functions.AddMoney/RemoveMoney/GetMoney/SetMoney.
-- Aplica solo si framework_detect ∈ {QBox, QBCore} (CP4 detect).

local function install_qbcore_override()
  -- v1.0.1 R1 H003: idempotent check via GlobalState (NOT public attribute).
  local existing = GlobalState['sonar_bridges.core_override.sentinel']
  if existing and existing.signature then
    log_warn('core_override: already patched (sentinel signature ' .. existing.signature .. '), skipping idempotent boot')
    return
  end

  -- Capture originals
  local original_addmoney = QBCore.Functions.GetPlayer  -- adjusted per actual API shape
  -- ... pattern extends getter Player.Functions.AddMoney + RemoveMoney + GetMoney + SetMoney

  -- Monkey-patch via metatable proxy (preferred over direct function replacement — supports closures)
  local patched_player_functions_mt = setmetatable({}, {
    __index = function(t, key)
      if key == 'AddMoney' then
        return function(self, money_type, amount, reason)
          if money_type == 'bank' then
            -- Redirect to SONAR
            local citizen_id = self.PlayerData.citizenid
            return Bridges.Bank.AddMoney(citizen_id, amount, reason or 'qb_native', {
              correlation_id = Bridges.UUID.v4(),
              source_caller = 'qbcore_native_addmoney',
            })
          else
            return original_addmoney(self, money_type, amount, reason)  -- pass-through cash
          end
        end
      end
      -- ... RemoveMoney + GetMoney + SetMoney symmetric
      return original_addmoney  -- fallback
    end,
  })

  -- v1.0.1 R1 H003: hardened sentinel triple-defense (eliminado QBCore.__sonar_patched mutable):
  --   Layer 1: closure-local upvalue (NOT public attribute).
  --   Layer 2: GlobalState read-only replicated=false (server-only sentinel).
  --   Layer 3: SHA256 checksum of the patched function for integrity verification at watchdog time.

  local sentinel_signature = Bridges.UUID.v4()
  local patched_addmoney_fn = patched_player_functions_mt.__index({}, 'AddMoney')  -- materialize patched function reference
  local patched_checksum = sha256_hex(string.dump(patched_addmoney_fn))  -- function bytecode hash

  -- Defense layer 1: closure-local upvalue (NOT exposed to global)
  local _sentinel_upvalue = {
    applied_at = os.time() * 1000,
    version = '1.0.1',
    signature = sentinel_signature,
    checksum = patched_checksum,
    fn_ref = patched_addmoney_fn,  -- direct reference for re-verification
  }

  -- Defense layer 2: GlobalState server-only (replicated=false) — read-only from client perspective.
  GlobalState:set('sonar_bridges.core_override.sentinel', {
    applied_at = _sentinel_upvalue.applied_at,
    signature = sentinel_signature,
    checksum = patched_checksum,
  }, false)  -- replicated=false → NOT sent to clients.

  -- Defense layer 3: closure-local watchdog probe function (introspect upvalue at call time).
  _G._sonar_core_override_probe = function()
    local current_fn = QBCore.Functions and QBCore.Functions.AddMoney  -- whatever current mapping
    return {
      sentinel = _sentinel_upvalue,
      fn_still_patched = (current_fn == _sentinel_upvalue.fn_ref),
      checksum_current = current_fn and sha256_hex(string.dump(current_fn)) or nil,
    }
  end

  -- ⚠️ NUNCA: QBCore.__sonar_patched = ... (public mutable attribute — removed v1.0.1 R1 H003 fix).

  -- Schedule watchdog tier checks (consume probe via _G._sonar_core_override_probe)
  Citizen.SetTimeout(30000, function() watchdog_check_tier(1, 'T+30s_initial') end)
  Citizen.SetTimeout(300000, function() watchdog_check_tier(2, 'T+5min_progressive') end)
  Citizen.SetTimeout(1800000, function() watchdog_check_tier(3, 'T+30min_long_tail') end)

  log_info('core_override: QBCore monkey-patch applied + hardened sentinel (closure + GlobalState + checksum) + watchdog scheduled')
end
```

### 4.2.1 SHA256 utility (NEW v1.0.1 R1 — H003 dependency) — DEPRECATED

`sha256_hex(input_string)` lib helper required for function bytecode hashing. Implementation options:

- **Phase A:** pure-Lua SHA256 implementation (e.g. adapted from `lua-sha256` library, ~150 LoC) en `sonar_bridges/lib/sha256.lua`.
- **Phase B:** native FFI binding (`oxmysql` ships with mysql native crypto OR `lua-crypto` if available) for perf.

Performance budget: bytecode hash function (typically <2KB string) → <5ms p99. Watchdog checks <1Hz → no perf concern.

### 4.3 Caveats + edge cases — DEPRECATED

- **QBox API surface:** difiere ligeramente de QBCore. `qbx_core` exports + `qbx.PlayerFunctions` shape. Adapter `sonar_bridges/adapters/qbox/core_override_qbox.lua` per-framework.
- **Multi-framework simultaneous:** if both QBox + QBCore detected → log warn + abort Core Override + transit `compromised_load_order` (config conflict).
- **Hot-reload `restart sonar_bridges`:** sentinel idempotent boot — re-apply detect + skip if already patched same boot session.
- **External resource patches (other resources monkey-patch same functions post-SONAR):** watchdog métrica C indirect detects. Transit `compromised_load_order`.

</details>

---

## 4'. Server-to-Server Integration API surface (NEW v1.0.2 R2 — Phase 5)

### 4'.1 Modelo arquitectónico

SONAR Bank es un **ecosistema cerrado** en estilo ox_inventory (Overextended). Los recursos third-party que mutan dinero NO interceptan funciones nativas del framework — invocan explícitamente la superficie pública de exports SONAR Bank documentada en `@docs/design/04_sonar_bank_api.md` v0.2.

**Cobertura de la superficie pública:**

- **Tier 1 (11 exports)** — mutaciones day-to-day (`AddMoney`, `RemoveMoney`, `CanAfford`, `GetBalance`, `TransferBySource`, `TransferByIban`) + 5 `*ByCitizen` siblings para players offline (Q6 LOCKED).
- **Tier 2 (10 exports)** — admin/operator (`AdminCredit`, `AdminDebit`, `AdminSetBalance`, `Freeze`, `Unfreeze`) explicit pairs + 5 `*ByCitizen` siblings (Founder Decision #1 LOCKED 2026-05-12 = 22 explicit). Tier 2 admite `opts.allow_overdraft = true` (Q5 LOCKED, único caso).
- **Tier 3 (internal)** — servicios bancarios consumidos sólo por Tier 1/2 wrappers; no exportados a third parties.
- **`GetApiVersion()` (informational, +1)** — read-only feature-detect, no audit. Total públicos = 22 (21 mutation/read + 1 informational).

Spec canonical de los 22 públicos: `@docs/technical/bank_phase_a/c_be_02_api_contracts_v1_3.md` §10 (v1.0.2 R2).

### 4'.2 Boundary conversion convention (Q1 LOCKED split)

| Surface | Convention | Status |
|---|---|---|
| Exports surface (Tier 1/2) | INTEGER minor units | NEW Phase 5 |
| Service layer internal math | INTEGER minor units | Boundary conversion at wrapper |
| DB `sonar_bank_*` money columns | DECIMAL(19,2) major units | LOCKED Phase A (no touch) |
| Callbacks C001-C040 (LEGACY) | DECIMAL major units | LOCKED C-BE-02 (no touch Phase A) |
| Frontend display + input | DECIMAL major units | LOCKED Phase A (no touch) |

Helpers de boundary canonical `sonar_bank_app/server/lib/units.lua`:

- `units.to_minor(decimal_string|number) -> integer_minor` (HALF_UP rounding).
- `units.from_minor(integer_minor) -> decimal_string` (lossless representation para INSERT/UPDATE DB DECIMAL).

Helpers **mandatory** en el edge de cada wrapper Tier 1/2 (`to_minor` al recibir input externo, `from_minor` al invocar service layer + DB layer + a `Bridges.Player` events que esperan DECIMAL major).

Phase A+1 migra DB + callbacks + Frontend a INTEGER minor end-to-end — roadmap canonical `@docs/planning/roadmap_phase_a_plus_1_minor_units_migration.md`.

### 4'.3 Attack surface model

FiveM server-side `exports` son **invocables únicamente por otros recursos server-side**. Clients no tienen canal directo. Por tanto:

- NO se usa HMAC / JWT / signed tokens en la superficie exports — sería theater (cualquier recurso server-side es equally trusted por el FiveM runtime).
- SÍ se usa `GetInvokingResource()` para audit (campo `invoker_resource` del shape canónico §1.2.A C-SEC-01 v0.3 R2) y — para Tier 2 admin exports — para allowlisting opcional vía convar `sonar:admin_allowlist` (Q4 LOCKED no shim; allowlist es defensa adicional, no requisito).
- Client-triggered flows (NUI buttons, in-game commands) siguen pasando exclusivamente por `sonar:bank:*` net events / ox_lib callbacks con ACL + rate limit + ownership checks (LOCKED C-BE-02). Esa capa NO cambia.

| Surface | Callable from client? | Validation |
|---|---|---|
| `exports.sonar_bank_app:*` (Tier 1/2) | NO | Strict arg checks + boundary helpers + audit |
| `sonar:bank:*` callbacks (Tier 3 fronts) | YES (via NUI) | ACL + rate limit + ownership + idempotency |
| Direct SQL | NO (DB only) | Not exposed |

### 4'.4 Mirror to framework wallet (best-effort, no auth gate)

Cada mutación Tier 1/2 que afecte saldo invoca atomicamente `publish_balance_update(citizen_id, balance_major_decimal, account_class, opts)` (C-BE-05 §2.2.1 canonical helper, NetEvent CP1-B post-M004 R1) — ver `@docs/technical/bank_phase_a/c_be_05_statebags_global_publishers.md` §2.2.1 + §2.2.1.A.

Adicionalmente, `sonar_bridges/server/core_override.lua` se simplifica a ~150-200 líneas (Phase 3.2 cleanup post-LOCK) y conserva ÚNICAMENTE:

- `MirrorSync.SetBalance(citizen_id, balance_decimal, opts)` — best-effort push al wallet del framework activo (`players.money.bank` qb-core, `accounts.bank` ESX) post-mutation. Mirror failure NO bloquea la mutation — SONAR ledger es authoritative; mirror retry on player next login.
- `QBCore:Server:PlayerLoaded` + ESX + QBox equivalents login handlers para trigger initial mirror sync al rejoin.
- `Reconcile.Enqueue(citizen_id, drift_minor, reason)` — public API surface, consumida posiblemente Phase A+1 cuando se implemente reconciliation full.

**REMOVED del module simplificado (era parte de §4 Core Override DEPRECATED):**

- `install_qbcore_player` + wrappers + TRAP `__index`/`__newindex`.
- Sentinel triple-defense + SHA256 checksum + probe `_G._sonar_core_override_probe`.
- `state.in_flight`, `mirror_reason`, `consume_mirror_token`, `parse_mirror_token`.
- `OnMoneyPreHook` export (consumer qb-core local patch desinstalado Phase 3.1).
- Watchdog drift detection thread tier 1/2/3.
- `VerifyIntercept`, `GetCoreOverrideHealth` exports.
- `RegisterCommand('sonar_test_forge', ...)` dev probe.
- `RegisterCommand('mirror_sync_now', ...)` (no auto-mirror).
- QBox `registerHook` blocks (Phase 4 attempt abandonado).
- ESX observer blocks (Phase 4 attempt abandonado).

### 4'.5 Migration path operator-side (referencia)

Phase 5 NO ships `sonar_compat` shim (Q4 LOCKED — DROP definitivo). El operador del server migra cada recurso third-party explícitamente:

- `MIGRATION.md` top-level (Phase 4.7 implementation) con tabla `OLD → NEW` para 20+ recursos comunes (qb-vehicleshop, qb-banking, ...).
- `/sonar_scan_legacy` dev command (Phase 4.8) — grep resources cargados buscando `Functions\.(Add|Remove|Set)Money.*bank`, `exports.qbx_core:`, `xPlayer\.(add|remove)(Money|AccountMoney)` → reporte por recurso.

Forzar migración explícita es **security-positive**: el operador adquiere visibilidad completa de qué scripts tocan banco.

### 4'.6 Glosario Phase 5 (NEW v1.0.2 R2)

- **Exports Tier 1:** superficie pública de 11 exports server-side para recursos third-party mutar dinero (`AddMoney`, `RemoveMoney`, etc.).
- **Exports Tier 2:** superficie admin/operator de 10 exports server-side con ACE + allowlist gates (`AdminCredit`, `AdminDebit`, `AdminSetBalance`, `Freeze`, `Unfreeze` + 5 `*ByCitizen` siblings).
- **Boundary helper:** función `to_minor`/`from_minor` de `sonar_bank_app/server/lib/units.lua` para convertir entre INTEGER minor (exports surface) y DECIMAL major (DB + callbacks + Frontend).
- **MirrorSync (Phase 5 simplified):** mecanismo best-effort para sincronizar el wallet del framework activo con el saldo SONAR authoritative — NO es el ledger primary.
- **GetApiVersion (informational):** read-only export feature-detect (`{major, minor, patch, phase, api_lock}`). NO audit, NO mutation. Cuenta como público #22 pero fuera de los 21 mutation/read.

---

## 5. Lite Mode module (ESX 1.10+ ONLY) — `sonar_bridges/server/lite_mode.lua`

### 5.1 Triple capa structure (per Q16 + brief §3.2.2)

#### Capa A — Event Hooking + Mutex Correlation-ID

```lua
-- Listener on esx:setAccountMoney from ESX framework.
RegisterNetEvent('esx:setAccountMoney')
AddEventHandler('esx:setAccountMoney', function(playerId, accountName, money, reason)
  -- Reason metadata extracted (ESX 1.10+ supports metadata)
  local correlation_id = MutexEcho.extract_correlation_id(reason)

  if correlation_id and MutexEcho.is_pending_echo(correlation_id) then
    -- This is the echo of our own SONAR-initiated mutation. Drop it.
    MutexEcho.drop_echo(correlation_id)
    return
  end

  -- This is a foreign mutation (other resource / native ESX UI). Reconcile.
  Reconciliation.enqueue({
    player_id = playerId,
    account = accountName,
    new_balance = money,
    source = 'esx_external',
    detected_at = GetGameTimer(),
  })
end)
```

#### Capa B — Mapeo Híbrido Estricto

```lua
-- Bridges.Bank.AddMoney for ESX Lite Mode:
-- - account_class 'main' → mutate ESX users.accounts (anchor) + emit correlation-id mutex
-- - account_class ∈ {'savings', 'escrow', 'business_treasury', 'crypto_wallet'} → mutate sonar_bank_accounts only (CP6)

function Bridges.Bank.AddMoney(citizen_id, amount, reason, opts)
  opts = opts or {}
  opts.correlation_id = opts.correlation_id or Bridges.UUID.v4()
  opts.idempotency_key = opts.idempotency_key or Bridges.UUID.v4()

  -- Idempotency check (Q-BE-pre-06)
  local cached = IdempotencyKeys.Lock(opts.idempotency_key, 'bank_addmoney', { citizen_id, amount, reason })
  if cached.replay then return cached.result end

  local account_class = opts.account_class or 'main'
  if account_class == 'main' and Bridges.BankStatus.GetState() == 'lite_mode_active' then
    -- Lite Mode: mutate ESX users.accounts + emit echo with correlation-id
    MutexEcho.register_pending_echo(opts.correlation_id, { citizen_id = citizen_id, amount = amount })
    -- Encode correlation-id in reason metadata
    local reason_with_corr = MutexEcho.encode_correlation_id(reason, opts.correlation_id)
    local esx_player = ESX.GetPlayerFromIdentifier(citizen_id)
    esx_player.addAccountMoney('bank', amount, reason_with_corr)
    -- DB write SONAR side (atomic)
    local db_result = MySQL.transaction.await({
      { 'UPDATE sonar_bank_accounts SET balance = balance + ? WHERE citizen_id = ? AND account_class = ?', { amount, citizen_id, account_class } },
      { 'INSERT INTO sonar_bank_movements (...) VALUES (...)', {...} },
    })
    -- Audit ledger append
    BankAuditLedger.Append({ event_type = 'bank_addmoney_lite', citizen_id = citizen_id, amount = amount, correlation_id = opts.correlation_id })
    -- v1.0.1 R1 M004 cross-cutting: balance update via CP1-B NetEvent (replaces deprecated CP1-A `GlobalState['bank.balance.*']`).
    -- Per c_be_05 §2.2.1 publish_balance_update() canonical helper (target = owner source only, ownership defensive check inside).
    local balance_after = MySQL.scalar.await('SELECT balance FROM sonar_bank_accounts WHERE citizen_id = ? AND account_class = ? LIMIT 1', { citizen_id, account_class })
    publish_balance_update(citizen_id, balance_after, account_class, { correlation_id = opts.correlation_id })
    -- Idempotency complete
    IdempotencyKeys.Complete(opts.idempotency_key, { status = 'ok', data = { balance_after = ... } })
    return { status = 'ok', data = {...}, correlation_id = opts.correlation_id }
  elseif account_class ~= 'main' then
    -- Premium tier: SONAR-only mutation (CP6 — NO ESX side)
    -- ... SONAR-only DB write + audit + bag emit + idempotency
  elseif account_class == 'main' and Bridges.BankStatus.GetState() == 'native_full' then
    -- Core Override active: direct SONAR mutation (Core Override redirected QBCore native call already).
    -- ... pattern
  else
    -- BANK_DISABLED defensive
    return { status = 'error', error = { code = 'BANK_DISABLED', reason = GetResourceKvpString('sonar_bank_disabled') } }
  end
end
```

#### Capa C — Reconciliación Activa Async (per §6 below)

---

## 6. Correlation-ID Mutex lib — `sonar_bridges/lib/mutex_echo.lua`

### 6.1 Spec (CP2 path #1 — NO TTL, NO hash-fallback)

```lua
-- pending_echoes hash table: correlation_id → { citizen_id, amount, account, queued_at_ms }
local pending_echoes = {}
local PENDING_ECHO_GC_TTL_MS = 60000  -- 60s defensive GC (NO mutex semantic — only memory cleanup)

function MutexEcho.register_pending_echo(correlation_id, payload)
  pending_echoes[correlation_id] = payload
  -- Defensive GC schedule (memory hygiene only — not mutex TTL)
  Citizen.SetTimeout(PENDING_ECHO_GC_TTL_MS, function()
    if pending_echoes[correlation_id] then
      pending_echoes[correlation_id] = nil
      log_warn('mutex_echo: echo never received for correlation_id ' .. correlation_id .. ' — GC fired (possible Lite Mode framework lag or external resource swallowed event)')
    end
  end)
end

function MutexEcho.is_pending_echo(correlation_id)
  return pending_echoes[correlation_id] ~= nil
end

function MutexEcho.drop_echo(correlation_id)
  pending_echoes[correlation_id] = nil
end

-- v1.0.1 R1 M008: escape `|` in reason_string prior to concat + use append-at-tail strict format.
-- Strict format: append marker `|sonar_correlation:<uuid>|END` AT END of reason. Extract only LAST match (rightmost).

function MutexEcho.encode_correlation_id(reason_string, correlation_id)
  -- Sanitize reason_string: escape pre-existing `|` to prevent collision.
  local safe_reason = (reason_string or ''):gsub('|', '\\|')  -- backslash escape
  -- Validate correlation_id format (defensive — must match v4 UUID hex shape).
  if not correlation_id:match('^[0-9a-f]+%-[0-9a-f]+%-[0-9a-f]+%-[0-9a-f]+%-[0-9a-f]+$') then
    error('encode_correlation_id: invalid correlation_id format (expected UUID v4 lowercase hex)', 2)
  end
  -- Append marker at END with terminal sentinel `|END` for unambiguous parse.
  return string.format('%s|sonar_correlation:%s|END', safe_reason, correlation_id)
end

function MutexEcho.extract_correlation_id(reason_string)
  if not reason_string then return nil end
  -- Match strict pattern: `|sonar_correlation:<UUID-shape>|END` AT END of string.
  -- Anchored `$` end ensures we only match the trailing sonar marker, not any embedded variant.
  local cid = string.match(reason_string,
    '|sonar_correlation:([0-9a-f]+%-[0-9a-f]+%-[0-9a-f]+%-[0-9a-f]+%-[0-9a-f]+)|END$')
  return cid
end
```

### 6.1.1 Encoding format invariants (NEW v1.0.1 R1 — M008 fix)

Format wire `{escaped_reason}|sonar_correlation:{uuid_v4}|END`:

- **Escape pipe** in `reason_string` (replace `|` → `\|`) before concat → prevents collision when external resource emits `addAccountMoney` reason that legitimately contains `|`.
- **Terminal sentinel `|END`** anchors extract regex to trailing UUID — defense against intermediate forged `|sonar_correlation:` markers within `reason_string`.
- **Strict UUID shape regex** `[0-9a-f]+%-` 5 segments — prevents accepting non-UUID payloads (e.g. attacker injects `sonar_correlation:malicious_string`).
- **Anchored `$` extraction** ensures we always extract THE LAST sonar marker (the one our encode just added), not any embedded forgery.
- **Decode validation:** `encode_correlation_id` validates UUID shape pre-encode (errors on malformed input). `extract_correlation_id` returns `nil` if no clean match (caller MUST treat as orphan event).

**Defense-in-depth:** combined con §3.3.1 R1 M002 multi-entropy UUID + AP-UUID-1 prohibition, attacker collision attack surface essentially eliminated.

### 6.2 Anti-pattern explicit prohibido

```lua
-- ❌ HASH-BASED MUTEX CODE PATH — CP2 path #1 ONLY (per Q16 LOCKED + ADR-018)
-- ❌ TTL-BASED MUTEX (e.g. 5-second window) — confiabilidad ESX legacy ONLY, cut Phase A
-- Si encuentras este código en un PR Backend → REJECT review automático.
```

---

## 7. Reconciliation Pipeline lib — `sonar_bridges/lib/reconciliation.lua`

### 7.1 Spec (CP3 + CP5 + CP6)

```lua
-- Async queue + batch SQL multi-row + cache LRU + trust window 5min.
-- Performance target: 200 concurrent <500ms p99.
-- Threshold auto-apply €1000 (CP5) — sobre threshold → admin flag queue.
-- Scope main_account only (CP6) — premium tiers excluded.

local reconciliation_queue = {}  -- ring buffer FIFO
local cache_lru = {}  -- citizen_id → { balance_cached, last_updated_ms, source }
local TRUST_WINDOW_MS = 300000  -- 5min static (Phase A — adaptive defer Phase B per OQ-BE-10)
local AUTO_APPLY_THRESHOLD = 1000  -- €1000 (CP5)

function Reconciliation.enqueue(item)
  -- item: { player_id, account, new_balance, source, detected_at }
  if item.account ~= 'bank' then return end  -- CP6 main only — NOT 'savings' / etc
  table.insert(reconciliation_queue, item)
end

-- Async batch processor (CreateThread loop)
CreateThread(function()
  while true do
    Wait(100)  -- 10Hz tick
    if #reconciliation_queue > 0 then
      local batch = {}
      while #reconciliation_queue > 0 and #batch < 50 do
        table.insert(batch, table.remove(reconciliation_queue, 1))
      end
      Reconciliation.process_batch(batch)
    end
  end
end)

function Reconciliation.process_batch(batch)
  -- Step 1: deduplicate per citizen_id (latest wins)
  local dedup = {}
  for _, item in ipairs(batch) do
    dedup[item.player_id] = item
  end

  -- Step 2: trust window check
  local pending = {}
  for citizen_id, item in pairs(dedup) do
    local cached = cache_lru[citizen_id]
    if cached and (GetGameTimer() - cached.last_updated_ms < TRUST_WINDOW_MS) and cached.source == 'sonar' then
      -- Skip — recently mutated by SONAR, ignore foreign event
    else
      table.insert(pending, item)
    end
  end

  -- Step 3: batch SQL multi-row read current balances
  -- v1.0.1 R1 H004: prepared statement with positional placeholders (NO string.format/concat with user data)
  if #pending == 0 then return end
  local pending_ids = {}
  for _, item in ipairs(pending) do
    table.insert(pending_ids, item.player_id)
  end
  -- Build placeholders: "?,?,?" matching pending_ids count
  local placeholders = string.rep('?,', #pending_ids):sub(1, -2)  -- "?,?,?"
  local sql_select = 'SELECT citizen_id, balance FROM sonar_bank_accounts WHERE citizen_id IN (' .. placeholders .. ") AND account_class = 'main'"
  local rows = MySQL.query.await(sql_select, pending_ids)  -- positional binding, fully sanitized by oxmysql driver

  -- Step 4: compute deltas + apply or flag
  local apply_batch = {}
  local flag_batch = {}
  for _, item in ipairs(pending) do
    local sonar_balance = find_row_balance(rows, item.player_id) or 0
    local delta = item.new_balance - sonar_balance
    if math.abs(delta) <= AUTO_APPLY_THRESHOLD then
      table.insert(apply_batch, { citizen_id = item.player_id, new_balance = item.new_balance })
    else
      -- CP5 — admin flag queue (NO auto-apply)
      table.insert(flag_batch, { citizen_id = item.player_id, delta = delta, sonar_balance = sonar_balance, esx_balance = item.new_balance })
    end
  end

  -- Step 5: batch SQL multi-row UPDATE apply
  -- v1.0.1 R1 H004: prepared CASE expression with positional placeholders (zero string concat user data)
  if #apply_batch > 0 then
    local case_clauses = {}
    local case_args = {}     -- alternating cid + balance pairs
    local in_args = {}        -- citizen_ids for WHERE IN clause
    for _, x in ipairs(apply_batch) do
      table.insert(case_clauses, 'WHEN ? THEN ?')
      table.insert(case_args, x.citizen_id)
      table.insert(case_args, x.new_balance)
      table.insert(in_args, x.citizen_id)
    end
    local in_placeholders = string.rep('?,', #in_args):sub(1, -2)
    local sql_update = 'UPDATE sonar_bank_accounts SET balance = CASE citizen_id ' .. table.concat(case_clauses, ' ') ..
                ' END, last_reconciled_at = NOW() WHERE citizen_id IN (' .. in_placeholders .. ") AND account_class = 'main'"
    -- Final args array: case_args (cid+balance pairs) followed by in_args (cids only)
    local final_args = {}
    for _, a in ipairs(case_args) do table.insert(final_args, a) end
    for _, a in ipairs(in_args) do table.insert(final_args, a) end
    MySQL.update.await(sql_update, final_args)

    -- Append audit ledger entries (batch INSERT)
    BankAuditLedger.AppendBatch(map(apply_batch, function(x)
      return { event_type = 'reconciliation_auto_applied', citizen_id = x.citizen_id, ... }
    end))

    -- Update cache LRU
    for _, x in ipairs(apply_batch) do
      cache_lru[x.citizen_id] = { balance_cached = x.new_balance, last_updated_ms = GetGameTimer(), source = 'reconciliation_apply' }
    end

    -- v1.0.1 R1 M004 cross-cutting: balance updates via CP1-B NetEvent (replaces deprecated CP1-A pattern)
    -- Per c_be_05 §2.2.1 publish_balance_update() canonical helper.
    for _, x in ipairs(apply_batch) do
      publish_balance_update(x.citizen_id, x.new_balance, 'main', {
        correlation_id = x.correlation_id or 'reconciliation_apply',
        occurred_at = GetGameTimer(),
      })
    end
  end

  -- Step 6: admin flag queue persist (CP5)
  if #flag_batch > 0 then
    -- INSERT into sonar_bank_compliance_flags with flag_type 'reconciliation_delta_above_threshold'
    -- Security Lead C-SEC-03 spec defines exact compliance flag shape post-H2
    log_warn(string.format('reconciliation: %d delta(s) above €%d threshold queued for admin review', #flag_batch, AUTO_APPLY_THRESHOLD))
    -- TBD v0.2: integrate Security Lead spec
  end
end
```

### 7.1.1 Anti-pattern explicit prohibido (NEW v1.0.1 R1 — H004 fix)

```lua
-- ❌ NUNCA en SONAR Bank reconciliation pipeline (o ANY oxmysql query con datos externos):
local sql = string.format("SELECT * FROM accounts WHERE citizen_id IN (%s)", citizen_ids_str)  -- SQL injection vulnerable.

-- ✅ SIEMPRE: prepared statement with positional placeholders.
local placeholders = string.rep('?,', #ids):sub(1, -2)
local sql = 'SELECT * FROM accounts WHERE citizen_id IN (' .. placeholders .. ')'
MySQL.query.await(sql, ids)  -- oxmysql sanitizes per-arg.
```

**Static lint enforcement (Phase B):** propose lint rule `sonar_lint_no_sqlformat_concat.lua` to DevOps Lead C-DO-* — flags `string.format` con SQL keyword adjacent + `..` concat con SQL string + variable.

**Cross-cutting:** este anti-patrón aplica a TODO callsite oxmysql en SONAR Bank (no solo reconciliation). Backend Lead Phase A implementación code review obligatoria pre-merge §exploit-prevention checklist `@docs/technical/08_audit_hooks.md` §5.

### 7.2 Performance target verification

- 200 concurrent reconciliations <500ms p99 (Q16.5 + CP3).
- Batch size 50 (configurable convar) — flush every 100ms tick.
- Multi-row UPDATE single SQL statement (CASE expression).
- LRU cache evict policy: max 5000 entries (configurable). Per Q16.5 200 concurrent worst-case 200 entries simultaneous.

**Benchmark execution Q-BE-pre-08 Opción C:** harness Lua standalone con mock oxmysql + simulated 200 reconciliations + report estimación fundada.

---

## 8. Defensive Boot module (CP4) — extends `sonar_bridges/server/init.lua` + `detect.lua`

### 8.1 3-method framework detection

```lua
function detect_framework()
  -- Method 1: GetResourceState (most reliable)
  if GetResourceState('qbx_core') == 'started' then return 'QBox', detect_qbox_version() end
  if GetResourceState('qb-core') == 'started' then return 'QBCore', detect_qbcore_version() end
  if GetResourceState('es_extended') == 'started' then
    local version = detect_esx_version()
    if version_lt(version, '1.10.0') then
      return 'ESX_LEGACY_CUT', version
    end
    return 'ESX', version
  end

  -- Method 2: exports existence (defensive double-check)
  -- ...

  -- Method 3: native fallback flag (no framework detected)
  return 'NONE', nil
end
```

### 8.2 KVP graceful disable

```lua
local function defensive_abort(reason_code, reason_message)
  SetResourceKvp('sonar_bank_disabled', reason_code)
  Bridges.BankStatus.Transition('framework_missing', reason_code, {})
  -- Console banner
  print('==================================================')
  print('  [SONAR][bank] DEFENSIVE ABORT')
  print('  Reason code: ' .. reason_code)
  print('  Detail: ' .. reason_message)
  print('  All bank operations will return BANK_DISABLED.')
  print('  Resolve framework detection issue + restart server.')
  print('==================================================')
end

-- Examples:
-- ESX_LEGACY_CUT detected → defensive_abort('unsupported_esx_legacy', 'ESX <1.10 detected (' .. version .. ') — cut official Q16 LOCKED.')
-- NONE detected → defensive_abort('framework_not_detected', 'No supported framework found (QBox / QBCore / ESX 1.10+).')
```

### 8.3 Watchdog progressive (B + C combined per Q-BE-pre-05)

```lua
-- sonar_bridges/server/watchdog.lua
local watchdog_metrics = {
  esx_events_observed = 0,
  esx_events_with_sonar_correlation = 0,
  last_metric_window_start = GetGameTimer(),
}

function watchdog_check_tier(tier_num, tier_label)
  local current_state = Bridges.BankStatus.GetState()

  -- v1.0.1 R1 H003: hardened sentinel B check via probe function (closure introspection, NOT mutable attribute).
  if current_state == 'native_full' then
    local probe_fn = _G._sonar_core_override_probe
    if not probe_fn then
      -- Probe function gone → cheat removed our closure access. Critical compromise.
      Bridges.BankStatus.Transition('compromised_load_order', 'probe_fn_missing_tier_' .. tier_num, watchdog_metrics, { caller_source = 0, internal_call = true })
      log_security_alert('watchdog_probe_missing', { tier = tier_label })
      return
    end

    local probe_result = probe_fn()
    -- Triple check:
    --   (a) Sentinel data present in closure upvalue.
    --   (b) Function reference still equals patched_addmoney_fn (NOT reassigned to original by cheat).
    --   (c) Checksum still matches stored checksum (function not silently replaced).
    if not probe_result.sentinel or not probe_result.fn_still_patched or
       probe_result.checksum_current ~= probe_result.sentinel.checksum then
      Bridges.BankStatus.Transition('compromised_load_order', 'sentinel_integrity_fail_tier_' .. tier_num, watchdog_metrics, { caller_source = 0, internal_call = true })
      log_security_alert('watchdog_sentinel_fail_hardened', {
        tier = tier_label,
        sentinel_present = probe_result.sentinel ~= nil,
        fn_still_patched = probe_result.fn_still_patched,
        checksum_match = probe_result.checksum_current == (probe_result.sentinel and probe_result.sentinel.checksum),
      })
      return
    end

    -- Cross-check GlobalState server-only sentinel still present (defense layer 2).
    local gs_sentinel = GlobalState['sonar_bridges.core_override.sentinel']
    if not gs_sentinel or gs_sentinel.signature ~= probe_result.sentinel.signature then
      Bridges.BankStatus.Transition('compromised_load_order', 'globalstate_sentinel_mismatch_tier_' .. tier_num, watchdog_metrics, { caller_source = 0, internal_call = true })
      log_security_alert('watchdog_gs_sentinel_mismatch', { tier = tier_label })
      return
    end
  end

  -- C métrica indirecta check (Lite Mode) — v1.0.1 R1 M007 fix per C-SEC-03 §6.2 thresholds
  if current_state == 'lite_mode_active' or current_state == 'native_full' then
    -- Refined metric (R1 M007): SONAR-emitted correlation-ids vs received-back ratio.
    -- Window: rolling 5min (windows reset by tier scheduler).
    local emitted = watchdog_metrics.sonar_emitted_correlation_ids or 0
    local received = watchdog_metrics.sonar_received_correlation_ids or 0

    if emitted < 50 then
      -- INSUFFICIENT_SAMPLE — skip decision, log debug only.
      log_debug('watchdog: metric C insufficient sample (emitted=' .. emitted .. ', received=' .. received .. ', tier=' .. tier_label .. ')')
    else
      local ratio = received / emitted

      if ratio >= 0.7 then
        -- HEALTHY — silent OK.
      elseif ratio >= 0.1 then
        -- DEGRADED — log warn, metric DevOps Lead.
        log_warn(string.format('watchdog: metric C DEGRADED ratio=%.3f (emitted=%d received=%d) tier=%s state=%s',
          ratio, emitted, received, tier_label, current_state))
      else
        -- COMPROMISED — ratio < 0.1 AND emitted >= 50 → transition.
        log_security_alert('watchdog_metric_c_compromised', {
          tier = tier_label,
          current_state = current_state,
          emitted = emitted,
          received = received,
          ratio = ratio,
        })
        Bridges.BankStatus.Transition('compromised_load_order',
          string.format('metric_c_below_action_threshold_ratio_%.3f_tier_%s', ratio, tier_label),
          watchdog_metrics,
          { caller_source = 0, internal_call = true }  -- v1.0.1 R1 H002 auth gate compliance
        )
        return  -- transition emitted, exit watchdog tick
      end
    end

    -- Reset window counters for next tier window
    watchdog_metrics.sonar_emitted_correlation_ids = 0
    watchdog_metrics.sonar_received_correlation_ids = 0
    watchdog_metrics.last_metric_window_start = GetGameTimer()
  end

  log_info('watchdog: tier ' .. tier_label .. ' check passed (state=' .. current_state .. ')')
end
```

### 8.3.1 Metric C counters integration (NEW v1.0.1 R1 — M007 fix)

Counters incremented at instrumentation points:

- **`sonar_emitted_correlation_ids`** — incremented inside `MutexEcho.encode_correlation_id(reason, cid)` cada call que emit a ESX `addAccountMoney`/`removeAccountMoney`.
- **`sonar_received_correlation_ids`** — incremented inside `MutexEcho.extract_correlation_id(reason)` cuando match `≠ nil` — confirma ESX returned event with our correlation-id intact.

Window reset cada tier check (per `watchdog_check_tier` cleanup at end). Alternative: rolling 5min sliding window if FiveM tick budget permits (Phase B optimization).

**Action thresholds (v1.0.1 R1 M007 canonical per C-SEC-03 §6.2):**

| Ratio (received/emitted) | Sample size | Status | Action |
|---|---|---|---|
| ≥ 0.7 | emitted ≥ 50 | HEALTHY | Silent |
| 0.1 ≤ ratio < 0.7 | emitted ≥ 50 | DEGRADED | log warn, metric DevOps |
| < 0.1 | emitted ≥ 50 | COMPROMISED | **Transition `compromised_load_order`** + audit hook + security alert |
| any | emitted < 50 | INSUFFICIENT_SAMPLE | Skip decision, log debug |

**Convars:**
- `sonar_bank_watchdog_compromise_ratio_threshold` default `0.1` (configurable).
- `sonar_bank_watchdog_min_sample_size` default `50` (configurable).

**~~OQ-CBE04-01~~ RESOLVED v1.0.1 R1 (M007 fix):** métrica C thresholds canonical per C-SEC-03 §6.2 — HEALTHY ≥0.7 / DEGRADED 0.1-0.7 / COMPROMISED <0.1+samp≥50 transition / INSUFFICIENT_SAMPLE skip. Counter integration via MutexEcho §8.3.1. See §8.3 watchdog block above.

---

## 9. Cut ESX legacy <1.10 oficial

### 9.1 Implementation

- `fxmanifest.lua` `dependencies { '/esx:1.10' }` declarative (when applicable).
- Defensive boot detect_esx_version() compares version string. If lt 1.10.0 → defensive abort.
- README install Phase A (DevOps Lead C-DO-03) explicit: "ESX <1.10 NOT SUPPORTED. Upgrade to ESX 1.10+ or use QBox/QBCore."
- KVP `sonar_bank_disabled = 'unsupported_esx_legacy'` set.

### 9.2 Anti-pattern eliminated

- ❌ NO hash-based mutex code path (sería required for ESX legacy sin metadata).
- ❌ NO TTL-based mutex.
- ❌ NO conditional fallback paths for ESX <1.10.

---

## 10. Cross-references contratos + ADRs

- ADR-018 (BANK-BE.0 proposed) — Bank Lite mode hybrid 3-layer + correlation-id mutex + cut ESX legacy + 8 mitigation patterns.
- ADR-009 (existing accepted) — Bridges Layer foundational principle.
- ADR-013 (existing accepted) — namespace migration `sonar_*`.
- C-BE-01 Events Catalog v1.3 — events fired by Bridges Layer (transferComplete + bank_status_changed).
- C-BE-02 API Contracts v1.3 — callbacks consume Bridges API.
- C-BE-03 State Machines v1.1 — `sonar_bank_status` FSM + cross-FSM cascade rules.
- C-BE-05 StateBags Global Publishers — bag emit pattern post-DB-commit.
- C-DO-02 fxmanifest + Load Order Spec (DevOps Lead H4) — dependencies declarations + boot ordering.
- C-SEC-01 Audit Hooks (Security Lead H2) — audit hooks integration + ACE checks watchdog detection.
- DB Schema v2.0 LOCKED PROVISIONAL `@docs/technical/03_db_schema.md` §22-§29 — tables consumed.

---

## 11. Open questions BANK-BE.0

| OQ | Tema | Resolution target |
|---|---|---|
| **OQ-CBE04-01** | Watchdog métrica C threshold concreto | Refinar v0.2 — default Phase A: log only, sentinel B suficiente. |
| **OQ-CBE04-02** | Reconciliation batch size + tick interval óptimos | Default batch 50 + tick 100ms. Confirmar via harness Lua Q-BE-pre-08 Opción C. |
| **OQ-CBE04-03** | LRU cache max entries | Default 5000. Phase B revisión post real metrics. |
| **OQ-CBE04-04** | `sonar_bank_status.compromised_load_order` recovery — automatic via watchdog re-check vs admin manual command | Default auto-recovery via watchdog re-checks T+5min recurring. Manual via `sonar_bank reset_status` admin console. |
| **OQ-CBE04-05** | Multi-framework simultaneous (QBox + QBCore detected) — abort vs prioritize | Default abort + transit `compromised_load_order` (config conflict). Founder confirma. |
| **OQ-CBE04-06** | `Bridges.BankStatus.RegisterChangeHandler` callback signature shape | Default `fn(new_state, old_state, reason)`. Confirmar pre-LOCKED. |

---

## 12. Sign-off matrix C-BE-04 v1.1 LOCKED target

| Stakeholder | Scope | Status DRAFT v0.1 |
|---|---|---|
| ☐ **Founder yaboula** | Final approval architectural extends + ADR-018 sign + 8 CP integrated | **PENDIENTE** review window |
| ☐ **Backend Lead (owner)** | Self-attest spec coherente con C-BE-01..05 + research notes + ADR-018 redactado | **DRAFT v0.1 self-signed BANK-BE.0** |
| ☐ **DevOps Lead (consumer consultative)** | Acepta fxmanifest dependencies + load order + boot sequence + convars | **PENDIENTE** activation post-H4 |
| ☐ **Security Lead (consumer consultative)** | Acepta watchdog logic + ACE checks + threat model Core Override compromise | **PENDIENTE** activation post-H2 |

---

## 13. Versioning C-BE-04

| Version | Fecha | Cambios |
|---|---|---|
| **v0.1 DRAFT** | 2026-05-06 | BANK-BE.0 — DRAFT inicial extends v1.2 con 8 CP integrated + Q-BE-pre-05/11/12 founder LOCKED. ADR-018 anchor. |
| **v1.0 LOCKED** | 2026-05-06 (BANK-BE.LOCK) | Promotion atomic. Sign-off ratificado: founder yaboula APPROVED + Backend Lead self-attested + DevOps Lead (consumer consultative) handoff via H4 future. Promoted: `drafts/be_phase_a/c_be_04_*` → `docs/technical/bank_phase_a/c_be_04_*`. Pointer §X.NEW en `docs/technical/07_bridges_compatibility.md` v1.2 → v1.3 LOCKED. ADR-018 anchor referenced. |
| **v1.0.1 R1 LOCKED** | 2026-05-06 (BANK-BE.LOCK.R1) | BANK-BE.AMEND.1 surgical patches Round 1 reactive a Security Lead audit C-SEC-01/02/03 v0.1 (founder APPROVED 2026-05-06): **H002** (Bridges.BankStatus.Transition ACE gate triple-path — P12 + console + whitelist internal_call + opts.caller_source mandatory + audit hook unauthorized attempts) + **H003** (Core Override sentinel hardening triple-defense: closure-upvalue + GlobalState replicated=false + SHA256 checksum + probe fn introspection — eliminated public attribute QBCore.__sonar_patched mutability vulnerability) + **H004** (reconciliation pipeline SQL prepared statements posicionales §7.1 steps 3+5 + AP-SQL-1 explicit prohibido §7.1.1) + **M002** (Bridges.UUID.v4 multi-entropy PRNG mix spec §3.3.1 + AP-UUID-1 prohibition + SHA256 helper §4.2.1) + **M007** (watchdog metric C action threshold COMPROMISED ratio<0.1 transition + INSUFFICIENT_SAMPLE skip + counter integration MutexEcho instrumentation §8.3.1 + 2 convars) + **M008** (MutexEcho delimiter `\|` escape + terminal sentinel `|END` + anchored UUID-strict regex §6.1 + invariants §6.1.1). **Cross-cutting M004 balance emit refactor** §5 Lite Mode `Bridges.Bank.AddMoney` + §7.1 step 5 reconciliation pipeline — `GlobalState['bank.balance.*']` reemplazado por `publish_balance_update()` helper canonical (per c_be_05 §2.2.1 v1.0.1 R1). 4 convars DevOps H4 runbook obligation: `sonar_status_transition_whitelist`, `sonar_bank_watchdog_compromise_ratio_threshold`, `sonar_bank_watchdog_min_sample_size`, `sonar_bank_atm_hmac_secret` (cross-ref C-BE-02 M006). Security Lead BANK-SEC.1 re-audit ✅ PASS veredicto + `08_audit_hooks.md` v0.2. Sign-off ratificado: founder yaboula APPROVED + Backend Lead self-attested + Security Lead PASS. |

| **v1.0.2 R2 LOCKED** | 2026-05-12 (BANK-BE.PHASE_5.1.LOCK.R2) | Phase 5 ecosystem pivot Round 2 reactive a Founder LOCK Q1-Q8 + §9 path (a). **NULLIFY §4 Core Override module entera** (~111 líneas §4.1 + §4.2 + §4.2.1 + §4.3) wrapped en blockquote DEPRECATED + `<details>` collapsible audit trail (contenido v1.0.1 R1 preservado verbatim, NO consume runtime). **NEW §4' Server-to-Server Integration API surface**: §4'.1 modelo arquitectónico ox_inventory-style + Tier 1/2/3 segregation + GetApiVersion informational (Founder Decision #1 LOCKED = 22 explicit públicos = 21 mutation/read + 1 informational), §4'.2 boundary conversion convention (Q1 LOCKED split + units.to_minor/from_minor mandatory en wrapper edge), §4'.3 attack surface model (FiveM server-only exports + GetInvokingResource audit + sonar:admin_allowlist Tier 2 defense), §4'.4 mirror simplified (MirrorSync.SetBalance best-effort + login handlers + Reconcile.Enqueue + REMOVED list explicit), §4'.5 migration operator-side (Q4 LOCKED no shim + MIGRATION.md + /sonar_scan_legacy), §4'.6 glosario Phase 5 (Exports Tier 1/2 + Boundary helper + MirrorSync + GetApiVersion). **Secciones preservadas verbatim:** §1 filosofía + §2 architecture overview + §3 Bridges API canonical (3.1 + 3.2 + 3.2.1 BankStatus.Transition H002 R1 + 3.3 + 3.3.1 UUID.v4 entropy M002 R1) + §5 Lite Mode + §6 Mutex + §7 Reconciliation + §8 Watchdog general (Core Override drift refs runtime preservado funcionalmente) + §9 Status FSM (4 transitions verbatim). **Cleanup runtime Phase 3 post-LOCK:** qb-core local patch revert founder-side (Phase 3.1) + `core_override.lua` simplification 980→~150-200 líneas (Phase 3.2) + `credit_command.lua` delete (Phase 3.3) + fxmanifest edit + obsolete convars cleanup (Phase 3.5: `sonar_co_watchdog_interval_ms`, `sonar_bridges_disable_prehook`). Cross-cutting LOCK-time impacts: C-BE-02 v1.0.2 R2 + C-BE-05 v1.0.2 R2 + C-SEC-01 v0.3 R2 atomic in-place patches. Security consumer review absorbed by PM Cascade per Founder Decision #3 — BANK-SEC.2 deuda técnica re-audit pending Phase B. Sign-off ratificado: founder yaboula APPROVED + Backend Lead self-attested + Security consumer PM Cascade absorbed + PM Cascade promote ceremony. |

— **C-BE-04 v1.0.2 R2 LOCKED** 2026-05-12 (BANK-BE.PHASE_5.1.LOCK.R2 ceremony). Sign-off founder + Backend Lead + Security consumer PM-absorbed. **Effective immediately.** DevOps Lead via H4 absorbed runbook update post-Phase 3.5 cleanup. Phase 5 implementation Tier 1/2 exports per design SSoT `@docs/design/04_sonar_bank_api.md` v0.2. Amendments adicionales require formal Round 3 protocol.
