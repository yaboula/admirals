-- =============================================================================
-- sonar_bank/server/admin_commands.lua
--
-- Phase 8+ post-rename smoke harness — DEV ONLY (gated por convar + ACE).
--
-- Replaces the deleted-per-sprint pattern (S1.1/S1.2/S1.3 cleanup post sign-off)
-- con commands permanentes integrados, gated por:
--   1. Convar `sonar_dev_mode 1` (server.cfg) — sin esto, NO se registran.
--   2. ACE permission `sonar.admin` per source>0 (console source=0 siempre allow).
--
-- Comandos disponibles (todos prefijo `/sonar_smoke_*`):
--
--   STATUS / INSPECT (read-only):
--     /sonar_smoke_status                                 — versions + counts.
--     /sonar_smoke_dump_accounts                          — list bank accounts.
--     /sonar_smoke_dump_movements [iban] [limit]          — list movements.
--     /sonar_smoke_dump_escrows [status]                  — list escrows.
--     /sonar_smoke_iban_gen [count]                       — gen IBANs sin DB write.
--
--   MUTATING (write):
--     /sonar_smoke_seed_player [source]                   — EnsureStarterAccount.
--     /sonar_smoke_transfer <from_iban> <to_iban> <amount> [concept]
--                                                         — invoke Transfer.Execute.
--     /sonar_smoke_escrow_create <buyer_iban> <seller_iban> <amount>
--                                                         — invoke Escrow.Create.
--     /sonar_smoke_escrow_release <escrow_id> <release|refund> [split_ratio]
--                                                         — invoke Escrow.Release.
--
-- Convención output: stdout (`print`) prefijo `[smoke]`. JSON pretty para tablas.
--
-- SSoT: docs/qa/01_testing_protocol.md (smoke procedural patterns).
-- Phase 8 ADR-013 — replaces deleted client/smoke_*.lua harnesses post-rename.
-- =============================================================================

-- Convar gate (server.cfg `set sonar_dev_mode 1`).
local DEV_MODE = GetConvar('sonar_dev_mode', '0') == '1'

if not DEV_MODE then
  -- No-op silent: no warnings spammeando log producción.
  return
end

print('[sonar_bank][admin_commands] DEV MODE active — registering /sonar_smoke_* commands')

-- -----------------------------------------------------------------------------
-- Module local aliases — todos los módulos de sonar_bank están namespaced bajo
-- SONAR.Bank.* (init.lua orchestration). admin_commands.lua carga LAST, después
-- del init.lua boot, así que SONAR.Bank.* está fully populated.
-- -----------------------------------------------------------------------------
local Config    = SONAR.Bank.Config
local Bank      = SONAR.Bank
local IBAN      = SONAR.Bank.IBAN
local Accounts  = SONAR.Bank.Accounts
local Movements = SONAR.Bank.Movements
local Transfer  = SONAR.Bank.Transfer
local Escrow    = SONAR.Bank.Escrow

-- -----------------------------------------------------------------------------
-- ACE gate helper.
-- source=0 (server console) → always allow.
-- source>0 (player) → IsPlayerAceAllowed(source, 'sonar.admin') required.
-- -----------------------------------------------------------------------------
local function _ace_allowed(source)
  source = tonumber(source) or 0
  if source <= 0 then return true end
  return IsPlayerAceAllowed(source, 'sonar.admin') == true
end

local function _deny(source)
  if (tonumber(source) or 0) > 0 then
    TriggerClientEvent('chat:addMessage', source, {
      args = { '^1[smoke]^7', 'denied: ace `sonar.admin` required' }
    })
  else
    print('^1[smoke]^7 denied: ace `sonar.admin` required (player only).')
  end
end

local function _say(source, msg)
  if (tonumber(source) or 0) > 0 then
    TriggerClientEvent('chat:addMessage', source, { args = { '[smoke]', msg } })
  end
  print('[smoke] ' .. msg)
end

local function _json(tbl)
  -- Best-effort pretty-print for console.
  if type(tbl) ~= 'table' then return tostring(tbl) end
  local ok, encoded = pcall(function()
    return (json and json.encode(tbl)) or tostring(tbl)
  end)
  return ok and encoded or tostring(tbl)
