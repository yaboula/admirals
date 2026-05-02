-- =============================================================================
-- Admirals Bank — server/init.lua
--
-- Boot orchestration. LAST script en server_scripts del fxmanifest.
--
-- Secuencia boot:
--   1. Wait Admirals.Core.WaitReady (Config.CoreWaitTimeoutMs).
--      — hard-fail si timeout (admirals_core no arrancó / DB no lista /
--        migrations no aplicadas).
--   2. Verify migration 003 aplicada (admirals_bank_accounts table existe).
--      — hard-fail si no (sanity check pre-conditions).
--   3. Register Identity hooks:
--      - OnPlayerLoaded → cache _src_to_cid + EnsureStarterAccount(citizen_id, source).
--      - OnPlayerDropped → purge cache + log.
--   4. Mark Bank._ready + emit admirals:bank:ready.
--   5. Print boot panel ASCII.
--
-- Admin commands:
--   /admirals_bank_status — muestra ready state + version + counts.
--
-- Exports cross-resource:
--   IsReady()  → boolean
--   Version()  → string
--
-- API local en VM admirals_bank (consumido por callbacks.lua):
--   Bank.GetCitizenIdBySource(source) → citizen_id | nil
--
-- Referencias SSoT:
--   docs/technical/04_api_contracts.md §3.1 (callbacks scope S1.1).
--   docs/technical/04_api_contracts.md §10.3 (audit obligatorio).
-- =============================================================================

Admirals = Admirals or {}
Admirals.Bank = Admirals.Bank or {}

local Config = Admirals.Bank.Config
local IBAN = Admirals.Bank.IBAN
local Accounts = Admirals.Bank.Accounts
local Bank = Admirals.Bank

Bank._ready = false

-- =============================================================================
-- Cache source ↔ citizen_id — populated en Identity.OnPlayerLoaded hook.
-- Usado por callbacks.lua (resolve source→citizen_id sin export bridges).
-- =============================================================================
local _src_to_cid = {}

--- Bank.GetCitizenIdBySource — resuelve source a citizen_id desde cache.
---@param source number FiveM player source.
---@return string|nil citizen_id.
function Bank.GetCitizenIdBySource(source)
  return _src_to_cid[tonumber(source) or -1]
end

-- =============================================================================
-- Public API.
-- =============================================================================
function Bank.IsReady()
  return Bank._ready == true
end

function Bank.Version()
  return Config.Version
end

exports('IsReady', Bank.IsReady)
exports('Version', Bank.Version)

-- =============================================================================
-- Boot report — ASCII panel coherente con admirals_core.
-- =============================================================================
local _boot_started_at = 0
local _boot_completed_at = 0

