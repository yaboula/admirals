-- =============================================================================
-- Admirals Bank — client/smoke.lua
--
-- S1.2 SMOKE TEST TEMPORAL — DELETE POST SIGN-OFF (cleanup commit separado).
-- Disposable infrastructure per workspace convention S1.x (igual que el
-- patrón S1.1 client/smoke.lua removido en S1.1 cleanup).
--
-- Provee 5 client-side commands para ejecutar smoke 10 pasos del founder:
--
--   /smoke_transfer <to_iban> <amount>       — happy path (paso 2).
--   /smoke_transfer_replay [request_id]      — forced replay (paso 3).
--                                              Sin args → replayea último OK.
--   /smoke_transfer_self                     — SELF_TRANSFER (paso 4).
--   /smoke_transfer_overdraw                 — INSUFFICIENT_FUNDS (paso 5).
--   /smoke_transfer_burst <to_iban>          — 11 calls → RATE_LIMITED (paso 6).
--
-- Diseño:
--   1. Cliente fetcha su propio IBAN via C001 admirals:bank:getBalance al boot
--      (cached). Si el cache está vacío en momento del comando, re-fetch on-demand.
--   2. UUID v4 generado client-side per nueva attempt.
--   3. lib.callback.await para invocar C002 admirals:bank:transfer.
--   4. _last_request_id cached para soportar /smoke_transfer_replay sin args
--      (UX-friendly per founder spec — evita copy-paste UUIDs).
--
-- Output:
--   Imprime al chat (^2 verde OK, ^1 rojo FAIL, ^3 amarillo info).
--   También TriggerEvent('chat:addMessage') para persistir en historial.
--
-- Convención error_code (per SSoT §3.1 + S1.2 fix):
--   AMOUNT_OUT_OF_RANGE, INVALID_IBAN, SELF_TRANSFER, NOT_AUTHORIZED,
--   ACCOUNT_FROZEN, INSUFFICIENT_FUNDS, RACE_DETECTED, TX_CRASH, TX_ROLLBACK,
--   RATE_LIMITED, NOT_AUTHENTICATED, MISSING_FIELD.
-- =============================================================================

-- =============================================================================
-- State.
-- =============================================================================
local _own_iban = nil          -- cached self IBAN (refreshed on-demand)
local _own_balance = 0.0       -- cached self balance (informational)
local _last_request_id = nil   -- last successful transfer request_id (for replay)

-- =============================================================================
-- UUID v4 generator (client-side — per request_id idempotency key).
-- =============================================================================
local function _uuid_v4()
  local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
  return (template:gsub('[xy]', function(c)
    local v = (c == 'x') and math.random(0, 15) or math.random(8, 11)
    return string.format('%x', v)
  end))
end

-- =============================================================================
-- Print helpers.
-- =============================================================================
local function _print(msg)
  print(msg)  -- F8 console
  TriggerEvent('chat:addMessage', { args = { msg } })
end

local function _ok(fmt, ...)
  _print('^2[smoke] ' .. string.format(fmt, ...) .. '^7')
end

local function _fail(fmt, ...)
  _print('^1[smoke] ' .. string.format(fmt, ...) .. '^7')
end

local function _info(fmt, ...)
  _print('^3[smoke] ' .. string.format(fmt, ...) .. '^7')
end

-- =============================================================================
-- Internal — fetch self IBAN+balance via C001 getBalance.
--
-- @param force boolean — force refresh even if cached.
-- @return iban:string | nil, balance:number | nil
-- =============================================================================
local function _fetch_own_iban(force)
  if _own_iban and not force then return _own_iban, _own_balance end

  local response = lib.callback.await('admirals:bank:getBalance', false, {})
  if type(response) ~= 'table' or response.success ~= true then
    _fail('Failed to fetch own balance via C001: %s',
      tostring(response and response.error_code or 'NO_RESPONSE'))
    return nil, nil
  end

  _own_iban = response.data and response.data.iban
  _own_balance = tonumber(response.data and response.data.balance) or 0.0
  return _own_iban, _own_balance
end

-- =============================================================================
-- Internal — execute C002 transfer + print result.
--
-- @param from_iban string
-- @param to_iban string
-- @param amount number
-- @param request_id string (UUID v4, idempotency key)
-- @param concept string
-- @return response:table | nil
-- =============================================================================
local function _do_transfer(from_iban, to_iban, amount, request_id, concept)
  local response = lib.callback.await('admirals:bank:transfer', false, {
    from_iban  = from_iban,
    to_iban    = to_iban,
    amount     = amount,
    concept    = concept or 'Smoke',
    request_id = request_id,
  })

  if type(response) ~= 'table' then
    _fail('No response from C002 (request_id=%s)', request_id)
    return nil
  end

  if response.success == true then
    _last_request_id = request_id
    _ok('OK | request_id=%s | tx=%s | new_balance=%.2f €',
      request_id,
      tostring(response.data and response.data.transaction_id or '?'),
      tonumber(response.data and response.data.new_balance_from) or 0.0)
  else
    _fail('FAIL | request_id=%s | error_code=%s | message=%s',
      request_id,
      tostring(response.error_code or 'UNKNOWN'),
      tostring(response.message or ''))
  end
  return response
end

