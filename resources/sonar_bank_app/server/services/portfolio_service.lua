-- =============================================================================
-- SONAR Bank App — services/portfolio_service.lua
-- =============================================================================
-- Investment portfolio service.
--
-- Operations:
--   ListSelf(citizen_id)
--   Buy(ctx)   — debit balance, increase units (avg cost recalculated DB-side)
--   Sell(ctx)  — reduce units, credit balance
--
-- Pricing source: a stub `GetMarketPrice(asset_symbol)` — production integrates
-- with sonar_market or external feed. Phase A: deterministic pseudo price.
-- =============================================================================

BankApp.services.portfolio = {}
local S = BankApp.services.portfolio

local Validators = BankApp.lib.validators
local Errors     = BankApp.lib.errors
local DB         = BankApp.lib.db
local Audit      = BankApp.lib.audit
local Publish    = BankApp.lib.publish
local Auth       = BankApp.lib.auth
local Idempotency= BankApp.lib.idempotency
local Enums      = BankApp.lib.enums
local Perf       = BankApp.lib.perf

local PortfolioRepo = BankApp.repos.portfolio
local AccountsRepo  = BankApp.repos.accounts

local function invalidate_bootstrap(citizen_id)
  if BankApp.services.bootstrap and BankApp.services.bootstrap.InvalidateCitizen then
    BankApp.services.bootstrap.InvalidateCitizen(citizen_id)
  end
end

-- -----------------------------------------------------------------------------
-- §1. Pricing source (stub)
-- -----------------------------------------------------------------------------

local function get_market_price_minor(asset_symbol)
  -- Phase A stub: deterministic price by hash. Replace with sonar_market call.
  if _G.Bridges and _G.Bridges.Market and _G.Bridges.Market.GetPrice then
    local ok, price = pcall(_G.Bridges.Market.GetPrice, asset_symbol)
    if ok and type(price) == 'number' and price > 0 then return math.floor(price) end
  end
  -- Fallback deterministic
  local h = 0
  for i = 1, #asset_symbol do h = (h * 31 + string.byte(asset_symbol, i)) & 0x7fffffff end
  return 1000 + (h % 50000)  -- price between 1000 and 51000 minor units
end

local function decorate_holding(row)
  if not row then return nil end
  local qty = tonumber(row.units or row.qty) or 0
  local cost_basis_minor = math.floor(qty * (tonumber(row.avg_cost_minor) or 0))
  local price_minor = get_market_price_minor(row.asset_symbol or row.symbol or '')
  local market_value_minor = math.floor(qty * price_minor)
  row.symbol = row.asset_symbol or row.symbol
  row.qty = qty
  row.cost_basis_minor = cost_basis_minor
  row.market_value_minor = market_value_minor
  row.delta_pct = cost_basis_minor > 0 and ((market_value_minor - cost_basis_minor) / cost_basis_minor) * 100 or 0
  row.created_ms = tonumber(row.updated_ms) or os.time() * 1000
  row.asset_symbol = nil
  row.units = nil
  row.avg_cost_minor = nil
  row.updated_ms = nil
  return row
end

-- -----------------------------------------------------------------------------
-- §2. ListSelf
-- -----------------------------------------------------------------------------

function S.ListSelf(citizen_id)
  if not Validators.IsValidCitizenId(citizen_id) then
    return nil, Errors.New('INVALID_CITIZEN_ID')
  end
  local rows, err = PortfolioRepo.ListByCitizen(citizen_id, 64)
  if err then return nil, err end
  for _, row in ipairs(rows or {}) do decorate_holding(row) end
  return rows, nil
end

function S.ListSelfResponse(citizen_id)
  local rows, err = S.ListSelf(citizen_id)
  if err then return { ok = false, error = err } end
  local total_cost_basis_minor = 0
  local total_market_value_minor = 0
  for _, row in ipairs(rows or {}) do
    total_cost_basis_minor = total_cost_basis_minor + (tonumber(row.cost_basis_minor) or 0)
    total_market_value_minor = total_market_value_minor + (tonumber(row.market_value_minor) or 0)
  end
  local total_delta_minor = total_market_value_minor - total_cost_basis_minor
  return {
    ok = true,
    data = {
      holdings = rows or {},
      total_cost_basis_minor = total_cost_basis_minor,
      total_market_value_minor = total_market_value_minor,
      total_delta_minor = total_delta_minor,
      total_delta_pct = total_cost_basis_minor > 0 and (total_delta_minor / total_cost_basis_minor) * 100 or 0,
      fetched_at_ms = os.time() * 1000,
    },
  }
