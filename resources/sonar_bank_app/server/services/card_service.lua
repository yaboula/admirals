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
local Idempotency = BankApp.lib.idempotency

local CardsRepo = BankApp.repos.cards
local AccountsRepo = BankApp.repos.accounts
local TransactionsRepo = BankApp.repos.transactions
local DB = BankApp.lib.db
local UUID = BankApp.lib.uuid
local Config = BankApp.Config
local Economy = BankApp.lib.economy

-- Build the products catalog from config.lua, normalizing the `designs` array
-- to a set for O(1) whitelist checks (designs may be declared as either an
-- array of strings or a set { id = true } depending on edit style).
local CARD_PRODUCTS = {}
do
  local cfg = (Config.Cards and Config.Cards.Products) or {}
  for product_id, spec in pairs(cfg) do
    local designs_set = {}
    if type(spec.designs) == 'table' then
      for k, v in pairs(spec.designs) do
        if type(k) == 'number' and type(v) == 'string' then
          designs_set[v] = true                       -- array form
        elseif type(k) == 'string' and v then
          designs_set[k] = true                       -- set form
        end
      end
    end
    CARD_PRODUCTS[product_id] = {
      card_kind           = spec.card_kind,
      default_design_id   = spec.default_design_id,
      daily_limit_minor   = tonumber(spec.daily_limit_minor)   or 0,
      monthly_limit_minor = tonumber(spec.monthly_limit_minor) or 0,
      issue_fee_minor     = tonumber(spec.issue_fee_minor)     or 0,
      designs             = designs_set,
      label               = spec.label,
      description         = spec.description,
    }
  end
  -- Defensive fallback if config block is missing entirely
  if not CARD_PRODUCTS.classic then
    CARD_PRODUCTS.classic = {
      card_kind = 'debit', default_design_id = 'noir',
      daily_limit_minor = 200000, monthly_limit_minor = 2500000,
      issue_fee_minor = 2500, designs = { noir = true, sonar_signature = true },
    }
  end
end

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

--- HashPin — exposed for the F06 ATM PIN verification flow (`atm_service.lua`).
--- Uses the same HMAC algorithm as issuance + ChangePin so hashes match.
function S.HashPin(pin_plain, citizen_id, card_id_or_zero)
  return hash_pin(pin_plain, citizen_id, card_id_or_zero)
end

function S.ListSelf(citizen_id)
  if not Validators.IsValidCitizenId(citizen_id) then
    return nil, Errors.New('INVALID_CITIZEN_ID')
  end
  return CardsRepo.ListByCitizen(citizen_id, 8)
end

