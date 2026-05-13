RegisterNetEvent('qb-vehicleshop:server:financePayment', function(paymentAmount, vehData)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    if player then
        if player.Functions.RemoveMoney('bank', paymentAmount, 'financed vehicle') then
            MySQL.update('UPDATE player_vehicles SET balance = ?', { 0 })
        end
        player.Functions.RemoveMoney('bank', 50, 'literal fee')
    end
end)
