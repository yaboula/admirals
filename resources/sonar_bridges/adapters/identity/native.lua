-- =============================================================================
-- SONAR Bridges — adapters/identity/native.lua
--
-- Adapter NATIVE (fallback) para Identity.
--
-- Comportamiento (per doc §7.4 + §11.2):
--   Usa `GetPlayerIdentifiers(source)` directamente. `license:xxxx` prefix
--   stripped → usado como `citizenId`. Permite SONAR standalone sin
--   framework externo.
--
-- Lifecycle:
--   'playerJoining' + `Wait(500)` para que identifiers estén ready → fire
--   'sonar:bridge:_identityPlayerLoaded'.
--   'playerDropped' → fire 'sonar:bridge:_identityPlayerDropped'.
--
-- Limitaciones (per doc §11.2):
--   - No jobs/charinfo framework-level (GetJob returns nil).
--   - firstname/lastname default a "Native"/"Player".
--
-- Referencias SSoT:
--   docs/technical/07_bridges_compatibility.md §7.2, §7.4, §11.2.
-- =============================================================================

local Logger = Bridges.Logger
local NativeIdentity = {}

-- Caches bidireccionales. Invalidated en playerDropped.
local _src_to_cid = {}   -- [source] = citizenId
local _cid_to_src = {}   -- [citizenId] = source

-- -----------------------------------------------------------------------------
-- Helper — extract license from identifiers. Preferimos license2 (rockstar
-- stable) si existe, sino license clásico.
-- -----------------------------------------------------------------------------
local function _extract_license(source)
  local ids = GetPlayerIdentifiers(source)
  if not ids then return nil end
  local license, license2
  for _, id in ipairs(ids) do
    if id:sub(1, 9) == 'license2:' then
      license2 = id:sub(10)
    elseif id:sub(1, 8) == 'license:' then
      license = id:sub(9)
    end
  end
  return license2 or license
end

-- -----------------------------------------------------------------------------
-- GetCitizenId — cache-first, fallback to GetPlayerIdentifiers.
-- -----------------------------------------------------------------------------
function NativeIdentity.GetCitizenId(source)
  source = tonumber(source)
  if not source or source <= 0 then return nil end
  if _src_to_cid[source] then return _src_to_cid[source] end

  local license = _extract_license(source)
  if not license then return nil end

  _src_to_cid[source] = license
  _cid_to_src[license] = source
  return license
end

-- -----------------------------------------------------------------------------
-- GetSource — cache-first, fallback O(n) scan GetPlayers().
-- -----------------------------------------------------------------------------
function NativeIdentity.GetSource(citizenId)
  if type(citizenId) ~= 'string' or citizenId == '' then return nil end
  if _cid_to_src[citizenId] then
    -- Verify source still online
    if GetPlayerPing(_cid_to_src[citizenId]) > 0 then
      return _cid_to_src[citizenId]
    end
    _cid_to_src[citizenId] = nil
  end

  -- Rebuild cache via scan.
  for _, src_str in ipairs(GetPlayers()) do
    local src = tonumber(src_str)
    local cid = NativeIdentity.GetCitizenId(src)
    if cid == citizenId then return src end
  end
  return nil
end

-- -----------------------------------------------------------------------------
-- GetPlayerData — shape minimal consistent con doc §7.2.
-- -----------------------------------------------------------------------------
function NativeIdentity.GetPlayerData(citizenId)
  local src = NativeIdentity.GetSource(citizenId)
  if not src then return nil end
  return {
    citizenId = citizenId,
    source = src,
    firstname = 'Native',
    lastname = 'Player',
    charinfo = nil,
    name = GetPlayerName(src),
  }
end

-- -----------------------------------------------------------------------------
-- GetJob — native no tiene framework jobs.
-- -----------------------------------------------------------------------------
function NativeIdentity.GetJob(citizenId)
  return nil
end

-- -----------------------------------------------------------------------------
-- IsOnline
-- -----------------------------------------------------------------------------
function NativeIdentity.IsOnline(citizenId)
  return NativeIdentity.GetSource(citizenId) ~= nil
end

-- -----------------------------------------------------------------------------
-- IsAvailable — native siempre disponible.
-- -----------------------------------------------------------------------------
function NativeIdentity.IsAvailable()
  return true
end

-- =============================================================================
-- Lifecycle hooks — fire eventos internos consumidos por bridges/identity.lua.
-- Solo fire si este adapter es el activo (no queremos duplicate events con
-- adapter externo). Check `Bridges._active.identity == 'native'` en runtime.
-- =============================================================================

local function _is_active()
  return Bridges._active and Bridges._active.identity == 'native'
end

AddEventHandler('playerJoining', function(source, oldId)
  -- source aquí es el temporary id del player joining. Puede quedar invalidado
  -- si reconecta — por eso usamos CreateThread + Wait para settling.
  local src = source
  CreateThread(function()
    Wait(500)  -- identifiers settling
    if not _is_active() then return end
    local cid = NativeIdentity.GetCitizenId(src)
    if cid then
      TriggerEvent('sonar:bridge:_identityPlayerLoaded', cid, src)
      Logger.Debug('NativeIdentity: player loaded src=%d cid=%s', src, cid)
    else
      Logger.Warn('NativeIdentity: could not resolve citizenId for source %d', src)
    end
  end)
end)

AddEventHandler('playerDropped', function(reason)
  if not _is_active() then return end
  local src = source  -- FiveM convention: playerDropped runs in context of dropping player
  local cid = _src_to_cid[src]
  if cid then
    TriggerEvent('sonar:bridge:_identityPlayerDropped', cid, src, reason or 'unknown')
    Logger.Debug('NativeIdentity: player dropped src=%d cid=%s reason=%s',
      src, cid, tostring(reason))
    _src_to_cid[src] = nil
    _cid_to_src[cid] = nil
  end
end)

-- -----------------------------------------------------------------------------
-- Debug helpers
-- -----------------------------------------------------------------------------

function NativeIdentity._DumpCache()
  local snap = { by_source = {}, by_citizen = {} }
  for k, v in pairs(_src_to_cid) do snap.by_source[k] = v end
  for k, v in pairs(_cid_to_src) do snap.by_citizen[k] = v end
  return snap
end

function NativeIdentity._Reset()
  _src_to_cid = {}
  _cid_to_src = {}
end

Bridges.RegisterAdapter('identity', 'native', NativeIdentity)