end

function S.ListMarketAssets(ctx)
  local rows, err = PortfolioRepo.ListAssets((ctx and ctx.limit) or 64)
  if err then return { ok = false, error = err } end
  for _, row in ipairs(rows or {}) do
    row.price_minor = (tonumber(row.price_minor) or 0) > 0 and tonumber(row.price_minor) or get_market_price_minor(row.symbol)
    row.change_24h_pct = 0
    row.market_cap_minor = row.price_minor * 100000
    row.volume_24h = 0
    row.updated_ms = tonumber(row.updated_ms) or os.time() * 1000
  end
  return { ok = true, data = { items = rows or {}, fetched_at_ms = os.time() * 1000 } }
end

-- -----------------------------------------------------------------------------
-- §3. Buy
-- -----------------------------------------------------------------------------

function S.Buy(ctx)
  local timer = Perf.StartTimer()
  if not Validators.IsValidCitizenId(ctx.citizen_id) then
    Perf.EndTimer(timer, 'C027', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('INVALID_CITIZEN_ID') }
  end
  local norm_iban = Validators.NormalizeIBAN(ctx.from_iban)
  if not norm_iban then
    Perf.EndTimer(timer, 'C027', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('INVALID_IBAN') }
  end
  if type(ctx.asset_symbol) ~= 'string' or #ctx.asset_symbol < 1 or #ctx.asset_symbol > 16 then
    Perf.EndTimer(timer, 'C027', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('VALIDATION_FAILED', { field = 'asset_symbol' }) }
  end
  if type(ctx.units) ~= 'number' or ctx.units <= 0 then
    Perf.EndTimer(timer, 'C027', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('VALIDATION_FAILED', { field = 'units' }) }
  end
  if not Validators.IsValidUUID(ctx.idempotency_key) then
    Perf.EndTimer(timer, 'C027', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('VALIDATION_FAILED', { field = 'idempotency_key' }) }
  end

  local owner_cid, account, own_err = Auth.RequireOwnership(ctx.src, norm_iban)
  if own_err then
    Perf.EndTimer(timer, 'C027', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = own_err }
  end

  local price = get_market_price_minor(ctx.asset_symbol)
  local total_cost = math.floor(ctx.units * price)
  if total_cost < 1 then total_cost = 1 end

  if (tonumber(account.balance_minor) or 0) < total_cost then
    Perf.EndTimer(timer, 'C027', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('INSUFFICIENT_FUNDS', {
      required = total_cost, available = account.balance_minor,
    }) }
  end

  local idem_status, cached, idem_err = Idempotency.Acquire(
    ctx.idempotency_key,
    { iban = norm_iban, asset = ctx.asset_symbol, units = ctx.units, price = price },
    { actor_citizen_id = owner_cid, callback_id = 'C027' }
  )
  if idem_status == 'replay' then
    Perf.EndTimer(timer, 'C027', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = true, data = cached, replayed = true }
  elseif idem_status ~= 'acquired' then
    Perf.EndTimer(timer, 'C027', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = idem_err or Errors.New('IDEMPOTENCY_IN_FLIGHT') }
  end

  local tx_queries = {
    AccountsRepo.BuildDebitBalanceQuery(norm_iban, total_cost),
  }
  for _, q in ipairs(PortfolioRepo.BuildBuyQueries(owner_cid, norm_iban, ctx.asset_symbol, ctx.units, price, total_cost)) do
    tx_queries[#tx_queries + 1] = q
  end
  local ok, tx_err = DB.Transaction(tx_queries)
  if not ok then
    Idempotency.Orphan(ctx.idempotency_key)
    Perf.EndTimer(timer, 'C027', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = tx_err }
  end

  Audit.Write({
    event_type       = Enums.AUDIT_EVENT_TYPE.PORTFOLIO_BUY,
    actor_citizen_id = owner_cid,
    actor_src        = ctx.src,
    target_citizen_id= owner_cid,
    target_iban      = norm_iban,
    event_data       = {
      asset      = ctx.asset_symbol,
      units      = ctx.units,
      price_minor= price,
      total_cost = total_cost,
    },
  })

  -- Publish balance
  local fresh = AccountsRepo.GetBalance(norm_iban)
  if fresh then
    Publish.PublishBalanceUpdate(
      ctx.src, owner_cid,
      tonumber(fresh.balance_minor) or 0,
      tonumber(fresh.savings_minor) or 0,
      { reason = 'portfolio_buy' }
    )
  end

  local result = {
    asset = ctx.asset_symbol, units = ctx.units, price_minor = price, total_cost = total_cost,
  }
  Idempotency.Commit(ctx.idempotency_key, result)
  invalidate_bootstrap(owner_cid)
  Perf.EndTimer(timer, 'C027', { tier = Enums.TIER.TIER_2_WRITE })
  return { ok = true, data = result }
end

-- -----------------------------------------------------------------------------
-- §4. Sell
-- -----------------------------------------------------------------------------

function S.Sell(ctx)
  local timer = Perf.StartTimer()
  if not Validators.IsValidCitizenId(ctx.citizen_id) then
    Perf.EndTimer(timer, 'C028', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('INVALID_CITIZEN_ID') }
  end
  local norm_iban = Validators.NormalizeIBAN(ctx.to_iban)
  if not norm_iban then
    Perf.EndTimer(timer, 'C028', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('INVALID_IBAN') }
  end
  if type(ctx.asset_symbol) ~= 'string' or #ctx.asset_symbol < 1 or #ctx.asset_symbol > 16 then
    Perf.EndTimer(timer, 'C028', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('VALIDATION_FAILED', { field = 'asset_symbol' }) }
  end
  if type(ctx.units) ~= 'number' or ctx.units <= 0 then
    Perf.EndTimer(timer, 'C028', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('VALIDATION_FAILED', { field = 'units' }) }
  end
  if not Validators.IsValidUUID(ctx.idempotency_key) then
    Perf.EndTimer(timer, 'C028', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('VALIDATION_FAILED', { field = 'idempotency_key' }) }
  end

  local owner_cid, _, own_err = Auth.RequireOwnership(ctx.src, norm_iban)
  if own_err then
    Perf.EndTimer(timer, 'C028', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = own_err }
  end

  local holding, h_err = PortfolioRepo.Get(owner_cid, ctx.asset_symbol)
  if h_err then
    Perf.EndTimer(timer, 'C028', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = h_err }
  end
  if not holding or (tonumber(holding.units) or 0) < ctx.units then
    Perf.EndTimer(timer, 'C028', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('VALIDATION_FAILED', { reason = 'insufficient units' }) }
  end

  local price = get_market_price_minor(ctx.asset_symbol)
  local proceeds = math.floor(ctx.units * price)

  local idem_status, cached, idem_err = Idempotency.Acquire(
    ctx.idempotency_key,
    { iban = norm_iban, asset = ctx.asset_symbol, units = ctx.units, price = price },
    { actor_citizen_id = owner_cid, callback_id = 'C028' }
  )
  if idem_status == 'replay' then
    Perf.EndTimer(timer, 'C028', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = true, data = cached, replayed = true }
  elseif idem_status ~= 'acquired' then
    Perf.EndTimer(timer, 'C028', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = idem_err or Errors.New('IDEMPOTENCY_IN_FLIGHT') }
  end

  local tx_queries = {}
  for _, q in ipairs(PortfolioRepo.BuildSellQueries(owner_cid, norm_iban, ctx.asset_symbol, ctx.units, price, proceeds)) do
    tx_queries[#tx_queries + 1] = q
  end
  tx_queries[#tx_queries + 1] = AccountsRepo.BuildCreditBalanceQuery(norm_iban, proceeds)
  local ok, tx_err = DB.Transaction(tx_queries)
  if not ok then
    Idempotency.Orphan(ctx.idempotency_key)
    Perf.EndTimer(timer, 'C028', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = tx_err }
  end

  Audit.Write({
    event_type       = Enums.AUDIT_EVENT_TYPE.PORTFOLIO_SELL,
    actor_citizen_id = owner_cid,
    actor_src        = ctx.src,
    target_citizen_id= owner_cid,
    target_iban      = norm_iban,
    event_data       = {
      asset       = ctx.asset_symbol,
      units       = ctx.units,
      price_minor = price,
      proceeds    = proceeds,
    },
  })

  local fresh = AccountsRepo.GetBalance(norm_iban)
  if fresh then
    Publish.PublishBalanceUpdate(
      ctx.src, owner_cid,
      tonumber(fresh.balance_minor) or 0,
      tonumber(fresh.savings_minor) or 0,
      { reason = 'portfolio_sell' }
    )
  end

  invalidate_bootstrap(owner_cid)
  local result = { asset = ctx.asset_symbol, units = ctx.units, proceeds = proceeds }
  Idempotency.Commit(ctx.idempotency_key, result)
  Perf.EndTimer(timer, 'C028', { tier = Enums.TIER.TIER_2_WRITE })
  return { ok = true, data = result }
end

return S
