-- =============================================================================
-- Admirals Bank — server/accounts.lua
--
-- Gestión de admirals_bank_accounts (CRUD básico S1.1) + EnsureStarterAccount
-- (idempotent first-login flow que crea admirals_accounts + bank_account
-- + 2.500€ starter seed atómicamente vía Admirals.DB.Transaction).
--
-- API pública:
--   Accounts.EnsureStarterAccount(citizenId, source?)
--     → ok, account_row | false, err_code
--     Idempotent: si ya existe personal account para citizenId, return existing.
--
--   Accounts.GetByIban(iban)
--     → row | nil
--
--   Accounts.GetPersonalByCitizenId(citizenId)
--     → row | nil
--     Si admirals_accounts row no existe → nil (caller decide si crear).
--
--   Accounts.GetAccountIdByCitizenId(citizenId)
--     → admirals_accounts.id (UUID) | nil
--
-- TECHNICAL DEBT (anotado en SESSION_LOG S1.1):
--   - INSERT a admirals_accounts es responsabilidad de admirals_bank en S1.1,
--     pero arquitectónicamente debería vivir en admirals_player_lifecycle (o
--     admirals_core mismo). Extract en S2+.
--   - alias derivation primitiva ('Player_' + citizenId truncado) — sustituir
--     por Bridges.Identity.GetPlayerData lookup en S2 cuando el bridge expose
--     esa API cross-resource.
--
-- Referencias SSoT:
--   docs/technical/03_db_schema.md §3.1 (admirals_accounts canonical).
--   docs/technical/03_db_schema.md §4.1 (admirals_bank_accounts canonical).
--   docs/technical/03_db_schema.md §4.2 (admirals_bank_movements canonical).
--   docs/economy/01_economic_model.md §4.1 (starter balance 2.500 €).
--   docs/technical/04_api_contracts.md §10.3 (audit logging obligatorio).
-- =============================================================================

Admirals = Admirals or {}
Admirals.Bank = Admirals.Bank or {}
Admirals.Bank.Accounts = Admirals.Bank.Accounts or {}

local Config = Admirals.Bank.Config
local IBAN = Admirals.Bank.IBAN
local Accounts = Admirals.Bank.Accounts

-- =============================================================================
-- UUID v4 generator (RFC 4122 §4.4) — mismo patrón event_bus.lua:67-74.
-- Usado para id de admirals_accounts y admirals_bank_accounts (CHAR(36) PK).
-- =============================================================================
local function _uuid_v4()
  local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
  return (template:gsub('[xy]', function(c)
    local v = (c == 'x') and math.random(0, 15) or math.random(8, 11)
    return string.format('%x', v)
  end))
end

-- Detectar framework activo via admirals_bridges export.
-- Si Bridges no responde (timeout / error), default 'unknown' — non-fatal,
-- pero log warn para visibilidad.
local function _detect_framework_source()
  local ok, active = pcall(function() return exports.admirals_bridges:GetActive() end)
  if not ok or type(active) ~= 'table' then
    Admirals.Log.Warn('Could not resolve framework_source via Bridges.GetActive: %s', tostring(active))
    return 'unknown'
  end
  return active.identity or 'unknown'
end

-- Derivar alias inicial desde citizenId (S1.1 primitive — improve S2+).
-- 'CIT_ABCD1234' style. Truncado a 64 chars (column limit).
local function _derive_alias(citizen_id)
  local s = 'Player_' .. tostring(citizen_id or 'unknown')
  if #s > 64 then s = s:sub(1, 64) end
  return s
end

-- =============================================================================
-- Public — GetByIban.
-- =============================================================================
function Accounts.GetByIban(iban)
  if type(iban) ~= 'string' or iban == '' then return nil end
  return Admirals.DB.FetchOne([[
    SELECT id, iban, type, owner_account_id, owner_company_id,
           balance, daily_limit_out, is_frozen, frozen_reason,
           created_at, updated_at, closed_at
    FROM admirals_bank_accounts
    WHERE iban = ?
  ]], { iban })
end

-- =============================================================================
-- Public — GetAccountIdByCitizenId.
-- Lookup admirals_accounts.id (UUID) por citizen_id framework.
-- Returns nil si admirals_accounts row no existe aún para ese citizen.
-- =============================================================================
function Accounts.GetAccountIdByCitizenId(citizen_id)
  if type(citizen_id) ~= 'string' or citizen_id == '' then return nil end
  return Admirals.DB.Scalar([[
    SELECT id FROM admirals_accounts WHERE char_id = ? LIMIT 1
  ]], { citizen_id })
end

