local PATTERNS = {
  'AddMoney',
  'RemoveMoney',
  'SetMoney',
  'xPlayer.addAccountMoney',
  'xPlayer.removeAccountMoney',
  'Player.Functions.AddMoney',
  'Player.Functions.RemoveMoney',
  'bank =',
}

local function scan_resource(resource)
  local manifest = LoadResourceFile(resource, 'fxmanifest.lua') or LoadResourceFile(resource, '__resource.lua')
  if not manifest then return nil end
  local hits = {}
  for _, pattern in ipairs(PATTERNS) do
    if manifest:find(pattern, 1, true) then hits[#hits + 1] = pattern end
  end
  return #hits > 0 and hits or nil
end

RegisterCommand('sonar_scan_legacy', function(source)
  if source ~= 0 then return end
  local count = GetNumResources()
  local found = 0
  print('[sonar_bank_app][legacy-scan] scanning resources for likely bank mutation residues')
  for i = 0, count - 1 do
    local resource = GetResourceByFindIndex(i)
    if resource and resource ~= 'sonar_bank_app' then
      local hits = scan_resource(resource)
      if hits then
        found = found + 1
        print(('[sonar_bank_app][legacy-scan] %s: %s'):format(resource, table.concat(hits, ', ')))
      end
    end
  end
  print(('[sonar_bank_app][legacy-scan] complete: %d resource(s) flagged'):format(found))
end, true)
