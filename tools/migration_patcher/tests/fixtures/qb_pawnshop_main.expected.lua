RegisterNetEvent('qb-pawnshop:server:sellPawnItems', function(itemName, itemAmount, itemPrice)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local totalPrice = (tonumber(itemAmount) * itemPrice)
    if Config.BankMoney then
        -- SONAR_PATCHED v1: S1 orig_line=6
        exports.sonar_bank_app:AddMoney(src, (totalPrice) * 100, 'qb-pawnshop:server:sellPawnItems', nil)
    else
        Player.Functions.AddMoney('cash', totalPrice, 'qb-pawnshop:server:sellPawnItems')
    end
end)
