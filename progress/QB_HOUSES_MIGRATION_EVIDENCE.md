# qb-houses SONAR Bank Migration Evidence

## Resource-Level Checklist (per SONAR_BANK_QBCORE_MIGRATION_GUIDE.md)

- [x] Make backup: `server/main.lua.bak` created at `D:\FiveM_Server\Sonar_phase5c\resources\[qb]\qb-houses\server\`
- [x] Search all bank call sites: Found 3 patterns (2 migrated, 1 removed)
- [x] Classify each call site: Both classified as CRITICAL/Bucket C
- [x] Apply safe replacements: N/A (both required manual rewrite)
- [x] Manually rewrite Bucket C flows: Both flows rewritten
- [x] Ensure fxmanifest.lua depends on sonar_bank_app: Already present (line 43)
- [ ] Restart only the changed resource: PENDING (requires runtime)
- [ ] Check server console for Lua parse errors: PENDING (requires runtime)
- [ ] Run one positive test: PENDING (requires runtime)
- [ ] Run one negative test with insufficient funds: PENDING (requires runtime)
- [ ] Confirm no item/vehicle/house is granted when debit fails: PENDING (requires runtime)
- [ ] Confirm audit/movement rows: PENDING (requires runtime)
- [ ] Confirm HUD/UI behavior or document compatibility gap: PENDING (requires runtime)

## QA Evidence Template

### Flow 1: House Purchase (buyHouse)

**Resource:** qb-houses  
**File:** server/main.lua  
**Flow/event:** RegisterNetEvent('qb-houses:server:buyHouse')  
**Risk level:** CRITICAL (Bucket C)  
**Migration type:** Manual rewrite

**Player source:** PENDING runtime test  
**Citizen ID:** PENDING runtime test  
**Account status:** PENDING runtime test

**Before balance_minor:** PENDING runtime test  
**Action:** Purchase house via realestate  
**Expected delta_minor:** -HousePrice * 100  
**After balance_minor:** PENDING runtime test

**Audit evidence:** PENDING runtime test  
**Movement evidence:** PENDING runtime test  
**DB/ownership evidence:** PENDING runtime test  
**HUD/UI result:** PENDING runtime test

**Positive path:** PENDING  
**Negative insufficient funds path:** PENDING  
**Negative frozen account path:** PENDING  
**Notes:** Migration follows guide template: debit before irreversible effects (MySQL.insert/update, ownership assignment, client events). Removed QBCore pre-gate `bankBalance >= HousePrice`. Added SONAR RemoveMoney with ok check. Realestate commission payout via qb-banking commented out (Phase A scope: player bank only - qb-banking export not available).

### Flow 2: Furniture Purchase (buyFurniture)

**Resource:** qb-houses  
**File:** server/main.lua  
**Flow/event:** QBCore.Functions.CreateCallback('qb-houses:server:buyFurniture')  
**Risk level:** CRITICAL (Bucket C)  
**Migration type:** Manual rewrite (fixed existing partial patch)

**Player source:** PENDING runtime test  
**Citizen ID:** PENDING runtime test  
**Account status:** PENDING runtime test

**Before balance_minor:** PENDING runtime test  
**Action:** Buy furniture item  
**Expected delta_minor:** -price * 100  
**After balance_minor:** PENDING runtime test

**Audit evidence:** PENDING runtime test  
**Movement evidence:** PENDING runtime test  
**DB/ownership evidence:** PENDING runtime test  
**HUD/UI result:** PENDING runtime test

**Positive path:** PENDING  
**Negative insufficient funds path:** PENDING  
**Negative frozen account path:** PENDING  
**Notes:** Removed QBCore pre-gate `bankBalance >= price`. Fixed existing SONAR patch which lacked ok check. Added SONAR RemoveMoney with ok check before callback(true).

## Migration Summary

### Patterns Found (Original)
1. Line 243: `local bankBalance = pData.PlayerData.money['bank']` - pre-gate QBCore (buyHouse)
2. Line 262: `pData.Functions.RemoveMoney('bank', HousePrice, 'bought-house')` - debit AFTER irreversible effects (buyHouse)
3. Line 413: `local bankBalance = pData.PlayerData.money['bank']` - pre-gate QBCore (buyFurniture)
4. Line 417: `exports.sonar_bank_app:RemoveMoney(src, (price) * 100, 'bought-furniture', nil)` - partial patch without ok check (buyFurniture)

### Changes Applied

#### buyHouse (lines 238-275)
- Removed: `local bankBalance = pData.PlayerData.money['bank']`
- Removed: `if (bankBalance >= HousePrice) then` pre-gate
- Added: SONAR debit before irreversible effects
  ```lua
  local amountMinor = HousePrice and math.floor(HousePrice * 100) or nil
  local ok, err, data = exports.sonar_bank_app:RemoveMoney(src, amountMinor, 'bought-house', nil)
  if not ok then
      print(('[sonar_migration] house purchase debit failed src=%s house=%s amount_minor=%s err=%s'):format(...))
      TriggerClientEvent('QBCore:Notify', src, Lang:t('error.not_enough_money'), 'error')
      return
  end
  ```
- Moved: All irreversible effects (ownership assignment, MySQL.insert/update, client events) AFTER ok check
- Commented: realestate commission payout via exports['qb-banking']:AddMoney (Phase A scope: player bank only, qb-banking export not available)

#### buyFurniture (lines 416-433)
- Removed: `local bankBalance = pData.PlayerData.money['bank']`
- Removed: `if bankBalance >= price then` pre-gate
- Fixed: SONAR patch to include ok check
  ```lua
  local amountMinor = price and math.floor(price * 100) or nil
  local ok, err, data = exports.sonar_bank_app:RemoveMoney(src, amountMinor, 'bought-furniture', nil)
  if not ok then
      print(('[sonar_migration] furniture purchase debit failed src=%s amount_minor=%s err=%s'):format(...))
      TriggerClientEvent('QBCore:Notify', src, Lang:t('error.not_enough_money'), 'error')
      cb(false)
      return
  end
  cb(true)
  ```

### Verification (Static)
- [x] No remaining QBCore bank patterns: grep confirmed 0 matches
- [x] SONAR exports present: 2 calls to exports.sonar_bank_app:RemoveMoney
- [x] fxmanifest dependency: sonar_bank_app present (line 43)
- [x] Units conversion: math.floor(amount * 100) for minor units
- [x] Error handling: ok check with print diagnostic and user notification
- [x] Backup created: server/main.lua.bak

### Next Steps (Runtime Validation)
1. Restart qb-houses resource: `restart qb-houses`
2. Check server console for Lua parse errors
3. Positive test: Purchase house with sufficient SONAR balance
4. Negative test: Attempt purchase with insufficient funds
5. Negative test: Attempt purchase with frozen account
6. Verify audit/movement rows via qa_audit commands
7. Verify no house ownership granted on failed debit
8. Document HUD/UI behavior if needed