-- =============================================================================
-- /smoke_transfer <to_iban> <amount>
-- Smoke step 2 — happy path C002.
-- =============================================================================
RegisterCommand('smoke_transfer', function(source, args)
  local to_iban = args[1]
  local amount = tonumber(args[2])

  if not to_iban or not amount then
    _info('Usage: /smoke_transfer <to_iban> <amount>')
    return
  end

  local from_iban, balance = _fetch_own_iban(true)  -- force refresh — para reflejar balance pre-transfer
  if not from_iban then return end

  _info('Initiating transfer: %s → %s | amount=%.2f € | balance_pre=%.2f €',
    from_iban, to_iban, amount, balance or 0.0)

  local req_id = _uuid_v4()
  _do_transfer(from_iban, to_iban, amount, req_id, 'Smoke transfer S1.2')
end, false)

-- =============================================================================
-- /smoke_transfer_replay [request_id]
-- Smoke step 3 — forced idempotency replay. Sin args → replayea último OK.
-- =============================================================================
RegisterCommand('smoke_transfer_replay', function(source, args)
  local req_id = args[1] or _last_request_id

  if not req_id then
    _info('Usage: /smoke_transfer_replay [request_id]')
    _info('  (sin args replayea el último request_id exitoso — ninguno cached aún)')
    return
  end

  local from_iban = _fetch_own_iban(false)
  if not from_iban then return end

  _info('Replay request_id=%s — esperado: response cached idéntica + audit replay log',
    req_id)

  -- Args spurios para el replay: server resuelve por request_id, los demás
  -- campos NO afectan el resultado (cached response retornada).
  -- PERO — para que el shape validation pase, mandamos campos válidos.
  _do_transfer(from_iban, from_iban, 1.00, req_id, 'Replay')
end, false)

-- =============================================================================
-- /smoke_transfer_self
-- Smoke step 4 — SELF_TRANSFER error_code.
-- =============================================================================
RegisterCommand('smoke_transfer_self', function(source, args)
  local own_iban = _fetch_own_iban(true)
  if not own_iban then return end

  _info('Self-transfer attempt: %s → %s | esperado SELF_TRANSFER', own_iban, own_iban)

  local req_id = _uuid_v4()
  _do_transfer(own_iban, own_iban, 10.00, req_id, 'Self test')
end, false)

-- =============================================================================
-- /smoke_transfer_overdraw
-- Smoke step 5 — INSUFFICIENT_FUNDS error_code.
-- =============================================================================
RegisterCommand('smoke_transfer_overdraw', function(source, args)
  local own_iban, balance = _fetch_own_iban(true)
  if not own_iban then return end

  -- Necesitamos un IBAN destino válido — usamos system IBAN AD-SYS0-0000-0001.
  -- (Migration 004 garantiza que existe en cualquier server boot.)
  local to_iban = 'AD-SYS0-0000-0001'
  local amount = balance + 1000.00  -- siempre exceeds

  _info('Overdraw attempt: %s → %s | amount=%.2f € (balance=%.2f €) | esperado INSUFFICIENT_FUNDS',
    own_iban, to_iban, amount, balance)

  local req_id = _uuid_v4()
  _do_transfer(own_iban, to_iban, amount, req_id, 'Overdraw test')
end, false)

-- =============================================================================
-- /smoke_transfer_burst <to_iban>
-- Smoke step 6 — 11 calls válidos rápidos → 10 OK + 1 RATE_LIMITED.
-- Cada call con request_id distinto (sino sería replay).
-- Bucket bank.write 10/60s per citizen (SSoT §04 §8).
-- =============================================================================
RegisterCommand('smoke_transfer_burst', function(source, args)
  local to_iban = args[1]
  if not to_iban then
    _info('Usage: /smoke_transfer_burst <to_iban>')
    return
  end

  local from_iban, balance = _fetch_own_iban(true)
  if not from_iban then return end

  if balance < 11.00 then
    _fail('Burst requires balance >= 11 € (current: %.2f €). Add funds first.', balance)
    return
  end

  _info('Burst test: 11 calls of 1 € each | esperado 10 OK + 1 RATE_LIMITED')

  local ok_n, fail_n = 0, 0
  local rate_limited = false
  for i = 1, 11 do
    local req_id = _uuid_v4()
    local response = lib.callback.await('admirals:bank:transfer', false, {
      from_iban  = from_iban,
      to_iban    = to_iban,
      amount     = 1.00,
      concept    = 'Burst ' .. i,
      request_id = req_id,
    })
    if response and response.success then
      ok_n = ok_n + 1
    else
      fail_n = fail_n + 1
      if response and response.error_code == 'RATE_LIMITED' then
        rate_limited = true
      end
      _info('  call #%d: FAIL error_code=%s', i, tostring(response and response.error_code or '?'))
    end
  end

  if ok_n == 10 and rate_limited then
    _ok('Burst PASS: 10 OK + RATE_LIMITED on 11th (expected behavior).')
  else
    _fail('Burst UNEXPECTED: ok=%d fail=%d rate_limited=%s', ok_n, fail_n, tostring(rate_limited))
  end
end, false)

-- =============================================================================
-- Boot: fetch own IBAN al arrancar el client (best-effort, log only).
-- =============================================================================
CreateThread(function()
  Wait(2500)  -- yield to give server callback registration time
  local iban, bal = _fetch_own_iban(true)
  if iban then
    _info('Client smoke ready. Own IBAN=%s balance=%.2f €', iban, bal)
    _info('Commands: /smoke_transfer /smoke_transfer_replay /smoke_transfer_self /smoke_transfer_overdraw /smoke_transfer_burst')
  end
end)
