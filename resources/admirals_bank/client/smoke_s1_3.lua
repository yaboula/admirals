-- =============================================================================
-- Admirals Bank — client/smoke_s1_3.lua
--
-- S1.3 SMOKE TEST TEMPORAL — DELETE POST SIGN-OFF (cleanup commit separado).
--
-- 6 client commands disposables para validar C004 createEscrow + C005
-- releaseEscrow end-to-end. Mismo patrón S1.2 smoke harness.
--
-- Commands:
--   /smoke_escrow_create <seller_iban> <amount>
--     → C004 happy path (create from your personal IBAN).
--
--   /smoke_escrow_release_seller <escrow_id>
--     → C005 direction='seller' (release to seller).
--
--   /smoke_escrow_release_buyer <escrow_id>
--     → C005 direction='buyer' (refund to buyer).
--
--   /smoke_escrow_split <escrow_id>
--     → C005 direction='split' — esperado NOT_IMPLEMENTED.
--
--   /smoke_escrow_replay [request_id]
--     → Re-play último request_id de create (sin args) o uno explícito.
--
--   /smoke_escrow_status <escrow_id>
--     → Trigger lib.callback de getBalance en buyer/seller IBAN para visualizar
--       balance post-transition. NO es un callback formal — usa C001.
--
-- Output canonical:
--   ^2[smoke] OK | ...^7   (verde)
--   ^1[smoke] FAIL | error_code=<code>^7   (rojo)
-- =============================================================================

local _own_iban      = nil
local _last_create_request_id = nil

-- =============================================================================
-- UUID v4 client-side (RFC 4122) — consistente con patrón accounts.lua.
-- =============================================================================
local function _uuid_v4()
  math.randomseed(GetGameTimer() + math.random(1, 1000000))
  local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
  return (template:gsub('[xy]', function(c)
    local v = (c == 'x') and math.random(0, 15) or math.random(8, 11)
    return string.format('%x', v)
  end))
end

