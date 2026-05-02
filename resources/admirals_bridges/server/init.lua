-- =============================================================================
-- Admirals Bridges — server/init.lua
--
-- Boot orchestration:
--   1. Validate bridges + native adapters todos registrados correctamente.
--   2. ConflictScan (warn) → Run auto-detection → ApplyOverrides.
--   3. SetActive → PrintBootReport.
--
-- Este archivo debe ser EL ÚLTIMO en `server_scripts` del fxmanifest (per
-- doc §2.3), cargado después de todos los bridges + adapters.
--
-- Reference: docs/technical/07_bridges_compatibility.md §10.4 (boot report).
-- =============================================================================

Bridges = Bridges or {}

local Logger = Bridges.Logger

-- -----------------------------------------------------------------------------
-- Helper — PascalCase para lookup Bridges.<Module> tabla.
-- -----------------------------------------------------------------------------
local function _pascal(module)
  return module:sub(1, 1):upper() .. module:sub(2)
end

-- -----------------------------------------------------------------------------
-- _ValidateBridges — asegura que cada módulo tiene:
--   - Bridges.<Module> tabla con _required_methods declarado.
--   - Un adapter 'native' registrado (fallback garantizado).
-- Fallo = error() boot-time (servidor no arranca).
-- -----------------------------------------------------------------------------
local function _ValidateBridges()
  for _, module in ipairs(Config.Modules) do
    local bridge = Bridges[_pascal(module)]
    if type(bridge) ~= 'table' then
      error(('[init] Bridges.%s not loaded — check fxmanifest order'):format(_pascal(module)))
    end
    if type(bridge._required_methods) ~= 'table' then
      error(('[init] Bridges.%s missing _required_methods'):format(_pascal(module)))
    end

    if not Bridges.GetAdapter(module, 'native') then
      error(('[init] Native adapter for "%s" not registered — check fxmanifest load order'):format(module))
    end
  end
end

-- -----------------------------------------------------------------------------
-- Bridges.PrintBootReport — ASCII art config report al console (per doc §10.4).
-- -----------------------------------------------------------------------------
function Bridges.PrintBootReport()
  local active = Bridges._active or {}
  local t1, t2, native_count = 0, 0, 0
  local warnings = 0

  for _, module in ipairs(Config.Modules) do
    local name = active[module] or '?'
    local tier = (Config.AdapterTiers[module] or {})[name] or 'Unknown'
    if tier == 'T1' then t1 = t1 + 1
    elseif tier == 'T2' then t2 = t2 + 1
    elseif tier == 'Native' then native_count = native_count + 1
    else warnings = warnings + 1 end
  end

  local function _tier_tag(tier)
    if tier == 'T1' then return '^2[T1 OFFICIAL]' end
    if tier == 'T2' then return '^3[T2 COMPAT]  ' end
    if tier == 'Native' then return '^8[NATIVE]     ' end
    return '^1[UNKNOWN]    '
  end

  local divider = '^5═══════════════════════════════════════════════════════════^7'
  local thin    = '^5───────────────────────────────────────────────────────────^7'

  print('')
  print(divider)
  print(string.format('^5  Admirals Bridges v%s — Configuration Report^7', Config.Version))
  print(divider)

  for _, module in ipairs(Config.Modules) do
    local name = active[module] or '?'
    local tier = (Config.AdapterTiers[module] or {})[name] or 'Unknown'
    print(string.format('  %-9s → %-18s %s^7',
      _pascal(module), name, _tier_tag(tier)))
  end

  print(thin)
  print(string.format('  Bank mode : %s', Config.BankMode))
  print(string.format('  Log level : %s  |  Boundary[global]: %s',
    Config.LogLevel, Config.LogBoundaryGlobal and 'ON' or 'off'))
  print(thin)
  print(string.format('  ^2T1: %d^7  |  ^3T2: %d^7  |  ^8Native: %d^7  |  Total: %d',
    t1, t2, native_count, #Config.Modules))
  if warnings > 0 then
    print(string.format('  ^1Warnings: %d^7', warnings))
  end
  print(divider)
  print('')
end

-- =============================================================================
-- Boot sequence — deferred 1 tick para asegurar que todos los scripts en
-- `server_scripts` hayan finalizado su load fase.
-- =============================================================================
CreateThread(function()
  -- Yield 1 tick. Permite que los adapters' RegisterAdapter calls (que se
  -- ejecutan sincrónicamente al load) estén completos antes de validación.
  Wait(0)

  Logger.Info('Admirals Bridges v%s booting...', Config.Version)

  -- 1) Structural validation.
  _ValidateBridges()
  Logger.Debug('Bridge interfaces + native adapters validated')

  -- 2) Conflict scan (warn only).
  Bridges.Detect.ConflictScan()

  -- 3) Auto-detection.
  local detected = Bridges.Detect.Run()

  -- 4) Apply overrides (convars + CustomAdapters).
  detected = Bridges.Detect.ApplyOverrides(detected)

  -- 5) Activate.
  Bridges.SetActive(detected)

  -- 6) Boot report.
  Bridges.PrintBootReport()

  -- 7) Mark ready + fire global event para admirals_core (S0.4+).
  Bridges._ready = true
  TriggerEvent('admirals:bridge:ready', detected)
  Logger.Info('Bridges ready. Modules active: %s',
    (function()
      local parts = {}
      for _, m in ipairs(Config.Modules) do
        parts[#parts + 1] = m .. '=' .. (detected[m] or '?')
      end
      return table.concat(parts, ', ')
    end)())
end)

-- -----------------------------------------------------------------------------
-- Bridges.IsReady — para consumers (admirals_core) check antes de usar.
-- -----------------------------------------------------------------------------
function Bridges.IsReady()
  return Bridges._ready == true
end

-- -----------------------------------------------------------------------------
-- Bridges.WaitReady — async-friendly helper para consumers.
-- -----------------------------------------------------------------------------
function Bridges.WaitReady(timeout_ms)
  timeout_ms = timeout_ms or 10000
  local start = GetGameTimer()
  while not Bridges._ready and (GetGameTimer() - start) < timeout_ms do
    Wait(50)
  end
  return Bridges._ready == true
end
