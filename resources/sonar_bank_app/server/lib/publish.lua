-- =============================================================================
-- SONAR Bank App — lib/publish.lua
-- =============================================================================
-- M004 — `publish_balance_update()` canonical helper (CP1-B).
--
-- Background:
--   - CP1-A (deprecated, R1): GlobalState `bank.balance.<citizen_id>` shared.
--   - CP1-B (canonical, R1):  Per-player StateBag `Player(src).state.bank_balance`
--     (auto-filtered to that player only — financial PII privacy boundary).
--
-- Anti-pattern AP-CP1-1 prohibido: ningún módulo escribe directamente a Player
-- StateBag para financial data — TODOS deben pasar por PublishBalanceUpdate().
--
-- Functions:
--   PublishBalanceUpdate(src, citizen_id, balance_minor, savings_minor, opts)
--     - Updates Player(src).state.bank_balance with payload.
--     - Optionally emits NetEvent `sonar:bank:balance:update` (server→client).
--     - Lazy mode (opts.lazy=true): only publishes si player online.
--
--   PublishOnPlayerJoining(src, citizen_id, balance_minor, savings_minor)
--     - Per M004 §2.2.2 — call este en `playerJoining` event hook.
--     - Initial publish at session start.
--
--   InvalidatePlayerState(src)
--     - Clear bank_balance StateBag (e.g. on account closure).
--
-- Deps: lib/enums.lua + lib/validators.lua (no DB / no errors / no audit).
-- =============================================================================

BankApp.lib.publish = {}
local M = BankApp.lib.publish

local Enums      = BankApp.lib.enums
local Validators = BankApp.lib.validators
local Config     = BankApp.Config

-- -----------------------------------------------------------------------------
-- §1. Internal helpers
-- -----------------------------------------------------------------------------

local function now_ms()
  return math.floor(os.time() * 1000)
end

local function is_player_online(src)
  if type(src) ~= 'number' or src <= 0 then return false end
  -- GetPlayerName returns nil/empty if player offline
  local name = GetPlayerName(src)
  return name ~= nil and name ~= ''
end

-- -----------------------------------------------------------------------------
-- §2. Public API
-- -----------------------------------------------------------------------------

--- PublishBalanceUpdate: canonical M004 helper for CP1-B balance publishing.
---
--- @param src integer player source id (FiveM session id)
--- @param citizen_id string player's citizen identifier
--- @param balance_minor integer primary account balance (minor units / cents)
--- @param savings_minor integer|nil savings account balance (minor units), default 0
--- @param opts table|nil {
---   lazy         = boolean, -- default true: skip if player offline
---   emit_event   = boolean, -- default true: emit `sonar:bank:balance:update` NetEvent
---   reason       = string,  -- audit-friendly reason ('transfer_committed', etc.)
---   correlation  = string,  -- optional correlation_id for cross-resource tracing
--- }
--- @return boolean published true if state actually wrote, false if skipped
--- @return string|nil reason 'ok'|'offline'|'invalid_input'|'invalid_amounts'
function M.PublishBalanceUpdate(src, citizen_id, balance_minor, savings_minor, opts)
  opts = opts or {}
  local lazy       = opts.lazy ~= false       -- default true
  local emit_event = opts.emit_event ~= false -- default true

  -- Input validation
  if type(src) ~= 'number' or src <= 0 then
    return false, 'invalid_input'
  end
  if not Validators.IsValidCitizenId(citizen_id) then
    return false, 'invalid_input'
  end
  if not Validators.IsNonNegativeInteger(balance_minor) then
    return false, 'invalid_amounts'
  end
  savings_minor = savings_minor or 0
  if not Validators.IsNonNegativeInteger(savings_minor) then
    return false, 'invalid_amounts'
  end

  -- Lazy: skip if offline
  if lazy and not is_player_online(src) then
    return false, 'offline'
  end

  local payload = {
    citizen_id    = citizen_id,
    balance_minor = balance_minor,
    savings_minor = savings_minor,
    updated_ms    = now_ms(),
    reason        = opts.reason,
    correlation   = opts.correlation,
  }

  -- Per-player StateBag set (replicated=true → client receives via state listener)
  -- This is the CP1-B canonical write. Player StateBag is auto-filtered to
  -- this specific src (privacy boundary preserved).
  local player_state = Player(src).state
  player_state:set('bank_balance', payload, true)

  -- Optional NetEvent emit (eventos catalogados C-BE-01 v1.0.1 R1)
  if emit_event then
    -- TriggerClientEvent goes only to specific src — privacy preserved.
    TriggerClientEvent('sonar:bank:balance:update', src, payload)
  end

  return true, 'ok'
