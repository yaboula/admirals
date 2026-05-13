RegisterNetEvent('qb-houses:server:buyHouse', function(house)
    local src = source
    local pData = QBCore.Functions.GetPlayer(src)
    local HousePrice = math.ceil(Config.Houses[house].price * 1.21)
    pData.Functions.RemoveMoney('bank', HousePrice, 'bought-house')
    exports['qb-banking']:AddMoney('realestate', HousePrice, 'House purchase')
end)

QBCore.Functions.CreateCallback('qb-houses:server:buyFurniture', function(source, cb, price)
    local src = source
    local pData = QBCore.Functions.GetPlayer(src)
    pData.Functions.RemoveMoney('bank', price, 'bought-furniture')
end)
