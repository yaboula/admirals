local QBCore = exports['qb-core']:GetCoreObject()
local Bail = {}

local function deliveryPay(source, shop)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    -- SONAR_PATCHED v1: S1 orig_line=7
    exports.sonar_bank_app:AddMoney(source, (Config.DeliveryPrice) * 100, 'qb-shops:deliveryPay', nil)
end

RegisterNetEvent('qb-shops:server:DoBail', function(bool)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if bool then
        if Player.Functions.RemoveMoney('cash', Config.TruckDeposit, 'tow-received-bail') then
            Bail[Player.PlayerData.citizenid] = Config.TruckDeposit
        elseif Player.Functions.RemoveMoney('bank', Config.TruckDeposit, 'tow-received-bail') then
            Bail[Player.PlayerData.citizenid] = Config.TruckDeposit
        end
    end
end)
