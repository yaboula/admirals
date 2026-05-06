# C-BE-04 — Bridges Compatibility Layer v1.1 Bank Phase A (DRAFT v0.1)

> **Owner:** Backend Money & Compatibility Lead.
> **Consumer Leads:** DevOps Lead (fxmanifest + load order + boot sequence) + Security Lead (audit watchdog + ACE checks + exploit prevention).
> **Status:** 🟡 **DRAFT v0.1 — review window open.** No LOCKED hasta sign-off triple founder + Backend + DevOps (consultative) + Security (consultative).
> **Fecha:** 2026-05-06 (BANK-BE.0).
> **Path canonical post-LOCKED:** extends `docs/technical/07_bridges_compatibility.md` v1.2 → v1.3 con NEW §X Bank Phase A.
> **ADR anchor:** ADR-018 (Bank Lite mode hybrid 3-layer + correlation-id mutex + cut ESX legacy + 8 mitigation patterns) — proposed BANK-BE.0, sign target H2.

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
Bridges.BankStatus.GetState()                                     → string
Bridges.BankStatus.Transition(new_state, reason, metrics)         → success | error
Bridges.BankStatus.IsDisabled()                                   → boolean
Bridges.BankStatus.RegisterChangeHandler(fn)                      → unregister_fn
Bridges.UUID.v4()                                                 → string

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

### 3.3 Backwards compatibility

Existing callsites `Bridges.Bank.AddMoney(cid, 100, 'reason')` (3-arg) → continúan funcionando. `opts` parameter optional (default `nil`). Si `opts == nil` → mutex correlation-id auto-generated + idempotency_key auto-generated (UUID v4) + metadata empty.

**Impact existing code:** **ZERO breaking** — solo adds opts capability.

---

## 4. Core Override module (QBox/QBCore) — `sonar_bridges/server/core_override.lua`

### 4.1 Approach decision (per Q-BE-pre-05 founder green-light)

**Hybrid B + C combined:**

- **B) Sentinel attribute** post-monkey-patch — `QBCore.__sonar_patched = { applied_at = epoch_ms, version = '1.0' }`.
- **C) Métrica indirecta** — listener on framework events (e.g. `esx:setAccountMoney`) verifies correlation-id sonar inyectado en metadata. Si X minutos pasan sin events con correlation-id sonar AND money mutations occurring → suspect compromise.

### 4.2 Pseudo-code spec

```lua
-- sonar_bridges/server/core_override.lua
-- Core Override module — runtime monkey-patch QBox/QBCore Player.Functions.AddMoney/RemoveMoney/GetMoney/SetMoney.
-- Aplica solo si framework_detect ∈ {QBox, QBCore} (CP4 detect).

local function install_qbcore_override()
  if QBCore.__sonar_patched then
    log_warn('core_override: already patched, skipping (idempotent boot)')
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

  -- Apply sentinel attribute (B detection)
  QBCore.__sonar_patched = {
    applied_at = os.time() * 1000,
    version = '1.0',
    sentinel_signature = Bridges.UUID.v4(),  -- per-boot unique to detect re-load
  }

  -- Schedule watchdog tier checks
  Citizen.SetTimeout(30000, function() watchdog_check_tier(1, 'T+30s_initial') end)
  Citizen.SetTimeout(300000, function() watchdog_check_tier(2, 'T+5min_progressive') end)
  Citizen.SetTimeout(1800000, function() watchdog_check_tier(3, 'T+30min_long_tail') end)

  log_info('core_override: QBCore monkey-patch applied + sentinel set + watchdog scheduled')
end
```

### 4.3 Caveats + edge cases

- **QBox API surface:** difiere ligeramente de QBCore. `qbx_core` exports + `qbx.PlayerFunctions` shape. Adapter `sonar_bridges/adapters/qbox/core_override_qbox.lua` per-framework.
- **Multi-framework simultaneous:** if both QBox + QBCore detected → log warn + abort Core Override + transit `compromised_load_order` (config conflict).
- **Hot-reload `restart sonar_bridges`:** sentinel idempotent boot — re-apply detect + skip if already patched same boot session.
- **External resource patches (other resources monkey-patch same functions post-SONAR):** watchdog métrica C indirect detects. Transit `compromised_load_order`.

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
    -- StateBag publish (CP1-A)
    GlobalState['bank.balance.' .. citizen_id] = (GlobalState['bank.balance.' .. citizen_id] or 0) + amount
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

