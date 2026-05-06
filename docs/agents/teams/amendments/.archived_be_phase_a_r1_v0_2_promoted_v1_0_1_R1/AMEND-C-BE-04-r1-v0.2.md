# AMEND-C-BE-04-r1-v0.2 — Surgical Patches DRAFT

> **Target contract:** `@docs/technical/bank_phase_a/c_be_04_bridges_v1_1.md` v1.0 LOCKED → v1.0.1 R1 PENDING-LOCK.
> **Round:** 1 (BANK-BE.AMEND.1).
> **Status:** 🟡 DRAFT v0.2 — review founder + Security Lead.
> **Findings addressed:** H002 + H003 + H004 (HIGH) + M002 (MEDIUM AMEND, parcial — UUID lib spec) + M007 + M008 (MEDIUM AMEND).

---

## §1 — H002 fix · `Bridges.BankStatus.Transition()` ACE gate

**Severity:** HIGH
**Spec ref:** `@docs/technical/bank_phase_a/c_be_04_bridges_v1_1.md:168-169` (§3.2 Bridges.BankStatus exports).
**Recommendation source:** `@docs/technical/08_audit_hooks.md:133-139`.

### Root cause analysis

Export `Bridges.BankStatus.Transition(new_state, reason, metrics)` declarado público en §3.2 sin auth gate alguno. Cualquier `exports['sonar_bridges'].BankStatus_Transition()` desde third-party resource puede forzar transitions a `compromised_load_order` o `framework_missing` → **DoS global Bank** (todos los callbacks retornan `BANK_DISABLED` per CP4 §8.1 defensive abort path).

Adicionalmente, `Bridges.BankStatus.RegisterChangeHandler(fn)` permite hooking listener handlers — también necesita gating o documentation explicit (read-only acceptable, mutation NO).

### 1.1 BEFORE — §3.2 export list

```@/d/theBigProject/docs/technical/bank_phase_a/c_be_04_bridges_v1_1.md:168-171
Bridges.BankStatus.GetState()                                     → string
Bridges.BankStatus.Transition(new_state, reason, metrics)         → success | error
Bridges.BankStatus.IsDisabled()                                   → boolean
Bridges.BankStatus.RegisterChangeHandler(fn)                      → unregister_fn
```

### 1.1 AFTER

```markdown
Bridges.BankStatus.GetState()                                     → string  -- READ-ONLY public (no auth gate)
Bridges.BankStatus.Transition(new_state, reason, metrics, opts)   → success | error  -- ⚠️ AUTH-GATED (R1 H002): caller MUST be source=0 (console) OR P12 ACE permission. opts.caller_source mandatory non-nil.
Bridges.BankStatus.IsDisabled()                                   → boolean  -- READ-ONLY public (no auth gate)
Bridges.BankStatus.RegisterChangeHandler(fn)                      → unregister_fn  -- READ-ONLY listener registration. Handler runs in caller resource sandbox. NO mutation capability.
```

### 1.2 ADD NEW — §3.2.1 BankStatus.Transition auth gate spec

Insert new sub-section §3.2.1 after §3.2 (after current export listing block). NEW:

```markdown
### 3.2.1 `Bridges.BankStatus.Transition` auth gate (NEW v0.2 R1 — H002 fix)

Export crítico — fuerza transitions FSM Bank Status (§4.x compromised_load_order / lite_mode_active / framework_missing). DoS-capable si exposed.

**Auth contract:**

```lua
function Bridges.BankStatus.Transition(new_state, reason, metrics, opts)
  -- opts.caller_source: number (mandatory NEW R1) — player handle of caller. 0 = console.
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

**Internal callsites (refactor required at LOCK time):**
- `sonar_bridges/server/init.lua` (defensive_abort path) → call with `opts={caller_source=0, internal_call=true}`.
- `sonar_bridges/server/watchdog.lua` (`watchdog_check_tier`) → same.
- Any `sonar_bank` / `sonar_bank_app` callsite that mutates status.

