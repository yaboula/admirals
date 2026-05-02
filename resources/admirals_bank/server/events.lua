-- =============================================================================
-- Admirals Bank — server/events.lua
--
-- Helpers de publicación de eventos canónicos via Admirals.Bus.Publish.
-- Centraliza el shape per SSoT `docs/technical/02_events_catalog.md` y evita
-- duplicación de payload assembly en transfer.lua / accounts.lua / etc.
--
-- Publish flow:
--   1. Validate payload shape mínimo (campos required).
--   2. Fill defaults sane (occurred_at = os.time() si missing).
--   3. Admirals.Bus.Publish — auto-decora `_event_name, _event_id, _emitted_at,
--      _schema_version` per `02_events_catalog.md` §1.4.
--   4. Wrap admirals_core en su Bus.Publish ya hace fanout server-wide via
--      TriggerEvent('admirals_lib:dispatch') — los consumers en otros resources
--      reciben automáticamente.
--
-- API pública:
--
--   Events.PublishTransferCompleted(payload)
--     Para C002 transfer success (S1.2). Schema canonical §4.3.
--
--   Events.PublishAccountCreated(payload)        — S1.1, ya emitido desde accounts.lua.
--   Events.PublishStarterBalanceCredited(payload) — S1.1, ya emitido desde accounts.lua.
--
--   (S1.3+) Events.PublishEscrowCreated, PublishEscrowReleased, etc.
--
-- Schema validation:
--   S1.2 enforce shape MÍNIMO via _validate_required (set de campos obligatorios).
--   S2+ podrá usar Admirals.Bus.RegisterSchema con validators tipados completos
--   (ya hay hook BusRegisterSchemaByName en core/init.lua, no-op por ahora).
--
-- Referencias SSoT:
--   docs/technical/02_events_catalog.md §1.4 (auto-decoration tracing keys).
--   docs/technical/02_events_catalog.md §4.3 (transfer_completed payload shape).
--   docs/technical/01_architecture.md §5 (EventBus pub/sub semantics).
-- =============================================================================

Admirals = Admirals or {}
Admirals.Bank = Admirals.Bank or {}
Admirals.Bank.Events = Admirals.Bank.Events or {}

local Config = Admirals.Bank.Config
local Events = Admirals.Bank.Events

-- =============================================================================
-- Internal — _validate_required.
--
-- @param payload table
-- @param required_fields table (array de strings)
-- @return ok:boolean, missing_field:string | nil
-- =============================================================================
local function _validate_required(payload, required_fields)
  if type(payload) ~= 'table' then return false, '<payload>' end
  for _, field in ipairs(required_fields) do
    if payload[field] == nil then return false, field end
  end
  return true
end

-- =============================================================================
-- Public — PublishTransferCompleted.
--
-- Schema canonical per docs/technical/02_events_catalog.md §4.3:
--   {
--     movement_id_from, movement_id_to,    -- (S1.2 omited — INSERT ids no devueltos por TX wrapper)
--     from_iban, to_iban,
--     amount, concept,
--     category, related_doc_id,
--     requester_account_id,
--     occurred_at
--   }
--
-- Field S1.2-specific (additivo, non-breaking vs SSoT):
--   transaction_id : UUID v4 server-generado (también en request_nonce de
--                    ambas movement rows). Permite consumer reconciliar event ↔ ledger
--                    sin necesitar movement_ids.
--
-- movement_id_from/movement_id_to NO se emiten en S1.2 — Admirals.DB.Transaction
-- (oxmysql wrapper) retorna boolean, no insertIds del batch. S2+ podrá hacer
-- post-select via request_nonce + bank_account_id si necesario para downstream
-- (ej. admirals_documents auto-receipt generation).
-- =============================================================================
function Events.PublishTransferCompleted(payload)
  local ok, missing = _validate_required(payload, {
    'transaction_id', 'from_iban', 'to_iban',
    'amount', 'requester_account_id', 'occurred_at',
  })
  if not ok then
    Admirals.Log.Error('PublishTransferCompleted: missing field "%s"', tostring(missing))
    Admirals.Metrics.Counter('bank.events.transfer_completed.invalid_payload')
    return false
  end

  local final_payload = {
    -- SSoT §4.3 canonical fields.
    from_iban             = payload.from_iban,
    to_iban               = payload.to_iban,
    amount                = payload.amount,
    concept               = payload.concept or '',
    category              = payload.category or 'transfer',
    related_doc_id        = payload.related_doc_id,
    requester_account_id  = payload.requester_account_id,
    occurred_at           = payload.occurred_at,
    -- movement_id_from/to omitted (see header note).
    -- S1.2 additivo:
    transaction_id        = payload.transaction_id,
  }

  Admirals.Bus.Publish('admirals:bank:transfer_completed', final_payload, {
    audit = 'always',  -- per SSoT §4.3 "Audit: always"
  })

  Admirals.Metrics.Counter('bank.events.transfer_completed.published')
  return true
end

-- =============================================================================
-- Boot announce.
-- =============================================================================
Admirals.Log.Info('Events module ready (transfer_completed schema §4.3 wired)')
