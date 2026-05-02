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
