-- =============================================================================
-- SONAR Bank — server/transfer.lua
--
-- Lógica core de transferencias player→player (callback C002 backend).
--
-- Atomicidad (S1.2 fix-and-validate — Opción D pura):
--   `SONAR.DB.Transaction` envuelve 4 queries en una MySQL TX:
--     1. UPDATE sonar_bank_accounts (debit from)
--     2. UPDATE sonar_bank_accounts (credit to)
--     3. INSERT sonar_bank_movements (row debe — amount negativo)
--     4. INSERT sonar_bank_movements (row haber — amount positivo)
--   Cualquier SQL error en cualquier query → rollback automático per
--   MySQL.transaction (oxmysql wrapper). 2 rows compartiendo request_nonce =
--   transaction_id permite reconstrucción + reconciliación lineage post-mortem.
--
-- Atomicity guarantee:
--   CHECK constraint chk_sonar_bank_accounts_balance_nonneg (migration 005)
--   garantiza balance >= 0 SQL-side. UPDATE Q1 hace `balance = balance - amount`
--   sin `WHERE balance >= ?`: si una operación concurrente vacía el saldo entre
--   nuestro pre-fetch y el UPDATE, MySQL throws CHECK violation → toda la TX
--   rollback automático per oxmysql native behavior. Ledger queda 100%
--   consistente. Pre-flight check (line ~165) sigue para UX (evita TX attempt
--   innecesaria en happy path overdraw — devuelve INSUFFICIENT_FUNDS direct).
--
--   oxmysql NO soporta function-form transaction con handle (verificado vía
--   doc /Functions/transaction). CHECK constraint es upstream root cause fix.
--
-- Fee policy (S1.2):
--   Internal transfer fee = 0 € per SSoT economy/01_economic_model.md §10.3:697.
--   Fees retornados en response (fee_retained=0) preservan shape canónico §3.1
--   para forward-compat con S1.3 escrow fees y S2+ external transfer fees.
--
-- Referencias SSoT:
--   docs/technical/04_api_contracts.md §3.1 C002 (signature + errors).
--   docs/technical/03_db_schema.md §4.2 (sonar_bank_movements signed amount).
--   docs/technical/02_events_catalog.md §4.3 (transfer_completed payload).
--   docs/economy/01_economic_model.md §10.3 (internal fee = 0 €).
-- =============================================================================

SONAR = SONAR or {}
SONAR.Bank = SONAR.Bank or {}
SONAR.Bank.Transfer = SONAR.Bank.Transfer or {}

local Config   = SONAR.Bank.Config
local IBAN     = SONAR.Bank.IBAN
local Accounts = SONAR.Bank.Accounts
local Bank     = SONAR.Bank
local Transfer = SONAR.Bank.Transfer

-- Per SSoT §3.1 C002: amount > 0 AND amount <= 1.000.000 €.
local _MIN_AMOUNT = 0.01    -- centavo mínimo (DECIMAL(14,2) precisión).
local _MAX_AMOUNT = 1000000.00
local _MAX_CONCEPT_LEN = 120  -- per §3.1 C002 request schema.

-- =============================================================================
-- UUID v4 generator — used for transaction_id (server-side identity).
-- Mismo patrón que accounts.lua._uuid_v4.
-- =============================================================================
local function _uuid_v4()
  local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
  return (template:gsub('[xy]', function(c)
    local v = (c == 'x') and math.random(0, 15) or math.random(8, 11)
    return string.format('%x', v)
  end))
end

-- =============================================================================
-- Internal — round to 2 decimal places (defense — JSON deserialization a veces
-- introduce float drift).
-- =============================================================================
local function _round2(n)
  return math.floor(n * 100 + 0.5) / 100
end