**Audit hook integration:** every Transition call (success OR fail) generates `audit_hook_watchdog_status_change` if state actually changed (existing C-SEC-01 §1.2). Unauthorized attempts log `audit_hook_auth_fail` (NEW behavior R1).
```

### 1.3 Test scenarios

- [ ] **T-AMEND-H002.1** — Third-party resource `exports['sonar_bridges'].BankStatus_Transition('compromised_load_order', 'fake', {})` from non-whitelisted resource → `AUTH_FORBIDDEN` + audit entry.
- [ ] **T-AMEND-H002.2** — Player without P12 ACE → `AUTH_FORBIDDEN`.
- [ ] **T-AMEND-H002.3** — Console call (source=0) → succeeds.
- [ ] **T-AMEND-H002.4** — Whitelisted resource internal call (`opts.internal_call=true`) → succeeds.
- [ ] **T-AMEND-H002.5** — Player WITH P12 ACE granted via `add_ace identifier:license:abc sonar.devops.bank.diagnostics allow` → succeeds.
- [ ] **T-AMEND-H002.6** — `opts` nil or missing `caller_source` → `AUTH_GATE_REQUIRED`.

---

## §2 — H003 fix · Core Override sentinel hardening

**Severity:** HIGH
**Spec ref:** `@docs/technical/bank_phase_a/c_be_04_bridges_v1_1.md:215-260` (§4.2 Core Override pseudo-code) + watchdog §8.3 sentinel B check (line 591).
**Recommendation source:** `@docs/technical/08_audit_hooks.md:141-147`.

### Root cause

Sentinel `QBCore.__sonar_patched = { ... }` es **public attribute en table global QBCore**. Resource cheat malicioso post-boot puede ejecutar `QBCore.__sonar_patched = nil` → bypass watchdog check sentinel B (§8.3 line 591), watchdog cree que aún native_full pero el patch fue removido por un actor adversario que reasignó `Player.Functions.AddMoney` al original.

Adicionalmente, no hay checksum del function patcheada — solo presence check del attribute marker.

### 2.1 BEFORE — §4.2 sentinel application block

```@/d/theBigProject/docs/technical/bank_phase_a/c_be_04_bridges_v1_1.md:247-252
  -- Apply sentinel attribute (B detection)
  QBCore.__sonar_patched = {
    applied_at = os.time() * 1000,
    version = '1.0',
    sentinel_signature = Bridges.UUID.v4(),  -- per-boot unique to detect re-load
  }
```

### 2.1 AFTER (DRAFT v0.2)

```lua
  -- Apply hardened sentinel (R1 H003 fix) — triple-defense:
  --   1. Closure-local upvalue (NOT public attribute).
  --   2. GlobalState read-only replicated=false (server-only sentinel).
  --   3. SHA256 checksum of the patched function for integrity verification at watchdog time.
  -- The PUBLIC attribute QBCore.__sonar_patched is REMOVED v1.0.1 R1.

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
  -- Sentinel data accessible only server-side via `GlobalState['sonar_bridges.core_override.sentinel']`.
  GlobalState:set('sonar_bridges.core_override.sentinel', {
    applied_at = _sentinel_upvalue.applied_at,
    signature = sentinel_signature,
    checksum = patched_checksum,
  }, false)  -- replicated=false → NOT sent to clients.

  -- Defense layer 3: closure-local watchdog probe function (introspect upvalue at call time).
  _G._sonar_core_override_probe = function()
    -- Returns sentinel data via closure access (not via mutable global attribute).
    -- Verifies fn_ref still equals current QBCore.Functions.AddMoney post-patch (if reassigned by cheat → mismatch detected).
    local current_fn = QBCore.Functions and QBCore.Functions.AddMoney  -- whatever current mapping
    return {
      sentinel = _sentinel_upvalue,
      fn_still_patched = (current_fn == _sentinel_upvalue.fn_ref),
      checksum_current = current_fn and sha256_hex(string.dump(current_fn)) or nil,
    }
  end

  -- ⚠️ NUNCA: QBCore.__sonar_patched = ... (public mutable attribute — removed R1 H003 fix).

  -- Schedule watchdog tier checks (consume probe via _G._sonar_core_override_probe)
  Citizen.SetTimeout(30000, function() watchdog_check_tier(1, 'T+30s_initial') end)
  Citizen.SetTimeout(300000, function() watchdog_check_tier(2, 'T+5min_progressive') end)
  Citizen.SetTimeout(1800000, function() watchdog_check_tier(3, 'T+30min_long_tail') end)

  log_info('core_override: QBCore monkey-patch applied + hardened sentinel (closure + GlobalState + checksum) + watchdog scheduled')
