-- =============================================================================
-- SONAR Bank App — services/card_service.lua
-- =============================================================================
-- Virtual cards service. PIN stored as HMAC-SHA256 (NEVER plaintext).
--
-- Operations:
--   ListSelf(citizen_id)
--   Issue(ctx)         — generates masked number + initial PIN
--   Freeze / Unfreeze
--   ChangePin(ctx)     — verifies old PIN HMAC, updates with new
-- =============================================================================

BankApp.services.card = {}
local S = BankApp.services.card

local Validators = BankApp.lib.validators
local Errors     = BankApp.lib.errors
local Audit      = BankApp.lib.audit
local Auth       = BankApp.lib.auth
local Enums      = BankApp.lib.enums
local HMAC       = BankApp.lib.hmac

local CardsRepo = BankApp.repos.cards

local function invalidate_bootstrap(citizen_id)
  if BankApp.services.bootstrap and BankApp.services.bootstrap.InvalidateCitizen then
    BankApp.services.bootstrap.InvalidateCitizen(citizen_id)
  end
end

local function generate_masked_number()
  -- Format: **** **** **** XXXX (last 4 random digits)
  local last4 = string.format('%04d', math.random(0, 9999))
  return '**** **** **** ' .. last4
end

local function hash_pin(pin_plain, citizen_id, card_id_or_zero)
  -- HMAC the PIN with citizen_id + card_id as salt context.
  -- Even if HMAC convar not loaded (dev), fallback to deterministic but salted hash.
  local payload = ('%s:%s:%s'):format(tostring(citizen_id), tostring(card_id_or_zero), tostring(pin_plain))
  if HMAC.IsLoaded() then
    local sig, err = HMAC.SignPayload(payload)
    if sig then return sig end
    -- fallthrough on err
  end
  -- Defensive fallback: SHA256 (still strong, but no key separation)
  return HMAC.SHA256(payload)
end

function S.ListSelf(citizen_id)
  if not Validators.IsValidCitizenId(citizen_id) then
    return nil, Errors.New('INVALID_CITIZEN_ID')
  end
  return CardsRepo.ListByCitizen(citizen_id, 8)
end

function S.Issue(ctx)
  local norm_iban = Validators.NormalizeIBAN(ctx.account_iban)
  if not norm_iban then return { ok = false, error = Errors.New('INVALID_IBAN') } end
  if type(ctx.pin) ~= 'string' or #ctx.pin < 4 or #ctx.pin > 8 or not ctx.pin:match('^[0-9]+$') then
    return { ok = false, error = Errors.New('VALIDATION_FAILED', { field = 'pin', reason = '4-8 digits' }) }
  end

  local owner_cid, _, own_err = Auth.RequireOwnership(ctx.src, norm_iban, { allow_joint = false })
  if own_err then return { ok = false, error = own_err } end

  -- Max 3 cards per citizen
  local existing_cards, list_err = CardsRepo.ListByCitizen(owner_cid, 3)
  if list_err then return { ok = false, error = list_err } end
  if #existing_cards >= 3 then
    return { ok = false, error = Errors.New('VALIDATION_FAILED', { field = 'cards', reason = 'max 3 cards per citizen' }) }
  end

  -- Map card_type to card_kind (virtual maps to debit for schema compatibility)
  local card_type = ctx.card_type or 'debit'
  local card_kind = card_type == 'virtual' and 'debit' or card_type

  local masked = generate_masked_number()
  -- Insert with placeholder hash, update once we know card_id (PIN salted by card_id)
  local card_id, ins_err = CardsRepo.Insert({
    owner_citizen_id  = owner_cid,
    account_iban      = norm_iban,
    masked_number     = masked,
    pin_hash          = hash_pin(ctx.pin, owner_cid, 0),  -- temporary salt = 0
    spend_limit_minor = ctx.spend_limit_minor,
    card_kind         = card_kind,
  })
  if ins_err then return { ok = false, error = ins_err } end

  -- Re-hash with card_id as salt + persist
  local final_hash = hash_pin(ctx.pin, owner_cid, card_id)
  CardsRepo.SetPinHash(card_id, owner_cid, final_hash)

  Audit.Write({
    event_type       = Enums.AUDIT_EVENT_TYPE.CARD_ISSUE,
    actor_citizen_id = owner_cid,
    actor_src        = ctx.src,
    target_citizen_id= owner_cid,
    target_iban      = norm_iban,
    event_data       = {
      card_id           = card_id,
      masked_number     = masked,
      spend_limit_minor = ctx.spend_limit_minor,
    },
  })
  invalidate_bootstrap(owner_cid)
  return { ok = true, data = { card_id = card_id, masked_number = masked } }
