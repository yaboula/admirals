-- =============================================================================
-- SONAR Bank App — callbacks/recipients.lua
-- =============================================================================
-- REQ-FE-002 — Recent recipients + saved recipients management.
--
-- Callbacks (4):
--   C009 sonar:bank:transfer:recentRecipients   — REQ-FE-002 cached p99 < 30ms
--   C010 sonar:bank:recipients:save             — upsert favorite/alias
--   C011 sonar:bank:recipients:delete
--   C012 sonar:bank:recipients:toggleFavorite
-- =============================================================================

local Wrap  = BankApp.callbacks._wrap
local Enums = BankApp.lib.enums

local RecipientsService = BankApp.services.recipients

-- -----------------------------------------------------------------------------
-- C009 — recentRecipients (REQ-FE-002)
-- -----------------------------------------------------------------------------

Wrap.Register('sonar:bank:transfer:recentRecipients', {
  tier  = Enums.TIER.TIER_1_READ,
  cb_id = 'sonar:bank:transfer:recentRecipients',  -- match perf budget bucket name
}, function(src, citizen_id, payload)
  local result, err = RecipientsService.GetRecent(citizen_id)
  if err then return { ok = false, error = err } end
  return result
end)

-- -----------------------------------------------------------------------------
-- C010 — save (upsert with alias + favorite)
-- -----------------------------------------------------------------------------

Wrap.Register('sonar:bank:recipients:save', {
  tier  = Enums.TIER.TIER_2_WRITE,
  cb_id = 'C010',
}, function(src, citizen_id, payload)
  local ok, err = RecipientsService.SaveRecipient(
    citizen_id,
    payload.counterpart_iban,
    payload.alias,
    payload.is_favorite
  )
  if not ok then return { ok = false, error = err } end
  return { saved = true, counterpart_iban = payload.counterpart_iban }
end)

-- -----------------------------------------------------------------------------
-- C011 — delete
-- -----------------------------------------------------------------------------

Wrap.Register('sonar:bank:recipients:delete', {
  tier  = Enums.TIER.TIER_2_WRITE,
  cb_id = 'C011',
}, function(src, citizen_id, payload)
  local ok, err = RecipientsService.DeleteRecipient(citizen_id, payload.counterpart_iban)
  if not ok then return { ok = false, error = err } end
  return { deleted = true, counterpart_iban = payload.counterpart_iban }
end)

-- -----------------------------------------------------------------------------
-- C012 — toggleFavorite
-- -----------------------------------------------------------------------------

Wrap.Register('sonar:bank:recipients:toggleFavorite', {
  tier  = Enums.TIER.TIER_2_WRITE,
  cb_id = 'C012',
}, function(src, citizen_id, payload)
  local ok, err = RecipientsService.ToggleFavorite(
    citizen_id,
    payload.counterpart_iban,
    payload.is_favorite
  )
  if not ok then return { ok = false, error = err } end
  return {
    counterpart_iban = payload.counterpart_iban,
    is_favorite      = payload.is_favorite and true or false,
  }
end)
