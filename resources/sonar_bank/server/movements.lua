-- =============================================================================
-- SONAR Bank — server/movements.lua
--
-- Helpers de bajo nivel sobre sonar_bank_movements (ledger inmutable
-- PARTITIONED, SSoT §03 §4.2). Esta capa NO orquestra TX (eso es responsabilidad
-- de Transfer.Execute en server/transfer.lua que arma queries inline para
-- SONAR.DB.Transaction).
--
-- API pública:
--
--   Movements.Insert(opts) → insert_id | nil, err
--     Inserción no-transaccional single-row. Útil para adjustments, audit
--     trail futures (S2+). NO usado por Transfer.Execute.
--
--   Movements.GetByAccount(bank_account_id, limit?, offset?) → rows | {}
--     Extracto bancario reciente. Index canónico hits p99 <5ms per SSoT §15.
--
--   Movements.GetByNonce(request_nonce) → row | nil
--     Lookup directo por idempotency nonce. Útil para verificar transfer
--     persistido + para reconciliación.
--
--   Movements.RecalcBalance(bank_account_id) → { sum_movements, balance, delta }
--     Reconciliación: SUM(amount) GROUP BY account vs sonar_bank_accounts.balance.
--     Delta != 0 indica inconsistencia. Usado por smoke atomicity verification.
--
-- Convention firmas:
--   - Queries usan placeholders '?' — SONAR.DB.* enforce prepared-only.
--   - amount es signed (positivo=ingreso, negativo=salida) per SSoT §4.2:553.
--
-- Referencias SSoT:
--   docs/technical/03_db_schema.md §4.2 (sonar_bank_movements DDL).
--   docs/technical/04_api_contracts.md §6 (DB layer).
-- =============================================================================

SONAR = SONAR or {}
SONAR.Bank = SONAR.Bank or {}
SONAR.Bank.Movements = SONAR.Bank.Movements or {}

local Movements = SONAR.Bank.Movements

-- Categorías canónicas ENUM sonar_bank_movements.category (SSoT §4.2:556 +
-- migration 003 que añadió 'starter_seed').
local _VALID_CATEGORIES = {
  salary         = true, b2b_payment    = true, transfer       = true,
  tax            = true, refund         = true, b2c_sale       = true,
  expense        = true, deposit        = true, withdrawal     = true,
  escrow_lock    = true, escrow_release = true, adjustment     = true,
  starter_seed   = true,
}

-- =============================================================================
-- Public — Movements.Insert (non-transactional single row).
--
-- @param opts table {
--   bank_account_id    : CHAR(36)  required
--   amount             : DECIMAL   required (signed; positivo=ingreso)
--   balance_after      : DECIMAL   required (snapshot post-movement)
--   category           : ENUM      required (must be valid per _VALID_CATEGORIES)
--   counterpart_iban   : VARCHAR(20)? optional
--   concept            : VARCHAR(255)? optional
--   request_nonce      : CHAR(36)? optional (idempotency anti-replay)
--   related_doc_id     : CHAR(36)? optional
--   related_offer_id   : CHAR(36)? optional
--   related_job_id     : CHAR(36)? optional
--   initiated_by_account_id : CHAR(36)? optional
--   source_resource    : VARCHAR(64)? defaults 'sonar_bank'
--   occurred_at        : INT? defaults os.time()
-- }
-- @return insert_id:number | nil, err:string
-- =============================================================================
function Movements.Insert(opts)
  if type(opts) ~= 'table' then return nil, 'INVALID_OPTS' end
  if type(opts.bank_account_id) ~= 'string' or opts.bank_account_id == '' then
    return nil, 'INVALID_ACCOUNT_ID'
  end
  if type(opts.amount) ~= 'number' then return nil, 'INVALID_AMOUNT' end
  if type(opts.balance_after) ~= 'number' then return nil, 'INVALID_BALANCE_AFTER' end
  if type(opts.category) ~= 'string' or not _VALID_CATEGORIES[opts.category] then
    return nil, 'INVALID_CATEGORY'
  end

  local insert_id = SONAR.DB.Insert([[
    INSERT INTO sonar_bank_movements
      (bank_account_id, occurred_at,
       amount, balance_after,
       category, counterpart_iban, concept,
       related_doc_id, related_offer_id, related_job_id,
       request_nonce, initiated_by_account_id, source_resource)
    VALUES (?, ?,
            ?, ?,
            ?, ?, ?,
            ?, ?, ?,
            ?, ?, ?)
  ]], {
    opts.bank_account_id, opts.occurred_at or os.time(),
    opts.amount, opts.balance_after,
    opts.category, opts.counterpart_iban, opts.concept,
    opts.related_doc_id, opts.related_offer_id, opts.related_job_id,
    opts.request_nonce, opts.initiated_by_account_id,
    opts.source_resource or 'sonar_bank',
  })

  return insert_id
