-- =============================================================================
-- SONAR Bank App — services/banker/dashboard.lua
-- =============================================================================
-- Dashboard KPIs + timeseries (F2).
--
--   Single endpoint shape, designed to be consumed by the FE Dashboard
--   route in one network round-trip.
--
--   Failure semantics: any sub-query that errors is logged but does NOT
--   abort the whole snapshot — the failing section is returned as null and
--   the FE renders a neutral empty state. This keeps the dashboard always
--   bootable even if (e.g.) the movements partition is being maintained.
-- =============================================================================

BankApp.services.banker = BankApp.services.banker or {}
BankApp.services.banker.dashboard = {}
local S = BankApp.services.banker.dashboard

local Errors      = BankApp.lib.errors
local BankerAuth  = BankApp.lib.banker_auth
local BankerAggr  = BankApp.repos.banker_aggregate

local function now_ms() return os.time() * 1000 end

local function safe_call(fn, ...)
  local ok, result, err = pcall(fn, ...)
  if not ok then return nil, tostring(result):sub(1, 200) end
  if err then return nil, err end
  return result, nil
end

function S.GetSnapshot(ctx)
  local _, _, auth_err = BankerAuth.RequireBanker(ctx.src, 'panel_open')
  if auth_err then return { ok = false, error = auth_err } end

  local kpis,        kpis_err   = safe_call(BankerAggr.GetDashboardKpis)
  local by_class,    class_err  = safe_call(BankerAggr.AccountsByClass)
  local timeseries,  ts_err     = safe_call(BankerAggr.TransfersTimeseries, ctx.window_days or 14)
  local portfolio,   port_err   = safe_call(BankerAggr.LoanPortfolio)

  return {
    ok = true,
    data = {
      kpis              = kpis or {},
      accounts_by_class = by_class or {},
      transfers_timeseries = timeseries or {},
      loan_portfolio    = portfolio or {},
      partial_errors    = {
        kpis        = kpis_err and tostring(kpis_err) or nil,
        by_class    = class_err and tostring(class_err) or nil,
        timeseries  = ts_err and tostring(ts_err) or nil,
        portfolio   = port_err and tostring(port_err) or nil,
      },
      fetched_at_ms = now_ms(),
    },
  }
end
