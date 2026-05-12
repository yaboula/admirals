Bridges = Bridges or {}

Bridges.LiteMode = Bridges.LiteMode or {}

function Bridges.LiteMode.IsActive()
  local health = Bridges.CoreOverride and Bridges.CoreOverride.GetHealth and Bridges.CoreOverride.GetHealth() or {}
  return health.active_bank == 'esx' and health.esx_registered == true
end

function Bridges.LiteMode.GetStatus()
  local health = Bridges.CoreOverride and Bridges.CoreOverride.GetHealth and Bridges.CoreOverride.GetHealth() or {}
  return {
    active = health.active_bank == 'esx' and health.esx_registered == true,
    framework = health.active_bank,
    reconcile = health.reconcile,
  }
end

exports('GetLiteModeStatus', function()
  return Bridges.LiteMode.GetStatus()
end)