end

local function _new_request_id()
  -- UUID v4 simplificado (suficiente para smoke idempotency).
  local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
  return (template:gsub('[xy]', function(c)
    local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
    return ('%x'):format(v)
  end))
end

-- -----------------------------------------------------------------------------
-- Helper: resolve from_iban → citizen_id (Accounts.GetByIban gives owner_account_id;
-- we need char_id of sonar_accounts row for Transfer.Execute(from_cid, ...)).
-- -----------------------------------------------------------------------------
local function _cid_from_iban(iban)
  local row = SONAR.DB.FetchOne([[
    SELECT a.char_id AS cid
    FROM sonar_bank_accounts ba
    JOIN sonar_accounts a ON a.id = ba.owner_account_id
    WHERE ba.iban = ?
    LIMIT 1
  ]], { iban })
  return row and row.cid or nil
end

-- =============================================================================
-- STATUS / INSPECT commands (read-only).
-- =============================================================================

RegisterCommand('sonar_smoke_status', function(source)
  if not _ace_allowed(source) then return _deny(source) end

  local accounts_count = SONAR.DB.Scalar('SELECT COUNT(*) FROM sonar_bank_accounts') or 0
  local movements_count = SONAR.DB.Scalar('SELECT COUNT(*) FROM sonar_bank_movements') or 0
  local escrows_count = SONAR.DB.Scalar('SELECT COUNT(*) FROM sonar_escrows') or 0
  local schema_count = SONAR.DB.Scalar('SELECT COUNT(*) FROM sonar_schema_versions') or 0

  _say(source, ('sonar_bank v%s | accounts=%d movements=%d escrows=%d migrations_applied=%d'):format(
    Bank.Version() or '?', accounts_count, movements_count, escrows_count, schema_count
  ))
end, false)

