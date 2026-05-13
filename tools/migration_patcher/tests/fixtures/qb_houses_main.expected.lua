RegisterNetEvent('qb-houses:server:buyHouse', function(house)
    local src = source
    local pData = QBCore.Functions.GetPlayer(src)
    local HousePrice = math.ceil(Config.Houses[house].price * 1.21)
    -- SONAR_PATCHED v1: S1 orig_line=5
    exports.sonar_bank_app:RemoveMoney(src, (HousePrice) * 100, 'bought-house', nil)
    exports['qb-banking']:AddMoney('realestate', HousePrice, 'House purchase')
end)

QBCore.Functions.CreateCallback('qb-houses:server:buyFurniture', function(source, cb, price)
    local src = source
    local pData = QBCore.Functions.GetPlayer(src)
    -- SONAR_PATCHED v1: S1 orig_line=12
    exports.sonar_bank_app:RemoveMoney(src, (price) * 100, 'bought-furniture', nil)
end)
