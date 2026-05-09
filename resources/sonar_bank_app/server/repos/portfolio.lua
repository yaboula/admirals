-- =============================================================================
-- SONAR Bank App — repos/portfolio.lua
-- =============================================================================
-- Investment portfolio holdings DAO.
--
-- Schema (sonar_core migration 017 bank_portfolio_holdings):
--   holding_id        BIGINT PK AUTO_INCREMENT
--   owner_citizen_id  VARCHAR(64) NOT NULL
--   asset_symbol      VARCHAR(16) NOT NULL  (e.g. 'GTASTOCK_A', 'GOLD')
--   units             DECIMAL(20,8) NOT NULL
--   avg_cost_minor    BIGINT NOT NULL  (cost basis per unit × 10000 for cents-precision)
--   created_at, updated_at TIMESTAMP(6)
--   UNIQUE KEY (owner_citizen_id, asset_symbol)
-- =============================================================================

BankApp.repos.portfolio = {}
local R = BankApp.repos.portfolio

local DB = BankApp.lib.db
local UUID = BankApp.lib.uuid

local SQL_LIST = [[
SELECT h.id AS holding_id, a.ticker AS asset_symbol, h.qty_total AS units,
       CAST(ROUND(COALESCE(h.avg_cost_basis, 0) * 100) AS SIGNED) AS avg_cost_minor,
       h.last_recomputed_at * 1000 AS updated_ms
FROM sonar_bank_stocks_holdings h
INNER JOIN sonar_accounts sa ON sa.id = h.citizen_id
INNER JOIN sonar_bank_stocks_assets a ON a.id = h.asset_id
WHERE sa.char_id = ? AND h.qty_total > 0
ORDER BY a.ticker ASC
LIMIT ?
]]

local SQL_GET = [[
SELECT h.id AS holding_id, a.ticker AS asset_symbol, h.qty_total AS units,
       CAST(ROUND(COALESCE(h.avg_cost_basis, 0) * 100) AS SIGNED) AS avg_cost_minor
FROM sonar_bank_stocks_holdings h
INNER JOIN sonar_accounts sa ON sa.id = h.citizen_id
INNER JOIN sonar_bank_stocks_assets a ON a.id = h.asset_id
WHERE sa.char_id = ? AND a.ticker = ?
LIMIT 1
]]

local SQL_UPSERT_ASSET = [[
INSERT INTO sonar_bank_stocks_assets
  (ticker, display_name, enabled, current_price, price_updated_at)
VALUES (?, ?, TRUE, (? / 100.0), UNIX_TIMESTAMP())
ON DUPLICATE KEY UPDATE
  current_price = VALUES(current_price), price_updated_at = VALUES(price_updated_at)
]]

local SQL_INSERT_STOCK_TX = [[
INSERT INTO sonar_bank_stocks_transactions
  (citizen_id, asset_id, fiat_bank_account_id, tx_kind, qty, price_per_share,
   total_amount, request_nonce, initiated_by_account_id, occurred_at)
SELECT sa.id, a.id, ba.id, ?, ?, (? / 100.0), (? / 100.0), ?, sa.id, UNIX_TIMESTAMP()
FROM sonar_accounts sa
INNER JOIN sonar_bank_stocks_assets a ON a.ticker = ?
INNER JOIN sonar_bank_accounts ba ON ba.iban = ?
WHERE sa.char_id = ?
LIMIT 1
]]

local SQL_UPSERT_BUY = [[
INSERT INTO sonar_bank_stocks_holdings
  (id, citizen_id, asset_id, qty_total, avg_cost_basis, last_recomputed_at)
SELECT ?, sa.id, a.id, ?, (? / 100.0), UNIX_TIMESTAMP()
FROM sonar_accounts sa
INNER JOIN sonar_bank_stocks_assets a ON a.ticker = ?
WHERE sa.char_id = ?
ON DUPLICATE KEY UPDATE
  avg_cost_basis = CASE
    WHEN qty_total + VALUES(qty_total) > 0 THEN
      ((qty_total * COALESCE(avg_cost_basis, 0)) + (VALUES(qty_total) * VALUES(avg_cost_basis)))
      / (qty_total + VALUES(qty_total))
    ELSE avg_cost_basis
  END,
  qty_total = qty_total + VALUES(qty_total),
  last_recomputed_at = UNIX_TIMESTAMP()
]]

local SQL_REDUCE_SELL = [[
UPDATE sonar_bank_stocks_holdings h
INNER JOIN sonar_accounts sa ON sa.id = h.citizen_id
INNER JOIN sonar_bank_stocks_assets a ON a.id = h.asset_id
SET h.qty_total = h.qty_total - ?, h.last_recomputed_at = UNIX_TIMESTAMP()
WHERE sa.char_id = ? AND a.ticker = ? AND h.qty_total >= ?
]]

function R.ListByCitizen(citizen_id, limit)
  return DB.Query(SQL_LIST, { citizen_id, limit or 64 })
end

function R.Get(citizen_id, asset_symbol)
  return DB.QuerySingle(SQL_GET, { citizen_id, asset_symbol })
end

function R.BuildBuyQueries(citizen_id, fiat_iban, asset_symbol, units, price_per_unit_minor, total_cost_minor)
  return {
    {
      query  = SQL_UPSERT_ASSET,
      values = { asset_symbol, asset_symbol, price_per_unit_minor },
    },
    {
      query  = SQL_INSERT_STOCK_TX,
      values = {
        'buy', units, price_per_unit_minor, total_cost_minor, UUID.V4(),
        asset_symbol, fiat_iban, citizen_id,
      },
    },
    {
      query  = SQL_UPSERT_BUY,
      values = { UUID.V4(), units, price_per_unit_minor, asset_symbol, citizen_id },
    },
  }
end

function R.BuildSellQueries(citizen_id, fiat_iban, asset_symbol, units, price_per_unit_minor, proceeds_minor)
  return {
    {
      query  = SQL_UPSERT_ASSET,
      values = { asset_symbol, asset_symbol, price_per_unit_minor },
    },
    {
      query  = SQL_REDUCE_SELL,
      values = { units, citizen_id, asset_symbol, units },
    },
    {
      query  = SQL_INSERT_STOCK_TX,
      values = {
        'sell', -units, price_per_unit_minor, proceeds_minor, UUID.V4(),
        asset_symbol, fiat_iban, citizen_id,
      },
    },
  }
end

--- BuildSnapshotQuery — REQ-FE-001 bootstrap parallel.
function R.BuildSnapshotQuery(citizen_id, limit)
  return {
    sql    = SQL_LIST,
    params = { citizen_id, limit or 64 },
    kind   = 'query',
  }
end

return R
