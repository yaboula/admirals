-- =============================================================================
-- SONAR Bridges — adapters/notify/qb.lua
--
-- Adapter QBCore T2 para Notify.
-- =============================================================================

local QbNotify = {}
local _core = nil

local function _get_core()
  if _core then return _core end
  if GetResourceState('qb-core') ~= 'started' then return nil end
  local ok, core = pcall(function()
    return exports['qb-core']:GetCoreObject()
  end)
  if not ok or type(core) ~= 'table' then return nil end
  _core = core
  return _core
end

local function _message(opts)
  opts = opts or {}
  local title = opts.title and (opts.title .. ': ') or ''
  return title .. (opts.message or '')
end

local function _type(opts)
  opts = opts or {}
  local ntype = opts.type or 'primary'
  if ntype == 'info' then return 'primary' end
  if ntype == 'success' then return 'success' end
  if ntype == 'warning' then return 'error' end
  if ntype == 'error' then return 'error' end
  return 'primary'
end

function QbNotify.Show(source, opts)
  source = tonumber(source)
  if not source then return false end
  TriggerClientEvent('QBCore:Notify', source, _message(opts), _type(opts), opts and opts.duration or 5000)
  return true
end

function QbNotify.Broadcast(opts)
  for _, src in ipairs(GetPlayers()) do
    QbNotify.Show(tonumber(src), opts)
  end
  return true
end

function QbNotify.IsAvailable()
  return _get_core() ~= nil
end

Bridges.RegisterAdapter('notify', 'qb', QbNotify)
