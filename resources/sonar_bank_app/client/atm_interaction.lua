-- =============================================================================
-- SONAR Bank App — client/atm_interaction.lua
-- =============================================================================
-- Physical ATM interaction layer (F06).
--
--   Multi-target abstraction. The customer's server may run any of:
--     - ox_target        (preferred; modern, ox_lib companion)
--     - qb-target        (QBCore default)
--     - qtarget          (legacy, esx-era)
--   When none is present, falls back to a proximity scan + ox_lib `showTextUI`
--   prompting `[E] Use ATM`. ox_lib is already a hard dependency of this
--   resource so the fallback is always available.
--
--   The interaction emits the local NetEvent declared in `C.ClientEvents.OPEN_ATM`,
--   which `nui_bridge.lua` listens to and uses to open the NUI on /atm.
-- =============================================================================

local Config = BankApp and BankApp.Config
if not Config or not Config.Atm or Config.Atm.EnableInteraction == false then
  return
end

local AtmCfg   = Config.Atm
local OPEN_ATM = (Config.ClientEvents and Config.ClientEvents.OPEN_ATM)
                  or 'sonar:bank:client:open_atm'
local PREFIX   = (Config.Logging and Config.Logging.PREFIX) or '[sonar_bank_app]'

local function _log(msg) print(('%s[atm_interaction] %s'):format(PREFIX, msg)) end

-- -----------------------------------------------------------------------------
-- §1. Common interact handler
-- -----------------------------------------------------------------------------
--   Fires when the player triggers the ATM action (regardless of which target
--   system invoked us). We forward to the local NetEvent so the NUI bridge
--   can open the bank app at /atm with terminal context.
-- -----------------------------------------------------------------------------
local function on_atm_interact(entity)
  local payload = {}
  if entity and entity ~= 0 then
    payload.entity     = entity
    payload.model_hash = GetEntityModel(entity)
    local coords       = GetEntityCoords(entity)
    payload.coords     = { x = coords.x, y = coords.y, z = coords.z }
  end
  TriggerEvent(OPEN_ATM, payload)
end

-- -----------------------------------------------------------------------------
-- §2. Target-system probes
-- -----------------------------------------------------------------------------
--   Each probe returns true if it can register the ATM model interaction with
--   that target system. The first one to succeed wins.
-- -----------------------------------------------------------------------------

local function _has_resource(name)
  return GetResourceState(name) == 'started'
end

local function _hash_models()
  local hashes = {}
  for i = 1, #AtmCfg.PropModels do
    hashes[i] = joaat(AtmCfg.PropModels[i])
  end
  return hashes
end

local function probe_ox_target()
  if not _has_resource('ox_target') then return false end
  local ok, err = pcall(function()
    exports.ox_target:addModel(_hash_models(), {
      {
        name     = 'sonar_bank_atm_use',
        icon     = AtmCfg.Icon or 'fa-solid fa-credit-card',
        label    = AtmCfg.Label or 'Use ATM',
        distance = 2.0,
        onSelect = function(data) on_atm_interact(data and data.entity) end,
      },
    })
  end)
  if not ok then
    _log('ox_target registration failed: ' .. tostring(err))
    return false
  end
  _log('registered with ox_target')
  return true
end

local function probe_qb_target()
  if not _has_resource('qb-target') then return false end
  local ok, err = pcall(function()
    exports['qb-target']:AddTargetModel(_hash_models(), {
      options = {
        {
          icon   = AtmCfg.Icon or 'fa-solid fa-credit-card',
          label  = AtmCfg.Label or 'Use ATM',
          action = function(entity) on_atm_interact(entity) end,
        },
      },
      distance = 2.0,
    })
  end)
  if not ok then
    _log('qb-target registration failed: ' .. tostring(err))
    return false
  end
  _log('registered with qb-target')
  return true
end

local function probe_qtarget()
  if not _has_resource('qtarget') then return false end
  local ok, err = pcall(function()
    exports.qtarget:AddTargetModel(_hash_models(), {
      options = {
        {
          icon   = AtmCfg.Icon or 'fa-solid fa-credit-card',
          label  = AtmCfg.Label or 'Use ATM',
          action = function(entity) on_atm_interact(entity) end,
        },
      },
      distance = 2.0,
    })
  end)
  if not ok then
    _log('qtarget registration failed: ' .. tostring(err))
    return false
  end
  _log('registered with qtarget')
  return true
end

-- -----------------------------------------------------------------------------
-- §3. Fallback — proximity + ox_lib showTextUI
-- -----------------------------------------------------------------------------
--   Adaptive polling: 500ms while no ATM nearby (cheap), 16ms when within
--   detection_radius (so the [E] press feels instant).
-- -----------------------------------------------------------------------------
local function _is_atm_model(model)
  for i = 1, #AtmCfg.PropModels do
    if model == joaat(AtmCfg.PropModels[i]) then return true end
  end
  return false
end

local function _find_nearest_atm(player_coords, max_radius)
  -- GetClosestObjectOfType per model, take the closest match.
  local best_entity, best_dist = 0, max_radius * max_radius
  for i = 1, #AtmCfg.PropModels do
    local ent = GetClosestObjectOfType(
      player_coords.x, player_coords.y, player_coords.z,
      max_radius, joaat(AtmCfg.PropModels[i]), false, false, false)
    if ent ~= 0 then
      local ec = GetEntityCoords(ent)
      local dx, dy, dz = ec.x - player_coords.x, ec.y - player_coords.y, ec.z - player_coords.z
      local d2 = dx * dx + dy * dy + dz * dz
      if d2 < best_dist then
        best_entity, best_dist = ent, d2
      end
    end
  end
  return best_entity
