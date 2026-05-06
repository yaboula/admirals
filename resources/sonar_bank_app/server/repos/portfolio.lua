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

local SQL_LIST = [[
SELECT holding_id, asset_symbol, units, avg_cost_minor,
       UNIX_TIMESTAMP(updated_at)*1000 AS updated_ms
FROM bank_portfolio_holdings
WHERE owner_citizen_id = ? AND units > 0
ORDER BY asset_symbol ASC
LIMIT ?
]]

local SQL_GET = [[
SELECT holding_id, asset_symbol, units, avg_cost_minor
FROM bank_portfolio_holdings
WHERE owner_citizen_id = ? AND asset_symbol = ?
LIMIT 1
]]

local SQL_UPSERT_BUY = [[
INSERT INTO bank_portfolio_holdings
  (owner_citizen_id, asset_symbol, units, avg_cost_minor)
VALUES (?, ?, ?, ?)
ON DUPLICATE KEY UPDATE
  avg_cost_minor = ((units * avg_cost_minor) + (VALUES(units) * VALUES(avg_cost_minor)))
                   / (units + VALUES(units)),
  units = units + VALUES(units),
  updated_at = CURRENT_TIMESTAMP(6)
]]

local SQL_REDUCE_SELL = [[
UPDATE bank_portfolio_holdings
SET units = units - ?, updated_at = CURRENT_TIMESTAMP(6)
WHERE owner_citizen_id = ? AND asset_symbol = ? AND units >= ?
]]

function R.ListByCitizen(citizen_id, limit)
  return DB.Query(SQL_LIST, { citizen_id, limit or 64 })
end

function R.Get(citizen_id, asset_symbol)
  return DB.QuerySingle(SQL_GET, { citizen_id, asset_symbol })
end

function R.BuildBuyQuery(citizen_id, asset_symbol, units, price_per_unit_minor)
  return {
    query  = SQL_UPSERT_BUY,
    values = { citizen_id, asset_symbol, units, price_per_unit_minor },
  }
end

function R.BuildSellQuery(citizen_id, asset_symbol, units)
  return {
    query  = SQL_REDUCE_SELL,
    values = { units, citizen_id, asset_symbol, units },
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
