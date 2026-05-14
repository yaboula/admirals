-- =============================================================================
-- SONAR Bank App — services/recurring_service.lua
-- =============================================================================
-- Recurring debits (subscriptions / scheduled payments) FSM orchestrator.
--
-- Operations:
--   ListSelf(citizen_id)
--   Subscribe(ctx)        — create subscription
--   Cancel(ctx)           — owner-only
--   Pause(ctx)/Resume(ctx)
--   ChargeDue(now_ms)     — cron task (delegates to TransferService)
-- =============================================================================

BankApp.services.recurring = {}
local S = BankApp.services.recurring

local Validators = BankApp.lib.validators
local Errors     = BankApp.lib.errors
local UUID       = BankApp.lib.uuid
local Audit      = BankApp.lib.audit
local Auth       = BankApp.lib.auth
local Enums      = BankApp.lib.enums
local Idempotency= BankApp.lib.idempotency

local RecurringRepo = BankApp.repos.recurring

local function now_ms() return os.time() * 1000 end

local function invalidate_bootstrap(citizen_id)
  if BankApp.services.bootstrap and BankApp.services.bootstrap.InvalidateCitizen then
    BankApp.services.bootstrap.InvalidateCitizen(citizen_id)
  end
end

function S.ListSelf(citizen_id)
  if not Validators.IsValidCitizenId(citizen_id) then
    return nil, Errors.New('INVALID_CITIZEN_ID')
  end
  return RecurringRepo.ListByCitizen(citizen_id, 32)
end

function S.Subscribe(ctx)
  local from_iban = Validators.NormalizeIBAN(ctx.from_iban)
  local to_iban   = Validators.NormalizeIBAN(ctx.to_iban)
  if not from_iban or not to_iban then
    return { ok = false, error = Errors.New('INVALID_IBAN') }
  end
  if not Validators.IsValidAmountMinor(ctx.amount_minor) then
    return { ok = false, error = Errors.New('INVALID_AMOUNT') }
  end
  if not Validators.IsInRange(ctx.interval_days, 1, 365) then
    return { ok = false, error = Errors.New('VALIDATION_FAILED', { field = 'interval_days' }) }
  end
  if not Validators.IsValidUUID(ctx.idempotency_key) then
    return { ok = false, error = Errors.New('VALIDATION_FAILED', { field = 'idempotency_key' }) }
  end

  local owner_cid, _, own_err = Auth.RequireOwnership(ctx.src, from_iban)
  if own_err then return { ok = false, error = own_err } end

  local first_charge = ctx.first_charge_ms or (now_ms() + ctx.interval_days * 86400 * 1000)
  local idem_status, cached, idem_err = Idempotency.Acquire(
    ctx.idempotency_key,
    { from_iban = from_iban, to_iban = to_iban, amount_minor = ctx.amount_minor, interval_days = ctx.interval_days, first_charge_ms = first_charge },
    { actor_citizen_id = owner_cid, callback_id = 'C014' }
  )
  if idem_status == 'replay' then
    return { ok = true, data = cached, replayed = true }
  elseif idem_status ~= 'acquired' then
    return { ok = false, error = idem_err or Errors.New('IDEMPOTENCY_IN_FLIGHT') }
  end

  local id, err = RecurringRepo.Insert({
    owner_citizen_id = owner_cid,
    from_iban        = from_iban,
    to_iban          = to_iban,
    amount_minor     = ctx.amount_minor,
    reason           = Validators.SanitizeReason(ctx.reason),
    interval_days    = ctx.interval_days,
    next_charge_ms   = first_charge,
  })
  if err then Idempotency.Orphan(ctx.idempotency_key); return { ok = false, error = err } end

  Audit.Write({
    event_type       = Enums.AUDIT_EVENT_TYPE.RECURRING_SUBSCRIBE,
    actor_citizen_id = owner_cid,
    actor_src        = ctx.src,
    target_citizen_id= owner_cid,
    target_iban      = from_iban,
    event_data       = {
      recurring_id    = id,
      to_iban         = to_iban,
      amount_minor    = ctx.amount_minor,
      interval_days   = ctx.interval_days,
      first_charge_ms = first_charge,
    },
  })

  invalidate_bootstrap(owner_cid)
  local result = { recurring_id = id, next_charge_ms = first_charge }
  Idempotency.Commit(ctx.idempotency_key, result)
  return { ok = true, data = result }
end