-- =============================================================================
-- Public — GetPersonalByCitizenId.
-- Lookup admirals_bank_accounts personal por citizen_id (joined via accounts).
-- =============================================================================
function Accounts.GetPersonalByCitizenId(citizen_id)
  if type(citizen_id) ~= 'string' or citizen_id == '' then return nil end
  return Admirals.DB.FetchOne([[
    SELECT bk.id, bk.iban, bk.type, bk.owner_account_id, bk.owner_company_id,
           bk.balance, bk.daily_limit_out, bk.is_frozen, bk.frozen_reason,
           bk.created_at, bk.updated_at, bk.closed_at
    FROM admirals_bank_accounts bk
    JOIN admirals_accounts a ON a.id = bk.owner_account_id
    WHERE a.char_id = ?
      AND bk.type = 'personal'
      AND bk.closed_at IS NULL
    LIMIT 1
  ]], { citizen_id })
end

-- =============================================================================
-- Internal — Ensure admirals_accounts row existe (creates if not).
-- Returns admirals_accounts.id (UUID).
--
-- TECHNICAL DEBT: S2+ extract a admirals_player_lifecycle resource.
-- =============================================================================
local function _ensure_admirals_account(citizen_id)
  local existing_id = Accounts.GetAccountIdByCitizenId(citizen_id)
  if existing_id then
    -- Update last_login_at + updated_at app-managed.
    Admirals.DB.Execute([[
      UPDATE admirals_accounts
      SET last_login_at = ?, updated_at = ?
      WHERE id = ?
    ]], { os.time(), os.time(), existing_id })
    return existing_id
  end

  -- Crear nuevo admirals_accounts row.
  local new_id = _uuid_v4()
  local fw = _detect_framework_source()
  local alias = _derive_alias(citizen_id)
  local now = os.time()

  Admirals.DB.Insert([[
    INSERT INTO admirals_accounts
      (id, char_id, framework_source, alias, created_at, updated_at, last_login_at)
    VALUES (?, ?, ?, ?, ?, ?, ?)
  ]], { new_id, citizen_id, fw, alias, now, now, now })

  Admirals.Log.Info('Created admirals_accounts row id=%s char_id=%s framework=%s',
    new_id, citizen_id, fw)
  Admirals.Metrics.Counter('bank.accounts.admirals_account_created')

  -- Audit (ownership creation).
  Admirals.Log.Audit({
    category = 'identity.account_create',
    action = 'create',
    actor = citizen_id,
    target = new_id,
    payload = { framework_source = fw, alias = alias },
  })

  return new_id
end