```

### 2.2 BEFORE — §4.2 idempotent boot check (line ~216)

```@/d/theBigProject/docs/technical/bank_phase_a/c_be_04_bridges_v1_1.md:215-219
local function install_qbcore_override()
  if QBCore.__sonar_patched then
    log_warn('core_override: already patched, skipping (idempotent boot)')
    return
  end
```

### 2.2 AFTER

```lua
local function install_qbcore_override()
  -- R1 H003: idempotent check via GlobalState (NOT public attribute).
  local existing = GlobalState['sonar_bridges.core_override.sentinel']
  if existing and existing.signature then
    log_warn('core_override: already patched (sentinel signature ' .. existing.signature .. '), skipping idempotent boot')
    return
  end
```

### 2.3 BEFORE — §8.3 watchdog sentinel B check (line ~591)

```@/d/theBigProject/docs/technical/bank_phase_a/c_be_04_bridges_v1_1.md:589-596
  -- B sentinel attribute check
  if current_state == 'native_full' then
    if not (QBCore and QBCore.__sonar_patched) and not (qbx_core and qbx_core.__sonar_patched) then
      Bridges.BankStatus.Transition('compromised_load_order', 'sentinel_attribute_missing_tier_' .. tier_num, watchdog_metrics)
      log_security_alert('watchdog_sentinel_fail', { tier = tier_label, current_state = current_state })
      return
    end
  end
```

### 2.3 AFTER (DRAFT v0.2)

```lua
  -- R1 H003: hardened sentinel B check via probe function (closure introspection, NOT mutable attribute).
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
```

### 2.4 ADD NEW — §4.2.1 sha256_hex utility note

```markdown
### 4.2.1 SHA256 utility (NEW v0.2 R1 — H003 dependency)

`sha256_hex(input_string)` lib helper required for function bytecode hashing. Implementation options:

- **Phase A:** pure-Lua SHA256 implementation (e.g. adapted from `lua-sha256` library, ~150 LoC) en `sonar_bridges/lib/sha256.lua`.
- **Phase B:** native FFI binding (`oxmysql` ships with mysql native crypto OR `lua-crypto` if available) for perf.