RegisterCommand('sonar_smoke_dump_accounts', function(source)
  if not _ace_allowed(source) then return _deny(source) end

  local rows = SONAR.DB.FetchAll([[
    SELECT iban, owner_type AS type, owner_type, account_class, balance, owner_account_id, owner_company_id, is_frozen, closed_at
    FROM sonar_bank_accounts
    ORDER BY owner_type, account_class, iban
  ]], {}) or {}

  _say(source, ('accounts (%d):'):format(#rows))
  for _, r in ipairs(rows) do
    print(('  %s  type=%s  bal=%s€  owner_acct=%s  owner_co=%s  frozen=%s  closed=%s'):format(
      r.iban, r.type, tostring(r.balance), tostring(r.owner_account_id),
      tostring(r.owner_company_id), tostring(r.is_frozen), tostring(r.closed_at)
    ))
  end
end, false)

RegisterCommand('sonar_smoke_dump_movements', function(source, args)
  if not _ace_allowed(source) then return _deny(source) end

  local iban = args[1]
  local limit = tonumber(args[2]) or 20

  local sql, params
  if iban then
    sql = [[
      SELECT m.occurred_at, m.amount, m.balance_after, m.category, m.counterpart_iban, m.concept
      FROM sonar_bank_movements m
      JOIN sonar_bank_accounts ba ON ba.id = m.bank_account_id
      WHERE ba.iban = ?
      ORDER BY m.occurred_at DESC
      LIMIT ?
    ]]
    params = { iban, limit }
  else
    sql = [[
      SELECT occurred_at, amount, balance_after, category, counterpart_iban, concept
      FROM sonar_bank_movements
      ORDER BY occurred_at DESC
      LIMIT ?
    ]]
    params = { limit }
  end

  local rows = SONAR.DB.FetchAll(sql, params) or {}
  _say(source, ('movements (%d, iban=%s):'):format(#rows, iban or 'ALL'))
  for _, r in ipairs(rows) do
    print(('  ts=%d  amount=%s  after=%s  cat=%s  cp=%s  concept=%s'):format(
      r.occurred_at, tostring(r.amount), tostring(r.balance_after),
      r.category, tostring(r.counterpart_iban), tostring(r.concept)
    ))
  end
end, false)

RegisterCommand('sonar_smoke_dump_escrows', function(source, args)
  if not _ace_allowed(source) then return _deny(source) end

  local status_filter = args[1]
  local sql, params
  if status_filter then
    sql = [[
      SELECT id, status, amount, fee_charged, expires_at, released_to, released_at
      FROM sonar_escrows
      WHERE status = ?
      ORDER BY created_at DESC
      LIMIT 50
    ]]
    params = { status_filter }
  else
    sql = [[
      SELECT id, status, amount, fee_charged, expires_at, released_to, released_at
      FROM sonar_escrows
      ORDER BY created_at DESC
      LIMIT 50
    ]]
    params = {}
  end

  local rows = SONAR.DB.FetchAll(sql, params) or {}
  _say(source, ('escrows (%d, status=%s):'):format(#rows, status_filter or 'ALL'))
  for _, r in ipairs(rows) do
    print(('  id=%s  status=%s  amount=%s  fee=%s  exp=%d  released_to=%s  released_at=%s'):format(
      r.id, r.status, tostring(r.amount), tostring(r.fee_charged),
      r.expires_at, tostring(r.released_to), tostring(r.released_at)
    ))
  end
end, false)

RegisterCommand('sonar_smoke_iban_gen', function(source, args)
  if not _ace_allowed(source) then return _deny(source) end

  local n = tonumber(args[1]) or 5
  if n < 1 then n = 1 end
  if n > 50 then n = 50 end

  _say(source, ('generating %d IBANs (no DB write):'):format(n))
  for i = 1, n do
    local iban, err = IBAN.Generate()
    if iban then
      print(('  [%d] %s'):format(i, iban))
    else
      print(('  [%d] ERR: %s'):format(i, tostring(err)))
    end
  end
end, false)

-- =============================================================================
-- MUTATING commands.
-- =============================================================================

RegisterCommand('sonar_smoke_seed_player', function(source, args)
  if not _ace_allowed(source) then return _deny(source) end

  local target_src = tonumber(args[1]) or tonumber(source)
  if not target_src or target_src <= 0 then
    return _say(source, 'usage: /sonar_smoke_seed_player <source>')
  end

  local cid = Bank.GetCitizenIdBySource(target_src)
  if not cid then
    return _say(source, ('no citizen_id for source=%d (player connected?)'):format(target_src))
  end

  local ok, result = Accounts.EnsureStarterAccount(cid, target_src)
  if ok then
    _say(source, ('seed OK: cid=%s iban=%s balance=%s€ created=%s'):format(
      cid, result.iban, tostring(result.balance), tostring(result.created)
    ))
  else
    _say(source, ('seed FAIL: cid=%s err=%s'):format(cid, tostring(result)))
  end
end, false)

RegisterCommand('sonar_smoke_transfer', function(source, args)
  if not _ace_allowed(source) then return _deny(source) end

  local from_iban, to_iban, amount, concept = args[1], args[2], tonumber(args[3]), args[4]
  if not from_iban or not to_iban or not amount then
    return _say(source, 'usage: /sonar_smoke_transfer <from_iban> <to_iban> <amount> [concept]')
  end

  local from_cid = _cid_from_iban(from_iban)
  if not from_cid then
    return _say(source, ('cid not resolvable for from_iban=%s (system/company iban?)'):format(from_iban))
  end

  local request_id = _new_request_id()
  local ok, result, err = Transfer.Execute(from_cid, from_iban, to_iban, amount, concept or 'smoke_test', request_id)

  if ok then
    _say(source, ('transfer OK: tx=%s req=%s amount=%s€ from=%s to=%s'):format(
      tostring(result and result.transaction_id or '?'), request_id, tostring(amount), from_iban, to_iban
    ))
    print('  full: ' .. _json(result))
  else
    _say(source, ('transfer FAIL: %s'):format(tostring(err)))
  end
end, false)

RegisterCommand('sonar_smoke_escrow_create', function(source, args)
  if not _ace_allowed(source) then return _deny(source) end

  local buyer_iban, seller_iban, amount = args[1], args[2], tonumber(args[3])
  if not buyer_iban or not seller_iban or not amount then
    return _say(source, 'usage: /sonar_smoke_escrow_create <buyer_iban> <seller_iban> <amount>')
  end

  local buyer_cid = _cid_from_iban(buyer_iban)
  if not buyer_cid then
    return _say(source, ('cid not resolvable for buyer_iban=%s'):format(buyer_iban))
  end

  local request_id = _new_request_id()
  local ok, result, err = Escrow.Create(
    buyer_cid, buyer_iban, seller_iban, amount,
    nil,        -- contract_id
    'manual',   -- release_condition
    nil,        -- release_date
    request_id
  )

  if ok then
    _say(source, ('escrow OK: id=%s req=%s amount=%s€ fee=%s€ status=%s'):format(
      tostring(result and result.escrow_id or '?'), request_id,
      tostring(result and result.amount or '?'), tostring(result and result.fee_charged or '?'),
      tostring(result and result.status or '?')
    ))
    print('  full: ' .. _json(result))
  else
    _say(source, ('escrow FAIL: %s'):format(tostring(err)))
  end
end, false)

RegisterCommand('sonar_smoke_escrow_release', function(source, args)
  if not _ace_allowed(source) then return _deny(source) end

  local escrow_id, direction_alias, split_ratio = args[1], args[2], tonumber(args[3])
  if not escrow_id or not direction_alias then
    return _say(source, 'usage: /sonar_smoke_escrow_release <escrow_id> <release|refund|seller|buyer> [split_ratio]')
  end

  -- Map smoke aliases → API direction (Escrow.Release expects 'seller'|'buyer').
  --   release → seller (funds to seller, terminal=released)
  --   refund  → buyer  (funds back to buyer, terminal=refunded)
  --   seller/buyer passthrough (también acepta directo).
  local _ALIAS = { release = 'seller', refund = 'buyer', seller = 'seller', buyer = 'buyer' }
  local direction = _ALIAS[direction_alias]
  if not direction then
    return _say(source, ('unknown direction `%s` (use: release|refund|seller|buyer)'):format(direction_alias))
  end

  -- split no implementado en Escrow.Release (returns NOT_IMPLEMENTED). Excluido alias.
  if direction == 'split' and not split_ratio then split_ratio = 0.5 end

  -- caller_cid resolution:
  --   - Player source>0 → Bank.GetCitizenIdBySource.
  --   - Console source=0 → auto-resolve from escrow per authorization matrix
  --     (escrow.lua _authorize_release):
  --       direction='seller' (release) → caller must own escrow.seller_account_id.
  --       direction='buyer'  (refund)  → caller must own escrow.buyer_account_id.
  local caller_cid
  if (tonumber(source) or 0) > 0 then
    caller_cid = Bank.GetCitizenIdBySource(source)
  else
    local owner_col = (direction == 'seller') and 'e.seller_account_id' or 'e.buyer_account_id'
    local row = SONAR.DB.FetchOne(([[
      SELECT a.char_id AS cid
      FROM sonar_escrows e
      JOIN sonar_bank_accounts ba ON ba.id = %s
      JOIN sonar_accounts a ON a.id = ba.owner_account_id
      WHERE e.id = ?
      LIMIT 1
    ]]):format(owner_col), { escrow_id })
    caller_cid = row and row.cid
  end

  if not caller_cid then
    return _say(source, ('cannot resolve caller_cid for escrow_id=%s'):format(escrow_id))
  end

  local request_id = _new_request_id()
  local ok, result, err = Escrow.Release(caller_cid, escrow_id, direction, split_ratio, request_id)

  if ok then
    _say(source, ('release OK: id=%s direction=%s req=%s'):format(escrow_id, direction, request_id))
    print('  full: ' .. _json(result))
  else
    _say(source, ('release FAIL: %s'):format(tostring(err)))
  end
end, false)

print('[sonar_bank][admin_commands] 9 /sonar_smoke_* commands registered (ACE: sonar.admin).')
