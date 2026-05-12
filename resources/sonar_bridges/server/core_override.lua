Bridges = Bridges or {}

local Logger = Bridges.Logger

Bridges.CoreOverride = Bridges.CoreOverride or {}
Bridges.MirrorSync = Bridges.MirrorSync or {}
Bridges.Reconcile = Bridges.Reconcile or {}

local CoreOverride = Bridges.CoreOverride
local MirrorSync = Bridges.MirrorSync
local Reconcile = Bridges.Reconcile

local state = {
  active_bank = nil,
  qbcore_registered = false,
  qbox_registered = false,
  esx_registered = false,
  players = {},
  queue = {},
  -- in_flight[token] = { expires_at, citizen_id, op, amount } — single-use
  -- capability tokens for legitimate Sonar mirror mutations. See M2 design.
  in_flight = {},
}

-- One-time PRNG seed. Combines wallclock + game timer + a FiveM-provided
-- 32-bit random integer for variety across server restarts.
math.randomseed((os.time() or 0) + (GetGameTimer() or 0) + (math.random(0, 2147483647)))

local function framework_amount(balance_minor)
  local minor = tonumber(balance_minor)
  if not minor then return nil end
  return math.floor(minor / 100)
end

-- ---------------------------------------------------------------------------
-- M2 security model: single-use capability tokens.
-- mirror_reason(opts) is called by Sonar code BEFORE invoking a foreign
-- framework's SetMoney/AddMoney/RemoveMoney as part of a legitimate mirror
-- sync. It generates a random token, registers it in state.in_flight with a
-- short TTL, and returns the reason string `sonar_mirror_sync|<token>`.
-- The framework's pre-hook (e.g. qb-core OnMoneyPreHook) extracts the token
-- and calls consume_mirror_token() which BOTH validates the token exists AND
-- removes it (single-use). An attacker forging the reason string would have
-- to guess a 64-bit random token AND the token would be valid for at most
-- ~30 seconds — and only ONE attacker-controlled call would succeed before
-- it gets consumed (legit Sonar code would then fail the consume).
-- ---------------------------------------------------------------------------
local MIRROR_TOKEN_TTL_MS = 30000

local function gen_correlation()
  -- 64 bits of randomness from two 32-bit draws plus timestamp suffix.
  return string.format('%08x%08x%x',
    math.random(0, 0xFFFFFFFF),
    math.random(0, 0xFFFFFFFF),
    GetGameTimer() or 0)
end

local function mirror_reason(opts)
  opts = opts or {}
  local correlation = opts.correlation_id or opts.correlation or opts.idempotency_key or gen_correlation()
  state.in_flight[correlation] = {
    expires_at = GetGameTimer() + MIRROR_TOKEN_TTL_MS,
    citizen_id = opts.citizen_id,
    op         = opts.op,
    amount     = opts.amount,
  }
  return ('sonar_mirror_sync|%s'):format(tostring(correlation))
end

local function parse_mirror_token(reason)
  if type(reason) ~= 'string' then return nil end
  return reason:match('^sonar_mirror_sync|(.+)$')
end

-- Lax check (preserved for back-compat in the dead wrapper path and qbox/esx
-- post-mutation observers which are NOT in the security boundary). Does NOT
-- consume the token; returns true if the reason has the mirror prefix.
local function is_mirror_reason(reason)
  return parse_mirror_token(reason) ~= nil
end

-- STRICT check: validates the token exists in state.in_flight, has not
-- expired, AND removes it (single-use). Returns true only for a valid,
-- previously-issued Sonar mirror token. This is the function used at the
-- real security boundary (qb-core OnMoneyPreHook).
local function consume_mirror_token(reason)
  local token = parse_mirror_token(reason)
  if not token then return false end
  local entry = state.in_flight[token]
  if not entry then return false end
  state.in_flight[token] = nil
  if GetGameTimer() > entry.expires_at then return false end
  return true
end

-- Periodic cleanup of expired tokens (in case a Sonar mirror call started
-- but never reached the framework pre-hook — e.g. framework error before
-- reaching SetMoney). Runs every 60s.
CreateThread(function()
  while true do
    Wait(60000)
    local now = GetGameTimer()
    for token, entry in pairs(state.in_flight) do
      if now > entry.expires_at then state.in_flight[token] = nil end
    end
  end
end)

-- Some QB resources wrap player.Functions.* and core.Functions.* with
-- callable tables (tables with __call metamethod) for logging/metrics/perm
-- middleware. Lua type() returns 'table' for those, but they ARE callable.
-- We must accept both functions and callable tables anywhere we previously
-- required a function.
local function is_callable(v)
  local t = type(v)
  if t == 'function' then return true end
  if t == 'table' then
    local mt = getmetatable(v)
    if mt and type(mt.__call) == 'function' then return true end
  end
  return false
end

local function get_qbcore()
  if GetResourceState('qb-core') ~= 'started' then return nil end
  local ok, core = pcall(function()
    return exports['qb-core']:GetCoreObject()
  end)
  if ok and type(core) == 'table' then return core end
  return nil
end

local function get_qbcore_player_by_source(source)
  local core = get_qbcore()
  if not core or not core.Functions or not is_callable(core.Functions.GetPlayer) then return nil end
  local ok, player = pcall(core.Functions.GetPlayer, tonumber(source))
  if ok then return player end
  return nil
end

local function get_qbcore_player_by_citizen_id(citizen_id)
  local core = get_qbcore()
  if not core or not core.Functions then return nil end
  if is_callable(core.Functions.GetPlayerByCitizenId) then
    local ok, player = pcall(core.Functions.GetPlayerByCitizenId, citizen_id)
    if ok and player then return player end
  end
  for _, src in ipairs(GetPlayers()) do
    local player = get_qbcore_player_by_source(tonumber(src))
    if player and player.PlayerData and player.PlayerData.citizenid == citizen_id then return player end
  end
  return nil
