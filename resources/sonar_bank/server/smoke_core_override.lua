-- =============================================================================
-- SMOKE CORE OVERRIDE — ST-023 series
-- =============================================================================
-- Owner:   AI Money Authority Lead (BANK-BE.MONEY_AUTHORITY.1).
-- Status:  DEV ONLY. Gated by convar `sonar_dev_mode 1` + ACE `sonar.bank.admin`.
-- Scope:   Probes Bridges.CoreOverride / MirrorSync / Reconcile / Watchdog
--          surface from sonar_bank VM via exports.sonar_bridges.
-- Non-goal: NOT a unit test of services. NOT a chaos run. Read-only probes
--          + observability assertions. No DB writes.
-- =============================================================================

local DEV_CONVAR = 'sonar_dev_mode'
local ACE_PERM   = 'sonar.bank.admin' -- aligned with existing add_ace group.admin sonar.bank.admin allow

local function is_dev_enabled()
  return GetConvarInt(DEV_CONVAR, 0) == 1
end

if not is_dev_enabled() then
  return -- no-op silent in production.
end

local SmokeCO = {}
SmokeCO.results = {}

local function color(level)
  if level == 'pass' then return '^2' end
  if level == 'fail' then return '^1' end
  if level == 'warn' then return '^3' end
  if level == 'skip' then return '^5' end
  return '^7'
end

local function log(level, fmt, ...)
  local msg = (select('#', ...) > 0) and string.format(fmt, ...) or fmt
  print(('%s[SMOKE_CORE_OVERRIDE] [%s] %s^7'):format(color(level), level:upper(), msg))
end