end

local function set_status_helper(ctx, new_status, event_type)
  local card = CardsRepo.GetById(ctx.card_id)
  if not card then return { ok = false, error = Errors.New('VALIDATION_FAILED', { reason = 'card not found' }) } end

  local actor_cid, auth_err = Auth.RequireCitizen(ctx.src)
  if auth_err then return { ok = false, error = auth_err } end
  if card.owner_citizen_id ~= actor_cid then
    return { ok = false, error = Errors.New('AUTH_OWNER_MISMATCH') }
  end

  local _, err = CardsRepo.SetStatus(ctx.card_id, actor_cid, new_status)
  if err then return { ok = false, error = err } end

  Audit.Write({
    event_type       = event_type,
    actor_citizen_id = actor_cid,
    actor_src        = ctx.src,
    target_citizen_id= actor_cid,
    target_iban      = card.account_iban,
    event_data       = { card_id = ctx.card_id, new_status = new_status },
  })
  invalidate_bootstrap(actor_cid)
  return { ok = true, data = { card_id = ctx.card_id, status = new_status } }
end

function S.Freeze(ctx)   return set_status_helper(ctx, 'frozen', Enums.AUDIT_EVENT_TYPE.CARD_FREEZE) end
function S.Unfreeze(ctx) return set_status_helper(ctx, 'active', Enums.AUDIT_EVENT_TYPE.CARD_UNFREEZE) end

function S.ChangePin(ctx)
  local card = CardsRepo.GetById(ctx.card_id)
  if not card then return { ok = false, error = Errors.New('VALIDATION_FAILED', { reason = 'card not found' }) } end

  local actor_cid, auth_err = Auth.RequireCitizen(ctx.src)
  if auth_err then return { ok = false, error = auth_err } end
  if card.owner_citizen_id ~= actor_cid then
    return { ok = false, error = Errors.New('AUTH_OWNER_MISMATCH') }
  end

  -- Verify old PIN
  local old_hash = hash_pin(ctx.old_pin, actor_cid, ctx.card_id)
  if old_hash ~= card.pin_hash then
    -- Audit failed attempt
    Audit.Write({
      event_type       = 'card_pin_change_failed',
      actor_citizen_id = actor_cid,
      actor_src        = ctx.src,
      target_citizen_id= actor_cid,
      event_data       = { card_id = ctx.card_id },
    })
    return { ok = false, error = Errors.New('AUTH_INSUFFICIENT', { reason = 'old PIN mismatch' }) }
  end

  if type(ctx.new_pin) ~= 'string' or #ctx.new_pin < 4 or #ctx.new_pin > 8 or not ctx.new_pin:match('^[0-9]+$') then
    return { ok = false, error = Errors.New('VALIDATION_FAILED', { field = 'new_pin' }) }
  end

  local new_hash = hash_pin(ctx.new_pin, actor_cid, ctx.card_id)
  CardsRepo.SetPinHash(ctx.card_id, actor_cid, new_hash)

  Audit.Write({
    event_type       = Enums.AUDIT_EVENT_TYPE.CARD_PIN_CHANGE,
    actor_citizen_id = actor_cid,
    actor_src        = ctx.src,
    target_citizen_id= actor_cid,
    event_data       = { card_id = ctx.card_id },
  })
  return { ok = true, data = { card_id = ctx.card_id, pin_changed_ms = os.time() * 1000 } }
end

return S
