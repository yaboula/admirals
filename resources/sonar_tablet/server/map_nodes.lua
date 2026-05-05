-- =============================================================================
-- SONAR Tablet — server/map_nodes.lua
-- =============================================================================
-- S2.5 scope: NUI bridge ad-hoc `sonar:tablet:map:getNodes` (consumer pattern
-- temporal per SPRINT_PLAN_S2 §2.2.3 + R8 DEFERRED catalog promotion S3+).
--
-- ⚠️  R8 mitigation (SPRINT_PLAN_S2 §9):
--   POIs admin-seed vía Config.MapPOIs S2. Futuro S3+ = DB table
--   `sonar_map_pois` + callback firmable `sonar:map:getPois` → swap
--   implementación interna de `getNodesDirect()` sin cambiar NUI contract.
--
-- ⚠️  DEFERRED catalog promotion (SPRINT_PLAN_S2 §2.2.3):
--   NO documentar en `docs/technical/02_events_catalog.md` v1.2 hasta S3+.
--
-- Flow:
--   1. Resolve source → citizen_id via cache local (SONAR.Identity hooks —
--      mismo pattern que server/bank_history.lua:41-60).
--   2. Rate-limit bucket 'tablet.query' (60/10s — registered en
--      sonar_core/config.lua:120 — NO re-register).
--   3. Iterar Config.MapPOIs + filtrar visible=true.
--   4. Audit log category 'tablet.read' action 'map_nodes' (frecuencia baja OK).
--   5. Return { success, data: { nodes, count, seed_version } } | error.
--
-- Referencias SSoT:
--   progress/SPRINT_PLAN_S2.md §2.2.3 (NUI bridge ad-hoc DEFERRED).
--   progress/SPRINT_PLAN_S2.md §9 R8 (DB promotion tech debt S3+).
--   progress/SPRINT_PLAN_S2.md §3 DC7b (≤500ms response budget).
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Cache source ↔ citizen_id — mismo pattern bank_history.lua:41-60.
-- -----------------------------------------------------------------------------
local _src_to_cid = {}

SONAR.Identity.OnPlayerLoaded(function(citizenId, source)
  if type(source) == 'number' and source > 0 and type(citizenId) == 'string' then
    _src_to_cid[source] = citizenId
  end
end)

SONAR.Identity.OnPlayerDropped(function(_, source)
  if type(source) == 'number' then
    _src_to_cid[source] = nil
  end
end)

---Resolve FiveM source to citizen_id via local cache.
---@param source number
---@return string|nil citizen_id
local function _get_citizen_id(source)
  return _src_to_cid[tonumber(source) or -1]
end

-- -----------------------------------------------------------------------------
-- Error response helper — shape canónica alineada bank_history.lua:65-67.
-- -----------------------------------------------------------------------------
local function _err(code, message)
  return { success = false, error_code = code, message = message }
end

-- -----------------------------------------------------------------------------
-- Seed version hash — cambia al mutar Config.MapPOIs (boot-time cache invalidate
-- en React si necesario). Simple count+length-based suficiente S2 (admin-seed).
-- -----------------------------------------------------------------------------
local function _compute_seed_version()
  local pois = Config.MapPOIs or {}
  local sum = 0
  for i = 1, #pois do
    local p = pois[i]
    if p and p.id then
      sum = sum + #p.id + (p.world_x or 0) + (p.world_y or 0)
    end
  end
  return ('s2-%d-%d'):format(#pois, math.floor(sum))
end

local _seed_version = _compute_seed_version()

-- =============================================================================
-- getNodesDirect() — internal wrapper.
--
-- TODO R8 (SPRINT_PLAN_S2 §9): swap internal implementation a
--   `SONAR.DB.FetchAll('SELECT * FROM sonar_map_pois WHERE visible=1')` cuando
--   migration sonar_map_pois ship S3+. NUI contract `sonar:tablet:map:getNodes`
--   se mantiene estable — MapApp React no requiere cambio consumer.
--
-- @return table response (success=true/false)
-- =============================================================================
local function getNodesDirect()
  local raw = Config.MapPOIs or {}
  local nodes = {}
  for i = 1, #raw do
    local p = raw[i]
    if p and p.visible ~= false and p.id and p.world_x and p.world_y then
      nodes[#nodes + 1] = {
        id       = tostring(p.id),
        label    = tostring(p.label or p.id),
        category = tostring(p.category or 'generic'),
        world_x  = tonumber(p.world_x) or 0.0,
        world_y  = tonumber(p.world_y) or 0.0,
        visible  = true,
      }
    end
  end

  return {
    success = true,
    data = {
      nodes        = nodes,
      count        = #nodes,
      seed_version = _seed_version,
    },
  }
end

-- =============================================================================
-- lib.callback.register — `sonar:tablet:map:getNodes`.
--
-- Request:  {} (sin params S2 — filtros category/radius S3+).
-- Response: { success=true, data: { nodes, count, seed_version } }
--           | { success=false, error_code, message }
-- =============================================================================
lib.callback.register('sonar:tablet:map:getNodes', function(source, _request)
  local start_ms = GetGameTimer()

  -- 1. Auth.
  local citizen_id = _get_citizen_id(source)
  if not citizen_id then
    SONAR.Metrics.Counter('tablet.map_nodes.not_authenticated')
    return _err('NOT_AUTHENTICATED', 'Player session not loaded')
  end

  -- 2. Rate limit (bucket 'tablet.query' — 60/10s — reutilizado, NO re-register).
  local rate_ok, rate_allowed = pcall(SONAR.Rate.Check, citizen_id, 'tablet.query')
  if not rate_ok or rate_allowed ~= true then
    if not rate_ok then
      SONAR.Log.Warn('SONAR.Rate.Check threw (tablet map_nodes): %s — fail-closed',
        tostring(rate_allowed))
    end
    SONAR.Metrics.Counter('tablet.map_nodes.rate_limited')
    return _err('RATE_LIMITED', 'Demasiadas consultas. Espera un momento.')
  end

  -- 3. Build response (R8 swap-point).
  local response = getNodesDirect()

  -- 4. Audit log.
  SONAR.Log.Audit({
    category = 'tablet.read',
    action   = 'map_nodes',
    actor    = citizen_id,
    target   = nil,
    payload  = {
      source       = source,
      returned     = (response.success and response.data and response.data.count) or 0,
      seed_version = (response.success and response.data and response.data.seed_version) or nil,
      success      = response.success,
      err          = response.error_code,
    },
  })

  -- 5. Metrics + DC7b warn.
  local duration_ms = GetGameTimer() - start_ms
  SONAR.Metrics.Observe('tablet.map_nodes.duration_ms', duration_ms)
  if duration_ms > 500 then
    SONAR.Log.Warn('tablet.map_nodes exceeded DC7b budget (%dms > 500ms)', duration_ms)
  end
  if response.success then
    SONAR.Metrics.Counter('tablet.map_nodes.ok')
  end

  return response
end)

-- =============================================================================
-- Boot announce.
-- =============================================================================
print(('[sonar_tablet] map_nodes callback registered (sonar:tablet:map:getNodes — %d POIs admin-seed, version=%s, R8 tech debt until DB S3+)'):format(
  #(Config.MapPOIs or {}),
  _seed_version
))
