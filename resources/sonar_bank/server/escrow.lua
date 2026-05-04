-- =============================================================================
-- SONAR Bank — server/escrow.lua
--
-- Lógica core de escrows (callbacks C004 createEscrow / C005 releaseEscrow
-- backend). FSM transitions validated via `server/fsm_escrow.lua`.
--
-- Atomicity pattern (consistent con S1.2 transfer.lua):
--   SONAR.DB.Transaction([...queries]) con CHECK constraints como
--   atomicity-by-construction (MariaDB 10.4.32+ enforce nativo, verificado
--   2026-05-02 VERSION()).
--
-- Create TX (8 queries per founder 2-movements decision + system credit):
--   1. INSERT sonar_bank_accounts (escrow técnico, type='escrow',
--      owner_* ambos NULL — habilitado por CHECK relax migration 006).
--   2. UPDATE sonar_bank_accounts.balance -= (amount + fee)   [buyer]
--        ↳ CHECK chk_...balance_nonneg garantiza INSUFFICIENT_FUNDS rollback.
--   3. UPDATE sonar_bank_accounts.balance += amount            [escrow account]
--   4. UPDATE sonar_bank_accounts.balance += fee               [system treasury]
--   5. INSERT sonar_bank_movements (buyer, -amount, 'escrow_lock')
--   6. INSERT sonar_bank_movements (buyer, -fee,    'escrow_fee')
--   7. INSERT sonar_bank_movements (escrow, +amount, 'escrow_lock')
--   8. INSERT sonar_bank_movements (system, +fee,    'escrow_fee')
--   9. INSERT sonar_escrows (status='locked' direct per S1.3 F3 decision).
--
-- Release TX (4 queries):
--   1. UPDATE sonar_bank_accounts.balance -= amount             [escrow account]
--   2. UPDATE sonar_bank_accounts.balance += amount             [recipient]
--   3. INSERT sonar_bank_movements (escrow, -amount, 'escrow_release'|'escrow_refund')
--   4. INSERT sonar_bank_movements (recipient, +amount, ídem)
--   5. UPDATE sonar_escrows SET status=<new>, released_to=<dir>,
--            released_by_account_id=<caller>, released_at=<ts>, updated_at=<ts>
--            WHERE id=? AND status='locked'  (guard: race contra 2nd release).
--
-- NOTA ENUM movements: sonar_bank_movements.category no tiene 'escrow_fee'
-- literal en SSoT §4.2:556 pero migration 003 lo aditiva de facto — verificado
-- en `@d:\theBigProject\resources\sonar_bank\server\movements.lua:43-49`
-- valid categories incluye `escrow_lock`, `escrow_release`. Para el fee
-- (destino system treasury) re-usamos `escrow_lock` en el debit buyer (single
-- category per TX row) y category='escrow_release' para el refund path.
-- Refinement S2+: ALTER ENUM ADD 'escrow_fee' dedicado + ALTER ENUM ADD
-- 'escrow_refund'. Actualmente categories existentes cubren el flujo S1.3
-- sin schema change — decisión pragmatic, documentada en fee_retained movement.
--
-- Auth matrix C005 (per F3 founder S1.3 — SSoT gap resolved):
--   caller==seller + dir='seller'  → allowed (release)
--   caller==buyer  + dir='buyer'   → allowed (refund)
--   cualquier otro                 → NOT_AUTHORIZED
--   dir='split'                    → NOT_IMPLEMENTED (deferred S3+)
--
-- Referencias SSoT:
--   docs/technical/04_api_contracts.md §3.1 C004/C005.
--   docs/technical/03_db_schema.md §4.3 (sonar_escrows — GAP SSoT
--     llenado en migration 006, tracked SPRINT_RETRO_S1).
--   docs/technical/05_state_machines.md §4.1 (FSM escrow_lifecycle).
--   docs/economy/01_economic_model.md §10.4.1 (lifecycle) + §10.4.2 (fee 2-100€).
-- =============================================================================

SONAR = SONAR or {}
SONAR.Bank = SONAR.Bank or {}
SONAR.Bank.Escrow = SONAR.Bank.Escrow or {}

local Config   = SONAR.Bank.Config
local IBAN     = SONAR.Bank.IBAN
local Accounts = SONAR.Bank.Accounts
local FSM      = SONAR.Bank.FSMEscrow
local Bank     = SONAR.Bank
local Escrow   = SONAR.Bank.Escrow

-- =============================================================================
-- UUID v4 generator — consistent con transfer.lua._uuid_v4 (RFC 4122 §4.4).
-- =============================================================================
local function _uuid_v4()
  local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
  return (template:gsub('[xy]', function(c)
    local v = (c == 'x') and math.random(0, 15) or math.random(8, 11)
    return string.format('%x', v)
  end))
end

-- =============================================================================
-- Internal — round to 2 decimal places.
-- =============================================================================
local function _round2(n)
  return math.floor(n * 100 + 0.5) / 100
end

