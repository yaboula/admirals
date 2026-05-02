-- =============================================================================
-- Admirals Bridges — adapters/bank/native.lua
--
-- Adapter NATIVE (fallback) para Bank.
--
-- Comportamiento:
--   Modo A (standalone, default): NO-OP. El ledger Admirals (admirals_core
--     S0.4+) es SSoT única; bridge externo no toca nada.
--   Modo B (synced): sin script externo no hay nada que sync, comportamiento
--     degrada a no-op + log warning.
--
-- Idempotencia honorada — sigue pattern canónico via Bridges._IsIdemReplay /
-- Bridges._StoreIdem para que callers no se rompan al switchear a adapter
-- externo después.
--
-- Referencias SSoT:
--   docs/technical/07_bridges_compatibility.md §4.1 modos, §11.2 native Bank.
-- =============================================================================

local Logger = Bridges.Logger
local NativeBank = {}

-- Wrapper idempotency boilerplate shared across methods.
local function _with_idem(idem_key, actual_fn)
  if idem_key then
    local replay, cached = Bridges._IsIdemReplay(idem_key)
    if replay then return table.unpack(cached or { true, nil, { replay = true } }) end
  end
  local results = table.pack(actual_fn())
  if idem_key then Bridges._StoreIdem(idem_key, results) end
  return table.unpack(results, 1, results.n)
end

-- -----------------------------------------------------------------------------
-- GetBalance
-- Modo A: no external account → devuelve 0 (ledger vive en admirals_core).
-- Modo B: sin script externo → 0 + warn.
-- -----------------------------------------------------------------------------
function NativeBank.GetBalance(identifier, account_type)
  if type(identifier) ~= 'string' or identifier == '' then
    return nil, 'NOT_FOUND'
  end
  if Config.BankMode == 'synced' then
    Logger.Warn('NativeBank.GetBalance: synced mode with no external adapter — returning 0')
  end
  return 0, nil
end

-- -----------------------------------------------------------------------------
-- AddMoney — no-op (Modo A) / no-op + warn (Modo B).
-- -----------------------------------------------------------------------------
function NativeBank.AddMoney(identifier, amount, reason, idempotency_key)
  return _with_idem(idempotency_key, function()
    if type(identifier) ~= 'string' or identifier == '' then
      return false, 'NOT_FOUND'
    end
    if type(amount) ~= 'number' or amount < 0 then
      return false, 'VALIDATION_FAILED'
    end
    Logger.Debug('NativeBank.AddMoney %s +%d (%s) [no-op mode=%s]',
      identifier, amount, tostring(reason), Config.BankMode)
    return true, nil, { mode = Config.BankMode, noop = true }
  end)
end

-- -----------------------------------------------------------------------------
-- RemoveMoney — no-op (Modo A).
-- No simula INSUFFICIENT_FUNDS: en Modo A el caller (admirals_core) valida
-- contra su ledger ANTES de invocar bridges.
-- -----------------------------------------------------------------------------
function NativeBank.RemoveMoney(identifier, amount, reason, idempotency_key)
  return _with_idem(idempotency_key, function()
    if type(identifier) ~= 'string' or identifier == '' then
      return false, 'NOT_FOUND'
    end
    if type(amount) ~= 'number' or amount < 0 then
      return false, 'VALIDATION_FAILED'
    end
    Logger.Debug('NativeBank.RemoveMoney %s -%d (%s) [no-op mode=%s]',
      identifier, amount, tostring(reason), Config.BankMode)
    return true, nil, { mode = Config.BankMode, noop = true }
  end)
end

-- -----------------------------------------------------------------------------
-- Transfer — atómico trivialmente (no-op en Modo A).
-- -----------------------------------------------------------------------------
function NativeBank.Transfer(from, to, amount, reason, idempotency_key)
  return _with_idem(idempotency_key, function()
    if type(from) ~= 'string' or type(to) ~= 'string' then
      return false, 'NOT_FOUND'
    end
    if type(amount) ~= 'number' or amount < 0 then
      return false, 'VALIDATION_FAILED'
    end
    Logger.Debug('NativeBank.Transfer %s→%s %d (%s) [no-op]',
      from, to, amount, tostring(reason))
    return true, nil, { mode = Config.BankMode, noop = true }
  end)
end

-- -----------------------------------------------------------------------------
-- IsAvailable — native siempre disponible (sin external dependency).
-- Nota: esto es el contrato adapter-side. Bridge-level IsAvailable() devuelve
-- false para native (per bridges/bank.lua línea ~90).
-- -----------------------------------------------------------------------------
function NativeBank.IsAvailable()
  return true
end

Bridges.RegisterAdapter('bank', 'native', NativeBank)
