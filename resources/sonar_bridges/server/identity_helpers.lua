Bridges = Bridges or {}
Bridges.Identity = Bridges.Identity or {}

local loaded_by_source = {}
local loaded_by_citizen = {}

local function mark_loaded(citizen_id, src)
  src = tonumber(src)
  if type(citizen_id) ~= 'string' or citizen_id == '' or not src or src <= 0 then return end
  loaded_by_source[src] = citizen_id
  loaded_by_citizen[citizen_id] = src
end

local function mark_unloaded(citizen_id, src)
  src = tonumber(src)
  if src then loaded_by_source[src] = nil end
  if type(citizen_id) == 'string' then loaded_by_citizen[citizen_id] = nil end
end

AddEventHandler('sonar:bridge:_identityPlayerLoaded', function(citizen_id, src)
  mark_loaded(citizen_id, src)
end)

AddEventHandler('sonar:bridge:_identityPlayerDropped', function(citizen_id, src)
  mark_unloaded(citizen_id, src)
end)

AddEventHandler('playerDropped', function()
  local src = source
  local citizen_id = loaded_by_source[src]
  mark_unloaded(citizen_id, src)
end)

function Bridges.Identity.IsLoaded(value)
  if type(value) == 'number' then
    if loaded_by_source[value] then return true end
    local cid = Bridges.Identity.GetCitizenId and Bridges.Identity.GetCitizenId(value) or nil
    if type(cid) == 'string' and cid ~= '' then
      mark_loaded(cid, value)
      return true
    end
    return false
  end
  if type(value) == 'string' then
    if loaded_by_citizen[value] then return true end
    local src = Bridges.Identity.GetSource and Bridges.Identity.GetSource(value) or nil
    if type(src) == 'number' and src > 0 then
      mark_loaded(value, src)
      return true
    end
  end
  return false
end

function Bridges.Identity.GetLoadedSnapshot()
  local by_source, by_citizen = {}, {}
  for src, cid in pairs(loaded_by_source) do by_source[src] = cid end
  for cid, src in pairs(loaded_by_citizen) do by_citizen[cid] = src end
  return { by_source = by_source, by_citizen = by_citizen }
end

exports('IsIdentityLoaded', function(value)
  return Bridges.Identity.IsLoaded(value)
end)