end

--- PublishSavingsUpdate: variant para cuando solo savings cambia (loans payments,
--- recurring debit). Re-uses PublishBalanceUpdate con balance_minor pasado del
--- estado actual (caller debe leer current balance primero — para evitar
--- requerir re-fetch hacemos un snapshot-publish que combina ambos).
---
---@param src integer
---@param citizen_id string
---@param current_balance_minor integer caller-supplied (must be authoritative)
---@param new_savings_minor integer
---@param opts table|nil
---@return boolean published
---@return string reason
function M.PublishSavingsUpdate(src, citizen_id, current_balance_minor, new_savings_minor, opts)
  opts = opts or {}
  -- Optionally emit savings-specific event en lugar de balance:update.
  if opts.emit_event ~= false then
    -- Use savings:update específico per C-BE-01 §3.1 (R1 NEW M004 event)
    if Validators.IsValidCitizenId(citizen_id) and is_player_online(src)
       and Validators.IsNonNegativeInteger(new_savings_minor) then
      TriggerClientEvent('sonar:bank:savings:update', src, {
        citizen_id    = citizen_id,
        savings_minor = new_savings_minor,
        updated_ms    = now_ms(),
        reason        = opts.reason,
        correlation   = opts.correlation,
      })
    end
  end
  -- Then publish full balance state (preserves CP1-B invariant — bank_balance
  -- StateBag siempre tiene shape completo).
  return M.PublishBalanceUpdate(src, citizen_id, current_balance_minor, new_savings_minor, {
    lazy         = opts.lazy,
    emit_event   = false,  -- already emitted savings:update above
    reason       = opts.reason,
    correlation  = opts.correlation,
  })
end

--- PublishOnPlayerJoining: M004 §2.2.2 lazy initial publish on session start.
---   Caller (typically state/statebags.lua bound to playerJoining hook) provides
---   citizen_id + balances tras DB lookup.
---@param src integer
---@param citizen_id string
---@param balance_minor integer
---@param savings_minor integer|nil
---@return boolean published
function M.PublishOnPlayerJoining(src, citizen_id, balance_minor, savings_minor)
  return M.PublishBalanceUpdate(src, citizen_id, balance_minor, savings_minor or 0, {
    lazy         = false,  -- explicit publish at boot
    emit_event   = false,  -- client UI suscribe directly via Player(src).state — no NetEvent needed
    reason       = 'playerJoining',
  })
end

--- InvalidatePlayerState: clear bank_balance (e.g. on account closure / dropout).
---@param src integer
function M.InvalidatePlayerState(src)
  if type(src) ~= 'number' or src <= 0 then return end
  if not is_player_online(src) then return end
  Player(src).state:set('bank_balance', nil, true)
end

-- -----------------------------------------------------------------------------
-- §3. Admin/govt audit-only event (C-BE-01 §4.1 R1 NEW)
--
--   `sonar:bank:balance:adminAudit` — Tier 2, admin-ACE-only, on-demand response.
--   Per M004 cross-cutting refactor, este es el ÚNICO canal admin para receive
--   balance snapshots de otros players (NUNCA se publica a admin via Player
--   StateBag — admin solicita on-demand via callback C038 govt audit response).
-- -----------------------------------------------------------------------------

--- EmitAdminAudit: send admin audit response NetEvent al specific admin src.
---@param admin_src integer admin player source (must have ACE)
---@param target_citizen_id string player being audited
---@param balance_minor integer
---@param savings_minor integer|nil
---@param audit_metadata table|nil { audit_id, requested_at_ms, reason }
---@return boolean ok
function M.EmitAdminAudit(admin_src, target_citizen_id, balance_minor, savings_minor, audit_metadata)
  if type(admin_src) ~= 'number' or admin_src <= 0 then return false end
  if not Validators.IsValidCitizenId(target_citizen_id) then return false end
  if not Validators.IsNonNegativeInteger(balance_minor) then return false end
  savings_minor = savings_minor or 0

  TriggerClientEvent('sonar:bank:balance:adminAudit', admin_src, {
    target_citizen_id = target_citizen_id,
    balance_minor     = balance_minor,
    savings_minor     = savings_minor,
    delivered_ms      = now_ms(),
    audit_id          = audit_metadata and audit_metadata.audit_id,
    requested_at_ms   = audit_metadata and audit_metadata.requested_at_ms,
    reason            = audit_metadata and audit_metadata.reason,
  })
  return true
end

return M
