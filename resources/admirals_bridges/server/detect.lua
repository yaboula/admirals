-- =============================================================================
-- Admirals Bridges — server/detect.lua
--
-- Auto-detection de scripts externos al boot + apply convar/config overrides.
--
-- Flujo (invocado por server/init.lua):
--   1. Run()           — escanea priority list per módulo, primer match gana.
--   2. ApplyOverrides()— convars `admirals_bridge_<module>` + CustomAdapters.
--   3. ConflictScan()  — warn si >1 resource started para mismo módulo.
--
-- Reference: docs/technical/07_bridges_compatibility.md §10.1, §10.2, §10.3.
-- =============================================================================

Bridges = Bridges or {}
Bridges.Detect = {}

local Logger = Bridges.Logger

-- -----------------------------------------------------------------------------
-- Bridges.Detect.Run — scan priority list, first match wins.
--
-- Criterios match:
--   1. Config.AdapterResourceMap[adapter_name] define resource.
--   2. GetResourceState(resource) == 'started'.
--   3. Adapter registrado via Bridges.GetAdapter(module, name).
--   4. adapter.IsAvailable() == true.
--
-- @return table { [module] = adapter_name }
-- -----------------------------------------------------------------------------
function Bridges.Detect.Run()
  local detected = {}

  for _, module in ipairs(Config.Modules) do
    detected[module] = 'native'  -- default

    local priority = Config.DetectionPriority[module] or {}
    for _, adapter_name in ipairs(priority) do
      local resource_name = Config.AdapterResourceMap[adapter_name]
      if resource_name then
        local state = GetResourceState(resource_name)
        if state == 'started' then
          local impl = Bridges.GetAdapter(module, adapter_name)
          if impl and type(impl.IsAvailable) == 'function' then
            local ok, available = pcall(impl.IsAvailable)
            if ok and available then
              detected[module] = adapter_name
              Logger.Debug('Detect: %s → %s (resource %s started)',
                module, adapter_name, resource_name)
              break
            else
              Logger.Warn('Detect: %s/%s resource started but IsAvailable returned %s',
                module, adapter_name, tostring(available))
            end
          else
            -- Adapter no registrado en este release (T2+ vendrán en S0.3+).
            Logger.Debug('Detect: resource %s started but adapter %s/%s not registered (skipped)',
              resource_name, module, adapter_name)
          end
        end
      end
    end
  end

  return detected
end

-- -----------------------------------------------------------------------------
-- Bridges.Detect.ApplyOverrides — convar overrides + Config.CustomAdapters.
--
-- Precedencia (más alto primero):
--   1. Config.CustomAdapters (SDK T3 registered).
--   2. Convar admirals_bridge_<module>.
--   3. Auto-detection result.
--
-- @param detected table — result de Bridges.Detect.Run().
-- @return table — detected mutated con overrides aplicados.
-- -----------------------------------------------------------------------------
function Bridges.Detect.ApplyOverrides(detected)
  -- (2) Convar overrides
  for _, module in ipairs(Config.Modules) do
    local override = GetConvar('admirals_bridge_' .. module, '')
    if override ~= '' then
      if Bridges.GetAdapter(module, override) then
        if detected[module] ~= override then
          Logger.Info('Override[convar] %s: %s → %s', module, detected[module], override)
        end
        detected[module] = override
      else
        Logger.Warn('Override[convar] admirals_bridge_%s=%s: adapter not registered, keeping "%s"',
          module, override, detected[module])
      end
    end
  end

  -- (1) Config.CustomAdapters — highest precedence (SDK T3).
  for module, name in pairs(Config.CustomAdapters or {}) do
    if type(module) == 'string' and type(name) == 'string' then
      if Bridges.GetAdapter(module, name) then
        Logger.Info('Override[custom] %s: %s → %s', module, detected[module] or 'none', name)
        detected[module] = name
      else
        Logger.Warn('Override[custom] %s=%s: adapter not registered, ignoring',
          module, name)
      end
    end
  end

  return detected
end

-- -----------------------------------------------------------------------------
-- Bridges.Detect.ConflictScan — detecta múltiples resources del mismo módulo
-- started. Warn-only (per doc §10.3, primero en priority wins).
-- -----------------------------------------------------------------------------
function Bridges.Detect.ConflictScan()
  for _, module in ipairs(Config.Modules) do
    local started = {}
    for _, adapter_name in ipairs(Config.DetectionPriority[module] or {}) do
      local resource_name = Config.AdapterResourceMap[adapter_name]
      if resource_name and GetResourceState(resource_name) == 'started' then
        started[#started + 1] = string.format('%s(%s)', adapter_name, resource_name)
      end
    end
    if #started > 1 then
      Logger.Warn('Conflict[%s]: multiple resources started [%s], first-priority wins. '
        .. 'Use convar admirals_bridge_%s to override.',
        module, table.concat(started, ', '), module)
    end
  end
end
