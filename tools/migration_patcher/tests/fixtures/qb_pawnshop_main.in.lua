RegisterNetEvent('qb-pawnshop:server:sellPawnItems', function(itemName, itemAmount, itemPrice)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local totalPrice = (tonumber(itemAmount) * itemPrice)
    if Config.BankMoney then
        Player.Functions.AddMoney('bank', totalPrice, 'qb-pawnshop:server:sellPawnItems')
    else
        Player.Functions.AddMoney('cash', totalPrice, 'qb-pawnshop:server:sellPawnItems')
    end
end)