end

local function start_fallback_loop()
  local fb       = AtmCfg.Fallback
  local radius   = fb.detection_radius or 1.6
  local long_ms  = fb.polling_ms or 500
  local short_ms = fb.polling_ms_close or 16
  local open_key = fb.open_key or 38
  local text_ui  = fb.text_ui or '[E] Use ATM'

  local lib = lib  -- ox_lib global
  local ui_open = false

  local function show()
    if ui_open then return end
    if lib and lib.showTextUI then lib.showTextUI(text_ui) else
      -- Last-resort: native HUD print so the user knows the prompt exists
      -- without ox_lib (shouldn't happen since ox_lib is a manifest dep).
      BeginTextCommandDisplayHelp('STRING')
      AddTextComponentSubstringPlayerName(text_ui)
      EndTextCommandDisplayHelp(0, false, true, -1)
    end
    ui_open = true
  end

  local function hide()
    if not ui_open then return end
    if lib and lib.hideTextUI then lib.hideTextUI() end
    ui_open = false
  end

  CreateThread(function()
    _log(('fallback proximity loop active (radius=%.1fm)'):format(radius))
    while true do
      local sleep = long_ms
      local ped   = PlayerPedId()
      local pcoords = GetEntityCoords(ped)
      local atm = _find_nearest_atm(pcoords, radius)

      if atm ~= 0 then
        sleep = short_ms
        show()
        if IsControlJustReleased(0, open_key) then
          hide()
          on_atm_interact(atm)
          -- small cooldown so we don't immediately re-prompt while NUI opens
          Wait(800)
        end
      else
        hide()
      end

      Wait(sleep)
    end
  end)
end

-- -----------------------------------------------------------------------------
-- §4. Bootstrap — pick first available target system
-- -----------------------------------------------------------------------------
local function _resolve_target()
  local order = AtmCfg.TargetPreferenceOrder or {
    'ox_target', 'qb-target', 'qtarget', 'fallback',
  }
  for _, kind in ipairs(order) do
    if kind == 'ox_target' and probe_ox_target() then return 'ox_target' end
    if kind == 'qb-target' and probe_qb_target() then return 'qb-target' end
    if kind == 'qtarget'   and probe_qtarget()   then return 'qtarget'   end
    if kind == 'fallback' then
      start_fallback_loop()
      return 'fallback'
    end
  end
  -- All probes failed and fallback wasn't in the list — start fallback anyway
  -- so the feature is never silently dead.
  start_fallback_loop()
  return 'fallback (forced)'
end

-- -----------------------------------------------------------------------------
-- §5. Map blips
-- -----------------------------------------------------------------------------
--   Best-effort: scan props within streaming distance every 30s and place a
--   short-range blip on each. Light-weight; won't slow down populated zones.
-- -----------------------------------------------------------------------------
local _blipped = {}  -- entity → blip_id

local function _refresh_blips()
  local cfg = AtmCfg.Blips
  if not cfg or cfg.Enabled == false then return end
  local ped = PlayerPedId()
  local pc  = GetEntityCoords(ped)
  for i = 1, #AtmCfg.PropModels do
    local hash = joaat(AtmCfg.PropModels[i])
    -- Multiple ATMs may share a model; iterate via a loop over the closest.
    for _ = 1, 6 do
      local ent = GetClosestObjectOfType(pc.x, pc.y, pc.z, 70.0, hash, false, false, false)
      if ent == 0 or _blipped[ent] then break end
      local b = AddBlipForEntity(ent)
      SetBlipSprite(b, cfg.sprite or 277)
      SetBlipColour(b, cfg.color or 2)
      SetBlipScale(b, cfg.scale or 0.7)
      SetBlipAsShortRange(b, cfg.short_range ~= false)
      BeginTextCommandSetBlipName('STRING')
      AddTextComponentSubstringPlayerName(cfg.label or 'ATM')
      EndTextCommandSetBlipName(b)
      _blipped[ent] = b
      -- Move the player away virtually to find the next closest in next loop.
      pc = vector3(pc.x + 1.0, pc.y, pc.z)
    end
  end
end

local function start_blip_loop()
  if not AtmCfg.Blips or AtmCfg.Blips.Enabled == false then return end
  CreateThread(function()
    Wait(5000)             -- allow streaming to settle on first connect
    while true do
      _refresh_blips()
      Wait(30 * 1000)
    end
  end)
end

-- -----------------------------------------------------------------------------
-- §6. Bootstrap (deferred until QBCore:Client:OnPlayerLoaded — keeps blips
--                from spawning during loading screen).
-- -----------------------------------------------------------------------------
local function bootstrap()
  local resolved = _resolve_target()
  _log(('interaction layer ready (target=%s, props=%d)'):format(
    resolved, #AtmCfg.PropModels))
  start_blip_loop()
end

CreateThread(function()
  -- Defer briefly so target resources (which may load after us) finish init.
  Wait(2000)
  bootstrap()
end)