local function set_status_helper(ctx, new_status, event_type, callback_id)
  if not Validators.IsValidUUID(ctx.idempotency_key) then
    return { ok = false, error = Errors.New('VALIDATION_FAILED', { field = 'idempotency_key' }) }
  end
  local row = RecurringRepo.GetById(ctx.recurring_id)
  if not row then return { ok = false, error = Errors.New('VALIDATION_FAILED', { reason = 'recurring not found' }) } end

  local owner_cid, _, own_err = Auth.RequireCitizen(ctx.src)
  if own_err then return { ok = false, error = own_err } end
  if row.owner_citizen_id ~= owner_cid then
    return { ok = false, error = Errors.New('AUTH_OWNER_MISMATCH') }
  end

  local idem_status, cached, idem_err = Idempotency.Acquire(
    ctx.idempotency_key,
    { recurring_id = ctx.recurring_id, status = new_status },
    { actor_citizen_id = owner_cid, callback_id = callback_id }
  )
  if idem_status == 'replay' then
    return { ok = true, data = cached, replayed = true }
  elseif idem_status ~= 'acquired' then
    return { ok = false, error = idem_err or Errors.New('IDEMPOTENCY_IN_FLIGHT') }
  end

  local _, err = RecurringRepo.SetStatus(ctx.recurring_id, owner_cid, new_status)
  if err then Idempotency.Orphan(ctx.idempotency_key); return { ok = false, error = err } end

  Audit.Write({
    event_type       = event_type,
    actor_citizen_id = owner_cid,
    actor_src        = ctx.src,
    target_citizen_id= owner_cid,
    event_data       = { recurring_id = ctx.recurring_id, new_status = new_status },
  })
  invalidate_bootstrap(owner_cid)
  local result = { recurring_id = ctx.recurring_id, status = new_status }
  Idempotency.Commit(ctx.idempotency_key, result)
  return { ok = true, data = result }
end

function S.Cancel(ctx) return set_status_helper(ctx, 'cancelled', Enums.AUDIT_EVENT_TYPE.RECURRING_UNSUBSCRIBE, 'C017') end
function S.Pause(ctx)  return set_status_helper(ctx, 'paused',    'recurring_pause', 'C018a') end
function S.Resume(ctx) return set_status_helper(ctx, 'active',    'recurring_resume', 'C018b') end

-- -----------------------------------------------------------------------------
-- §3. ChargeDue — cron pickup → delegates to TransferService.Execute per row
-- -----------------------------------------------------------------------------

--- ChargeDue — executed by boot/cron.lua periodically.
--- Uses TransferService.ExecuteAsSystem (privileged path, sentinel src=0) so
--- charges proceed even when the borrower is offline.
---@param batch_limit integer
---@return integer charged_count, integer failed_count
function S.ChargeDue(batch_limit)
  local now = now_ms()
  local rows, err = RecurringRepo.GetDueForCharge(now, batch_limit or 50)
  if err or not rows then return 0, 0 end

  local TransferService = BankApp.services.transfer
  if not TransferService or not TransferService.ExecuteAsSystem then return 0, 0 end

  local charged, failed = 0, 0
  for _, r in ipairs(rows) do
    local amount = tonumber(r.amount_minor) or 0
    local ctx = {
      actor_citizen_id = r.owner_citizen_id,
      from_iban        = r.from_iban,
      to_iban          = r.to_iban,
      amount_minor     = amount,
      reason           = ('recurring_charge:%s'):format(r.recurring_id),
      idempotency_key  = ('rec_%s_%d'):format(r.recurring_id, math.floor(now / 1000)),
      correlation_id   = ('recurring/%s/%d'):format(r.recurring_id, now),
      system_origin    = 'recurring',
    }

    local result = TransferService.ExecuteAsSystem(ctx)

    if result and result.ok then
      charged = charged + 1
      RecurringRepo.BumpNextCharge(
        r.recurring_id, now,
        now + (tonumber(r.interval_days) or 30) * 86400 * 1000
      )
      Audit.Write({
        event_type       = Enums.AUDIT_EVENT_TYPE.RECURRING_CHARGE,
        actor_citizen_id = r.owner_citizen_id,
        actor_src        = 0,
        target_citizen_id= r.owner_citizen_id,
        cross_ref_audit_id = result.data and result.data.cross_ref_audit_id,
        event_data       = {
          recurring_id     = r.recurring_id,
          amount_minor     = amount,
          txn_id           = result.data and result.data.txn_id,
          system_initiated = true,
        },
      })
    else
      failed = failed + 1
      -- Failed row: retry in 24h (insufficient funds, frozen, etc.).
      RecurringRepo.BumpNextCharge(
        r.recurring_id, now,
        now + 86400 * 1000
      )
      Audit.Write({
        event_type       = Enums.AUDIT_EVENT_TYPE.RECURRING_FAILED,
        actor_citizen_id = r.owner_citizen_id,
        actor_src        = 0,
        target_citizen_id= r.owner_citizen_id,
        event_data       = {
          recurring_id     = r.recurring_id,
          amount_minor     = amount,
          reason           = result and result.error and result.error.code or 'unknown',
          system_initiated = true,
        },
      })
    end
  end
  return charged, failed
end

return S
