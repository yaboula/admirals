RegisterNetEvent('qb-vehicleshop:server:financePayment', function(paymentAmount, vehData)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    if player then
        -- SONAR_PATCHED v1: S2 orig_line=5
        local ok_7d873330, _, _ = exports.sonar_bank_app:RemoveMoney(src, (paymentAmount) * 100, 'financed vehicle', nil)
        if ok_7d873330 then
            MySQL.update('UPDATE player_vehicles SET balance = ?', { 0 })
        end
        player.Functions.RemoveMoney('bank', 50, 'literal fee')
    end
end)