end

-- =============================================================================
-- Public — Movements.GetByAccount.
-- =============================================================================
function Movements.GetByAccount(bank_account_id, limit, offset)
  if type(bank_account_id) ~= 'string' or bank_account_id == '' then return {} end
  limit = tonumber(limit) or 50
  offset = tonumber(offset) or 0
  if limit > 200 then limit = 200 end  -- defensive cap
  if limit < 1 then limit = 1 end
  if offset < 0 then offset = 0 end

  return SONAR.DB.FetchAll([[
    SELECT id, bank_account_id, occurred_at, amount, balance_after,
           category, counterpart_iban, concept, request_nonce,
           related_doc_id, related_offer_id, related_job_id,
           initiated_by_account_id, source_resource
    FROM sonar_bank_movements
    WHERE bank_account_id = ?
    ORDER BY occurred_at DESC, id DESC
    LIMIT ? OFFSET ?
  ]], { bank_account_id, limit, offset }) or {}
end

-- =============================================================================
-- Public — Movements.GetByNonce.
-- Lookup directo por request_nonce. Múltiples rows posibles si el nonce
-- representa una TX multi-row (ej. transfer = 2 rows con mismo nonce).
-- =============================================================================
function Movements.GetByNonce(request_nonce)
  if type(request_nonce) ~= 'string' or request_nonce == '' then return {} end
  return SONAR.DB.FetchAll([[
    SELECT id, bank_account_id, occurred_at, amount, balance_after,
           category, counterpart_iban, concept, request_nonce, source_resource
    FROM sonar_bank_movements
    WHERE request_nonce = ?
    ORDER BY id ASC
  ]], { request_nonce }) or {}
end

-- =============================================================================
-- Public — Movements.RecalcBalance.
--
-- Reconciliación contable: SUM(amount) over all movements for an account
-- vs sonar_bank_accounts.balance. Delta != 0 → ledger desbalanceado
-- (atomicity bug, manual UPDATE fuera de TX, o data corruption).
--
-- @param bank_account_id string
-- @return table { sum_movements, balance, delta } | nil
-- =============================================================================
function Movements.RecalcBalance(bank_account_id)
  if type(bank_account_id) ~= 'string' or bank_account_id == '' then return nil end

  -- SUM(amount) — partitioned scan, cubre TODA la historia de la cuenta.
  -- Para accounts con muchos movements (>1M filas) considerar caching S2+.
  local sum = SONAR.DB.Scalar([[
    SELECT COALESCE(SUM(amount), 0)
    FROM sonar_bank_movements
    WHERE bank_account_id = ?
  ]], { bank_account_id })

  local balance = SONAR.DB.Scalar([[
    SELECT balance FROM sonar_bank_accounts WHERE id = ?
  ]], { bank_account_id })

  local sum_n = tonumber(sum) or 0.0
  local bal_n = tonumber(balance) or 0.0
  return {
    sum_movements = sum_n,
    balance       = bal_n,
    delta         = bal_n - sum_n,  -- 0 = consistente; !=0 = anomalía
  }
end

-- =============================================================================
-- Boot announce.
-- =============================================================================
SONAR.Log.Info('Movements module ready (ENUM categories: %d valid)',
  (function() local n = 0; for _ in pairs(_VALID_CATEGORIES) do n = n + 1 end; return n end)())
