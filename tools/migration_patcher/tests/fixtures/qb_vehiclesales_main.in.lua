RegisterNetEvent('qb-occasions:server:buyVehicle', function(vehicleData)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local SellerCitizenId = result[1].seller
    local SellerData = QBCore.Functions.GetPlayerByCitizenId(SellerCitizenId)
    local NewPrice = math.ceil((result[1].price / 100) * 77)
    Player.Functions.RemoveMoney('bank', result[1].price, 'bought vehicle used lot')
    if SellerData then
        SellerData.Functions.AddMoney('bank', NewPrice, 'sold vehicle used lot')
    end
    MySQL.update('UPDATE players SET money = ? WHERE citizenid = ?', { json.encode(BuyerMoney), SellerCitizenId })
end)