-- =============================================================================
-- Internal — compute escrow fee per economy §10.4.2.
--
-- fee = max(EscrowFeeMin, min(amount * EscrowFeeRate, EscrowFeeMax))
-- @param amount number (>= EscrowAmountMin)
-- @return number fee (2-decimal rounded)
-- =============================================================================
local function _compute_fee(amount)
  local raw = amount * Config.EscrowFeeRate
  local clamped = math.max(Config.EscrowFeeMin, math.min(raw, Config.EscrowFeeMax))
  return _round2(clamped)
end

-- =============================================================================
-- Internal — authorize C005 release per F3 auth matrix.
--
-- Post-008 design: `escrow.buyer_account_id` / `seller_account_id` almacenan
-- **bank_account.id** (no player identity). Auth resuelve el owner del bank
-- account stored via SQL lookup y compara contra caller identity.
--
-- @param caller_identity string — sonar_accounts.id del caller (C005).
-- @param escrow          table  — escrow row (buyer/seller_account_id = bank_account.id).
-- @param direction       string — 'seller' | 'buyer' | 'split'.
-- @return ok:boolean, error_code:string|nil
-- =============================================================================
local function _authorize_release(caller_identity, escrow, direction)
  if direction == 'split' then
    return false, 'NOT_IMPLEMENTED'
  end
  if type(caller_identity) ~= 'string' or caller_identity == '' then
    return false, 'NOT_AUTHORIZED'
  end

  local relevant_bank_account_id
  if direction == 'seller' then
    relevant_bank_account_id = escrow.seller_account_id
  elseif direction == 'buyer' then
    relevant_bank_account_id = escrow.buyer_account_id
  else
    return false, 'INVALID_REQUEST'
  end

  -- Resolver owner del bank_account stored. Si account no existe o no tiene
  -- owner (escrow-type account sin owner, impossible para buyer/seller) → deny.
  local owner_identity = SONAR.DB.Scalar([[
    SELECT owner_account_id FROM sonar_bank_accounts WHERE id = ? LIMIT 1
  ]], { relevant_bank_account_id })

  if not owner_identity or owner_identity == '' then
    return false, 'NOT_AUTHORIZED'
  end
  if owner_identity == caller_identity then return true, nil end
  return false, 'NOT_AUTHORIZED'
end

-- =============================================================================
-- Public — Escrow.GetById.
-- =============================================================================
function Escrow.GetById(escrow_id)
  if type(escrow_id) ~= 'string' or escrow_id == '' then return nil end
  return SONAR.DB.FetchOne([[
    SELECT id, status, buyer_account_id, seller_account_id, escrow_account_id,
           amount, fee_charged, contract_id, release_condition, release_date,
           expires_at, request_nonce,
           released_to, released_by_account_id, released_at,
           created_at, updated_at
    FROM sonar_escrows
    WHERE id = ?
  ]], { escrow_id })
end

-- =============================================================================
-- Internal — resolve system treasury account id from Config.EscrowFeeDestIban.
-- Cached after first lookup.
-- =============================================================================
local _system_account_id_cache = nil
local function _resolve_system_account_id()
  if _system_account_id_cache then return _system_account_id_cache end
  local row = Accounts.GetByIban(Config.EscrowFeeDestIban)
  if not row or not row.id then
    return nil, 'SYSTEM_ACCOUNT_NOT_FOUND'
  end
  _system_account_id_cache = row.id
  return _system_account_id_cache
end