-- =============================================================================
-- Helper — imprimir resultado (OK/FAIL con color FiveM ^N).
-- =============================================================================
local function _print_result(cmd_tag, response, extras)
  if response and response.success then
    local parts = { ('^2[smoke %s] OK'):format(cmd_tag) }
    if response.data then
      for k, v in pairs(response.data) do
        parts[#parts + 1] = ('%s=%s'):format(k, tostring(v))
      end
    end
    if extras then
      for k, v in pairs(extras) do
        parts[#parts + 1] = ('%s=%s'):format(k, tostring(v))
      end
    end
    parts[#parts + 1] = '^7'
    print(table.concat(parts, ' | '))
  else
    local code = response and response.error_code or 'NULL_RESPONSE'
    local msg = response and response.message or 'No response'
    print(('^1[smoke %s] FAIL | error_code=%s | message=%s^7'):format(
      cmd_tag, tostring(code), tostring(msg)))
  end
end

-- =============================================================================
-- Fetch own IBAN on resource start (for visibility only — C004 doesn't take buyer_iban
-- as convenience field, caller provides explicit).
-- =============================================================================
CreateThread(function()
  Wait(2000)  -- wait for server + ox_lib readiness.
  local resp = lib.callback.await('admirals:bank:getBalance', false, {})
  if resp and resp.success and resp.data and resp.data.iban then
    _own_iban = resp.data.iban
    print(('^3[smoke] Own IBAN cached: %s (balance=%s €)^7'):format(_own_iban, resp.data.balance))
  else
    print('^3[smoke] Could not fetch own IBAN (maybe starter account not seeded yet).^7')
  end
end)

-- =============================================================================
-- /smoke_escrow_create <seller_iban> <amount>
-- =============================================================================
RegisterCommand('smoke_escrow_create', function(_, args)
  local seller_iban = args[1]
  local amount = tonumber(args[2])
  if not seller_iban or not amount then
    print('^3[smoke] Usage: /smoke_escrow_create <seller_iban> <amount>^7')
    return
  end
  if not _own_iban then
    print('^1[smoke] Own IBAN not cached — reconnect and retry.^7')
    return
  end

  local request_id = _uuid_v4()
  _last_create_request_id = request_id

  local req = {
    buyer_iban         = _own_iban,
    seller_iban        = seller_iban,
    amount             = amount,
    release_condition  = 'manual',
    request_id         = request_id,
  }

  local resp = lib.callback.await('admirals:bank:createEscrow', false, req)
  _print_result('create', resp, { request_id = request_id })
end, false)

-- =============================================================================
-- /smoke_escrow_release_seller <escrow_id>
-- =============================================================================
RegisterCommand('smoke_escrow_release_seller', function(_, args)
  local escrow_id = args[1]
  if not escrow_id then
    print('^3[smoke] Usage: /smoke_escrow_release_seller <escrow_id>^7')
    return
  end
  local request_id = _uuid_v4()
  local resp = lib.callback.await('admirals:bank:releaseEscrow', false, {
    escrow_id  = escrow_id,
    release_to = 'seller',
    request_id = request_id,
  })
  _print_result('release_seller', resp, { request_id = request_id })
end, false)

-- =============================================================================
-- /smoke_escrow_release_buyer <escrow_id>
-- =============================================================================
RegisterCommand('smoke_escrow_release_buyer', function(_, args)
  local escrow_id = args[1]
  if not escrow_id then
    print('^3[smoke] Usage: /smoke_escrow_release_buyer <escrow_id>^7')
    return
  end
  local request_id = _uuid_v4()
  local resp = lib.callback.await('admirals:bank:releaseEscrow', false, {
    escrow_id  = escrow_id,
    release_to = 'buyer',
    request_id = request_id,
  })
  _print_result('release_buyer', resp, { request_id = request_id })
end, false)

-- =============================================================================
-- /smoke_escrow_split <escrow_id>
-- Expected: NOT_IMPLEMENTED error_code.
-- =============================================================================
RegisterCommand('smoke_escrow_split', function(_, args)
  local escrow_id = args[1]
  if not escrow_id then
    print('^3[smoke] Usage: /smoke_escrow_split <escrow_id>^7')
    return
  end
  local request_id = _uuid_v4()
  local resp = lib.callback.await('admirals:bank:releaseEscrow', false, {
    escrow_id   = escrow_id,
    release_to  = 'split',
    split_ratio = 0.5,
    request_id  = request_id,
  })
  _print_result('split_rejected', resp, { request_id = request_id })
end, false)

-- =============================================================================
-- /smoke_escrow_replay [request_id]
-- Sin args → re-play último create request_id cached.
-- =============================================================================
RegisterCommand('smoke_escrow_replay', function(_, args)
  local request_id = args[1] or _last_create_request_id
  if not request_id then
    print('^1[smoke] No cached request_id. Pass one explicitly: /smoke_escrow_replay <uuid>^7')
    return
  end
  if not _own_iban then
    print('^1[smoke] Own IBAN not cached — reconnect and retry.^7')
    return
  end
  -- For replay to trigger Bridges idempotency lookup, resubmit same C004 request
  -- with same request_id (and same shape — Escrow.Create validates shape first).
  -- Use dummy seller_iban from cached last create (client doesn't remember it;
  -- use a placeholder — the idempotency check returns cached response without
  -- re-executing Escrow.Create, so seller_iban is irrelevant post-cache-hit).
  local req = {
    buyer_iban         = _own_iban,
    seller_iban        = _own_iban,  -- irrelevante en replay (cache hit antes de validación)
    amount             = 1.00,
    release_condition  = 'manual',
    request_id         = request_id,
  }
  local resp = lib.callback.await('admirals:bank:createEscrow', false, req)
  _print_result('replay', resp, { request_id = request_id })
end, false)

-- =============================================================================
-- /smoke_escrow_status <iban>
-- C001 getBalance — útil para ver balance post-create/release.
-- =============================================================================
RegisterCommand('smoke_escrow_status', function(_, args)
  local iban = args[1]
  if not iban then
    print('^3[smoke] Usage: /smoke_escrow_status <iban>^7')
    return
  end
  local resp = lib.callback.await('admirals:bank:getBalance', false, { iban = iban })
  _print_result('status', resp, { queried_iban = iban })
end, false)

-- =============================================================================
-- Boot log.
-- =============================================================================
print('^3[smoke] Admirals Bank S1.3 harness loaded: /smoke_escrow_create, _release_seller, _release_buyer, _split, _replay, _status.^7')