function MutexEcho.encode_correlation_id(reason_string, correlation_id)
  -- Encode UUID into reason metadata. Format: "{original_reason}|sonar_correlation:{uuid}"
  return string.format('%s|sonar_correlation:%s', reason_string or '', correlation_id)
end

function MutexEcho.extract_correlation_id(reason_string)
  if not reason_string then return nil end
  return string.match(reason_string, 'sonar_correlation:([0-9a-f%-]+)')
end
```

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
  if #pending == 0 then return end
  local citizen_ids_str = table.concat(map(pending, function(x) return string.format("'%s'", x.player_id) end), ',')
  local rows = MySQL.query.await(string.format([[
    SELECT citizen_id, balance FROM sonar_bank_accounts WHERE citizen_id IN (%s) AND account_class = 'main'
  ]], citizen_ids_str))

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
  if #apply_batch > 0 then
    local update_pairs = {}
    for _, x in ipairs(apply_batch) do
      table.insert(update_pairs, string.format("WHEN '%s' THEN %f", x.citizen_id, x.new_balance))
    end
    -- Use CASE expression for batch update single statement
    local sql = string.format([[
      UPDATE sonar_bank_accounts
      SET balance = CASE citizen_id %s END,
          last_reconciled_at = NOW()
      WHERE citizen_id IN (%s) AND account_class = 'main'
    ]], table.concat(update_pairs, ' '), citizen_ids_str)
    MySQL.update.await(sql)

    -- Append audit ledger entries (batch INSERT)
    BankAuditLedger.AppendBatch(map(apply_batch, function(x)
      return { event_type = 'reconciliation_auto_applied', citizen_id = x.citizen_id, ... }
    end))

    -- Update cache LRU
    for _, x in ipairs(apply_batch) do
      cache_lru[x.citizen_id] = { balance_cached = x.new_balance, last_updated_ms = GetGameTimer(), source = 'reconciliation_apply' }
    end

    -- Emit StateBag updates (CP1-A) batched 10ms-paced
    for _, x in ipairs(apply_batch) do
      GlobalState['bank.balance.' .. x.citizen_id] = x.new_balance
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

  -- B sentinel attribute check
  if current_state == 'native_full' then
    if not (QBCore and QBCore.__sonar_patched) and not (qbx_core and qbx_core.__sonar_patched) then
      Bridges.BankStatus.Transition('compromised_load_order', 'sentinel_attribute_missing_tier_' .. tier_num, watchdog_metrics)
      log_security_alert('watchdog_sentinel_fail', { tier = tier_label, current_state = current_state })
      return
    end
  end

  -- C métrica indirecta check (Lite Mode)
  if current_state == 'lite_mode_active' then
    -- Window: events observed last N minutes vs events with sonar correlation
    local total = watchdog_metrics.esx_events_observed
    local with_corr = watchdog_metrics.esx_events_with_sonar_correlation
    if total > 10 then  -- significant sample size
      local ratio = with_corr / total
      if ratio < 0.3 then  -- expect at least 30% to be SONAR-initiated (rest external/UI/etc)
        -- LOW ratio is fine if non-SONAR external mutations dominate
        -- HIGH external ratio is normal — but if our own SONAR mutations don't carry correlation-id, BUG
        -- Métrica realmente útil: verificar SONAR mutations DO carry correlation-id
        -- Backend Lead v0.2: refinar métrica — count emitted vs received correlation-ids
      end
    end
  end

  log_info('watchdog: tier ' .. tier_label .. ' check passed (state=' .. current_state .. ')')
end
```

**OQ-CBE04-01:** refinar métrica C v0.2 — falta consenso métrica final + threshold concreto. Default Phase A: log only, no transition compromise based on métrica C alone (B sentinel sufficient).

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

| **v1.0 LOCKED** | 2026-05-06 (BANK-BE.LOCK) | Promotion atomic. Sign-off ratificado: founder yaboula APPROVED + Backend Lead self-attested + DevOps Lead (consumer consultative — review boot order + watchdog metrics + bridges echo) handoff via H4 future. Promoted: `drafts/be_phase_a/c_be_04_*` → `docs/technical/bank_phase_a/c_be_04_*`. Pointer §X.NEW en `docs/technical/07_bridges_compatibility.md` v1.2 → v1.3 LOCKED. ADR-018 anchor referenced. |

— **C-BE-04 v1.0 LOCKED** 2026-05-06 (BANK-BE.LOCK ceremony). Sign-off founder + Backend Lead. **Effective immediately.** Security Lead recibe via H2 (audit Bridges trust boundaries). DevOps Lead via H4 (boot order + observability). Amendments require formal Round 1/2/3 protocol.
