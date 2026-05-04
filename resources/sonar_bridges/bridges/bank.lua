-- =============================================================================
-- SONAR Bridges — bridges/bank.lua
--
-- Bridges.Bank — interfaz pública para operaciones de dinero a través del
-- banco del framework externo (Modo B) o no-op (Modo A).
--
-- Responsabilidad (per doc §4.1):
--   SONAR tiene su propio ledger (`sonar_bank_accounts` — S0.4+). Este
--   bridge es EL ÚNICO canal permitido para tocar el dinero del framework
--   externo (qbx_core money, qb-banking, Renewed-Banking, etc.).
--
-- Modos:
--   standalone (Config.BankMode='standalone') — adapter native no-op, ledger
--     SONAR es SSoT única.
--   synced (Config.BankMode='synced') — adapters externos sincronizan.
--
-- Firmas literales de doc §4.2.
-- =============================================================================

Bridges = Bridges or {}
Bridges.Bank = {}

-- -----------------------------------------------------------------------------
-- _required_methods — adapters DEBEN implementar TODOS estos métodos.
-- Validado por Bridges.RegisterAdapter() en boot-time.
--
-- Nota: `IsAvailable` aquí es el contrato ADAPTER-side ("is my resource
-- started?"). El Bridges.Bank.IsAvailable() público (línea ~160) es distinto:
-- indica "is any non-native adapter active" (per doc §4.2 línea 298).
-- -----------------------------------------------------------------------------
Bridges.Bank._required_methods = {
  'GetBalance', 'AddMoney', 'RemoveMoney', 'Transfer', 'IsAvailable',
}

-- =============================================================================
-- Public API (per doc §4.2)
-- =============================================================================

--- Bridges.Bank.GetBalance
---@param identifier string citizenId (player) o IBAN (empresa/escrow).
---@param account_type string|nil 'cash'|'bank' (solo Modo B).
---@return number|nil balance
---@return string|nil error 'NOT_FOUND'|'TIMEOUT'|'BRIDGE_UNAVAILABLE'
function Bridges.Bank.GetBalance(identifier, account_type)
  return Bridges.Dispatcher.Call('bank', 'GetBalance', { identifier, account_type, n = 2 })
end

--- Bridges.Bank.AddMoney
---@param identifier string
---@param amount number positivo.
---@param reason string human-readable ("salary_payment", "contract_fulfilled").
---@param idempotency_key string unique per logical op.
---@return boolean success
---@return string|nil error
---@return table|nil metadata
function Bridges.Bank.AddMoney(identifier, amount, reason, idempotency_key)
  return Bridges.Dispatcher.Call('bank', 'AddMoney',
    { identifier, amount, reason, idempotency_key, n = 4 })
end

--- Bridges.Bank.RemoveMoney
---@param identifier string
---@param amount number positivo.
---@param reason string
---@param idempotency_key string
---@return boolean success
---@return string|nil error 'INSUFFICIENT_FUNDS'|'NOT_FOUND'|'FAILED'
---@return table|nil metadata
function Bridges.Bank.RemoveMoney(identifier, amount, reason, idempotency_key)
  return Bridges.Dispatcher.Call('bank', 'RemoveMoney',
    { identifier, amount, reason, idempotency_key, n = 4 })
end

--- Bridges.Bank.Transfer — atomic transfer (adapter garantiza atomicidad).
---@param from string
---@param to string
---@param amount number
---@param reason string
---@param idempotency_key string
---@return boolean success
---@return string|nil error
function Bridges.Bank.Transfer(from, to, amount, reason, idempotency_key)
  return Bridges.Dispatcher.Call('bank', 'Transfer',
    { from, to, amount, reason, idempotency_key, n = 5 })
end

--- Bridges.Bank.IsAvailable — true si un adapter EXTERNO (no native) está activo.
---@return boolean
function Bridges.Bank.IsAvailable()
  local active = Bridges._active and Bridges._active.bank
  return active ~= nil and active ~= 'native'
end

--- Bridges.Bank.GetMode — devuelve modo operacional ('standalone'|'synced').
---@return string
function Bridges.Bank.GetMode()
  return Config.BankMode or 'standalone'
end