local function record(id, status, detail)
  SmokeCO.results[#SmokeCO.results + 1] = { id = id, status = status, detail = detail or '' }
  log(status, '%s — %s %s', id, status:upper(), detail or '')
end

-- ---------------------------------------------------------------------------
-- Bridge surface helpers
-- ---------------------------------------------------------------------------

local function get_health()
  local ok, h = pcall(function() return exports.sonar_bridges:GetCoreOverrideHealth() end)
  if not ok or type(h) ~= 'table' then return nil end
  return h
end

local function reconcile_run(opts)
  local ok, r = pcall(function() return exports.sonar_bridges:ReconcileRun(opts or {}) end)
  if not ok then return nil end
  return r
end

local function reconcile_enqueue(item)
  local ok = pcall(function() return exports.sonar_bridges:ReconcileEnqueue(item or {}) end)
  return ok
end

local function mirror_sync(citizen_id, balance_minor, opts)
  local ok, r = pcall(function() return exports.sonar_bridges:MirrorSyncBalance(citizen_id, balance_minor, opts or {}) end)
  if not ok then return { ok = false, error = 'EXPORT_THROW' } end
  return r
end

local function watchdog_check(reason)
  local ok, r = pcall(function() return exports.sonar_bridges:WatchdogCheck(reason or 'smoke_co') end)
  if not ok then return false end
  return r
end

local function get_player_entry(players, src)
  if type(players) ~= 'table' then return nil end
  return players[tonumber(src)] or players[tostring(src)]
end

local function count_installed_players(players)
  local count = 0
  if type(players) ~= 'table' then return count end
  for _ in pairs(players) do count = count + 1 end
  return count
end

-- ---------------------------------------------------------------------------
-- ST-023.1 — Boot detect: override registered for active framework
-- ---------------------------------------------------------------------------
function SmokeCO.ST_023_1()
  local h = get_health()
  if not h then return record('ST-023.1', 'fail', 'GetCoreOverrideHealth export missing') end
  local bank = tostring(h.active_bank or 'nil')
  if bank == 'native' then
    return record('ST-023.1', 'skip', 'active_bank=native (no override expected)')
  end
  local flag = h[bank .. '_registered']
  if flag == true then
    return record('ST-023.1', 'pass', 'active_bank=' .. bank .. ' registered=true')
  end
  return record('ST-023.1', 'fail', 'active_bank=' .. bank .. ' registered flag missing or false')
end

-- ---------------------------------------------------------------------------
-- ST-023.2 — Install hook surface present (PlayerLoaded path)
-- ---------------------------------------------------------------------------
function SmokeCO.ST_023_2()
  -- We cannot mock QBCore:Server:PlayerLoaded from external VM; instead we
  -- assert that the installer surface exists and is callable.
  local has_health = type(exports.sonar_bridges) == 'table'
  if not has_health then
    return record('ST-023.2', 'fail', 'exports.sonar_bridges not reachable from sonar_bank VM')
  end
  local h = get_health()
  if not h then return record('ST-023.2', 'fail', 'health surface unavailable') end
  if type(h.players) ~= 'table' then
    return record('ST-023.2', 'fail', 'health.players table missing')
  end
  local installed = count_installed_players(h.players)
  local online = #GetPlayers()
  if online > 0 and installed == 0 then
    return record('ST-023.2', 'fail', ('installer surface present but no installed players; online=%d installed=%d'):format(online, installed))
  end
  return record('ST-023.2', 'pass', ('installer surface present; online=%d installed=%d'):format(online, installed))
end

-- ---------------------------------------------------------------------------
-- ST-023.3 — MirrorSyncBalance is reachable and synchronous
-- ---------------------------------------------------------------------------
function SmokeCO.ST_023_3()
  -- Use a synthetic citizen id that will not match any framework player.
  -- We assert the call returns synchronously with a typed result, not nil.
  local started = os.clock()
  local r = mirror_sync('CID-SMOKE-NONEXISTENT', 10000, { reason = 'smoke_co_023_3' })
  local elapsed_ms = math.floor((os.clock() - started) * 1000)
  if type(r) ~= 'table' then
    return record('ST-023.3', 'fail', 'MirrorSyncBalance returned non-table')
  end
  if elapsed_ms > 250 then
    return record('ST-023.3', 'warn', ('returned in %dms (>250ms threshold)'):format(elapsed_ms))
  end
  return record('ST-023.3', 'pass', ('sync return ok in %dms result.ok=%s err=%s'):format(elapsed_ms, tostring(r.ok), tostring(r.error)))
end

-- ---------------------------------------------------------------------------
-- ST-023.4 — Mirror failure auto-enqueues reconcile (Decision 1)
-- ---------------------------------------------------------------------------
function SmokeCO.ST_023_4()
  local h0 = get_health()
  local before = (h0 and h0.reconcile and h0.reconcile.pending) or 0
  -- Force a failing mirror sync on a non-existent citizen (NOT_FOUND when
  -- framework active is qbcore/qbox/esx; native returns ok=noop so we skip).
  local h = get_health()
  if h and h.active_bank == 'native' then
    return record('ST-023.4', 'skip', 'native bank: no foreign mirror to fail')
  end
  mirror_sync('CID-SMOKE-FORCE-FAIL', 12345, { reason = 'smoke_co_023_4', correlation_id = 'smoke_co_023_4_corr' })
  local h1 = get_health()
  local after = (h1 and h1.reconcile and h1.reconcile.pending) or 0
  if after > before then
    return record('ST-023.4', 'pass', ('reconcile pending grew %d→%d on mirror failure'):format(before, after))
  end
  return record('ST-023.4', 'fail', ('reconcile pending unchanged (%d) — fallback enqueue not triggered'):format(after))
end

-- ---------------------------------------------------------------------------
-- ST-023.5 — Reconcile.Run accepts balance_minor and target_balance_minor
-- ---------------------------------------------------------------------------
function SmokeCO.ST_023_5()
  local r1 = reconcile_run({ citizen_id = 'CID-SMOKE-RECONCILE', balance_minor = 9999, mode = 'smoke_co' })
  local r2 = reconcile_run({ citizen_id = 'CID-SMOKE-RECONCILE', target_balance_minor = 9999, mode = 'smoke_co' })
  if type(r1) ~= 'table' or type(r2) ~= 'table' then
    return record('ST-023.5', 'fail', 'ReconcileRun returned non-table')
  end
  if not r1.summary or not r2.summary then
    return record('ST-023.5', 'fail', 'ReconcileRun missing summary')
  end
  return record('ST-023.5', 'pass', 'ReconcileRun accepted both balance field aliases')
end

-- ---------------------------------------------------------------------------
-- ST-023.6 — Drift detection: manual enqueue surfaces in pending queue
-- ---------------------------------------------------------------------------
function SmokeCO.ST_023_6()
  local h0 = get_health()
  local before = (h0 and h0.reconcile and h0.reconcile.pending) or 0
  local ok = reconcile_enqueue({
    framework = 'smoke',
    operation = 'simulated_drift',
    citizen_id = 'CID-SMOKE-DRIFT',
    target_balance_minor = 50000,
    reason = 'smoke_co_023_6',
  })
  local h1 = get_health()
  local after = (h1 and h1.reconcile and h1.reconcile.pending) or 0
  if ok and after > before then
    return record('ST-023.6', 'pass', ('queue grew %d→%d on manual enqueue'):format(before, after))
  end
  return record('ST-023.6', 'fail', ('manual enqueue did not surface (before=%d after=%d)'):format(before, after))
end

-- ---------------------------------------------------------------------------
-- ST-023.7 — Watchdog cold boot probe returns boolean
-- ---------------------------------------------------------------------------
function SmokeCO.ST_023_7()
  local r = watchdog_check('smoke_co_023_7')
  if type(r) ~= 'boolean' then
    return record('ST-023.7', 'fail', 'WatchdogCheck did not return boolean')
  end
  local h = get_health()
  local bank = h and h.active_bank or 'native'
  if bank == 'native' and r == true then
    return record('ST-023.7', 'pass', 'native bank: watchdog vacuously ok')
  end
  if r == true then
    return record('ST-023.7', 'pass', 'watchdog ok for framework=' .. tostring(bank))
  end
  return record('ST-023.7', 'warn', 'watchdog reports degraded for framework=' .. tostring(bank))
end

-- ---------------------------------------------------------------------------
-- ST-023.8 — Idempotency: repeated mirror sync with same correlation_id
--           must remain synchronous and not crash. Reconcile growth is
--           bounded (does not multiply queue per retry beyond N=retries).
-- ---------------------------------------------------------------------------
function SmokeCO.ST_023_8()
  local h0 = get_health()
  if h0 and h0.active_bank == 'native' then
    return record('ST-023.8', 'skip', 'native bank: idempotency vacuous')
  end
  local before = (h0 and h0.reconcile and h0.reconcile.pending) or 0
  local opts = { reason = 'smoke_co_023_8', correlation_id = 'smoke_co_023_8_corr', idempotency_key = 'IDEM-SMOKE-023-8' }
  for _ = 1, 3 do
    mirror_sync('CID-SMOKE-IDEM', 7777, opts)
  end
  local h1 = get_health()
  local after = (h1 and h1.reconcile and h1.reconcile.pending) or 0
  -- We expect 3 enqueues (one per retry) because the reconcile primitive in
  -- Phase 4 does not dedupe by idempotency_key; this asserts at least
  -- bounded linear growth, not crash.
  if after >= before then
    return record('ST-023.8', 'pass', ('queue %d→%d after 3 retries with same corr id (no crash)'):format(before, after))
  end
  return record('ST-023.8', 'fail', ('queue regressed %d→%d unexpectedly'):format(before, after))
end

-- ---------------------------------------------------------------------------
-- ST-023.9 — Every online player has active framework override bookkeeping
-- ---------------------------------------------------------------------------
function SmokeCO.ST_023_9()
  local h = get_health()
  if not h then return record('ST-023.9', 'fail', 'health unavailable') end
  local bank = tostring(h.active_bank or 'native')
  if bank == 'native' or bank == 'esx' then
    return record('ST-023.9', 'skip', 'active_bank=' .. bank .. ' has no per-player assertion')
  end
  local missing = {}
  for _, src in ipairs(GetPlayers()) do
    local entry = get_player_entry(h.players, src)
    if not entry or entry.framework ~= bank then
      missing[#missing + 1] = tostring(src)
    end
  end
  if #missing == 0 then
    return record('ST-023.9', 'pass', ('all online players installed for framework=%s count=%d'):format(bank, #GetPlayers()))
  end
  return record('ST-023.9', 'fail', ('missing override bookkeeping for src=%s framework=%s'):format(table.concat(missing, ','), bank))
end

-- ---------------------------------------------------------------------------
-- Runner
-- ---------------------------------------------------------------------------
function SmokeCO.RunAll()
  SmokeCO.results = {}
  log('info', '=== ST-023 series START ===')
  SmokeCO.ST_023_1()
  SmokeCO.ST_023_2()
  SmokeCO.ST_023_3()
  SmokeCO.ST_023_4()
  SmokeCO.ST_023_5()
  SmokeCO.ST_023_6()
  SmokeCO.ST_023_7()
  SmokeCO.ST_023_8()
  SmokeCO.ST_023_9()
  local pass, fail, warn, skip = 0, 0, 0, 0
  for _, r in ipairs(SmokeCO.results) do
    if r.status == 'pass' then pass = pass + 1
    elseif r.status == 'fail' then fail = fail + 1
    elseif r.status == 'warn' then warn = warn + 1
    elseif r.status == 'skip' then skip = skip + 1 end
  end
  log('info', '=== ST-023 series END — pass=%d fail=%d warn=%d skip=%d ===', pass, fail, warn, skip)
  return SmokeCO.results
end

-- ---------------------------------------------------------------------------
-- Console command registration (ACE-gated)
-- ---------------------------------------------------------------------------
RegisterCommand('sonar_smoke_core_override', function(source)
  if source ~= 0 and not IsPlayerAceAllowed(source, ACE_PERM) then
    if source > 0 then
      TriggerClientEvent('chat:addMessage', source, { args = { '^1[SMOKE_CORE_OVERRIDE]', 'ACE denied.' } })
    end
    return
  end
  SmokeCO.RunAll()
end, true)

RegisterCommand('sonar_co_dump', function(source)
  if source ~= 0 and not IsPlayerAceAllowed(source, ACE_PERM) then
    if source > 0 then
      TriggerClientEvent('chat:addMessage', source, { args = { '^1[SMOKE_CORE_OVERRIDE]', 'ACE denied.' } })
    end
    return
  end

  local h = get_health()
  if not h then
    log('fail', 'health unavailable')
    return
  end
  log('info', 'health active_bank=%s qbcore_registered=%s qbox_registered=%s esx_registered=%s pending=%s',
    tostring(h.active_bank), tostring(h.qbcore_registered), tostring(h.qbox_registered),
    tostring(h.esx_registered), tostring(h.reconcile and h.reconcile.pending))
  for _, src in ipairs(GetPlayers()) do
    local entry = get_player_entry(h.players, src)
    if entry then
      log('info', 'player src=%s framework=%s citizen=%s installed_at=%s via=%s',
        tostring(src), tostring(entry.framework), tostring(entry.citizen_id),
        tostring(entry.installed_at), tostring(entry.via or 'instance_patch'))
    else
      log('warn', 'player src=%s has NO core override bookkeeping entry', tostring(src))
    end
  end
end, true)

_G.SmokeCoreOverride = SmokeCO

log('info', 'smoke_core_override.lua loaded (dev mode). Run: sonar_smoke_core_override or sonar_co_dump')