end

local function get_qbox_player_by_citizen_id(citizen_id)
  if GetResourceState('qbx_core') ~= 'started' then return nil end
  local ok, player = pcall(function()
    return exports.qbx_core:GetPlayerByCitizenId(citizen_id)
  end)
  if ok then return player end
  return nil
end

local function get_qbox_player_by_source(source)
  if GetResourceState('qbx_core') ~= 'started' then return nil end
  local ok, player = pcall(function()
    return exports.qbx_core:GetPlayer(tonumber(source))
  end)
  if ok then return player end
  return nil
end

local function get_esx()
  if GetResourceState('es_extended') ~= 'started' then return nil end
  local ok, obj = pcall(function()
    return exports['es_extended']:getSharedObject()
  end)
  if ok and type(obj) == 'table' then return obj end
  local esx = nil
  TriggerEvent('esx:getSharedObject', function(obj)
    if type(obj) == 'table' then esx = obj end
  end)
  return esx
end

local function get_esx_player(identifier)
  local ESX = get_esx()
  if not ESX then return nil end
  if is_callable(ESX.GetPlayerFromIdentifier) then
    local ok, player = pcall(ESX.GetPlayerFromIdentifier, identifier)
    if ok and player then return player end
  end
  if is_callable(ESX.Player) then
    local ok, player = pcall(ESX.Player, identifier)
    if ok and player then return player end
  end
  return nil
end

local function call_player_method(player, method, ...)
  local fn = player and player[method] or nil
  if not is_callable(fn) then return false end
  local ok, result = pcall(fn, player, ...)
  if ok then return result ~= false end
  ok, result = pcall(fn, ...)
  if ok then return result ~= false end
  return false
end

