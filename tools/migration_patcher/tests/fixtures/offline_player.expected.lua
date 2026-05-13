local Offline = QBCore.Functions.GetOfflinePlayer(citizenid)
-- SONAR_PATCHED v1: S3 orig_line=2
exports.sonar_bank_app:AddMoneyByCitizen(citizenid, (amount) * 100, 'offline-pay', nil)
