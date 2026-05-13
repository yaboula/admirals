RegisterNetEvent('qb-occasions:server:buyVehicle', function(vehicleData)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local SellerCitizenId = result[1].seller
    local SellerData = QBCore.Functions.GetPlayerByCitizenId(SellerCitizenId)
    local NewPrice = math.ceil((result[1].price / 100) * 77)
    -- SONAR_PATCHED v1: S1 orig_line=7
    exports.sonar_bank_app:RemoveMoney(src, (result[1].price) * 100, 'bought vehicle used lot', nil)
    if SellerData then
        -- SONAR_PATCHED v1: S1 orig_line=9
        exports.sonar_bank_app:AddMoney(SellerData.PlayerData.source, (NewPrice) * 100, 'sold vehicle used lot', nil)
    end
    MySQL.update('UPDATE players SET money = ? WHERE citizenid = ?', { json.encode(BuyerMoney), SellerCitizenId })
end)
