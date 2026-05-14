-- =============================================================================
-- SONAR Bank App — callbacks/portfolio.lua
-- =============================================================================
-- Investment portfolio.
--
-- Callbacks (5):
--   C027 sonar:bank:portfolio:buy
--   C028 sonar:bank:portfolio:sell
--   C029 sonar:bank:portfolio:list
--   REQ-FE-STOCKS-PORTFOLIO sonar:bank:stocks:portfolio
--   REQ-FE-STOCKS-LIST sonar:bank:stocks:list
-- =============================================================================

local Wrap   = BankApp.callbacks._wrap
local Enums  = BankApp.lib.enums

local PortfolioService = BankApp.services.portfolio

-- -----------------------------------------------------------------------------
-- C029 — list
-- -----------------------------------------------------------------------------

Wrap.Register('sonar:bank:portfolio:list', {
  tier  = Enums.TIER.TIER_1_READ,
  cb_id = 'C029',
}, function(src, citizen_id, payload)
  return PortfolioService.ListSelfResponse(citizen_id)
end)

Wrap.Register('sonar:bank:stocks:portfolio', {
  tier  = Enums.TIER.TIER_1_READ,
  cb_id = 'REQ-FE-STOCKS-PORTFOLIO',
}, function(src, citizen_id, payload)
  return PortfolioService.ListSelfResponse(citizen_id)
end)

Wrap.Register('sonar:bank:stocks:list', {
  tier  = Enums.TIER.TIER_1_READ,
  cb_id = 'REQ-FE-STOCKS-LIST',
}, function(src, citizen_id, payload)
  return PortfolioService.ListMarketAssets(payload or {})
end)

-- -----------------------------------------------------------------------------
-- C027 — buy
-- -----------------------------------------------------------------------------

Wrap.Register('sonar:bank:portfolio:buy', {
  tier  = Enums.TIER.TIER_2_WRITE,
  cb_id = 'C027',
}, function(src, citizen_id, payload)
  return PortfolioService.Buy({
    src              = src,
    citizen_id       = citizen_id,
    from_iban        = payload.from_iban,
    asset_symbol     = payload.asset_symbol,
    units            = payload.units,
    idempotency_key  = payload.idempotency_key,
  })
end)

-- -----------------------------------------------------------------------------
-- C028 — sell
-- -----------------------------------------------------------------------------

Wrap.Register('sonar:bank:portfolio:sell', {
  tier  = Enums.TIER.TIER_2_WRITE,
  cb_id = 'C028',
}, function(src, citizen_id, payload)
  return PortfolioService.Sell({
    src           = src,
    citizen_id    = citizen_id,
    to_iban       = payload.to_iban,
    asset_symbol  = payload.asset_symbol,
    units         = payload.units,
    idempotency_key = payload.idempotency_key,
  })
end)