local function _print_boot_report()
  local divider = '^5═══════════════════════════════════════════════════════════^7'
  local thin    = '^5───────────────────────────────────────────────────────────^7'
  local boot_ms = _boot_completed_at - _boot_started_at

  -- Cuenta accounts existentes (informativo).
  local accounts_count_ok, accounts_count = pcall(function()
    return Admirals.DB.Scalar('SELECT COUNT(*) FROM admirals_bank_accounts', {})
  end)
  if not accounts_count_ok then accounts_count = '?' end

  print('')
  print(divider)
  print(string.format('^5  Admirals Bank v%s — Boot Report^7', Config.Version))
  print(divider)
  print(string.format('  Starter    : %s € (currency=EUR)', Config.StarterBalanceEur))
  print(string.format('  IBAN       : %s + 11 random + 1 checksum (charset=%d)',
    Config.IbanPrefix, #Config.IbanCharset))
  print(string.format('  Audit reads: %s', Config.AuditReads and 'on' or 'off'))
  print(string.format('  Core ver   : %s', Admirals.Core.Version() or '?'))
  print(string.format('  Boot time  : %dms', boot_ms))
  print(thin)
  print(string.format('  bank_accounts rows: %s', tostring(accounts_count)))
  print(divider)
  print('^2  admirals_bank is READY^7')
  print(divider)
  print('')
end

-- =============================================================================
-- Admin command — /admirals_bank_status.
-- =============================================================================
local function _is_admin(source)
  if source == 0 then return true end
  return IsPlayerAceAllowed(source, 'command.admirals_bank_status')
end

RegisterCommand('admirals_bank_status', function(source)
  if not _is_admin(source) then return end
  print(string.format('^5[Admirals Bank] v%s | ready=%s | tracked_sources=%d^7',
    Config.Version, tostring(Bank._ready),
    (function()
      local n = 0
      for _ in pairs(_src_to_cid) do n = n + 1 end
      return n
    end)()))
end, true)

-- =============================================================================
-- Migration sanity check — verifica que admirals_bank_accounts existe.
-- =============================================================================
local function _verify_schema_migrated()
  local exists = Admirals.DB.Scalar([[
    SELECT COUNT(*) FROM information_schema.tables
    WHERE table_schema = DATABASE() AND table_name = 'admirals_bank_accounts'
  ]], {})
  if (tonumber(exists) or 0) == 0 then
    error('[admirals_bank] admirals_bank_accounts table NOT FOUND — migration 003 missing or failed', 0)
  end

  local exists_mov = Admirals.DB.Scalar([[
    SELECT COUNT(*) FROM information_schema.tables
    WHERE table_schema = DATABASE() AND table_name = 'admirals_bank_movements'
  ]], {})
  if (tonumber(exists_mov) or 0) == 0 then
    error('[admirals_bank] admirals_bank_movements table NOT FOUND — migration 003 missing or failed', 0)
  end
end

-- =============================================================================
-- Identity hooks — register tras core ready.
-- =============================================================================
local function _register_identity_hooks()
  Admirals.Identity.OnPlayerLoaded(function(citizen_id, source)
    if type(citizen_id) ~= 'string' or citizen_id == '' then return end
    local src_num = tonumber(source) or -1
    _src_to_cid[src_num] = citizen_id

    Admirals.Log.Debug('Identity loaded: source=%d citizen_id=%s', src_num, citizen_id)
    Admirals.Metrics.Counter('bank.identity.loaded')

    -- Trigger EnsureStarterAccount async (no bloquear el evento — algunos
    -- adapters esperan return rápido).
    Citizen.CreateThread(function()
      local ok, result = Accounts.EnsureStarterAccount(citizen_id, src_num)
      if not ok then
        Admirals.Log.Error('EnsureStarterAccount failed for %s: %s', citizen_id, tostring(result))
      else
        if result.created then
          Admirals.Log.Info('Starter account created for %s: %s (balance=%s €)',
            citizen_id, result.iban, result.balance)
        else
          Admirals.Log.Debug('Starter account already exists for %s: %s', citizen_id, result.iban)
        end
      end
    end)
  end)

  Admirals.Identity.OnPlayerDropped(function(citizen_id, source, reason)
    local src_num = tonumber(source) or -1
    _src_to_cid[src_num] = nil
    Admirals.Log.Debug('Identity dropped: source=%d citizen_id=%s reason=%s',
      src_num, tostring(citizen_id), tostring(reason))
    Admirals.Metrics.Counter('bank.identity.dropped')
  end)

  Admirals.Log.Info('Identity hooks registered (OnPlayerLoaded + OnPlayerDropped)')
end

-- =============================================================================
-- Boot sequence.
-- =============================================================================
CreateThread(function()
  Wait(0)  -- yield para que todos los server_scripts hayan cargado.
  _boot_started_at = GetGameTimer()

  Admirals.Log.Info('admirals_bank v%s booting...', Config.Version)

  -- ---------------------------------------------------------------------------
  -- 1. Wait admirals_core ready.
  -- ---------------------------------------------------------------------------
  Admirals.Log.Debug('Waiting admirals_core...')
  local core_ready = Admirals.Core.WaitReady(Config.CoreWaitTimeoutMs)
  if not core_ready then
    Admirals.Log.Error('admirals_core not ready after %dms — aborting boot',
      Config.CoreWaitTimeoutMs)
    error('[admirals_bank] admirals_core not ready', 0)
  end
  Admirals.Log.Info('admirals_core ready (v%s)', Admirals.Core.Version() or '?')

  -- ---------------------------------------------------------------------------
  -- 2. Verify migration 003 aplicada (sanity).
  -- ---------------------------------------------------------------------------
  local schema_ok, schema_err = pcall(_verify_schema_migrated)
  if not schema_ok then
    Admirals.Log.Error('Schema sanity check failed: %s', tostring(schema_err))
    error(tostring(schema_err), 0)
  end
  Admirals.Log.Info('Schema verified: admirals_bank_accounts + admirals_bank_movements OK')

  -- ---------------------------------------------------------------------------
  -- 3. Register Identity hooks.
  -- ---------------------------------------------------------------------------
  _register_identity_hooks()

  -- ---------------------------------------------------------------------------
  -- 4. Mark ready + emit event.
  -- ---------------------------------------------------------------------------
  Bank._ready = true
  _boot_completed_at = GetGameTimer()

  Admirals.Metrics.Counter('bank.boot_success')
  Admirals.Metrics.Gauge('bank.boot_duration_ms', _boot_completed_at - _boot_started_at)

  Admirals.Bus.Publish(Config.BankReadyEventName, {
    version = Config.Version,
    boot_duration_ms = _boot_completed_at - _boot_started_at,
  })

  -- TriggerEvent FiveM nativo para listeners cross-resource antiguos.
  TriggerEvent(Config.BankReadyEventName, {
    version = Config.Version,
    boot_duration_ms = _boot_completed_at - _boot_started_at,
  })

  -- ---------------------------------------------------------------------------
  -- 5. Boot report.
  -- ---------------------------------------------------------------------------
  _print_boot_report()
end)

-- =============================================================================
-- S1.2 SMOKE TEST TEMPORAL — DELETE POST SIGN-OFF (cleanup commit separado).
-- ACE-gated. Disposable infrastructure per workspace convention S1.x.
--
-- Founder otorga ACEs en server.cfg (líneas removibles post-smoke):
--   add_ace builtin.everyone command.admirals_bank_stress_transfer allow
--   add_ace builtin.everyone command.admirals_bank_recalc          allow
--   add_ace builtin.everyone command.admirals_bridge_idem_count    allow
--
-- Sigue patrón _is_admin S1.1: source==0 (console) → true; else
-- IsPlayerAceAllowed(source, 'command.<name>'). Per-command ACE.
-- =============================================================================

local function _smoke_ace(source, command_name)
  if source == 0 then return true end
  return IsPlayerAceAllowed(source, 'command.' .. command_name)
end

-- ----------------------------------------------------------------------------
-- /admirals_bank_recalc <iban>
-- Reconciliación: SUM(amount) over movements vs admirals_bank_accounts.balance.
-- Smoke test step 8 verify (delta == 0 exacto post-migration 005 CHECK).
-- ----------------------------------------------------------------------------
RegisterCommand('admirals_bank_recalc', function(source, args)
  if not _smoke_ace(source, 'admirals_bank_recalc') then return end
  local iban = args[1]
  if not iban then print('Usage: admirals_bank_recalc <IBAN>') return end

  local acc = Accounts.GetByIban(iban)
  if not acc then print('IBAN not found: ' .. iban) return end

  local result = Admirals.Bank.Movements.RecalcBalance(acc.id)
  if not result then print('RecalcBalance returned nil for ' .. iban) return end

  local declared = result.balance
  local sum_mov  = result.sum_movements
  local delta    = result.delta
  local abs_delta = math.abs(delta)
  print(string.format(
    '[recalc] %s | declared=%.2f | sum_movements=%.2f | delta=%.4f',
    iban, declared, sum_mov, delta
  ))
  if abs_delta == 0.0 then
    print('^2[recalc] LEDGER OK — delta=0 exacto (S1.2 fix-and-validate)^7')
  else
    print(string.format(
      '^1[recalc] LEDGER INCONSISTENCY — delta=%.4f (escalate — CHECK constraint should prevent this)^7',
      delta
    ))
  end
end, true)

-- ----------------------------------------------------------------------------
-- /admirals_bridge_idem_count
-- Visibilidad backend idempotency activo + entries count (DB mode).
-- ----------------------------------------------------------------------------
RegisterCommand('admirals_bridge_idem_count', function(source)
  if not _smoke_ace(source, 'admirals_bridge_idem_count') then return end

  local backend_name_ok, backend_name = pcall(function()
    return exports.admirals_bridges:IdemBackendName()
  end)
  local name = backend_name_ok and tostring(backend_name) or 'unknown'

  if name:sub(1, 2) == 'db' then
    local cnt = Admirals.DB.Scalar(
      'SELECT COUNT(*) FROM admirals_bridge_idempotency WHERE expires_at > UNIX_TIMESTAMP()', {}
    ) or 'N/A'
    print(string.format('[idem] backend=%s | active_entries=%s', name, tostring(cnt)))
  else
    print(string.format('[idem] backend=%s | (memory mode — entries N/A cross-VM)', name))
  end
end, true)

-- ----------------------------------------------------------------------------
-- /admirals_bank_stress_transfer <from_iban> <to_iban> <count> <from_citizen_id>
-- Stress test paso 8: N concurrent Transfer.Execute con request_ids únicos.
-- Tras stress, ejecutar /admirals_bank_recalc <from_iban> y <to_iban> para
-- verificar delta=0 exacto (atomicity garantizada via CHECK constraint S005).
-- ----------------------------------------------------------------------------
RegisterCommand('admirals_bank_stress_transfer', function(source, args)
  if not _smoke_ace(source, 'admirals_bank_stress_transfer') then return end

  local from_iban = args[1]
  local to_iban   = args[2]
  local count     = tonumber(args[3]) or 10
  local from_cid  = args[4]

  if not from_iban or not to_iban or not from_cid then
    print('Usage: admirals_bank_stress_transfer <from_iban> <to_iban> <count> <from_citizen_id>')
    return
  end

  local ok_count, err_count = 0, 0
  local err_breakdown = {}
  local start_ms = GetGameTimer()
  local stress_run_id = os.time()  -- distintivo por run para evitar idem replay cross-runs
  for i = 1, count do
    local tid = string.format('smoke-stress-%d-%04d', stress_run_id, i)
    local s, _, ec = Admirals.Bank.Transfer.Execute(
      from_cid, from_iban, to_iban, 1.00, 'Stress ' .. i, tid
    )
    if s then
      ok_count = ok_count + 1
    else
      err_count = err_count + 1
      err_breakdown[ec or 'NIL'] = (err_breakdown[ec or 'NIL'] or 0) + 1
    end
  end
  local elapsed_ms = GetGameTimer() - start_ms

  print(string.format('[stress] count=%d ok=%d errors=%d elapsed=%dms',
    count, ok_count, err_count, elapsed_ms))
  if err_count > 0 then
    for ec, n in pairs(err_breakdown) do
      print(string.format('  err[%s] = %d', ec, n))
    end
  end
  print('[stress] Tras esto ejecuta:')
  print(string.format('  admirals_bank_recalc %s', from_iban))
  print(string.format('  admirals_bank_recalc %s', to_iban))
  print('[stress] Esperado: delta=0 EXACTO en ambas (CHECK constraint S005 enforce).')
end, true)