-- =============================================================================
-- Public — Escrow.Create.
--
-- @param buyer_cid         string — citizen_id del caller C004 (auth pivot).
-- @param buyer_iban        string — IBAN del buyer (origen de fondos).
-- @param seller_iban       string — IBAN del seller (destino en release).
-- @param amount            number — monto a retener (sin fee). Range [EscrowAmountMin, EscrowAmountMax].
-- @param contract_id       string|nil — ref contrato B2B (NULL S1.3).
-- @param release_condition string — 'delivery_confirmed' | 'manual' | 'time_based'.
-- @param release_date      number|nil — UNIX ts si time_based.
-- @param request_id        string — UUID v4 client idempotency key (persisted en request_nonce).
--
-- @return success:boolean, data:table|nil, error_code:string|nil
--
-- data shape canonical per SSoT §3.1 C004:
--   { escrow_id, fee_charged, expires_at }
--
-- error_code values:
--   AMOUNT_OUT_OF_RANGE | INVALID_IBAN | SELF_ESCROW | NOT_AUTHORIZED |
--   ACCOUNT_FROZEN | INSUFFICIENT_FUNDS | INVALID_RELEASE_CONDITION |
--   INVALID_REQUEST | DUPLICATE_REQUEST | SYSTEM_ACCOUNT_NOT_FOUND |
--   TX_CRASH | TX_ROLLBACK | RACE_DETECTED
-- =============================================================================
function Escrow.Create(buyer_cid, buyer_iban, seller_iban, amount, contract_id, release_condition, release_date, request_id)
  -- ---------------------------------------------------------------------------
  -- 1. Input validation (defense-in-depth — callback ya validó shape basic).
  -- ---------------------------------------------------------------------------
  if type(buyer_cid) ~= 'string' or buyer_cid == '' then
    return false, nil, 'NOT_AUTHORIZED'
  end
  if type(buyer_iban) ~= 'string' or buyer_iban == '' then
    return false, nil, 'INVALID_IBAN'
  end
  if type(seller_iban) ~= 'string' or seller_iban == '' then
    return false, nil, 'INVALID_IBAN'
  end
  if buyer_iban == seller_iban then
    return false, nil, 'SELF_ESCROW'
  end
  if type(amount) ~= 'number' or amount < Config.EscrowAmountMin or amount > Config.EscrowAmountMax then
    return false, nil, 'AMOUNT_OUT_OF_RANGE'
  end
  amount = _round2(amount)
  if amount < Config.EscrowAmountMin then
    return false, nil, 'AMOUNT_OUT_OF_RANGE'
  end

  -- release_condition default + whitelist
  release_condition = release_condition or 'manual'
  if release_condition ~= 'manual'
     and release_condition ~= 'delivery_confirmed'
     and release_condition ~= 'time_based' then
    return false, nil, 'INVALID_RELEASE_CONDITION'
  end
  if release_condition == 'time_based'
     and (type(release_date) ~= 'number' or release_date <= os.time()) then
    return false, nil, 'INVALID_REQUEST'
  end
  if release_condition ~= 'time_based' then
    release_date = nil  -- no aplica.
  end

  if type(request_id) ~= 'string' or #request_id < 8 or #request_id > 64 then
    return false, nil, 'INVALID_REQUEST'
  end

  -- IBAN format defense-in-depth.
  local fmt_ok_b = IBAN.Validate(buyer_iban)
  if not fmt_ok_b then return false, nil, 'INVALID_IBAN' end
  local fmt_ok_s = IBAN.Validate(seller_iban)
  if not fmt_ok_s then return false, nil, 'INVALID_IBAN' end

  -- ---------------------------------------------------------------------------
  -- 2. Resolve accounts.
  -- ---------------------------------------------------------------------------
  local buyer_acc = Accounts.GetByIban(buyer_iban)
  if not buyer_acc then return false, nil, 'INVALID_IBAN' end
  local seller_acc = Accounts.GetByIban(seller_iban)
  if not seller_acc then return false, nil, 'INVALID_IBAN' end

  -- S1.3 restringe buyer y seller a personal accounts (company membership S2+).
  if buyer_acc.type ~= 'personal' then
    return false, nil, 'NOT_AUTHORIZED'
  end
  if seller_acc.type ~= 'personal' then
    -- S2+: allow company seller via membership.
    return false, nil, 'NOT_AUTHORIZED'
  end

  -- ---------------------------------------------------------------------------
  -- 3. Authorization. Only buyer creates the escrow (locks their funds).
  -- ---------------------------------------------------------------------------
  local caller_account_id = Accounts.GetAccountIdByCitizenId(buyer_cid)
  if not caller_account_id or buyer_acc.owner_account_id ~= caller_account_id then
    return false, nil, 'NOT_AUTHORIZED'
  end

  -- ---------------------------------------------------------------------------
  -- 4. State checks (frozen/closed).
  -- ---------------------------------------------------------------------------
  if (tonumber(buyer_acc.is_frozen) or 0) == 1 or buyer_acc.closed_at ~= nil then
    return false, nil, 'ACCOUNT_FROZEN'
  end
  if (tonumber(seller_acc.is_frozen) or 0) == 1 or seller_acc.closed_at ~= nil then
    return false, nil, 'ACCOUNT_FROZEN'
  end

  -- ---------------------------------------------------------------------------
  -- 5. Fee computation + pre-flight funds check (UX — atomicity real vía CHECK).
  -- ---------------------------------------------------------------------------
  local fee = _compute_fee(amount)
  local total_debit = _round2(amount + fee)

  local buyer_balance_pre = _round2(tonumber(buyer_acc.balance) or 0.0)
  if buyer_balance_pre < total_debit then
    return false, nil, 'INSUFFICIENT_FUNDS'
  end

  -- ---------------------------------------------------------------------------
  -- 6. Resolve system treasury account (FK fee destination).
  -- ---------------------------------------------------------------------------
  local system_account_id, sys_err = _resolve_system_account_id()
  if not system_account_id then
    SONAR.Log.Error('Escrow.Create: system treasury account not found (iban=%s)',
      Config.EscrowFeeDestIban)
    SONAR.Metrics.Counter('bank.escrow.create.system_account_missing')
    return false, nil, 'SYSTEM_ACCOUNT_NOT_FOUND'
  end
  local system_acc = SONAR.DB.FetchOne([[
    SELECT id, balance FROM sonar_bank_accounts WHERE id = ?
  ]], { system_account_id })
  if not system_acc then
    return false, nil, 'SYSTEM_ACCOUNT_NOT_FOUND'
  end

  -- ---------------------------------------------------------------------------
  -- 7. Prepare IDs + balances-after snapshots + new escrow IBAN.
  -- ---------------------------------------------------------------------------
  local escrow_id         = _uuid_v4()
  local escrow_account_id = _uuid_v4()
  local now               = os.time()
  local expires_at        = now + Config.EscrowDefaultExpirySeconds

  local buyer_balance_post   = _round2(buyer_balance_pre - total_debit)
  local escrow_balance_post  = _round2(amount)  -- escrow account nuevo empieza 0 → + amount
  local system_balance_pre   = _round2(tonumber(system_acc.balance) or 0.0)
  local system_balance_post  = _round2(system_balance_pre + fee)

  local escrow_iban
  local iban_ok, iban_or_err = pcall(IBAN.Generate)
  if not iban_ok then
    SONAR.Log.Error('Escrow.Create: IBAN.Generate failed: %s', tostring(iban_or_err))
    SONAR.Metrics.Counter('bank.escrow.create.iban_gen_failed')
    return false, nil, 'TX_CRASH'
  end
  escrow_iban = iban_or_err

  -- ---------------------------------------------------------------------------
  -- 8. Build TX queries (9 statements — escrow account + 3 UPDATEs + 4 movements + INSERT escrow).
  -- ---------------------------------------------------------------------------

  -- Q1: INSERT escrow bank account (type='escrow', owner_* NULL, balance=0).
  local q_create_escrow_acc = {
    query = [[
      INSERT INTO sonar_bank_accounts
        (id, iban, type, owner_account_id, owner_company_id,
         balance, daily_limit_out, is_frozen, frozen_reason,
         created_at, updated_at, closed_at)
      VALUES (?, ?, 'escrow', NULL, NULL,
              0.00, NULL, 0, NULL,
              ?, ?, NULL)
    ]],
    values = { escrow_account_id, escrow_iban, now, now },
  }

  -- Q2: Debit buyer (amount + fee). CHECK balance>=0 enforcea atomicity.
  local q_debit_buyer = {
    query = [[
      UPDATE sonar_bank_accounts
      SET balance = balance - ?, updated_at = ?
      WHERE id = ?
        AND is_frozen = 0
        AND closed_at IS NULL
    ]],
    values = { total_debit, now, buyer_acc.id },
  }

  -- Q3: Credit escrow account (amount only, fee va aparte).
  local q_credit_escrow_acc = {
    query = [[
      UPDATE sonar_bank_accounts
      SET balance = balance + ?, updated_at = ?
      WHERE id = ?
    ]],
    values = { amount, now, escrow_account_id },
  }

  -- Q4: Credit system treasury (fee).
  local q_credit_system = {
    query = [[
      UPDATE sonar_bank_accounts
      SET balance = balance + ?, updated_at = ?
      WHERE id = ?
    ]],
    values = { fee, now, system_account_id },
  }

  -- Q5: Movement buyer debit amount (category='escrow_lock').
  -- balance_after = buyer_balance_post (incluye fee ya debited).
  local q_mov_buyer_amount = {
    query = [[
      INSERT INTO sonar_bank_movements
        (bank_account_id, occurred_at,
         amount, balance_after,
         category, counterpart_iban, concept,
         related_doc_id, related_offer_id, related_job_id,
         request_nonce, initiated_by_account_id, source_resource)
      VALUES (?, ?,
              ?, ?,
              'escrow_lock', ?, ?,
              NULL, NULL, NULL,
              ?, ?, 'sonar_bank')
    ]],
    values = {
      buyer_acc.id, now,
      -amount, buyer_balance_post,
      escrow_iban, ('Escrow lock %s'):format(escrow_id:sub(1, 8)),
      escrow_id, caller_account_id,
    },
  }

  -- Q6: Movement buyer debit fee (category='escrow_release' — re-use en lugar
  -- de ALTER ENUM para 'escrow_fee'. Anotado en header. Counterpart=system IBAN.
  -- balance_after = buyer_balance_post (mismo — 2 rows comparten el snapshot final).
  local q_mov_buyer_fee = {
    query = [[
      INSERT INTO sonar_bank_movements
        (bank_account_id, occurred_at,
         amount, balance_after,
         category, counterpart_iban, concept,
         related_doc_id, related_offer_id, related_job_id,
         request_nonce, initiated_by_account_id, source_resource)
      VALUES (?, ?,
              ?, ?,
              'escrow_release', ?, ?,
              NULL, NULL, NULL,
              ?, ?, 'sonar_bank')
    ]],
    values = {
      buyer_acc.id, now,
      -fee, buyer_balance_post,
      Config.EscrowFeeDestIban, ('Escrow fee %s'):format(escrow_id:sub(1, 8)),
      escrow_id, caller_account_id,
    },
  }

  -- Q7: Movement escrow credit amount.
  local q_mov_escrow_credit = {
    query = [[
      INSERT INTO sonar_bank_movements
        (bank_account_id, occurred_at,
         amount, balance_after,
         category, counterpart_iban, concept,
         related_doc_id, related_offer_id, related_job_id,
         request_nonce, initiated_by_account_id, source_resource)
      VALUES (?, ?,
              ?, ?,
              'escrow_lock', ?, ?,
              NULL, NULL, NULL,
              ?, ?, 'sonar_bank')
    ]],
    values = {
      escrow_account_id, now,
      amount, escrow_balance_post,
      buyer_iban, ('Escrow lock from buyer %s'):format(escrow_id:sub(1, 8)),
      escrow_id, caller_account_id,
    },
  }

  -- Q8: Movement system credit fee.
  local q_mov_system_credit = {
    query = [[
      INSERT INTO sonar_bank_movements
        (bank_account_id, occurred_at,
         amount, balance_after,
         category, counterpart_iban, concept,
         related_doc_id, related_offer_id, related_job_id,
         request_nonce, initiated_by_account_id, source_resource)
      VALUES (?, ?,
              ?, ?,
              'escrow_release', ?, ?,
              NULL, NULL, NULL,
              ?, ?, 'sonar_bank')
    ]],
    values = {
      system_account_id, now,
      fee, system_balance_post,
      buyer_iban, ('Escrow fee from %s'):format(escrow_id:sub(1, 8)),
      escrow_id, caller_account_id,
    },
  }

  -- Q9: INSERT sonar_escrows con status='locked' direct per F3.
  -- request_nonce UNIQUE → duplicate request_id triggers SQL throw → rollback
  -- entire TX (idempotency guard DB-level además del Bridges upstream).
  local q_insert_escrow = {
    query = [[
      INSERT INTO sonar_escrows
        (id, status,
         buyer_account_id, seller_account_id, escrow_account_id,
         amount, fee_charged, contract_id, release_condition, release_date,
         expires_at, request_nonce,
         released_to, released_by_account_id, released_at,
         created_at, updated_at)
      VALUES (?, 'locked',
              ?, ?, ?,
              ?, ?, ?, ?, ?,
              ?, ?,
              NULL, NULL, NULL,
              ?, ?)
    ]],
    values = {
      escrow_id,
      buyer_acc.id, seller_acc.id, escrow_account_id,
      amount, fee, contract_id, release_condition, release_date,
      expires_at, request_id,
      now, now,
    },
  }

  -- ---------------------------------------------------------------------------
  -- 9. Execute TX (atomic).
  -- ---------------------------------------------------------------------------
  local start_ms = GetGameTimer()
  local tx_ok, tx_result = pcall(function()
    return SONAR.DB.Transaction({
      q_create_escrow_acc,
      q_debit_buyer,
      q_credit_escrow_acc,
      q_credit_system,
      q_mov_buyer_amount,
      q_mov_buyer_fee,
      q_mov_escrow_credit,
      q_mov_system_credit,
      q_insert_escrow,
    })
  end)
  local tx_ms = GetGameTimer() - start_ms

  if not tx_ok then
    SONAR.Log.Error('Escrow.Create TX crashed: buyer=%s seller=%s amount=%s fee=%s err=%s',
      buyer_iban, seller_iban, amount, fee, tostring(tx_result))
    SONAR.Metrics.Counter('bank.escrow.create.tx_crash')
    return false, nil, 'TX_CRASH'
  end
  if tx_result ~= true then
    -- Rollback. Causas: CHECK balance race, UNIQUE request_nonce (duplicate
    -- request_id — should be caught upstream by Bridges idempotency), UNIQUE
    -- iban race, FK fail, CHECK amount_positive/fee_nonneg.
    if buyer_balance_pre >= total_debit then
      SONAR.Log.Warn('Escrow.Create RACE_DETECTED (CHECK violation or UNIQUE race): buyer=%s seller=%s amount=%s fee=%s escrow_id=%s',
        buyer_iban, seller_iban, amount, fee, escrow_id)
      SONAR.Metrics.Counter('bank.escrow.create.race_detected')
      return false, nil, 'RACE_DETECTED'
    end
    SONAR.Log.Error('Escrow.Create TX rollback: buyer=%s seller=%s amount=%s escrow_id=%s',
      buyer_iban, seller_iban, amount, escrow_id)
    SONAR.Metrics.Counter('bank.escrow.create.tx_rollback')
    return false, nil, 'TX_ROLLBACK'
  end

  SONAR.Metrics.Counter('bank.escrow.create.success')
  SONAR.Metrics.Observe('bank.escrow.create.tx_ms', tx_ms)
  FSM.LogTransition(escrow_id, 'created', 'locked', { amount = amount, fee = fee })

  -- ---------------------------------------------------------------------------
  -- 10. Audit log.
  -- ---------------------------------------------------------------------------
  SONAR.Log.Audit({
    category = Config.AuditCategories.EscrowCreated,
    action   = 'create',
    actor    = buyer_cid,
    target   = escrow_id,
    payload  = {
      escrow_id          = escrow_id,
      escrow_iban        = escrow_iban,
      escrow_account_id  = escrow_account_id,
      buyer_iban         = buyer_iban,
      seller_iban        = seller_iban,
      amount             = amount,
      fee_charged        = fee,
      total_debit        = total_debit,
      contract_id        = contract_id,
      release_condition  = release_condition,
      release_date       = release_date,
      expires_at         = expires_at,
      request_id         = request_id,
      tx_ms              = tx_ms,
    },
  })

  -- ---------------------------------------------------------------------------
  -- 11. Publish event sonar:bank:escrow_created (schema §1.4 auto-decorated).
  -- ---------------------------------------------------------------------------
  if Bank.Events and Bank.Events.PublishEscrowCreated then
    Bank.Events.PublishEscrowCreated({
      escrow_id          = escrow_id,
      escrow_iban        = escrow_iban,
      buyer_iban         = buyer_iban,
      seller_iban        = seller_iban,
      amount             = amount,
      fee_charged        = fee,
      contract_id        = contract_id,
      release_condition  = release_condition,
      release_date       = release_date,
      expires_at         = expires_at,
      requester_account_id = caller_account_id,
      occurred_at        = now,
    })
  end

  -- ---------------------------------------------------------------------------
  -- 12. Response data (SSoT §3.1 C004 canonical shape).
  -- ---------------------------------------------------------------------------
  return true, {
    escrow_id   = escrow_id,
    fee_charged = fee,
    expires_at  = expires_at,
  }, nil
end

-- =============================================================================
-- Public — Escrow.Release.
--
-- @param caller_cid  string — citizen_id del caller (C005 auth pivot).
-- @param escrow_id   string — UUID v4 de sonar_escrows.id.
-- @param direction   string — 'seller' | 'buyer' | 'split' (split→NOT_IMPLEMENTED).
-- @param split_ratio number|nil — 0..1 (ignorado S1.3 salvo split).
-- @param request_id  string — UUID v4 client idempotency.
--
-- @return success:boolean, data:table|nil, error_code:string|nil
--
-- data shape canonical per SSoT §3.1 C005:
--   { released_amount_seller, released_amount_buyer, timestamp }
--
-- error_code values:
--   NOT_AUTHORIZED | ESCROW_NOT_FOUND | INVALID_STATE | NOT_IMPLEMENTED |
--   INVALID_REQUEST | TX_CRASH | TX_ROLLBACK
-- =============================================================================
function Escrow.Release(caller_cid, escrow_id, direction, split_ratio, request_id)
  -- ---------------------------------------------------------------------------
  -- 1. Input validation.
  -- ---------------------------------------------------------------------------
  if type(caller_cid) ~= 'string' or caller_cid == '' then
    return false, nil, 'NOT_AUTHORIZED'
  end
  if type(escrow_id) ~= 'string' or #escrow_id ~= 36 then
    return false, nil, 'ESCROW_NOT_FOUND'
  end
  if direction == 'split' then
    return false, nil, 'NOT_IMPLEMENTED'
  end
  if direction ~= 'seller' and direction ~= 'buyer' then
    return false, nil, 'INVALID_REQUEST'
  end
  if type(request_id) ~= 'string' or #request_id < 8 or #request_id > 64 then
    return false, nil, 'INVALID_REQUEST'
  end

  -- ---------------------------------------------------------------------------
  -- 2. Resolve escrow row.
  -- ---------------------------------------------------------------------------
  local escrow = Escrow.GetById(escrow_id)
  if not escrow then
    return false, nil, 'ESCROW_NOT_FOUND'
  end

  -- ---------------------------------------------------------------------------
  -- 3. FSM guard — must be in 'locked' state.
  -- ---------------------------------------------------------------------------
  local target_state = (direction == 'seller') and 'released' or 'refunded'
  local can_ok, can_err = FSM.CanTransition(escrow.status, target_state)
  if not can_ok then
    SONAR.Log.Warn('Escrow.Release: FSM reject %s→%s for escrow=%s (reason=%s)',
      escrow.status, target_state, escrow_id, tostring(can_err))
    SONAR.Metrics.Counter('bank.escrow.release.invalid_state')
    return false, nil, 'INVALID_STATE'
  end

  -- ---------------------------------------------------------------------------
  -- 4. Authorization matrix (F3).
  -- ---------------------------------------------------------------------------
  local caller_account_id = Accounts.GetAccountIdByCitizenId(caller_cid)
  local auth_ok, auth_err = _authorize_release(caller_account_id, escrow, direction)
  if not auth_ok then
    SONAR.Metrics.Counter('bank.escrow.release.not_authorized')
    return false, nil, auth_err
  end

  -- ---------------------------------------------------------------------------
  -- 5. Resolve recipient account_id by direction.
  -- ---------------------------------------------------------------------------
  local recipient_account_id
  if direction == 'seller' then
    -- seller owner → seller's personal bank account
    -- Post-008: escrow.seller_account_id ES el bank_account.id directo.
    local seller_bank = SONAR.DB.FetchOne([[
      SELECT id, balance, iban, is_frozen, closed_at
      FROM sonar_bank_accounts
      WHERE id = ?
        AND closed_at IS NULL
      LIMIT 1
    ]], { escrow.seller_account_id })
    if not seller_bank then return false, nil, 'ESCROW_NOT_FOUND' end
    if (tonumber(seller_bank.is_frozen) or 0) == 1 then
      return false, nil, 'ACCOUNT_FROZEN'
    end
    recipient_account_id = seller_bank.id
  else
    -- buyer refund → buyer's personal bank account
    -- Post-008: escrow.buyer_account_id ES el bank_account.id directo.
    local buyer_bank = SONAR.DB.FetchOne([[
      SELECT id, balance, iban, is_frozen, closed_at
      FROM sonar_bank_accounts
      WHERE id = ?
        AND closed_at IS NULL
      LIMIT 1
    ]], { escrow.buyer_account_id })
    if not buyer_bank then return false, nil, 'ESCROW_NOT_FOUND' end
    if (tonumber(buyer_bank.is_frozen) or 0) == 1 then
      return false, nil, 'ACCOUNT_FROZEN'
    end
    recipient_account_id = buyer_bank.id
  end

  -- Also need IBAN and balance of recipient for counterpart_iban + balance_after.
  local recipient_row = SONAR.DB.FetchOne([[
    SELECT id, iban, balance FROM sonar_bank_accounts WHERE id = ?
  ]], { recipient_account_id })
  if not recipient_row then return false, nil, 'ESCROW_NOT_FOUND' end

  local escrow_bank_row = SONAR.DB.FetchOne([[
    SELECT id, iban, balance FROM sonar_bank_accounts WHERE id = ?
  ]], { escrow.escrow_account_id })
  if not escrow_bank_row then return false, nil, 'ESCROW_NOT_FOUND' end

  local amount = _round2(tonumber(escrow.amount) or 0.0)
  local escrow_balance_pre   = _round2(tonumber(escrow_bank_row.balance) or 0.0)
  local recipient_balance_pre = _round2(tonumber(recipient_row.balance) or 0.0)

  if escrow_balance_pre < amount then
    -- Shouldn't happen — escrow account balance == amount by construction.
    -- Si ocurre, hay data corruption.
    SONAR.Log.Error('Escrow.Release: escrow balance %s < amount %s (escrow_id=%s) — data corruption',
      escrow_balance_pre, amount, escrow_id)
    SONAR.Metrics.Counter('bank.escrow.release.escrow_balance_insufficient')
    return false, nil, 'TX_ROLLBACK'
  end

  local escrow_balance_post    = _round2(escrow_balance_pre - amount)
  local recipient_balance_post = _round2(recipient_balance_pre + amount)

  -- ---------------------------------------------------------------------------
  -- 6. Build TX (5 queries).
  -- ---------------------------------------------------------------------------
  local now = os.time()
  local transaction_id = _uuid_v4()
  -- NOTA: sonar_bank_movements.request_nonce UQ? Revisando SSoT §4.2 —
  -- CHAR(36) pero NO UNIQUE (solo PK). El request_id de C005 NO se persiste en
  -- request_nonce de las 2 rows (sería colisión con el de Create si mismos rows
  -- se re-consultan). Usamos transaction_id fresh per Release (mismo patrón transfer.lua).

  local movement_category
  if direction == 'seller' then
    movement_category = 'escrow_release'
  else
    -- buyer refund: S1.3 re-usa 'escrow_release' (no hay 'escrow_refund' en
    -- SSoT ENUM §4.2:556 ni en _VALID_CATEGORIES de movements.lua). Distinguible
    -- via sonar_escrows.released_to + audit category. S2+ ALTER ENUM ADD 'escrow_refund'.
    movement_category = 'escrow_release'
  end

  local q_debit_escrow = {
    query = [[
      UPDATE sonar_bank_accounts
      SET balance = balance - ?, updated_at = ?
      WHERE id = ?
    ]],
    values = { amount, now, escrow.escrow_account_id },
  }

  local q_credit_recipient = {
    query = [[
      UPDATE sonar_bank_accounts
      SET balance = balance + ?, updated_at = ?
      WHERE id = ?
        AND is_frozen = 0
        AND closed_at IS NULL
    ]],
    values = { amount, now, recipient_account_id },
  }

  local q_mov_escrow_debit = {
    query = [[
      INSERT INTO sonar_bank_movements
        (bank_account_id, occurred_at,
         amount, balance_after,
         category, counterpart_iban, concept,
         related_doc_id, related_offer_id, related_job_id,
         request_nonce, initiated_by_account_id, source_resource)
      VALUES (?, ?,
              ?, ?,
              ?, ?, ?,
              NULL, NULL, NULL,
              ?, ?, 'sonar_bank')
    ]],
    values = {
      escrow.escrow_account_id, now,
      -amount, escrow_balance_post,
      movement_category, recipient_row.iban, ('Escrow %s to %s'):format(target_state, direction),
      transaction_id, caller_account_id,
    },
  }

  local q_mov_recipient_credit = {
    query = [[
      INSERT INTO sonar_bank_movements
        (bank_account_id, occurred_at,
         amount, balance_after,
         category, counterpart_iban, concept,
         related_doc_id, related_offer_id, related_job_id,
         request_nonce, initiated_by_account_id, source_resource)
      VALUES (?, ?,
              ?, ?,
              ?, ?, ?,
              NULL, NULL, NULL,
              ?, ?, 'sonar_bank')
    ]],
    values = {
      recipient_account_id, now,
      amount, recipient_balance_post,
      movement_category, escrow_bank_row.iban, ('Escrow %s from %s'):format(target_state, escrow_id:sub(1, 8)),
      transaction_id, caller_account_id,
    },
  }

  -- Q5: UPDATE sonar_escrows status + audit fields.
  -- WHERE status='locked' guard: race contra 2º Release concurrente — el 1º
  -- que gane UPDATE 1 row, el 2º UPDATE 0 rows (no-op). oxmysql transaction
  -- interpretará UPDATE 0 rows como success (no throw) — detectamos via
  -- pre-SELECT escrow.status en step 3 (FSM guard) + optimistic AND status='locked'.
  local q_update_escrow = {
    query = [[
      UPDATE sonar_escrows
      SET status = ?,
          released_to = ?,
          released_by_account_id = ?,
          released_at = ?,
          updated_at = ?
      WHERE id = ?
        AND status = 'locked'
    ]],
    values = {
      target_state, direction, caller_account_id, now, now, escrow_id,
    },
  }

  -- ---------------------------------------------------------------------------
  -- 7. Execute TX.
  -- ---------------------------------------------------------------------------
  local start_ms = GetGameTimer()
  local tx_ok, tx_result = pcall(function()
    return SONAR.DB.Transaction({
      q_debit_escrow,
      q_credit_recipient,
      q_mov_escrow_debit,
      q_mov_recipient_credit,
      q_update_escrow,
    })
  end)
  local tx_ms = GetGameTimer() - start_ms

  if not tx_ok then
    SONAR.Log.Error('Escrow.Release TX crashed: escrow=%s dir=%s err=%s',
      escrow_id, direction, tostring(tx_result))
    SONAR.Metrics.Counter('bank.escrow.release.tx_crash')
    return false, nil, 'TX_CRASH'
  end
  if tx_result ~= true then
    SONAR.Log.Error('Escrow.Release TX rollback: escrow=%s dir=%s',
      escrow_id, direction)
    SONAR.Metrics.Counter('bank.escrow.release.tx_rollback')
    return false, nil, 'TX_ROLLBACK'
  end

  -- Post-condition sanity: re-read escrow + confirm transition persisted.
  -- Si status sigue 'locked' → race lost (otro thread ganó el UPDATE).
  local escrow_post = Escrow.GetById(escrow_id)
  if not escrow_post or escrow_post.status ~= target_state then
    SONAR.Log.Warn('Escrow.Release post-UPDATE race: escrow=%s expected=%s actual=%s',
      escrow_id, target_state, escrow_post and escrow_post.status or 'nil')
    SONAR.Metrics.Counter('bank.escrow.release.race_lost')
    return false, nil, 'INVALID_STATE'
  end

  SONAR.Metrics.Counter(('bank.escrow.release.success.%s'):format(direction))
  SONAR.Metrics.Observe('bank.escrow.release.tx_ms', tx_ms)
  FSM.LogTransition(escrow_id, 'locked', target_state, { direction = direction })

  -- ---------------------------------------------------------------------------
  -- 8. Audit log.
  -- ---------------------------------------------------------------------------
  local audit_category = (direction == 'seller')
    and Config.AuditCategories.EscrowReleased
    or  Config.AuditCategories.EscrowRefunded

  SONAR.Log.Audit({
    category = audit_category,
    action   = target_state,
    actor    = caller_cid,
    target   = escrow_id,
    payload  = {
      escrow_id      = escrow_id,
      direction      = direction,
      amount         = amount,
      recipient_iban = recipient_row.iban,
      transaction_id = transaction_id,
      request_id     = request_id,
      tx_ms          = tx_ms,
    },
  })

  -- ---------------------------------------------------------------------------
  -- 9. Publish event.
  -- ---------------------------------------------------------------------------
  local released_amount_seller = (direction == 'seller') and amount or 0
  local released_amount_buyer  = (direction == 'buyer')  and amount or 0

  if direction == 'seller' and Bank.Events and Bank.Events.PublishEscrowReleased then
    Bank.Events.PublishEscrowReleased({
      escrow_id              = escrow_id,
      buyer_iban             = nil,  -- redundant — consumer puede SELECT escrow
      seller_iban            = recipient_row.iban,
      amount                 = amount,
      released_amount_seller = released_amount_seller,
      released_amount_buyer  = released_amount_buyer,
      transaction_id         = transaction_id,
      requester_account_id   = caller_account_id,
      occurred_at            = now,
    })
  elseif direction == 'buyer' and Bank.Events and Bank.Events.PublishEscrowRefunded then
    Bank.Events.PublishEscrowRefunded({
      escrow_id              = escrow_id,
      buyer_iban             = recipient_row.iban,
      seller_iban            = nil,
      amount                 = amount,
      released_amount_seller = released_amount_seller,
      released_amount_buyer  = released_amount_buyer,
      transaction_id         = transaction_id,
      requester_account_id   = caller_account_id,
      occurred_at            = now,
    })
  end

  -- ---------------------------------------------------------------------------
  -- 10. Response data (SSoT §3.1 C005 canonical shape).
  -- ---------------------------------------------------------------------------
  return true, {
    released_amount_seller = released_amount_seller,
    released_amount_buyer  = released_amount_buyer,
    timestamp              = now * 1000,  -- UNIX ms consistente con C001/C002.
  }, nil
end

-- =============================================================================
-- Boot announce.
-- =============================================================================
SONAR.Log.Info('Escrow module ready (fee_rate=%.2f%%, fee_range=[%.2f, %.2f]€, expiry_default=%ds)',
  Config.EscrowFeeRate * 100, Config.EscrowFeeMin, Config.EscrowFeeMax, Config.EscrowDefaultExpirySeconds)
