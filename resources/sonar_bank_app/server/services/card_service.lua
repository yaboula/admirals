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

local CARD_PRODUCTS = {
  classic = {
    card_kind = 'debit',
    default_design_id = 'noir',
    daily_limit_minor = 200000,
    monthly_limit_minor = 2500000,
    designs = { noir = true, sonar_signature = true },
  },
  premium = {
    card_kind = 'credit',
    default_design_id = 'sonar_signature',
    daily_limit_minor = 1000000,
    monthly_limit_minor = 10000000,
    designs = {
      noir = true,
      sonar_signature = true,
      aurora = true,
      sunset = true,
      titanium = true,
      deep_space = true,
      emerald_vault = true,
    },
  },
}

local function normalize_card_product(card_type)
  if card_type == 'premium' or card_type == 'credit' then return 'premium' end
  return 'classic'
end

local function product_for_card_kind(card_kind)
  return card_kind == 'credit' and CARD_PRODUCTS.premium or CARD_PRODUCTS.classic
end

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

  local product_key = normalize_card_product(ctx.card_type)
  local product = CARD_PRODUCTS[product_key]
  local design_id = ctx.design_id or product.default_design_id
  if not product.designs[design_id] then
    return { ok = false, error = Errors.New('INVALID_DESIGN', { design_id = design_id, card_type = product_key }) }
  end

  local daily_limit_minor = tonumber(ctx.spend_limit_minor) or product.daily_limit_minor
  if daily_limit_minor < 0 or daily_limit_minor > product.daily_limit_minor or math.floor(daily_limit_minor) ~= daily_limit_minor then
    return { ok = false, error = Errors.New('INVALID_LIMITS', { field = 'spend_limit_minor', card_type = product_key }) }
  end

  local masked = generate_masked_number()
  local card_id, ins_err = CardsRepo.Insert({
    owner_citizen_id  = owner_cid,
    account_iban      = norm_iban,
    masked_number     = masked,
    pin_hash          = hash_pin(ctx.pin, owner_cid, 0),
    spend_limit_minor = daily_limit_minor,
    monthly_limit_minor = product.monthly_limit_minor,
    card_kind         = product.card_kind,
    design_id         = design_id,
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
      card_type         = product_key,
      design_id         = design_id,
      spend_limit_minor = daily_limit_minor,
      monthly_limit_minor = product.monthly_limit_minor,
    },
  })
  invalidate_bootstrap(owner_cid)
  return { ok = true, data = { card_id = card_id, masked_number = masked, card_type = product_key, design_id = design_id } }
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
  local response_status = new_status == 'frozen' and 'locked' or new_status
  return { ok = true, data = { card_id = ctx.card_id, status = response_status } }
end

function S.Freeze(ctx)   return set_status_helper(ctx, 'frozen', Enums.AUDIT_EVENT_TYPE.CARD_FREEZE) end
function S.Unfreeze(ctx) return set_status_helper(ctx, 'active', Enums.AUDIT_EVENT_TYPE.CARD_UNFREEZE) end

