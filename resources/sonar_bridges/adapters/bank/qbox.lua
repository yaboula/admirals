-- =============================================================================
-- SONAR Bridges — adapters/bank/qbox.lua
--
-- Adapter QBox T1 para Bank.
--
-- Usa exports.qbx_core per doc §4.4.1. Tier 1 oficial.
--
-- QBox API usada:
--   exports.qbx_core:GetPlayerByCitizenId(citizenId) → Player | nil
--   Player.PlayerData.money[account_type]             → number balance
--   Player.Functions.AddMoney(account, amount, reason) → boolean
--   Player.Functions.RemoveMoney(account, amount, reason) → boolean
--
-- Idempotencia:
--   Wrapper _with_idem idéntico al native — callers no distinguen adapter activo.
--   Caller (sonar_core S0.4+) genera idempotency_key único por operación.
--
-- Referencias SSoT:
--   docs/technical/07_bridges_compatibility.md §4.2 interface, §4.4.1 adapter.
-- =============================================================================

local Logger = Bridges.Logger
local QboxBank = {}

-- Idempotency wrapper — mismo patrón que native.lua para comportamiento homogéneo
-- al switchear entre adapters (B3 / B6 principios bridges).
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
-- -----------------------------------------------------------------------------
---@param identifier string citizenId
---@param account_type string|nil 'cash'|'bank' — default 'bank'
---@return number|nil balance
---@return string|nil error 'NOT_FOUND'|'BRIDGE_UNAVAILABLE'
function QboxBank.GetBalance(identifier, account_type)
  if type(identifier) ~= 'string' or identifier == '' then
    return nil, 'NOT_FOUND'
  end
  local Player = exports.qbx_core:GetPlayerByCitizenId(identifier)
  if not Player then return nil, 'NOT_FOUND' end
  local acct = account_type or 'bank'
  local balance = Player.PlayerData.money[acct]
  if balance == nil then return nil, 'NOT_FOUND' end
  return balance, nil
end

-- -----------------------------------------------------------------------------
-- AddMoney
-- -----------------------------------------------------------------------------
---@param identifier string citizenId
---@param amount number positivo
---@param reason string human-readable
---@param idempotency_key string unique por operación lógica
---@return boolean success
---@return string|nil error
---@return table|nil meta
function QboxBank.AddMoney(identifier, amount, reason, idempotency_key)
  return _with_idem(idempotency_key, function()
    if type(identifier) ~= 'string' or identifier == '' then
      return false, 'NOT_FOUND'
    end
    if type(amount) ~= 'number' or amount < 0 then
      return false, 'VALIDATION_FAILED'
    end
    local Player = exports.qbx_core:GetPlayerByCitizenId(identifier)
    if not Player then return false, 'NOT_FOUND' end
    local ok = Player.Functions.AddMoney('bank', amount, reason or 'sonar')
    return ok, ok and nil or 'FAILED'
  end)
end

-- -----------------------------------------------------------------------------
-- RemoveMoney
-- -----------------------------------------------------------------------------
---@param identifier string citizenId
---@param amount number positivo
---@param reason string
---@param idempotency_key string
---@return boolean success
---@return string|nil error 'INSUFFICIENT_FUNDS'|'NOT_FOUND'|'FAILED'
function QboxBank.RemoveMoney(identifier, amount, reason, idempotency_key)
  return _with_idem(idempotency_key, function()
    if type(identifier) ~= 'string' or identifier == '' then
      return false, 'NOT_FOUND'
    end
    if type(amount) ~= 'number' or amount < 0 then
      return false, 'VALIDATION_FAILED'
    end
    local Player = exports.qbx_core:GetPlayerByCitizenId(identifier)
    if not Player then return false, 'NOT_FOUND' end
    local balance = Player.PlayerData.money['bank'] or 0
    if balance < amount then return false, 'INSUFFICIENT_FUNDS' end
    local ok = Player.Functions.RemoveMoney('bank', amount, reason or 'sonar')
    return ok, ok and nil or 'FAILED'
  end)
end

-- -----------------------------------------------------------------------------
-- Transfer — atómico: RemoveMoney from → AddMoney to.
-- Rollback automático si AddMoney falla (re-add al origen).
-- -----------------------------------------------------------------------------
---@param from string citizenId origen
---@param to string citizenId destino
---@param amount number
---@param reason string
---@param idempotency_key string
---@return boolean success
---@return string|nil error
function QboxBank.Transfer(from, to, amount, reason, idempotency_key)
  return _with_idem(idempotency_key, function()
    if type(from) ~= 'string' or type(to) ~= 'string' then
      return false, 'NOT_FOUND'
    end
    if type(amount) ~= 'number' or amount < 0 then
      return false, 'VALIDATION_FAILED'
    end
    local QBX        = exports.qbx_core
    local PlayerFrom = QBX:GetPlayerByCitizenId(from)
    local PlayerTo   = QBX:GetPlayerByCitizenId(to)
    if not PlayerFrom then return false, 'NOT_FOUND' end
    if not PlayerTo   then return false, 'NOT_FOUND' end
    local balance = PlayerFrom.PlayerData.money['bank'] or 0
    if balance < amount then return false, 'INSUFFICIENT_FUNDS' end
    local ok_remove = PlayerFrom.Functions.RemoveMoney('bank', amount, reason or 'sonar_transfer')
    if not ok_remove then return false, 'FAILED' end
    local ok_add = PlayerTo.Functions.AddMoney('bank', amount, reason or 'sonar_transfer')
    if not ok_add then
      PlayerFrom.Functions.AddMoney('bank', amount, 'sonar_transfer_rollback')
      Logger.Warn('QboxBank.Transfer: AddMoney to=%s failed — rolled back from=%s', to, from)
      return false, 'FAILED'
    end
    return true, nil
  end)
end

-- -----------------------------------------------------------------------------
-- IsAvailable — qbx_core debe estar iniciado.
-- -----------------------------------------------------------------------------
function QboxBank.IsAvailable()
  return GetResourceState('qbx_core') == 'started'
end

Bridges.RegisterAdapter('bank', 'qbox', QboxBank)