function S.Issue(ctx)
  -- Feature gate: server can disable card issuance globally.
  local Features = BankApp.lib.features
  if Features and Features.Require then
    local feat_err = Features.Require('cards_issue')
    if feat_err then return { ok = false, error = feat_err } end
  end

  local norm_iban = Validators.NormalizeIBAN(ctx.account_iban)
  if not norm_iban then return { ok = false, error = Errors.New('INVALID_IBAN') } end
  if type(ctx.pin) ~= 'string' or #ctx.pin < 4 or #ctx.pin > 8 or not ctx.pin:match('^[0-9]+$') then
    return { ok = false, error = Errors.New('VALIDATION_FAILED', { field = 'pin', reason = '4-8 digits' }) }
  end

  local owner_cid, _, own_err = Auth.RequireOwnership(ctx.src, norm_iban, { allow_joint = false })
  if own_err then return { ok = false, error = own_err } end

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

  local idem_acquired = false
  if ctx.idempotency_key then
    local idem_status, cached, idem_err = Idempotency.Acquire(
      ctx.idempotency_key,
      {
        account_iban = norm_iban,
        card_type = product_key,
        design_id = design_id,
        spend_limit_minor = daily_limit_minor,
        issue_fee_minor = product.issue_fee_minor,
      },
      {
        actor_citizen_id = owner_cid,
        callback_id = 'C032',
        ttl_seconds = BankApp.Config.Idempotency.DEFAULT_TTL_SECONDS,
      }
    )
    if idem_status == 'replay' then
      return { ok = true, data = cached, replayed = true }
    elseif idem_status == 'collision' or idem_status == 'in_flight' then
      return { ok = false, error = idem_err }
    elseif idem_status ~= 'acquired' then
      return { ok = false, error = idem_err or Errors.New('INTERNAL_ERROR', { reason = 'idempotency unknown status' }) }
    end
    idem_acquired = true
  end

  -- Max 3 cards per citizen
  local existing_cards, list_err = CardsRepo.ListByCitizen(owner_cid, 3)
  if list_err then
    if idem_acquired then Idempotency.Orphan(ctx.idempotency_key) end
    return { ok = false, error = list_err }
  end
  if #existing_cards >= 3 then
    if idem_acquired then Idempotency.Orphan(ctx.idempotency_key) end
    return { ok = false, error = Errors.New('VALIDATION_FAILED', { field = 'cards', reason = 'max 3 cards per citizen' }) }
  end

  local account = AccountsRepo.GetByIban(norm_iban)
  if not account then
    if idem_acquired then Idempotency.Orphan(ctx.idempotency_key) end
    return { ok = false, error = Errors.New('ACCOUNT_NOT_FOUND') }
  end
  local available_minor = tonumber(account.balance_minor) or 0
  -- Total issue fee = product baseline + global Economy override (banker-tunable).
  local extra_fee = Economy.CardIssueExtraFee() or 0
  local total_fee_minor = (product.issue_fee_minor or 0) + extra_fee
  if available_minor < total_fee_minor then
    if idem_acquired then Idempotency.Orphan(ctx.idempotency_key) end
    return { ok = false, error = Errors.New('INSUFFICIENT_FUNDS', { requested = total_fee_minor, available = available_minor }) }
  end

  local masked = generate_masked_number()
  local planned_card_id = UUID.V4()
  local insert_query, card_id = CardsRepo.BuildInsertQuery({
    card_id           = planned_card_id,
    owner_citizen_id  = owner_cid,
    account_iban      = norm_iban,
    masked_number     = masked,
    pin_hash          = hash_pin(ctx.pin, owner_cid, planned_card_id),
    spend_limit_minor = daily_limit_minor,
    monthly_limit_minor = product.monthly_limit_minor,
    card_kind         = product.card_kind,
    design_id         = design_id,
  })
  local ts = os.time() * 1000
  local txn_id = UUID.V4()
  local fee_reason = extra_fee > 0
    and ('SONAR %s card issue fee (+%d minor)'):format(product_key, extra_fee)
    or  ('SONAR %s card issue fee'):format(product_key)
  local ok, tx_err = DB.Transaction({
    AccountsRepo.BuildDebitBalanceQuery(norm_iban, total_fee_minor),
    insert_query,
    TransactionsRepo.BuildSingleDebitQuery({
      iban = norm_iban,
      amount_minor = total_fee_minor,
      category = 'expense',
      reason = fee_reason,
      txn_id = txn_id,
      timestamp_ms = ts,
      idempotency_key = ctx.idempotency_key or txn_id,
    }),
  })
  if not ok then
    if idem_acquired then Idempotency.Orphan(ctx.idempotency_key) end
    return { ok = false, error = tx_err }
  end

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
      issue_fee_minor   = total_fee_minor,
      base_fee_minor    = product.issue_fee_minor,
      extra_fee_minor   = extra_fee,
      spend_limit_minor = daily_limit_minor,
      monthly_limit_minor = product.monthly_limit_minor,
      fee_txn_id        = txn_id,
    },
  })
  local result = {
    card_id = card_id,
    masked_number = masked,
    card_type = product_key,
    design_id = design_id,
    issue_fee_minor = total_fee_minor,
    extra_fee_minor = extra_fee,
  }
  if idem_acquired then Idempotency.Commit(ctx.idempotency_key, result) end
  invalidate_bootstrap(owner_cid)
  return { ok = true, data = result }
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
function S.Revoke(ctx)
  local card = CardsRepo.GetById(ctx.card_id)
  if not card then return { ok = false, error = Errors.New('CARD_NOT_FOUND') } end

  local actor_cid, auth_err = Auth.RequireCitizen(ctx.src)
  if auth_err then return { ok = false, error = auth_err } end
  if card.owner_citizen_id ~= actor_cid then
    return { ok = false, error = Errors.New('AUTH_OWNER_MISMATCH') }
  end

  local _, err = CardsRepo.SetStatus(ctx.card_id, actor_cid, 'revoked')
  if err then return { ok = false, error = err } end

  Audit.Write({
    event_type       = Enums.AUDIT_EVENT_TYPE.CARD_REVOKE,
    actor_citizen_id = actor_cid,
    actor_src        = ctx.src,
    target_citizen_id= actor_cid,
    target_iban      = card.account_iban,
    event_data       = { card_id = ctx.card_id, reason = ctx.reason or 'lost' },
  })
  invalidate_bootstrap(actor_cid)
  return { ok = true, data = { card_id = ctx.card_id, status = 'revoked', revoked_ms = os.time() * 1000 } }
end

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