function Reconcile.Enqueue(item)
  if type(item) ~= 'table' then return false end
  item.enqueued_at = item.enqueued_at or GetGameTimer()
  state.queue[#state.queue + 1] = item
  if Logger and Logger.Warn then
    Logger.Warn('Money authority reconcile queued framework=%s reason=%s', tostring(item.framework), tostring(item.reason))
  end
  return true
end

function Reconcile.GetQueueStats()
  return { pending = #state.queue }
end

function Reconcile.Run(opts)
  opts = opts or {}
  local applied = 0
  local failed = 0
  local balance_minor = opts.balance_minor or opts.target_balance_minor
  if type(opts.citizen_id) == 'string' and type(balance_minor) == 'number' then
    local result = MirrorSync.SetBalance(opts.citizen_id, balance_minor, opts)
    if result.ok then applied = applied + 1 else failed = failed + 1 end
  end
  local pending = #state.queue
  if opts.drain == true then state.queue = {} end
  return {
    summary = {
      mode = opts.mode or 'admin_triggered',
      applied = applied,
      failed = failed,
      pending = pending,
      drained = opts.drain == true,
    },
  }
end

local function mirror_qbcore(citizen_id, balance_minor, opts)
  local amount = framework_amount(balance_minor)
  if not amount then return { ok = false, error = 'INVALID_AMOUNT' } end
  local player = get_qbcore_player_by_citizen_id(citizen_id)
  if not player or not player.Functions then return { ok = false, error = 'NOT_FOUND' } end
  local set = player.Functions.SetMoney
  if not is_callable(set) then return { ok = false, error = 'SET_UNAVAILABLE' } end
  local installed = false
  if player.PlayerData and player.PlayerData.source then
    local s = tonumber(player.PlayerData.source)
    if s and state.players[s] and state.players[s].framework == 'qbcore' then installed = true end
  end
  local ok, result = pcall(set, 'bank', amount, mirror_reason(opts))
  local call_form = 'flat'
  if not ok then
    ok, result = pcall(set, player, 'bank', amount, mirror_reason(opts))
    call_form = 'method'
  end
  if ok and result ~= false then
    if Logger and Logger.Info then
      Logger.Info('Mirror sync ok citizen=%s amount=%d form=%s installed=%s reason=%s',
        tostring(citizen_id), amount, call_form, tostring(installed), tostring(opts and opts.reason))
    end
    return { ok = true, framework = 'qbcore', balance = amount }
  end
  if Logger and Logger.Warn then
    Logger.Warn('Mirror sync FAILED citizen=%s amount=%d form=%s installed=%s pcall_ok=%s result=%s',
      tostring(citizen_id), amount, call_form, tostring(installed), tostring(ok), tostring(result))
  end
  return { ok = false, error = 'FAILED' }
end

local function mirror_qbox(citizen_id, balance_minor, opts)
  local amount = framework_amount(balance_minor)
  if not amount then return { ok = false, error = 'INVALID_AMOUNT' } end
  local player = get_qbox_player_by_citizen_id(citizen_id)
  if not player or not player.Functions then return { ok = false, error = 'NOT_FOUND' } end
  local set = player.Functions.SetMoney
  if not is_callable(set) then return { ok = false, error = 'SET_UNAVAILABLE' } end
  local ok, result = pcall(set, 'bank', amount, mirror_reason(opts))
  if not ok then ok, result = pcall(set, player, 'bank', amount, mirror_reason(opts)) end
  if ok and result ~= false then return { ok = true, framework = 'qbox', balance = amount } end
  return { ok = false, error = 'FAILED' }
end

local function mirror_esx(citizen_id, balance_minor, opts)
  local amount = framework_amount(balance_minor)
  if not amount then return { ok = false, error = 'INVALID_AMOUNT' } end
  local player = get_esx_player(citizen_id)
  if not player then return { ok = false, error = 'NOT_FOUND' } end
  local ok = call_player_method(player, 'setAccountMoney', 'bank', amount, mirror_reason(opts))
  if ok then return { ok = true, framework = 'esx', balance = amount } end
  return { ok = false, error = 'FAILED' }
end

function MirrorSync.SetBalance(citizen_id, balance_minor, opts)
  opts = opts or {}
  if type(citizen_id) ~= 'string' or citizen_id == '' then return { ok = false, error = 'INVALID_CITIZEN_ID' } end
  local active = opts.framework or state.active_bank or (Bridges._active and Bridges._active.bank) or 'native'
  if active == 'native' then return { ok = true, framework = 'native', noop = true } end
  if active == 'qbcore' then return mirror_qbcore(citizen_id, balance_minor, opts) end
  if active == 'qbox' then return mirror_qbox(citizen_id, balance_minor, opts) end
  if active == 'esx' then return mirror_esx(citizen_id, balance_minor, opts) end
  return { ok = false, error = 'UNSUPPORTED_FRAMEWORK', framework = active }
end

local function handle_foreign_mutation(payload)
  Reconcile.Enqueue(payload)
  return false
end

local function normalize_money_call(a, b, c, d)
  if type(a) == 'string' then return nil, a, b, c end
  return a, b, c, d
end

local function call_original(fn, self_arg, money_type, amount, reason)
  if self_arg ~= nil then return fn(self_arg, money_type, amount, reason) end
  return fn(money_type, amount, reason)
end

local function dump_functions_table(player)
  if type(player) ~= 'table' or type(player.Functions) ~= 'table' then return 'NIL_OR_NOT_TABLE' end
  local keys = {}
  local count = 0
  for k, v in pairs(player.Functions) do
    count = count + 1
    if count <= 30 then
      keys[#keys + 1] = ('%s=%s'):format(tostring(k), type(v))
    end
  end
  local mt = getmetatable(player.Functions)
  return ('count=%d mt=%s keys={%s}'):format(count, tostring(mt ~= nil), table.concat(keys, ','))
end

local function install_qbcore_player(player, install_ctx)
  install_ctx = install_ctx or 'unknown'
  if player and player.PlayerData and not player.Functions then
    local candidate = get_qbcore_player_by_source(player.PlayerData.source)
    if candidate then player = candidate end
  end
  if not player then
    if Logger and Logger.Warn then
      local core = get_qbcore()
      Logger.Warn('install_qbcore_player ctx=%s NO_PLAYER core_resolved=%s players_table_type=%s',
        tostring(install_ctx), tostring(core ~= nil), core and type(core.Players) or 'nil')
    end
    return false, 'NO_PLAYER'
  end
  if type(player) ~= 'table' then return false, 'INVALID_PLAYER' end
  if not player.PlayerData then return false, 'NO_PLAYERDATA' end
  if not player.Functions then return false, 'NO_FUNCTIONS' end
  local source = tonumber(player.PlayerData.source)
  if not source then return false, 'NO_SOURCE' end
  -- Idempotency: only skip if existing wrapper is still intact. If a third-party
  -- framework re-wrapped Functions.AddMoney after our install, we must re-patch.
  do
    local existing = state.players[source]
    if existing and existing.framework == 'qbcore' and existing.wrappers then
      if player.Functions.AddMoney == existing.wrappers.AddMoney then
        return true
      end
      if Logger and Logger.Warn then
        Logger.Warn('install_qbcore_player ctx=%s src=%s wrapper DRIFTED, re-installing. expected=%s actual=%s',
          tostring(install_ctx), tostring(source),
          tostring(existing.wrappers.AddMoney), tostring(player.Functions.AddMoney))
      end
    end
  end
  local originals = {
    AddMoney = player.Functions.AddMoney,
    RemoveMoney = player.Functions.RemoveMoney,
    SetMoney = player.Functions.SetMoney,
  }
  if Logger and Logger.Info then
    Logger.Info('install_qbcore_player ctx=%s src=%s PRE-WRAP types: Add=%s/%s Remove=%s/%s Set=%s/%s',
      tostring(install_ctx), tostring(source),
      type(originals.AddMoney), tostring(originals.AddMoney),
      type(originals.RemoveMoney), tostring(originals.RemoveMoney),
      type(originals.SetMoney), tostring(originals.SetMoney))
  end
  if not is_callable(originals.AddMoney) then
    if Logger and Logger.Warn then
      Logger.Warn('install_qbcore_player ctx=%s ADDMONEY_UNAVAILABLE src=%s addmoney_type=%s removemoney_type=%s setmoney_type=%s functions_dump={%s}',
        tostring(install_ctx), tostring(source),
        type(originals.AddMoney), type(originals.RemoveMoney), type(originals.SetMoney),
        dump_functions_table(player))
    end
    return false, 'ADDMONEY_UNAVAILABLE'
  end
  if not is_callable(originals.RemoveMoney) then return false, 'REMOVEMONEY_UNAVAILABLE' end
  -- TRACE wrappers (verbose). Convar `sonar_co_trace_intercept=1` enables.
  local function trace_enabled()
    return GetConvarInt('sonar_co_trace_intercept', 0) == 1
  end
  local function trace(op, money_type, amount, reason, decision)
    if not trace_enabled() then return end
    if Logger and Logger.Info then
      Logger.Info('[INTERCEPT] op=%s src=%s cid=%s money_type=%s amount=%s reason=%s mirror=%s decision=%s',
        op, tostring(source), tostring(player.PlayerData.citizenid),
        tostring(money_type), tostring(amount), tostring(reason),
        tostring(is_mirror_reason(reason)), decision)
    end
  end
  player.Functions.AddMoney = function(a, b, c, d)
    local self_arg, money_type, amount, reason = normalize_money_call(a, b, c, d)
    if money_type ~= 'bank' or is_mirror_reason(reason) then
      trace('AddMoney', money_type, amount, reason, 'PASS_THROUGH')
      return call_original(originals.AddMoney, self_arg, money_type, amount, reason)
    end
    trace('AddMoney', money_type, amount, reason, 'BLOCK_FOREIGN')
    return handle_foreign_mutation({ framework = 'qbcore', operation = 'add', source = source, citizen_id = player.PlayerData.citizenid, amount = amount, reason = reason })
  end
  player.Functions.RemoveMoney = function(a, b, c, d)
    local self_arg, money_type, amount, reason = normalize_money_call(a, b, c, d)
    if money_type ~= 'bank' or is_mirror_reason(reason) then
      trace('RemoveMoney', money_type, amount, reason, 'PASS_THROUGH')
      return call_original(originals.RemoveMoney, self_arg, money_type, amount, reason)
    end
    trace('RemoveMoney', money_type, amount, reason, 'BLOCK_FOREIGN')
    return handle_foreign_mutation({ framework = 'qbcore', operation = 'remove', source = source, citizen_id = player.PlayerData.citizenid, amount = amount, reason = reason })
  end
  if is_callable(originals.SetMoney) then
    player.Functions.SetMoney = function(a, b, c, d)
      local self_arg, money_type, amount, reason = normalize_money_call(a, b, c, d)
      if money_type ~= 'bank' or is_mirror_reason(reason) then
        trace('SetMoney', money_type, amount, reason, 'PASS_THROUGH')
        return call_original(originals.SetMoney, self_arg, money_type, amount, reason)
      end
      trace('SetMoney', money_type, amount, reason, 'BLOCK_FOREIGN')
      return handle_foreign_mutation({ framework = 'qbcore', operation = 'set', source = source, citizen_id = player.PlayerData.citizenid, amount = amount, reason = reason })
    end
  end
  -- Capture wrapper refs for drift detection. Lua resolves names statically
  -- in this block, so we capture by reading back the table slots we just wrote.
  local wrappers = {
    AddMoney    = player.Functions.AddMoney,
    RemoveMoney = player.Functions.RemoveMoney,
    SetMoney    = player.Functions.SetMoney,
  }
  -- Install __index/__newindex trap to CATCH + BLOCK third-party overwrites
  -- of our wrapper slots. __newindex only fires for ABSENT keys; so we move
  -- our wrappers into a closure-private store, clear the visible table slots,
  -- and serve reads via __index. Writes to trapped keys are blocked & logged
  -- with debug.traceback() to reveal the offending resource.
  -- Controlled by convar `sonar_co_trap_writes=1` (default ON).
  local trap_enabled = GetConvarInt('sonar_co_trap_writes', 1) == 1
  local trap_log_only = GetConvarInt('sonar_co_trap_log_only', 0) == 1
  if trap_enabled then
    local existing_mt = getmetatable(player.Functions)
    if existing_mt == nil then
      local trapped_keys = { AddMoney = true, RemoveMoney = true, SetMoney = true }
      -- Private store holding our wrappers; visible table slots cleared so
      -- __index / __newindex fire.
      local private_wrappers = {
        AddMoney    = wrappers.AddMoney,
        RemoveMoney = wrappers.RemoveMoney,
        SetMoney    = wrappers.SetMoney,
      }
      rawset(player.Functions, 'AddMoney',    nil)
      rawset(player.Functions, 'RemoveMoney', nil)
      rawset(player.Functions, 'SetMoney',    nil)
      setmetatable(player.Functions, {
        __index = function(_, k)
          if trapped_keys[k] then return private_wrappers[k] end
          return nil
        end,
        __newindex = function(t, k, v)
          if trapped_keys[k] then
            if Logger and Logger.Warn then
              Logger.Warn('[TRAP] overwrite attempt Functions.%s (type=%s value=%s) src=%s cid=%s log_only=%s\n%s',
                tostring(k), type(v), tostring(v),
                tostring(source), tostring(player.PlayerData.citizenid),
                tostring(trap_log_only),
                debug.traceback('stack:', 2))
            end
            if trap_log_only then
              -- allow the write through for debugging, so we observe natural drift
              private_wrappers[k] = v
            end
            return
          end
          rawset(t, k, v)
        end,
      })
      -- Since identity-compare against `wrappers` via raw table lookup won't
      -- work anymore (keys live in closure), watchdog must compare via
      -- `player.Functions[k]` which goes through __index. Keep wrappers
      -- pointing to the same functions so comparison is valid.
      if Logger and Logger.Info then
        Logger.Info('[TRAP] __index/__newindex installed on Functions for src=%s (wrappers moved to closure)', tostring(source))
      end
    else
      if Logger and Logger.Warn then
        Logger.Warn('[TRAP] Functions already has metatable — trap NOT installed (would clobber).')
      end
    end
  end
  state.players[source] = {
    framework      = 'qbcore',
    citizen_id     = player.PlayerData.citizenid,
    installed_at   = GetGameTimer(),
    originals      = originals,
    wrappers       = wrappers,
    functions_ref  = player.Functions,
    player_ref     = player,
  }
  if Logger and Logger.Info then
    Logger.Info('Core Override installed for QBCore player src=%d citizen=%s POST-WRAP types: Add=%s/%s Remove=%s/%s Set=%s/%s Functions_ref=%s',
      source, tostring(player.PlayerData.citizenid),
      type(wrappers.AddMoney), tostring(wrappers.AddMoney),
      type(wrappers.RemoveMoney), tostring(wrappers.RemoveMoney),
      type(wrappers.SetMoney), tostring(wrappers.SetMoney),
      tostring(player.Functions))
  end
  return true
end

local function install_qbox_player(source, player)
  source = tonumber(source)
  if not source then return false end
  if state.players[source] and state.players[source].framework == 'qbox' then return true end
  player = player or get_qbox_player_by_source(source)
  local citizen_id = nil
  if player and player.PlayerData then citizen_id = player.PlayerData.citizenid end
  -- QBox uses global registerHook; per-player install is bookkeeping for
  -- watchdog observability + reconcile correlation, not an interceptor patch.
  state.players[source] = {
    framework = 'qbox',
    citizen_id = citizen_id,
    installed_at = GetGameTimer(),
    via = 'registerHook',
  }
  return true
end

function CoreOverride.InstallForPlayer(source, ctx)
  local active = state.active_bank or (Bridges._active and Bridges._active.bank)
  if active == 'qbcore' then
    return install_qbcore_player(get_qbcore_player_by_source(source), ctx or 'install_for_player')
  end
  if active == 'qbox' then
    return install_qbox_player(source)
  end
  return false
end

function CoreOverride.InstallForAllOnlinePlayers()
  local installed = 0
  for _, src in ipairs(GetPlayers()) do
    if CoreOverride.InstallForPlayer(tonumber(src)) then installed = installed + 1 end
  end
  return installed
end

-- F2 — Login mirror sync. After Core Override install succeeds for a QBCore
-- player, if bank_mode is mirror|synced, pull canonical SONAR balance and
-- push it to QB (players.money.bank) so HUD / character-selector / qb-banking
-- / any 3rd-party resource reading PlayerData.money.bank reflects the SONAR
-- truth from the very first frame. Best-effort, never blocks login.
local function is_mirror_mode()
  local mode = GetConvar('sonar_bridge_bank_mode', 'standalone')
  return mode == 'mirror' or mode == 'synced'
end

local function login_mirror_sync(citizen_id, src)
  if not is_mirror_mode() then return end
  if type(citizen_id) ~= 'string' or citizen_id == '' then return end
  if GetResourceState('sonar_bank_app') ~= 'started' then return end
  local ok_exp, exports_proxy = pcall(function() return exports.sonar_bank_app end)
  if not ok_exp or not exports_proxy then return end
  local ok, balance_minor, err = pcall(function()
    return exports_proxy:GetPrimaryBalanceMinor(citizen_id)
  end)
  if not ok then
    if Logger and Logger.Warn then
      Logger.Warn('login_mirror_sync GetPrimaryBalanceMinor raised cid=%s err=%s',
        tostring(citizen_id), tostring(balance_minor))
    end
    return
  end
  if type(balance_minor) ~= 'number' then
    if Logger and Logger.Info then
      Logger.Info('login_mirror_sync skip cid=%s err=%s', tostring(citizen_id), tostring(err))
    end
    return
  end
  local result = MirrorSync.SetBalance(citizen_id, balance_minor, {
    reason         = 'login_sync',
    correlation_id = ('login|%s|%s'):format(tostring(src or '?'), tostring(GetGameTimer())),
  })
  if Logger and Logger.Info then
    local res_ok = type(result) == 'table' and result.ok == true
    Logger.Info('login_mirror_sync cid=%s src=%s sonar_minor=%d ok=%s err=%s',
      tostring(citizen_id), tostring(src or '?'), balance_minor,
      tostring(res_ok), tostring(type(result) == 'table' and result.error or 'nil'))
  end
end

local function install_qbcore()
  if state.qbcore_registered then return true end
  AddEventHandler('QBCore:Server:PlayerLoaded', function(player)
    local src = player and player.PlayerData and player.PlayerData.source or nil
    local cid = player and player.PlayerData and player.PlayerData.citizenid or nil
    if Logger and Logger.Info then
      Logger.Info('QBCore:Server:PlayerLoaded fired src=%s citizen=%s — installing override',
        tostring(src or '?'), tostring(cid or '?'))
    end
    local ok, reason = install_qbcore_player(player, 'player_loaded_event')
    if ok and cid then
      -- F2 login sync — only after successful install so the override
      -- interceptor lets the mirror reason through.
      login_mirror_sync(cid, src)
    end
    if not ok and Logger and Logger.Warn then
      Logger.Warn('install_qbcore_player returned false on PlayerLoaded reason=%s — scheduling retries (500/1500/3000ms)',
        tostring(reason))
    end
    if not ok and src then
      local function schedule_retry(delay, label)
        SetTimeout(delay, function()
          if state.players[tonumber(src)] and state.players[tonumber(src)].framework == 'qbcore' then return end
          local retry_ok, retry_reason = CoreOverride.InstallForPlayer(tonumber(src), label)
          if retry_ok then
            if Logger and Logger.Info then
              Logger.Info('QBCore Core Override %s installed src=%s', label, tostring(src))
            end
            if cid then login_mirror_sync(cid, src) end
          elseif Logger and Logger.Warn then
            Logger.Warn('QBCore Core Override %s failed src=%s reason=%s', label, tostring(src), tostring(retry_reason))
          end
        end)
      end
      schedule_retry(500, 'retry_500ms')
      schedule_retry(1500, 'retry_1500ms')
      schedule_retry(3000, 'retry_3000ms')
    end
  end)
  state.qbcore_registered = true
  local installed = CoreOverride.InstallForAllOnlinePlayers()
  if Logger and Logger.Info then
    Logger.Info('QBCore Core Override boot complete; sweep installed=%d online=%d',
      installed, #GetPlayers())
  end
  return true
end

local function install_qbox()
  if state.qbox_registered then return true end
  if GetResourceState('qbx_core') ~= 'started' then return false end
  local ok = pcall(function()
    exports.qbx_core:registerHook('addMoney', function(payload)
      payload = payload or {}
      local money_type = payload.moneyType or payload.money_type or payload.type or payload.account
      local reason = payload.reason
      if money_type ~= 'bank' then return true end
      if consume_mirror_token(reason) then return true end
      return handle_foreign_mutation({ framework = 'qbox', operation = 'add', payload = payload, reason = reason, forged_token = parse_mirror_token(reason) ~= nil or nil })
    end)
    exports.qbx_core:registerHook('removeMoney', function(payload)
      payload = payload or {}
      local money_type = payload.moneyType or payload.money_type or payload.type or payload.account
      local reason = payload.reason
      if money_type ~= 'bank' then return true end
      if consume_mirror_token(reason) then return true end
      return handle_foreign_mutation({ framework = 'qbox', operation = 'remove', payload = payload, reason = reason, forged_token = parse_mirror_token(reason) ~= nil or nil })
    end)
    exports.qbx_core:registerHook('setMoney', function(payload)
      payload = payload or {}
      local money_type = payload.moneyType or payload.money_type or payload.type or payload.account
      local reason = payload.reason
      if money_type ~= 'bank' then return true end
      if consume_mirror_token(reason) then return true end
      return handle_foreign_mutation({ framework = 'qbox', operation = 'set', payload = payload, reason = reason, forged_token = parse_mirror_token(reason) ~= nil or nil })
    end)
  end)
  state.qbox_registered = ok == true
  if state.qbox_registered then
    -- Hooks are global; sweep online players for bookkeeping parity with QBCore.
    CoreOverride.InstallForAllOnlinePlayers()
    AddEventHandler('qbx_core:server:playerLoaded', function(player)
      if type(player) == 'table' and player.PlayerData then
        install_qbox_player(player.PlayerData.source, player)
      end
    end)
  elseif Logger and Logger.Error then
    Logger.Error('QBox registerHook unavailable — bank money authority NOT installed. Foreign mutations will only be observed via reconcile drift checks.')
  end
  return state.qbox_registered
end

local function install_esx_lite()
  if state.esx_registered then return true end
  AddEventHandler('esx:setAccountMoney', function(player_id, account_name, money, reason)
    if account_name ~= 'bank' or is_mirror_reason(reason) then return end
    Reconcile.Enqueue({ framework = 'esx', operation = 'observed_set', source = player_id, observed_balance = money, reason = reason })
  end)
  state.esx_registered = true
  return true
end

function CoreOverride.Boot(active_bank)
  state.active_bank = active_bank or (Bridges._active and Bridges._active.bank) or 'native'
  if state.active_bank == 'qbcore' then return install_qbcore() end
  if state.active_bank == 'qbox' then return install_qbox() end
  if state.active_bank == 'esx' then return install_esx_lite() end
  return true
end

function CoreOverride.GetHealth()
  return {
    active_bank = state.active_bank,
    qbcore_registered = state.qbcore_registered,
    qbox_registered = state.qbox_registered,
    esx_registered = state.esx_registered,
    players = state.players,
    reconcile = Reconcile.GetQueueStats(),
  }
end

exports('MirrorSyncBalance', function(citizen_id, balance_minor, opts)
  opts = opts or {}
  local result = MirrorSync.SetBalance(citizen_id, balance_minor, opts)
  if type(result) == 'table' and result.ok == false then
    local framework = result.framework or state.active_bank or (Bridges._active and Bridges._active.bank) or 'native'
    if Logger and Logger.Warn then
      Logger.Warn(
        'Mirror sync failed citizen=%s framework=%s err=%s reason=%s — enqueuing reconcile (UX not blocked)',
        tostring(citizen_id), tostring(framework), tostring(result.error), tostring(opts.reason)
      )
    end
    Reconcile.Enqueue({
      framework = framework,
      operation = 'mirror_failed',
      citizen_id = citizen_id,
      target_balance_minor = balance_minor,
      reason = opts.reason or 'mirror_sync_failed',
      correlation_id = opts.correlation_id,
      idempotency_key = opts.idempotency_key,
      error = result.error,
    })
  end
  return result
end)

exports('ReconcileRun', function(opts)
  return Reconcile.Run(opts or {})
end)

exports('ReconcileEnqueue', function(item)
  return Reconcile.Enqueue(item or {})
end)

-- ---------------------------------------------------------------------------
-- OnMoneyPreHook
-- Synchronous veto export consumed by qb-core's patched player.lua AddMoney /
-- RemoveMoney / SetMoney. This is the canonical interception point because the
-- export executes inside qb-core's Lua state on the REAL QBCore.Players[src]
-- object (no cross-resource serialization). Wrapper-based interception in
-- sonar_bridges cannot work: FiveM serializes `player` when it crosses the
-- resource boundary and we end up wrapping a deep-copy snapshot.
--
-- Contract:
--   OnMoneyPreHook(op, source, citizen_id, money_type, amount, reason) -> bool
--     op         = 'add' | 'remove' | 'set'
--     returns true  => qb-core MUST cancel the mutation (return false)
--     returns false => qb-core MUST proceed normally
--
-- Policy (M2 security model):
--   - Only `bank` is intercepted (cash/black are framework-local).
--   - Invoker MUST be `qb-core` (the only resource carrying our patch).
--     Any other resource calling this export is rejected (pass-through to
--     avoid breaking unrelated paths, but logged as suspicious).
--   - Mirror passes ONLY if reason carries a valid, unconsumed Sonar token
--     (consume_mirror_token); the token is single-use and ~30s TTL.
--   - Foreign bank mutations are vetoed and enqueued for reconciliation.
-- ---------------------------------------------------------------------------
exports('OnMoneyPreHook', function(op, source, citizen_id, money_type, amount, reason)
  local invoker = GetInvokingResource()
  if invoker ~= 'qb-core' then
    if Logger and Logger.Warn then
      Logger.Warn('[PREHOOK] unexpected invoker resource=%s op=%s src=%s — ignored (pass-through)',
        tostring(invoker), tostring(op), tostring(source))
    end
    return false
  end
  if state.active_bank ~= 'qbcore' then return false end
  if type(money_type) ~= 'string' then return false end
  money_type = money_type:lower()
  if money_type ~= 'bank' then return false end
  if op ~= 'add' and op ~= 'remove' and op ~= 'set' then return false end
  -- Strict capability check: only pre-registered Sonar tokens pass.
  if consume_mirror_token(reason) then
    if Logger and Logger.Info then
      Logger.Info('[PREHOOK] op=%s src=%s cid=%s money_type=%s amount=%s reason=%s decision=PASS_MIRROR',
        tostring(op), tostring(source), tostring(citizen_id),
        tostring(money_type), tostring(amount), tostring(reason))
    end
    return false
  end
  -- Detect attempted forgery: reason has the mirror prefix but no valid token.
  local forged = parse_mirror_token(reason) ~= nil
  if Logger and Logger.Warn then
    Logger.Warn('[PREHOOK] op=%s src=%s cid=%s money_type=%s amount=%s reason=%s forged_token=%s decision=VETO',
      tostring(op), tostring(source), tostring(citizen_id),
      tostring(money_type), tostring(amount), tostring(reason), tostring(forged))
  end
  Reconcile.Enqueue({
    framework    = 'qbcore',
    operation    = op,
    source       = source,
    citizen_id   = citizen_id,
    amount       = amount,
    reason       = reason,
    forged_token = forged or nil,
  })
  return true
end)

exports('GetCoreOverrideHealth', function()
  return CoreOverride.GetHealth()
end)

-- ---------------------------------------------------------------------------
-- DEV-ONLY: forgery probe.
-- Gated by convar `sonar_dev_mode=1`. Registers `/sonar_test_forge` which
-- attempts to bypass the OnMoneyPreHook by calling AddMoney with a forged
-- mirror reason. Expected outcome with M2 enabled: VETO + forged_token=true
-- in logs, DB unchanged.
--
-- Usage from server console:
--   sonar_test_forge <src> [op] [amount] [token]
--     src    : player server id (required)
--     op     : add | remove | set            (default: add)
--     amount : integer                       (default: 1000000)
--     token  : raw token to embed            (default: 'fake_token')
--
-- Examples:
--   sonar_test_forge 1
--   sonar_test_forge 1 add 1000000 fake_token
--   sonar_test_forge 1 set 50000 abcdef0123456789
-- ---------------------------------------------------------------------------
if GetConvarInt('sonar_dev_mode', 0) == 1 then
  -- DEV: force a mirror sync of a citizen's bank balance from Sonar ledger to
  -- the active framework (e.g. qb-core's players.money.bank). Use after a
  -- manual SQL UPDATE on accounts.balance_minor to push the new value to qb.
  -- Usage: mirror_sync_now <citizen_id> <balance_minor>
  RegisterCommand('mirror_sync_now', function(_, args)
    local citizen_id    = args[1]
    local balance_minor = tonumber(args[2])
    if not citizen_id or not balance_minor then
      print('[mirror_sync_now] usage: mirror_sync_now <citizen_id> <balance_minor>')
      return
    end
    local res = MirrorSync.SetBalance(citizen_id, balance_minor, {
      reason         = 'dev_manual_sync',
      correlation_id = ('dev|%s|%s'):format(citizen_id, GetGameTimer()),
    })
    print(('[mirror_sync_now] cid=%s amount_minor=%s result=%s')
      :format(citizen_id, tostring(balance_minor), json.encode(res or {})))
  end, true)

  RegisterCommand('sonar_test_forge', function(_, args)
    local src    = tonumber(args[1])
    local op     = (args[2] or 'add'):lower()
    local amount = tonumber(args[3]) or 1000000
    local token  = args[4] or 'fake_token'
    if not src then
      print('[sonar_test_forge] usage: sonar_test_forge <src> [op] [amount] [token]')
      return
    end
    local reason = ('sonar_mirror_sync|%s'):format(token)
    local core = exports['qb-core']:GetCoreObject()
    local player = core and core.Functions and core.Functions.GetPlayer(src) or nil
    if not player or not player.Functions then
      print(('[sonar_test_forge] no player for src=%s'):format(tostring(src)))
      return
    end
    print(('[sonar_test_forge] firing op=%s src=%s amount=%s reason=%s')
      :format(op, tostring(src), tostring(amount), reason))
    local fn
    if op == 'add'    then fn = player.Functions.AddMoney
    elseif op == 'remove' then fn = player.Functions.RemoveMoney
    elseif op == 'set'    then fn = player.Functions.SetMoney
    end
    if not fn then
      print(('[sonar_test_forge] op not callable: %s'):format(op))
      return
    end
    local ok, result = pcall(fn, 'bank', amount, reason)
    print(('[sonar_test_forge] returned ok=%s result=%s (expected: result=false / VETO in logs)')
      :format(tostring(ok), tostring(result)))
  end, true) -- restricted=true: requires ace permission OR rcon (server console always allowed)
  if Logger and Logger.Info then
    Logger.Info('[DEV] sonar_test_forge command registered (sonar_dev_mode=1)')
  end
end

-- Diagnostic: verify whether AddMoney/RemoveMoney/SetMoney are still wrapped
-- for a given source, by comparing the current player.Functions.AddMoney
-- against the stored original.AddMoney captured at install time.
--   intact=true  → wrapper present (different Lua reference than original).
--   intact=false → wrapper LOST (someone overwrote our patch back to original
--                  OR another function — investigate further).
function CoreOverride.VerifyIntercept(source)
  source = tonumber(source)
  if not source then return { ok = false, error = 'INVALID_SOURCE' } end
  local entry = state.players[source]
  if not entry or entry.framework ~= 'qbcore' then
    return { ok = false, error = 'NO_QBCORE_ENTRY', source = source }
  end
  local player = get_qbcore_player_by_source(source)
  if not player or not player.Functions then
    return { ok = false, error = 'NO_PLAYER', source = source }
  end
  local originals = entry.originals or {}
  local wrappers  = entry.wrappers or {}
  local current = {
    AddMoney    = player.Functions.AddMoney,
    RemoveMoney = player.Functions.RemoveMoney,
    SetMoney    = player.Functions.SetMoney,
  }
  -- intact = the slot still holds the EXACT wrapper we installed (not just any
  -- non-original value). This is the strict invariant we want to defend.
  return {
    ok = true,
    source = source,
    citizen_id = entry.citizen_id,
    installed_at = entry.installed_at,
    intact = {
      AddMoney    = current.AddMoney    == wrappers.AddMoney    and wrappers.AddMoney    ~= nil,
      RemoveMoney = current.RemoveMoney == wrappers.RemoveMoney and wrappers.RemoveMoney ~= nil,
      SetMoney    = current.SetMoney    == wrappers.SetMoney    and wrappers.SetMoney    ~= nil,
    },
    addrs = {
      AddMoney_orig    = tostring(originals.AddMoney),
      AddMoney_wrap    = tostring(wrappers.AddMoney),
      AddMoney_now     = tostring(current.AddMoney),
      RemoveMoney_orig = tostring(originals.RemoveMoney),
      RemoveMoney_wrap = tostring(wrappers.RemoveMoney),
      RemoveMoney_now  = tostring(current.RemoveMoney),
      SetMoney_orig    = tostring(originals.SetMoney),
      SetMoney_wrap    = tostring(wrappers.SetMoney),
      SetMoney_now     = tostring(current.SetMoney),
    },
  }
end

exports('VerifyIntercept', function(source)
  return CoreOverride.VerifyIntercept(source)
end)

-- Console command (server console only, source=0) to dump verify report.
RegisterCommand('sonar_co_verify_intercept', function(source, args)
  if source ~= 0 then return end
  local src = tonumber(args[1]) or 1
  local report = CoreOverride.VerifyIntercept(src)
  if Logger and Logger.Info then
    Logger.Info('VerifyIntercept src=%s ok=%s err=%s citizen=%s intact.Add=%s intact.Remove=%s intact.Set=%s',
      tostring(src), tostring(report.ok), tostring(report.error),
      tostring(report.citizen_id),
      tostring(report.intact and report.intact.AddMoney),
      tostring(report.intact and report.intact.RemoveMoney),
      tostring(report.intact and report.intact.SetMoney))
    if report.addrs then
      Logger.Info('  addrs: Add orig=%s wrap=%s now=%s',
        report.addrs.AddMoney_orig, report.addrs.AddMoney_wrap, report.addrs.AddMoney_now)
      Logger.Info('         Rem orig=%s wrap=%s now=%s',
        report.addrs.RemoveMoney_orig, report.addrs.RemoveMoney_wrap, report.addrs.RemoveMoney_now)
      Logger.Info('         Set orig=%s wrap=%s now=%s',
        report.addrs.SetMoney_orig, report.addrs.SetMoney_wrap, report.addrs.SetMoney_now)
    end
  end
end, true)

-- ---------------------------------------------------------------------------
-- Wrapper drift watchdog.
-- Some frameworks (e.g. qbox compatibility shims, qb-multicharacter character
-- re-selection, late-loading inventory bridges) may re-assign
-- player.Functions.AddMoney AFTER our install, silently replacing our wrapper
-- with a different callable. This loop verifies every N seconds and re-patches
-- any drifted slots. Disabled by setting convar `sonar_co_watchdog_interval=0`.
-- Default interval: 5000ms.
-- ---------------------------------------------------------------------------
-- Watchdog disabled by default: cross-resource serialization makes the wrapper
-- approach inherently broken (we wrap snapshots, not the real player). The
-- canonical interception is now via `OnMoneyPreHook` invoked from qb-core's
-- patched player.lua. Set convar `sonar_co_watchdog_interval_ms` to a positive
-- value only for diagnostic spelunking.
CreateThread(function()
  while true do
    local interval = GetConvarInt('sonar_co_watchdog_interval_ms', 0)
    if interval <= 0 then
      Wait(10000)
    else
      Wait(interval)
      if state.active_bank == 'qbcore' then
        for src, entry in pairs(state.players) do
          if entry.framework == 'qbcore' and entry.wrappers then
            local player = get_qbcore_player_by_source(src)
            if player and player.Functions then
              local functions_replaced = (entry.functions_ref ~= nil and player.Functions ~= entry.functions_ref)
              local player_replaced = (entry.player_ref ~= nil and player ~= entry.player_ref)
              local drifted = functions_replaced
                           or (player.Functions.AddMoney ~= entry.wrappers.AddMoney)
                           or (player.Functions.RemoveMoney ~= entry.wrappers.RemoveMoney)
                           or (entry.wrappers.SetMoney and player.Functions.SetMoney ~= entry.wrappers.SetMoney)
              if drifted then
                if Logger and Logger.Warn then
                  Logger.Warn('[WATCHDOG] drift src=%s citizen=%s player_replaced=%s functions_replaced=%s now Add=%s expected=%s Functions_ref old=%s new=%s',
                    tostring(src), tostring(entry.citizen_id),
                    tostring(player_replaced), tostring(functions_replaced),
                    tostring(player.Functions.AddMoney),
                    tostring(entry.wrappers.AddMoney),
                    tostring(entry.functions_ref), tostring(player.Functions))
                end
                -- Reset bookkeeping so install_qbcore_player will re-run.
                state.players[src] = nil
                local ok, err = install_qbcore_player(player, 'watchdog_redrift')
                if not ok and Logger and Logger.Warn then
                  Logger.Warn('[WATCHDOG] re-install failed src=%s err=%s', tostring(src), tostring(err))
                end
              end
            end
          end
        end
      end
    end
  end
end)