-- =============================================================================
-- Public — Transfer.Execute.
--
-- @param from_cid    string — citizen_id del player que ejecuta (auth pivot).
-- @param from_iban   string — IBAN origen.
-- @param to_iban     string — IBAN destino.
-- @param amount      number — euros, > 0, <= 1M €, hasta 2 decimales.
-- @param concept     string — descripción 1-120 chars.
-- @param request_id  string — UUID v4 client-side (idempotency key — manejado
--                              UPSTREAM en callbacks.lua via Bridges._IsIdemReplay).
--
-- @return success:boolean,
--         data:table | nil,    -- { transaction_id, timestamp, new_balance_from, fee_retained }
--         error_code:string | nil  -- per SSoT §3.1 C002 errors
--
-- error_code valores:
--   AMOUNT_OUT_OF_RANGE — amount <= 0 o > 1M €
--   INVALID_IBAN        — formato o destino no existe
--   SELF_TRANSFER       — from_iban == to_iban
--   NOT_AUTHORIZED      — from_cid no es owner del from_iban
--   ACCOUNT_FROZEN      — alguna de las 2 cuentas congelada o cerrada
--   INSUFFICIENT_FUNDS  — saldo from < amount
--   TX_CRASH            — pcall trapped error en SONAR.DB.Transaction
--   TX_ROLLBACK         — TX hizo rollback (race / FK / CHECK)
-- =============================================================================
function Transfer.Execute(from_cid, from_iban, to_iban, amount, concept, request_id)
  -- ---------------------------------------------------------------------------
  -- 1. Validaciones de input.
  -- ---------------------------------------------------------------------------
  if type(from_cid) ~= 'string' or from_cid == '' then
    return false, nil, 'NOT_AUTHORIZED'
  end
  if type(from_iban) ~= 'string' or from_iban == '' then
    return false, nil, 'INVALID_IBAN'
  end
  if type(to_iban) ~= 'string' or to_iban == '' then
    return false, nil, 'INVALID_IBAN'
  end
  if from_iban == to_iban then
    return false, nil, 'SELF_TRANSFER'
  end
  if type(amount) ~= 'number' or amount < _MIN_AMOUNT or amount > _MAX_AMOUNT then
    return false, nil, 'AMOUNT_OUT_OF_RANGE'
  end
  amount = _round2(amount)
  if amount < _MIN_AMOUNT then
    return false, nil, 'AMOUNT_OUT_OF_RANGE'
  end
  if type(concept) ~= 'string' then concept = '' end
  if #concept > _MAX_CONCEPT_LEN then concept = concept:sub(1, _MAX_CONCEPT_LEN) end

  -- IBAN format defense-in-depth (anti-SQL probing via random IBANs).
  local fmt_ok_from, fmt_err_from = IBAN.Validate(from_iban)
  if not fmt_ok_from then return false, nil, 'INVALID_IBAN' end
  local fmt_ok_to, fmt_err_to = IBAN.Validate(to_iban)
  if not fmt_ok_to then return false, nil, 'INVALID_IBAN' end

  -- ---------------------------------------------------------------------------
  -- 2. Resolver accounts (no locked SELECT — atomicity garantizada via CHECK
  --    constraint balance>=0, ver header).
  -- ---------------------------------------------------------------------------
  local from_acc = Accounts.GetByIban(from_iban)
  if not from_acc then return false, nil, 'INVALID_IBAN' end
  local to_acc = Accounts.GetByIban(to_iban)
  if not to_acc then return false, nil, 'INVALID_IBAN' end

  -- ---------------------------------------------------------------------------
  -- 3. Authorization. S1.2: solo personal accounts (S2+ company membership check).
  -- ---------------------------------------------------------------------------
  if from_acc.type ~= 'personal' then
    return false, nil, 'NOT_AUTHORIZED'
  end

  local caller_account_id = Accounts.GetAccountIdByCitizenId(from_cid)
  if not caller_account_id or from_acc.owner_account_id ~= caller_account_id then
    return false, nil, 'NOT_AUTHORIZED'
  end

  -- ---------------------------------------------------------------------------
  -- 4. State checks (frozen, closed).
  -- ---------------------------------------------------------------------------
  if (tonumber(from_acc.is_frozen) or 0) == 1 or from_acc.closed_at ~= nil then
    return false, nil, 'ACCOUNT_FROZEN'
  end
  if (tonumber(to_acc.is_frozen) or 0) == 1 or to_acc.closed_at ~= nil then
    return false, nil, 'ACCOUNT_FROZEN'
  end

  -- ---------------------------------------------------------------------------
  -- 5. Funds check (pre-flight UX — evita TX innecesaria en happy path overdraw.
  --    Atomicity real garantizada por CHECK constraint S005 — ver header).
  -- ---------------------------------------------------------------------------
  local from_balance_pre = _round2(tonumber(from_acc.balance) or 0.0)
  local to_balance_pre   = _round2(tonumber(to_acc.balance) or 0.0)
  if from_balance_pre < amount then
    return false, nil, 'INSUFFICIENT_FUNDS'
  end

  -- ---------------------------------------------------------------------------
  -- 6. Build TX queries.
  --
  -- transaction_id = UUID v4 server-side. Persistido en request_nonce de las 2
  -- movement rows (CHAR(36) — encaja exact). Permite al cliente reconciliar
  -- response → ledger via transaction_id == request_nonce.
  -- ---------------------------------------------------------------------------
  local transaction_id = _uuid_v4()
  local now = os.time()
  local from_balance_post = _round2(from_balance_pre - amount)
  local to_balance_post   = _round2(to_balance_pre + amount)

  -- Q1: Debit from. CHECK constraint chk_sonar_bank_accounts_balance_nonneg
  -- (migration 005) garantiza atomicity bajo race: si concurrent op vacía el
  -- saldo, `balance - amount` resultaría negativo → MySQL throws CHECK
  -- violation → toda la TX rollback automático. Pre-flight check (line ~165)
  -- evita TX innecesaria en happy path overdraw (devuelve INSUFFICIENT_FUNDS
  -- sin TX attempt).
  local q_debit = {
    query = [[
      UPDATE sonar_bank_accounts
      SET balance = balance - ?, updated_at = ?
      WHERE id = ?
        AND is_frozen = 0
        AND closed_at IS NULL
    ]],
    values = { amount, now, from_acc.id },
  }

  local q_credit = {
    query = [[
      UPDATE sonar_bank_accounts
      SET balance = balance + ?, updated_at = ?
      WHERE id = ?
        AND is_frozen = 0
        AND closed_at IS NULL
    ]],
    values = { amount, now, to_acc.id },
  }

  -- Movement rows: signed amount (positivo=ingreso, negativo=salida).
  -- balance_after = snapshot expected post-TX. category='transfer' canonical §4.2.
  -- counterpart_iban = la otra cuenta — facilita extracto bancario human-readable.
  -- request_nonce = transaction_id (compartido entre las 2 rows).
  local q_mov_debit = {
    query = [[
      INSERT INTO sonar_bank_movements
        (bank_account_id, occurred_at,
         amount, balance_after,
         category, counterpart_iban, concept,
         related_doc_id, related_offer_id, related_job_id,
         request_nonce, initiated_by_account_id, source_resource)
      VALUES (?, ?,
              ?, ?,
              'transfer', ?, ?,
              NULL, NULL, NULL,
              ?, ?, 'sonar_bank')
    ]],
    values = {
      from_acc.id, now,
      -amount, from_balance_post,    -- debit: amount negativo
      to_iban, concept,
      transaction_id, caller_account_id,
    },
  }

  local q_mov_credit = {
    query = [[
      INSERT INTO sonar_bank_movements
        (bank_account_id, occurred_at,
         amount, balance_after,
         category, counterpart_iban, concept,
         related_doc_id, related_offer_id, related_job_id,
         request_nonce, initiated_by_account_id, source_resource)
      VALUES (?, ?,
              ?, ?,
              'transfer', ?, ?,
              NULL, NULL, NULL,
              ?, ?, 'sonar_bank')
    ]],
    values = {
      to_acc.id, now,
      amount, to_balance_post,        -- credit: amount positivo
      from_iban, concept,
      transaction_id, caller_account_id,
    },
  }

  -- ---------------------------------------------------------------------------
  -- 7. Execute TX (atomic).
  -- ---------------------------------------------------------------------------
  local start_ms = GetGameTimer()
  local tx_ok, tx_result = pcall(function()
    return SONAR.DB.Transaction({ q_debit, q_credit, q_mov_debit, q_mov_credit })
  end)
  local tx_ms = GetGameTimer() - start_ms

  if not tx_ok then
    SONAR.Log.Error('Transfer.Execute TX crashed: from=%s to=%s amount=%s err=%s',
      from_iban, to_iban, amount, tostring(tx_result))
    SONAR.Metrics.Counter('bank.transfer.tx_crash')
    return false, nil, 'TX_CRASH'
  end
  if tx_result ~= true then
    -- Rollback. Causa más probable post migration 005: CHECK violation por
    -- race detected (balance vaciado por concurrent op entre pre-flight y
    -- UPDATE). Otras causas raras: FK violation (companies/accounts deleted
    -- mid-flight), DB connection drop, etc.
    --
    -- Si pre-flight passed (from_balance_pre >= amount) y aun así rollback
    -- → race detected con CHECK constraint enforcement. Distinguimos para
    -- UX + observability (smoke test step 8 stress detection).
    if from_balance_pre >= amount then
      SONAR.Log.Warn('Transfer.Execute RACE_DETECTED (CHECK violation): from=%s to=%s amount=%s pre_balance=%s txid=%s',
        from_iban, to_iban, amount, from_balance_pre, transaction_id)
      SONAR.Metrics.Counter('bank.transfer.race_detected')
      return false, nil, 'RACE_DETECTED'
    end
    SONAR.Log.Error('Transfer.Execute TX rollback (other): from=%s to=%s amount=%s txid=%s',
      from_iban, to_iban, amount, transaction_id)
    SONAR.Metrics.Counter('bank.transfer.tx_rollback')
    return false, nil, 'TX_ROLLBACK'
  end

  SONAR.Metrics.Counter('bank.transfer.success')
  SONAR.Metrics.Observe('bank.transfer.tx_ms', tx_ms)

  -- ---------------------------------------------------------------------------
  -- 8. Audit log (categoria canónica 'bank.transfer').
  -- ---------------------------------------------------------------------------
  SONAR.Log.Audit({
    category = Config.AuditCategories.Transfer,
    action   = 'execute',
    actor    = from_cid,
    target   = transaction_id,
    payload  = {
      transaction_id   = transaction_id,
      request_id       = request_id,  -- client idempotency key (en caso de auditoría forense)
      from_iban        = from_iban,
      to_iban          = to_iban,
      amount           = amount,
      fee_retained     = 0.0,
      concept          = concept,
      new_balance_from = from_balance_post,
      tx_ms            = tx_ms,
    },
  })

  -- ---------------------------------------------------------------------------
  -- 9. Compose response data per SSoT §3.1 C002 shape.
  -- ---------------------------------------------------------------------------
  local data = {
    transaction_id    = transaction_id,
    timestamp         = now * 1000,    -- canonical UNIX ms (consistente con C001 last_updated)
    new_balance_from  = from_balance_post,
    fee_retained      = 0.0,           -- S1.2 internal transfer = 0 € per economy §10.3
  }

  -- ---------------------------------------------------------------------------
  -- 10. Publish event sonar:bank:transfer_completed.
  --     Shape canonical per docs/technical/02_events_catalog.md §4.3.
  -- ---------------------------------------------------------------------------
  if Bank.Events and Bank.Events.PublishTransferCompleted then
    Bank.Events.PublishTransferCompleted({
      transaction_id        = transaction_id,
      from_iban             = from_iban,
      to_iban               = to_iban,
      amount                = amount,
      concept               = concept,
      category              = 'transfer',
      related_doc_id        = nil,
      requester_account_id  = caller_account_id,
      occurred_at           = now,
    })
  end

  return true, data, nil
end

-- =============================================================================
-- Boot announce.
-- =============================================================================
SONAR.Log.Info('Transfer module ready (fee=0€, max=%d€, rate=bank.write)', _MAX_AMOUNT)