Performance budget: bytecode hash function (typically <2KB string) → <5ms p99. Watchdog checks <1Hz → no perf concern.
```

### 2.5 Test scenarios

- [ ] **T-AMEND-H003.1** — Adversary post-boot does `QBCore.__sonar_patched = nil` → no impact (attribute no longer used). Watchdog uses probe fn instead → still detects integrity OK.
- [ ] **T-AMEND-H003.2** — Adversary reassigns `QBCore.Functions.AddMoney = original_addmoney` (de-patches) → probe `fn_still_patched=false` → watchdog tier check transitions to `compromised_load_order`.
- [ ] **T-AMEND-H003.3** — Adversary replaces patched function with malicious lookalike → checksum mismatch → watchdog detects.
- [ ] **T-AMEND-H003.4** — Adversary deletes `_G._sonar_core_override_probe` → next watchdog tick detects probe missing → transition `compromised_load_order`.
- [ ] **T-AMEND-H003.5** — Adversary tries to write `GlobalState['sonar_bridges.core_override.sentinel']` from client → fails (server-only `replicated=false`).
- [ ] **T-AMEND-H003.6** — Idempotent boot scenario: resource restart → existing GlobalState sentinel detected → skip re-patch (no double-patch).

---

## §3 — H004 fix · Reconciliation pipeline SQL injection

**Severity:** HIGH
**Spec ref:** `@docs/technical/bank_phase_a/c_be_04_bridges_v1_1.md:459-491` (§7.1 reconciliation pipeline batch SQL).
**Recommendation source:** `@docs/technical/08_audit_hooks.md:149-155`.

### Root cause

Lines 459-462 (read query) and 480-491 (UPDATE query) usan `string.format` con `citizen_ids_str` concatenated directly into SQL:
```lua
local citizen_ids_str = table.concat(map(pending, function(x) return string.format("'%s'", x.player_id) end), ',')
local rows = MySQL.query.await(string.format([[
  SELECT citizen_id, balance FROM sonar_bank_accounts WHERE citizen_id IN (%s) AND account_class = 'main'
]], citizen_ids_str))
```

Si un cheat resource reemplaza ESX o injecta `player_id` malicioso (e.g. `"x'); DROP TABLE sonar_bank_accounts;--"`), la query se vuelve injection-vulnerable. Backend Lead sanitization actual = ninguna (string.format `%s` no escape).

### 3.1 BEFORE — §7.1 step 3 read query

```@/d/theBigProject/docs/technical/bank_phase_a/c_be_04_bridges_v1_1.md:459-462
  local citizen_ids_str = table.concat(map(pending, function(x) return string.format("'%s'", x.player_id) end), ',')
  local rows = MySQL.query.await(string.format([[
    SELECT citizen_id, balance FROM sonar_bank_accounts WHERE citizen_id IN (%s) AND account_class = 'main'
  ]], citizen_ids_str))