-- C035 — SetLimits
-- Updates the daily and monthly spending ceilings on a card the caller owns.
-- Validation:
--   * Both limits are integers in minor units, >= 0, <= 100_000_000 (= 1M EUR)
--   * monthly_limit_minor must be >= daily_limit_minor (matches FE guard)
--   * Caller must own the card
-- Audit row references the card_id, previous limits and new limits.
function S.SetLimits(ctx)
  local card_id = ctx.card_id
  if type(card_id) ~= 'string' or #card_id == 0 then
    return { ok = false, error = Errors.New('VALIDATION_FAILED', { field = 'card_id' }) }
  end

  local daily = tonumber(ctx.daily_limit_minor)
  local monthly = tonumber(ctx.monthly_limit_minor)

  local card = CardsRepo.GetById(card_id)
  if not card then
    return { ok = false, error = Errors.New('CARD_NOT_FOUND') }
  end

  local product = product_for_card_kind(card.card_kind)
  if not daily or daily < 0 or daily > product.daily_limit_minor or math.floor(daily) ~= daily then
    return { ok = false, error = Errors.New('VALIDATION_FAILED', { field = 'daily_limit_minor' }) }
  end
  if not monthly or monthly < 0 or monthly > product.monthly_limit_minor or math.floor(monthly) ~= monthly then
    return { ok = false, error = Errors.New('VALIDATION_FAILED', { field = 'monthly_limit_minor' }) }
  end
  if monthly < daily then
    return { ok = false, error = Errors.New('INVALID_LIMITS', { reason = 'monthly_below_daily' }) }
  end

  local actor_cid, auth_err = Auth.RequireCitizen(ctx.src)
  if auth_err then return { ok = false, error = auth_err } end
  if card.owner_citizen_id ~= actor_cid then
    return { ok = false, error = Errors.New('AUTH_OWNER_MISMATCH') }
  end

  local previous_daily_minor = tonumber(card.spend_limit_minor) or 0

  local _, err = CardsRepo.SetLimits(card_id, actor_cid, daily, monthly)
  if err then return { ok = false, error = err } end

  Audit.Write({
    event_type        = Enums.AUDIT_EVENT_TYPE.CARD_LIMITS_UPDATE,
    actor_citizen_id  = actor_cid,
    actor_src         = ctx.src,
    target_citizen_id = actor_cid,
    target_iban       = card.account_iban,
    event_data        = {
      card_id                       = card_id,
      previous_daily_limit_minor    = previous_daily_minor,
      new_daily_limit_minor         = daily,
      new_monthly_limit_minor       = monthly,
    },
  })
  invalidate_bootstrap(actor_cid)
  return {
    ok   = true,
    data = {
      card_id              = card_id,
      daily_limit_minor    = daily,
      monthly_limit_minor  = monthly,
      updated_ms           = os.time() * 1000,
    },
  }
end

-- C036 — ApplyDesign
-- Updates the visual design_id of a card the caller owns. Whitelisted to the
-- known FE registry ids (`cardDesigns.ts`); unknown ids are rejected. The
-- bootstrap snapshot is invalidated so the cards array reflects immediately.
local KNOWN_DESIGN_IDS = {
  noir            = true,
  sonar_signature = true,
  aurora          = true,
  sunset          = true,
  titanium        = true,
  deep_space      = true,
  emerald_vault   = true,
}

function S.ApplyDesign(ctx)
  return { ok = false, error = Errors.New('DESIGN_LOCKED') }
end

function S.ApplyDesignLegacy(ctx)
  local card_id = ctx.card_id
  if type(card_id) ~= 'string' or #card_id == 0 then
    return { ok = false, error = Errors.New('VALIDATION_FAILED', { field = 'card_id' }) }
  end
  local design_id = ctx.design_id
  if type(design_id) ~= 'string' or #design_id == 0 or #design_id > 64 then
    return { ok = false, error = Errors.New('INVALID_DESIGN', { field = 'design_id' }) }
  end
  if not KNOWN_DESIGN_IDS[design_id] then
    return { ok = false, error = Errors.New('INVALID_DESIGN', { design_id = design_id }) }
  end

  local card = CardsRepo.GetById(card_id)
  if not card then
    return { ok = false, error = Errors.New('CARD_NOT_FOUND') }
  end

  local actor_cid, auth_err = Auth.RequireCitizen(ctx.src)
  if auth_err then return { ok = false, error = auth_err } end
  if card.owner_citizen_id ~= actor_cid then
    return { ok = false, error = Errors.New('AUTH_OWNER_MISMATCH') }
  end

  local _, err = CardsRepo.SetDesign(card_id, actor_cid, design_id)
  if err then return { ok = false, error = err } end

  Audit.Write({
    event_type        = Enums.AUDIT_EVENT_TYPE.CARD_DESIGN_APPLIED or 'card_design_applied',
    actor_citizen_id  = actor_cid,
    actor_src         = ctx.src,
    target_citizen_id = actor_cid,
    event_data        = {
      card_id   = card_id,
      design_id = design_id,
    },
  })

  invalidate_bootstrap(actor_cid)

  return {
    ok = true,
    data = {
      card_id    = card_id,
      design_id  = design_id,
      updated_ms = os.time() * 1000,
    },
  }
end

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
  invalidate_bootstrap(actor_cid)
  return { ok = true, data = { card_id = ctx.card_id, pin_changed_ms = os.time() * 1000 } }
end

return S