-- =============================================================================
-- Public — EnsureStarterAccount.
--
-- Idempotent: invocable múltiples veces, solo crea la primera vez.
--
-- Flow:
--   1. Resolve admirals_accounts.id (create if needed).
--   2. Check si ya tiene personal bank_account → return existing (no-op).
--   3. Si no:
--      a. Generate IBAN unique.
--      b. TRANSACTION:
--         - INSERT admirals_bank_accounts (balance=2500, type='personal').
--         - INSERT admirals_bank_movements (amount=+2500, balance_after=2500,
--           category='starter_seed', request_nonce='starter_<citizen_id>',
--           source_resource='admirals_bank').
--      c. Audit log + Metrics + Bus.Publish('admirals:bank:account_created' +
--         'admirals:bank:starter_balance_credited').
--
-- @param citizen_id string — framework citizenId (qbox/qbcore/esx/native).
-- @param source number? — FiveM source id (opcional, debug only).
-- @return ok:boolean, result_or_err
--   ok=true,  result = { account_id, iban, balance, created } (created=bool si nuevo)
--   ok=false, err   = string error code | string error message
-- =============================================================================
function Accounts.EnsureStarterAccount(citizen_id, source)
  if type(citizen_id) ~= 'string' or citizen_id == '' then
    return false, 'INVALID_CITIZEN_ID'
  end

  local start_ms = GetGameTimer()

  -- Step 1: ensure admirals_accounts row.
  local account_id_ok, account_id_or_err = pcall(_ensure_admirals_account, citizen_id)
  if not account_id_ok then
    Admirals.Log.Error('EnsureStarterAccount: _ensure_admirals_account failed for %s: %s',
      citizen_id, tostring(account_id_or_err))
    Admirals.Metrics.Counter('bank.accounts.starter_failures')
    return false, 'ACCOUNT_ENSURE_FAILED'
  end
  local account_id = account_id_or_err

  -- Step 2: check si ya tiene personal bank_account.
  local existing = Accounts.GetPersonalByCitizenId(citizen_id)
  if existing then
    Admirals.Log.Debug('EnsureStarterAccount: existing bank_account for %s (iban=%s, balance=%s)',
      citizen_id, existing.iban, existing.balance)
    Admirals.Metrics.Counter('bank.accounts.starter_idempotent_hit')
    return true, {
      account_id = account_id,
      bank_account_id = existing.id,
      iban = existing.iban,
      balance = tonumber(existing.balance) or 0.0,
      created = false,
    }
  end

  -- Step 3a: generate IBAN.
  local iban_ok, iban_or_err = pcall(IBAN.Generate)
  if not iban_ok then
    Admirals.Log.Error('EnsureStarterAccount: IBAN.Generate failed for %s: %s',
      citizen_id, tostring(iban_or_err))
    Admirals.Metrics.Counter('bank.accounts.starter_failures')
    return false, 'IBAN_GEN_FAILED'
  end
  local iban = iban_or_err

  -- Step 3b: transaction atómica.
  -- Nonce: UUID v4 (36 chars, fits CHAR(36) per SSoT §4.2:563). Concatenar
  -- 'starter_' + citizen_id puede exceder 36 chars en frameworks ESX/native
  -- donde citizen_id es 'license:...' o 'steam:0:1:...' (>28 chars).
  -- Idempotency real está en step 2 (GetPersonalByCitizenId existing check),
  -- el nonce es solo trail anti-replay si alguien llama INSERT manual.
  local bank_account_id = _uuid_v4()
  local now = os.time()
  local nonce = _uuid_v4()
  local starter_balance = Config.StarterBalanceEur

  local tx_ok, tx_err = pcall(function()
    return Admirals.DB.Transaction({
      {
        query = [[
          INSERT INTO admirals_bank_accounts
            (id, iban, type, owner_account_id, owner_company_id,
             balance, daily_limit_out, is_frozen, frozen_reason,
             created_at, updated_at, closed_at)
          VALUES (?, ?, 'personal', ?, NULL,
                  ?, NULL, 0, NULL,
                  ?, ?, NULL)
        ]],
        values = { bank_account_id, iban, account_id, starter_balance, now, now },
      },
      {
        query = [[
          INSERT INTO admirals_bank_movements
            (bank_account_id, occurred_at,
             amount, balance_after,
             category, counterpart_iban, concept,
             related_doc_id, related_offer_id, related_job_id,
             request_nonce, initiated_by_account_id, source_resource)
          VALUES (?, ?,
                  ?, ?,
                  ?, NULL, ?,
                  NULL, NULL, NULL,
                  ?, NULL, 'admirals_bank')
        ]],
        values = {
          bank_account_id, now,
          starter_balance, starter_balance,
          Config.StarterMovementCategory, Config.StarterMovementConcept,
          nonce,
        },
      },
    })
  end)

  if not tx_ok then
    -- pcall trapped error desde Admirals.DB.Transaction (alguna query crash).
    Admirals.Log.Error('EnsureStarterAccount: TX crashed for %s: %s', citizen_id, tostring(tx_err))
    Admirals.Metrics.Counter('bank.accounts.starter_failures')
    return false, 'TX_CRASH'
  end

  if tx_err ~= true then
    -- pcall OK pero la TX hizo rollback (returned false).
    -- Posibles causas: UNIQUE iban race, FK fail, CHECK fail.
    Admirals.Log.Error('EnsureStarterAccount: TX rolled back for %s (iban=%s)',
      citizen_id, iban)
    Admirals.Metrics.Counter('bank.accounts.starter_rollbacks')
    return false, 'TX_ROLLBACK'
  end

  local duration_ms = GetGameTimer() - start_ms

  -- Step 3c: audit + metrics + bus.
  Admirals.Log.Info('EnsureStarterAccount created: %s → %s (%s €) in %dms',
    citizen_id, iban, starter_balance, duration_ms)

  Admirals.Log.Audit({
    category = Config.AuditCategories.StarterSeed,
    action = 'credit',
    actor = citizen_id,
    target = bank_account_id,
    payload = {
      iban = iban,
      balance = starter_balance,
      currency = 'EUR',
      nonce = nonce,
    },
  })

  Admirals.Metrics.Counter('bank.accounts.starter_created')
  Admirals.Metrics.Observe('bank.accounts.starter_duration_ms', duration_ms)

  Admirals.Bus.Publish(Config.Events.AccountCreated, {
    account_id = account_id,
    bank_account_id = bank_account_id,
    citizen_id = citizen_id,
    iban = iban,
    type = 'personal',
    balance = starter_balance,
    currency = 'EUR',
    source = source,
  })

  Admirals.Bus.Publish(Config.Events.StarterBalanceCredited, {
    citizen_id = citizen_id,
    iban = iban,
    amount = starter_balance,
    currency = 'EUR',
    nonce = nonce,
  })

  return true, {
    account_id = account_id,
    bank_account_id = bank_account_id,
    iban = iban,
    balance = starter_balance,
    created = true,
  }
end

-- =============================================================================
-- Boot announce.
-- =============================================================================
Admirals.Log.Info('Accounts module ready (starter_balance=%s €, currency=EUR)',
  Config.StarterBalanceEur)