```

### 3.1 AFTER (DRAFT v0.2)

```lua
  -- R1 H004: prepared statement with positional placeholders (NO string.format/concat with user data)
  local pending_ids = {}
  for _, item in ipairs(pending) do
    table.insert(pending_ids, item.player_id)
  end
  -- Build placeholders: "?,?,?" matching pending_ids count
  local placeholders = string.rep('?,', #pending_ids):sub(1, -2)  -- "?,?,?"
  local sql = 'SELECT citizen_id, balance FROM sonar_bank_accounts WHERE citizen_id IN (' .. placeholders .. ") AND account_class = 'main'"
  local rows = MySQL.query.await(sql, pending_ids)  -- positional binding, fully sanitized by oxmysql driver
```

### 3.2 BEFORE — §7.1 step 5 batch UPDATE

```@/d/theBigProject/docs/technical/bank_phase_a/c_be_04_bridges_v1_1.md:478-491
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
```

### 3.2 AFTER (DRAFT v0.2)

```lua
  -- R1 H004: prepared CASE expression with positional placeholders (zero string concat user data)
  if #apply_batch > 0 then
    -- Build CASE clause with positional placeholders + collect bind args
    -- Example final SQL: "UPDATE ... SET balance = CASE citizen_id WHEN ? THEN ? WHEN ? THEN ? END, last_reconciled_at = NOW() WHERE citizen_id IN (?,?) AND account_class = 'main'"
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
    local sql = 'UPDATE sonar_bank_accounts SET balance = CASE citizen_id ' .. table.concat(case_clauses, ' ') ..
                ' END, last_reconciled_at = NOW() WHERE citizen_id IN (' .. in_placeholders .. ") AND account_class = 'main'"
    -- Final args array: case_args (cid+balance pairs) followed by in_args (cids only)
    local final_args = {}
    for _, a in ipairs(case_args) do table.insert(final_args, a) end
    for _, a in ipairs(in_args) do table.insert(final_args, a) end
    MySQL.update.await(sql, final_args)
```

### 3.3 ADD NEW — §7.1.1 anti-pattern explicit prohibido

After §7.1 (post-pseudo-code block, before §7.2), insert:

```markdown
### 7.1.1 Anti-pattern explicit prohibido (NEW v0.2 R1 — H004 fix)

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
```

### 3.4 Test scenarios

- [ ] **T-AMEND-H004.1** — Mock `pending = [{player_id = "abc'); DROP TABLE sonar_bank_accounts;--"}]` → query executes safely (citizen_id IN (?) binds entire string as single value, no DDL execution).
- [ ] **T-AMEND-H004.2** — Mock 50 pending items normales → batch SELECT + batch UPDATE succeed con identical semantics que pre-patch.
- [ ] **T-AMEND-H004.3** — Performance benchmark: prepared statement vs string.format → ≤10% perf delta (oxmysql cache prepared statements, often FASTER en stable workloads).
- [ ] **T-AMEND-H004.4** — Static grep CI post-implementation: `string\.format\([^,]*['"][^'"]*\(SELECT\|UPDATE\|INSERT\|DELETE\)` → 0 hits in `resources/sonar_*`.

---

## §4 — M002 fix (parcial C-BE-04) · Bridges.UUID.v4 PRNG entropy

**Severity:** MEDIUM
**Spec ref:** `@docs/technical/bank_phase_a/c_be_04_bridges_v1_1.md:172` (§3.2 export `Bridges.UUID.v4`) + correlation_id usage §6.1.
**Recommendation source:** `@docs/technical/08_audit_hooks.md:181-187`.

### Root cause

`Bridges.UUID.v4()` exported sin spec PRNG. Si implementación naïve usa `math.random()` plain (FiveM Lua state-shared default seed) → predictable post-boot → adversary may collide correlation-ids → bypass CP2 mutex (path #1 only — collision faux-cumple uniqueness assumption).

### 4.1 ADD NEW — §3.3.1 PRNG entropy spec

After current §3.3 backwards compatibility note (or end of §3.x), insert:

```markdown
### 3.3.1 `Bridges.UUID.v4` PRNG entropy spec (NEW v0.2 R1 — M002 fix)

`Bridges.UUID.v4()` es la **única canonical UUID source** en SONAR Bank — usado para correlation_id (CP2 mutex), idempotency_key fallback (C-BE-02 §5.2), audit hook correlation_id, sentinel signatures (R1 H003 §4.2).

**Implementation spec (`sonar_bridges/lib/uuid.lua`):**

```lua
-- sonar_bridges/lib/uuid.lua (R1 M002 hardened entropy mix)
local M = {}

-- Per-call entropy mix:
--   1. os.clock() — sub-second monotonic (process-local).
--   2. GetGameTimer() — FiveM-internal monotonic ms.
--   3. os.time()*1000 — wall-clock epoch ms.
--   4. math.random(1, 2^31-1) — re-seeded each call below.
--   5. (optional) GetPlayerPing(source) if source > 0 (network-derived noise).
-- All combined → SHA256 → first 32 hex chars → formatted RFC 4122 v4 (8-4-4-4-12).

local function reseed_random()
  -- Re-seed math.random each call to break determinism. Combine 3 monotonic sources.
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
  -- SHA256 (lib helper, see C-BE-04 §4.2.1)
  local hash = sha256_hex(entropy_blob)  -- 64 hex chars

  -- RFC 4122 v4 format: xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
  -- Where 4 = version 4, y ∈ {8,9,a,b}.
  local version_nibble = '4'  -- v4
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

**Performance budget:** <0.5ms p99 per call (1KB string SHA256 ~negligible). Profiler validation at LOCK time benchmark harness.

**Anti-patrón AP-UUID-1 prohibido** — see `@docs/technical/bank_phase_a/c_be_02_api_contracts_v1_3.md` §5.6 (cross-ref).

**Phase B target:** migrate to FFI native crypto (`require('crypto.random_bytes')(16)` if available) — eliminates pure-Lua SHA256 dependency.
```

### 4.2 Test scenarios

- [ ] **T-AMEND-M002.1** — 1M iterations `Bridges.UUID.v4()` → 0 colisiones.
- [ ] **T-AMEND-M002.2** — Distinct boot sessions (10 simulated) → no UUID prefix collision (entropy mix breaks deterministic seeding).
- [ ] **T-AMEND-M002.3** — Format validation: regex `^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$` matches 100% of generated UUIDs.
- [ ] **T-AMEND-M002.4** — Concurrency: 100 parallel CreateThread loops calling `Bridges.UUID.v4()` 1000x each → 0 colisiones.
- [ ] **T-AMEND-M002.5** — Performance: avg `<0.5ms`, p99 `<2ms` on reference hardware.

---

## §5 — M007 fix · Watchdog metric C action threshold

**Severity:** MEDIUM
**Spec ref:** `@docs/technical/bank_phase_a/c_be_04_bridges_v1_1.md:598-611` (§8.3 watchdog Lite Mode metric C).
**Recommendation source:** `@docs/technical/08_audit_hooks.md:221-227` + Security Lead spec §6.2 (`08_audit_hooks.md:292-301`).

### Root cause

Current §8.3 metric C check para `lite_mode_active` solo loggea warnings + tiene comment `Backend Lead v0.2: refinar métrica`. No hay action threshold para transitionar a `compromised_load_order` automáticamente. Estado comprometido (ESX events sin correlation-id sonar) persiste indefinidamente sin reconciliation forced.

Security Lead C-SEC-03 §6.2 spec proporciona thresholds canónicos:
- `ratio >= 0.7` → HEALTHY.
- `0.1 <= ratio < 0.7` → DEGRADED (log warn).
- `ratio < 0.1` AND `emitted > 50` → COMPROMISED (transition).
- `emitted < 50` → INSUFFICIENT_SAMPLE (skip decision).

### 5.1 BEFORE — §8.3 metric C check block

```@/d/theBigProject/docs/technical/bank_phase_a/c_be_04_bridges_v1_1.md:598-611
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
```

### 5.1 AFTER (DRAFT v0.2)

```lua
  -- C métrica indirecta check (Lite Mode) — R1 M007 fix per C-SEC-03 §6.2 thresholds
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
          { caller_source = 0, internal_call = true }  -- R1 H002 auth gate compliance
        )
        return  -- transition emitted, exit watchdog tick
      end
    end

    -- Reset window counters for next tier window
    watchdog_metrics.sonar_emitted_correlation_ids = 0
    watchdog_metrics.sonar_received_correlation_ids = 0
    watchdog_metrics.last_metric_window_start = GetGameTimer()
  end
```

### 5.2 ADD NEW — §8.3.1 metric C counter integration

After §8.3 watchdog block, insert:

```markdown
### 8.3.1 Metric C counters integration (NEW v0.2 R1 — M007 fix)

Counters incremented at instrumentation points:

- **`sonar_emitted_correlation_ids`** — incremented inside `MutexEcho.encode_correlation_id(reason, cid)` (line 383 §6.1) cada call que emit a ESX `addAccountMoney`/`removeAccountMoney`.
- **`sonar_received_correlation_ids`** — incremented inside `MutexEcho.extract_correlation_id(reason)` cuando match `≠ nil` (línea 388-391) — confirma ESX returned event with our correlation-id intact.

Window reset cada tier check (per `watchdog_check_tier` cleanup at end). Alternative: rolling 5min sliding window if FiveM tick budget permits (Phase B optimization).

**Action thresholds (R1 M007 canonical per C-SEC-03 §6.2):**

| Ratio (received/emitted) | Sample size | Status | Action |
|---|---|---|---|
| ≥ 0.7 | emitted ≥ 50 | HEALTHY | Silent |
| 0.1 ≤ ratio < 0.7 | emitted ≥ 50 | DEGRADED | log warn, metric DevOps |
| < 0.1 | emitted ≥ 50 | COMPROMISED | **Transition `compromised_load_order`** + audit hook + security alert |
| any | emitted < 50 | INSUFFICIENT_SAMPLE | Skip decision, log debug |

**Convars:**
- `sonar_bank_watchdog_compromise_ratio_threshold` default `0.1` (configurable).
- `sonar_bank_watchdog_min_sample_size` default `50` (configurable).
```

### 5.3 Test scenarios

- [ ] **T-AMEND-M007.1** — emitted=100, received=80 → ratio 0.8 → HEALTHY (no transition).
- [ ] **T-AMEND-M007.2** — emitted=100, received=30 → ratio 0.3 → DEGRADED (log warn, no transition).
- [ ] **T-AMEND-M007.3** — emitted=100, received=5 → ratio 0.05 → COMPROMISED → transition `compromised_load_order` + audit hook + alert.
- [ ] **T-AMEND-M007.4** — emitted=20, received=0 → INSUFFICIENT_SAMPLE → skip decision.
- [ ] **T-AMEND-M007.5** — Multi-tick test: 3 tiers consecutive emitted=100 received=3 each → state transitions on tier 1 (do not retrigger transitions on subsequent ticks once already `compromised_load_order`).

---

## §6 — M008 fix · MutexEcho delimiter collision escape

**Severity:** MEDIUM
**Spec ref:** `@docs/technical/bank_phase_a/c_be_04_bridges_v1_1.md:383-391` (§6.1 `encode_correlation_id` + `extract_correlation_id`).
**Recommendation source:** `@docs/technical/08_audit_hooks.md:229-235`.

### Root cause

`encode_correlation_id` usa pipe `|` separator: `"{reason}|sonar_correlation:{uuid}"`. Si `reason_string` ya contiene `|sonar_correlation:` (legitimate edge case OR attacker-crafted reason), el regex `string.match(reason, 'sonar_correlation:([0-9a-f%-]+)')` extraerá el FIRST match, que podría no ser el sonar-emitted correlation-id sino uno injected en `reason`.

Adicionalmente, hay falsos negativos: si `reason` contiene `|sonar_correlation:not-a-real-uuid` antes del actual sonar segment, extract retorna el fake.

### 6.1 BEFORE — §6.1 encode/extract

```@/d/theBigProject/docs/technical/bank_phase_a/c_be_04_bridges_v1_1.md:383-391
function MutexEcho.encode_correlation_id(reason_string, correlation_id)
  -- Encode UUID into reason metadata. Format: "{original_reason}|sonar_correlation:{uuid}"
  return string.format('%s|sonar_correlation:%s', reason_string or '', correlation_id)
end

function MutexEcho.extract_correlation_id(reason_string)
  if not reason_string then return nil end
  return string.match(reason_string, 'sonar_correlation:([0-9a-f%-]+)')
end
```

### 6.1 AFTER (DRAFT v0.2)

```lua
-- R1 M008: escape `|` in reason_string prior to concat + use append-at-tail strict format.
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

### 6.2 ADD NEW — §6.1.1 encoding rationale

Insert after §6.1 (post-pseudo-code), before §6.2:

```markdown
### 6.1.1 Encoding format invariants (NEW v0.2 R1 — M008 fix)

Format wire `{escaped_reason}|sonar_correlation:{uuid_v4}|END`:

- **Escape pipe** in `reason_string` (replace `|` → `\|`) before concat → prevents collision when external resource emits `addAccountMoney` reason that legitimately contains `|`.
- **Terminal sentinel `|END`** anchors extract regex to trailing UUID — defense against intermediate forged `|sonar_correlation:` markers within `reason_string`.
- **Strict UUID shape regex** `[0-9a-f]+%-` 5 segments — prevents accepting non-UUID payloads (e.g. attacker injects `sonar_correlation:malicious_string`).
- **Anchored `$` extraction** ensures we always extract THE LAST sonar marker (the one our encode just added), not any embedded forgery.
- **Decode validation:** `encode_correlation_id` validates UUID shape pre-encode (errors on malformed input). `extract_correlation_id` returns `nil` if no clean match (caller MUST treat as orphan event).

**Defense-in-depth:** combined with R1 M002 multi-entropy UUID + AP-UUID-1 prohibition, attacker collision attack surface essentially eliminated.
```

### 6.3 Test scenarios

- [ ] **T-AMEND-M008.1** — `encode("user transfer | special chars", "abc-123-...")` → `"user transfer \\| special chars|sonar_correlation:abc-123-...|END"`. Extract returns `"abc-123-..."`.
- [ ] **T-AMEND-M008.2** — Adversary-crafted reason: `"|sonar_correlation:fake-uuid|END"` (injected). Encode wraps as `"\\|sonar_correlation:fake-uuid\\|END|sonar_correlation:real-uuid|END"`. Extract anchored `$` returns `"real-uuid"` (the rightmost legitimate marker).
- [ ] **T-AMEND-M008.3** — `extract("addAccountMoney 500")` (no sonar marker) → returns `nil`. Caller increments orphan counter.
- [ ] **T-AMEND-M008.4** — `extract("|sonar_correlation:malformed_string|END")` (non-UUID shape) → returns `nil`. UUID regex strict.
- [ ] **T-AMEND-M008.5** — Round-trip: encode + extract = original UUID for 1000 random UUIDs + 1000 reason permutations. Property-based test.

---

## §7 — Versioning + sign-off

### 7.1 Versioning entry (post-LOCK promotion)

Append a §13 Versioning C-BE-04 row pendiente:

```markdown
| **v1.0.1 R1 LOCKED** | TBD post-founder approval | BANK-BE.AMEND.1 surgical patches Round 1 reactive a Security Lead audit C-SEC-01/02/03 v0.1: H002 (Bridges.BankStatus.Transition ACE gate P12 + console + whitelist internal_call) + H003 (Core Override sentinel hardening triple-defense: closure-upvalue + GlobalState replicated=false + SHA256 checksum + probe fn introspection — eliminated public attribute QBCore.__sonar_patched mutability vulnerability) + H004 (reconciliation pipeline SQL prepared statements posicionales — eliminated string.format concat vulnerabilities steps 3+5) + M002 (Bridges.UUID.v4 multi-entropy PRNG mix spec + AP-UUID-1 prohibition) + M007 (watchdog metric C action threshold COMPROMISED ratio<0.1 + INSUFFICIENT_SAMPLE skip + counter integration MutexEcho instrumentation) + M008 (MutexEcho delimiter escape `\|` + terminal sentinel `|END` + anchored UUID-strict regex). SHA256 lib helper introduced (`sonar_bridges/lib/sha256.lua` Phase A pure-Lua, Phase B FFI). Sin schema migration impact (DB Lead consultative confirmed). Sign-off founder + Backend + Security re-audit. |
```

### 7.2 Sign-off (this AMEND file)

| Rol | Status |
|---|---|
| Backend Lead (Cascade) | ✅ self-attested DRAFT v0.2 emitted |
| Founder yaboula | ⏳ PENDING review |
| Security Lead (Cascade) | ⏳ PENDING re-audit closure H002 + H003 + H004 + M002 + M007 + M008 |
| DevOps Lead | ⚠️ CONSULTATIVE — H4 runbook deps: HMAC convar (M006 cross-ref), `sonar_bank_watchdog_compromise_ratio_threshold` convar (M007), `sonar_status_transition_whitelist` convar (H002) |

---

**FIN AMEND-C-BE-04-r1-v0.2 DRAFT** — 6 patches surgical (H002 + H003 + H004 + M002-partial + M007 + M008).
